import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/ovulation_test_result.dart';
import 'package:inner_flare/models/period_flow.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Hand-written SQL access to `cycle_day_logs`. Maps rows to/from
/// [CycleDayLog]; providers call this, never raw SQL directly.
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
    return _fromRow(rows.first);
  }

  /// All logged days between [start] and [end], inclusive — backs the
  /// calendar's month view (docs/features/calendar.feature).
  Future<List<CycleDayLog>> getInRange(DateTime start, DateTime end) async {
    final rows = await _db.query(
      cycleDayLogsTable,
      where: 'date >= ? AND date <= ?',
      whereArgs: [_dateKey(start), _dateKey(end)],
    );
    return rows.map(_fromRow).toList();
  }

  /// Every period-start date on record, oldest first — the raw input to
  /// the cycle-length/prediction math in `cycle_math.dart`.
  Future<List<DateTime>> getPeriodStartDates() async {
    final rows = await _db.query(
      cycleDayLogsTable,
      columns: ['date'],
      where: 'is_period_start = 1',
      orderBy: 'date ASC',
    );
    return rows.map((row) => DateTime.parse(row['date'] as String)).toList();
  }

  /// Whether the user has logged anything at all — distinguishes "no data
  /// yet" from "nothing in this particular month" for the calendar's empty
  /// state (docs/features/calendar.feature, "Empty calendar before any
  /// logging").
  Future<bool> hasAnyLogs() async {
    final rows = await _db.query(cycleDayLogsTable, limit: 1);
    return rows.isNotEmpty;
  }

  /// Saves [log], replacing any existing row for that date — there is
  /// never more than one row per date (see docs/features/log.feature,
  /// "Editing an existing day's log"). `isPeriodStart` on [log] is
  /// ignored and recomputed from whether the prior day already had a
  /// period flow logged.
  Future<CycleDayLog> save(CycleDayLog log) async {
    final dateKey = _dateKey(log.date);
    final saved = log.copyWith(
      isPeriodStart: await _isPeriodStart(log.date, log.periodFlow),
    );

    await _db.insert(
      cycleDayLogsTable,
      _toRow(saved, dateKey),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return saved;
  }

  Future<bool> _isPeriodStart(DateTime date, PeriodFlow? periodFlow) async {
    if (periodFlow == null) return false;

    final priorDayKey = _dateKey(date.subtract(const Duration(days: 1)));
    final priorRows = await _db.query(
      cycleDayLogsTable,
      columns: ['period_flow'],
      where: 'date = ?',
      whereArgs: [priorDayKey],
      limit: 1,
    );
    final priorHadFlow =
        priorRows.isNotEmpty && priorRows.first['period_flow'] != null;
    return !priorHadFlow;
  }

  static String _dateKey(DateTime date) {
    final dateOnly = DateTime.utc(date.year, date.month, date.day);
    return dateOnly.toIso8601String().split('T').first;
  }

  Map<String, Object?> _toRow(CycleDayLog log, String dateKey) {
    return {
      'date': dateKey,
      'period_flow': log.periodFlow?.name,
      'is_period_start': log.isPeriodStart ? 1 : 0,
      'symptoms': log.symptoms.join(','),
      'note': log.note,
      'ovulation_test_result': log.ovulationTestResult?.name,
      'basal_body_temp_celsius': log.basalBodyTempCelsius,
    };
  }

  CycleDayLog _fromRow(Map<String, Object?> row) {
    final symptomsRaw = row['symptoms'] as String? ?? '';
    return CycleDayLog(
      date: DateTime.parse(row['date'] as String),
      periodFlow: _enumOrNull(PeriodFlow.values, row['period_flow'] as String?),
      isPeriodStart: (row['is_period_start'] as int? ?? 0) != 0,
      symptoms: symptomsRaw.isEmpty
          ? const {}
          : symptomsRaw.split(',').toSet(),
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
