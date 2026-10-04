import 'package:inner_flare/core/cycle_math/cycle_math.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/ovulation_test_result.dart';
import 'package:inner_flare/models/period_flow.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Hand-written SQL access to `cycle_day_logs`. Maps rows to/from
/// [CycleDayLog]; providers call this, never raw SQL directly.
///
/// Period starts are never stored. Every read works them out from the
/// whole flow log with [periodStartsFromFlowLog] (issue #101), so saving
/// or editing one day always updates its neighbours, the order days were
/// saved in never matters, and stale flags written by older versions (or
/// carried in older backup files) are ignored. The `is_period_start`
/// column stays in the schema for compatibility but is not read; new
/// rows store 0 there.
class CycleDayLogRepository {
  CycleDayLogRepository(this._db);

  final Database _db;

  Future<CycleDayLog?> getByDate(DateTime date) async {
    final rows = await _db.query(
      cycleDayLogsTable,
      where: 'date = ?',
      whereArgs: [_dateKey(date)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final starts = await _periodStartKeys();
    return _fromRow(rows.first, starts);
  }

  /// All logged days between [start] and [end], inclusive: backs the
  /// calendar's month view (docs/features/calendar.feature).
  Future<List<CycleDayLog>> getInRange(DateTime start, DateTime end) async {
    final rows = await _db.query(
      cycleDayLogsTable,
      where: 'date >= ? AND date <= ?',
      whereArgs: [_dateKey(start), _dateKey(end)],
    );
    final starts = await _periodStartKeys();
    return rows.map((row) => _fromRow(row, starts)).toList();
  }

  /// Every period-start date on record, oldest first: the raw input to
  /// the cycle-length/prediction math in `cycle_math.dart`. Worked out
  /// from the whole flow log on every call; see the class comment.
  Future<List<DateTime>> getPeriodStartDates() async {
    final keys = await _periodStartKeys();
    return [for (final key in keys) DateTime.parse(key)];
  }

  /// Every date with a period flow logged: the raw input to
  /// `lastLoggedPeriodEndDate` in cycle_math.dart.
  Future<Set<DateTime>> getDatesWithPeriodFlow() async {
    final rows = await _db.query(
      cycleDayLogsTable,
      columns: ['date'],
      where: 'period_flow IS NOT NULL',
    );
    return rows.map((row) => DateTime.parse(row['date'] as String)).toSet();
  }

  /// Every logged day on record, oldest first: the full-history read
  /// export uses to build a backup file (docs/features/export.feature).
  Future<List<CycleDayLog>> getAll() async {
    final rows = await _db.query(cycleDayLogsTable, orderBy: 'date ASC');
    final starts = _periodStartKeysFromRows(rows);
    return rows.map((row) => _fromRow(row, starts)).toList();
  }

  /// Deletes every row: only used by import's "replace" strategy
  /// (docs/features/export.feature), immediately before re-inserting the
  /// imported set.
  Future<void> deleteAll() => _db.delete(cycleDayLogsTable);

  /// Whether the user has logged anything at all: distinguishes "no data
  /// yet" from "nothing in this particular month" for the calendar's empty
  /// state (docs/features/calendar.feature, "Empty calendar before any
  /// logging").
  Future<bool> hasAnyLogs() async {
    final rows = await _db.query(cycleDayLogsTable, limit: 1);
    return rows.isNotEmpty;
  }

  /// Saves [log], replacing any existing row for that date: there is
  /// never more than one row per date (see docs/features/log.feature,
  /// "Editing an existing day's log"). `isPeriodStart` on [log] is
  /// ignored; the returned log carries the value worked out from the
  /// whole log after this save.
  Future<CycleDayLog> save(CycleDayLog log) async {
    final dateKey = _dateKey(log.date);

    await _db.insert(
      cycleDayLogsTable,
      _toRow(log, dateKey),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final starts = await _periodStartKeys();
    return log.copyWith(isPeriodStart: starts.contains(dateKey));
  }

  Future<Set<String>> _periodStartKeys() async {
    final rows = await _db.query(
      cycleDayLogsTable,
      columns: ['date', 'period_flow'],
      where: 'period_flow IS NOT NULL',
    );
    return _periodStartKeysFromRows(rows);
  }

  /// Period-start date keys, in date order, from any set of rows that
  /// includes every flow day (rows without flow are skipped).
  Set<String> _periodStartKeysFromRows(List<Map<String, Object?>> rows) {
    final flowByDate = <DateTime, PeriodFlow>{
      for (final row in rows)
        if (row['period_flow'] != null)
          DateTime.parse(row['date'] as String): PeriodFlow.values.byName(
            row['period_flow'] as String,
          ),
    };
    return {
      for (final start in periodStartsFromFlowLog(flowByDate)) _dateKey(start),
    };
  }

  static String _dateKey(DateTime date) {
    final dateOnly = DateTime.utc(date.year, date.month, date.day);
    return dateOnly.toIso8601String().split('T').first;
  }

  Map<String, Object?> _toRow(CycleDayLog log, String dateKey) {
    return {
      'date': dateKey,
      'period_flow': log.periodFlow?.name,
      // Legacy column, not read since #101; see the class comment.
      'is_period_start': 0,
      'symptoms': log.symptoms.join(','),
      'note': log.note,
      'ovulation_test_result': log.ovulationTestResult?.name,
      'basal_body_temp_celsius': log.basalBodyTempCelsius,
    };
  }

  CycleDayLog _fromRow(Map<String, Object?> row, Set<String> periodStarts) {
    final symptomsRaw = row['symptoms'] as String? ?? '';
    final dateKey = row['date'] as String;
    return CycleDayLog(
      date: DateTime.parse(dateKey),
      periodFlow: _enumOrNull(PeriodFlow.values, row['period_flow'] as String?),
      isPeriodStart: periodStarts.contains(dateKey),
      symptoms: symptomsRaw.isEmpty ? const {} : symptomsRaw.split(',').toSet(),
      note: row['note'] as String?,
      ovulationTestResult: _enumOrNull(
        OvulationTestResult.values,
        row['ovulation_test_result'] as String?,
      ),
      basalBodyTempCelsius: (row['basal_body_temp_celsius'] as num?)
          ?.toDouble(),
    );
  }

  T? _enumOrNull<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    return values.byName(name);
  }
}
