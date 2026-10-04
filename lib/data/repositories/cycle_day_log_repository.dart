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
///
/// The user's own "Period day" choice (issue #103) is stored in
/// `period_day_override` and applied on every read through
/// [effectivePeriodFlowLog], before the period rule runs. A choice that
/// says no more than the day's flow is stored as NULL (see
/// [normalisePeriodDayOverride]).
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
    final period = await _periodInfo();
    return _fromRow(rows.first, period);
  }

  /// All logged days between [start] and [end], inclusive: backs the
  /// calendar's month view (docs/features/calendar.feature).
  Future<List<CycleDayLog>> getInRange(DateTime start, DateTime end) async {
    final rows = await _db.query(
      cycleDayLogsTable,
      where: 'date >= ? AND date <= ?',
      whereArgs: [_dateKey(start), _dateKey(end)],
    );
    final period = await _periodInfo();
    return rows.map((row) => _fromRow(row, period)).toList();
  }

  /// Every period-start date on record, oldest first: the raw input to
  /// the cycle-length/prediction math in `cycle_math.dart`. Worked out
  /// from the whole flow log on every call; see the class comment.
  Future<List<DateTime>> getPeriodStartDates() async {
    final period = await _periodInfo();
    return [for (final key in period.starts) DateTime.parse(key)];
  }

  /// Every date with period flow once the user's choices are applied:
  /// logged flow, minus days marked as not a period day, plus days marked
  /// as one. The raw input to `lastLoggedPeriodEndDate` in cycle_math.dart.
  Future<Set<DateTime>> getDatesWithPeriodFlow() async {
    final effective = _effectiveFlowLog(await _periodRows());
    return effective.keys.toSet();
  }

  /// Every logged day on record, oldest first: the full-history read
  /// export uses to build a backup file (docs/features/export.feature).
  Future<List<CycleDayLog>> getAll() async {
    final rows = await _db.query(cycleDayLogsTable, orderBy: 'date ASC');
    final period = _periodInfoFromRows(rows);
    return rows.map((row) => _fromRow(row, period)).toList();
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
  /// "Editing an existing day's log"). `isPeriodStart` and `isPeriodDay`
  /// on [log] are ignored, and `periodDayOverride` is stored normalised;
  /// the returned log carries all three as they are after this save.
  Future<CycleDayLog> save(CycleDayLog log) async {
    final dateKey = _dateKey(log.date);
    final normalised = log.copyWith(
      periodDayOverride: normalisePeriodDayOverride(
        flow: log.periodFlow,
        choice: log.periodDayOverride,
      ),
    );

    await _db.insert(
      cycleDayLogsTable,
      _toRow(normalised, dateKey),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final period = await _periodInfo();
    return normalised.copyWith(
      isPeriodStart: period.starts.contains(dateKey),
      isPeriodDay: period.days.contains(dateKey),
    );
  }

  /// Only the rows the period rule can see: a flow or a choice.
  Future<List<Map<String, Object?>>> _periodRows() {
    return _db.query(
      cycleDayLogsTable,
      columns: ['date', 'period_flow', 'period_day_override'],
      where: 'period_flow IS NOT NULL OR period_day_override IS NOT NULL',
    );
  }

  Future<_PeriodInfo> _periodInfo() async =>
      _periodInfoFromRows(await _periodRows());

  /// Period-start and period-day date keys from any set of rows that
  /// includes every row with a flow or a choice.
  _PeriodInfo _periodInfoFromRows(List<Map<String, Object?>> rows) {
    final effective = _effectiveFlowLog(rows);
    return _PeriodInfo(
      starts: {
        for (final start in periodStartsFromFlowLog(effective)) _dateKey(start),
      },
      days: {for (final day in periodDaysFromFlowLog(effective)) _dateKey(day)},
    );
  }

  Map<DateTime, PeriodFlow> _effectiveFlowLog(List<Map<String, Object?>> rows) {
    return effectivePeriodFlowLog(
      flowByDate: {
        for (final row in rows)
          DateTime.parse(row['date'] as String): _enumOrNull(
            PeriodFlow.values,
            row['period_flow'] as String?,
          ),
      },
      periodDayOverrides: {
        for (final row in rows)
          if (row['period_day_override'] != null)
            DateTime.parse(row['date'] as String):
                row['period_day_override'] == 1,
      },
    );
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
      'period_day_override': switch (log.periodDayOverride) {
        null => null,
        true => 1,
        false => 0,
      },
    };
  }

  CycleDayLog _fromRow(Map<String, Object?> row, _PeriodInfo period) {
    final symptomsRaw = row['symptoms'] as String? ?? '';
    final dateKey = row['date'] as String;
    return CycleDayLog(
      date: DateTime.parse(dateKey),
      periodFlow: _enumOrNull(PeriodFlow.values, row['period_flow'] as String?),
      isPeriodStart: period.starts.contains(dateKey),
      isPeriodDay: period.days.contains(dateKey),
      periodDayOverride: switch (row['period_day_override']) {
        null => null,
        final value => value == 1,
      },
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

class _PeriodInfo {
  const _PeriodInfo({required this.starts, required this.days});

  final Set<String> starts;
  final Set<String> days;
}
