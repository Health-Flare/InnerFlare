import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/cycle_day_log_repository.dart';
import 'package:inner_flare/models/period_flow.dart';
import 'package:inner_flare/models/symptom.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../fixtures/cycle_day_log_fixtures.dart';
import '../../helpers/test_database.dart';

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  late Database db;
  late CycleDayLogRepository repository;

  setUp(() async {
    db = await openInMemoryTestDatabase(onCreate: onCreate);
    repository = CycleDayLogRepository(db);
  });

  tearDown(() => db.close());

  test('a saved log with zero input can be read back unchanged', () async {
    final log = emptyLog(date: DateTime.utc(2026, 3, 1));

    await repository.save(log);
    final result = await repository.getByDate(log.date);

    expect(result?.periodFlow, isNull);
    expect(result?.symptoms, isEmpty);
    expect(result?.note, isNull);
  });

  test('getByDate returns null when nothing was ever logged', () async {
    final result = await repository.getByDate(DateTime.utc(2026, 3, 1));
    expect(result, isNull);
  });

  test(
    'a period flow with no prior-day flow is marked as the period start',
    () async {
      final log = periodStartLog(date: DateTime.utc(2026, 3, 1));

      final saved = await repository.save(log);

      expect(saved.isPeriodStart, isTrue);
    },
  );

  test(
    'a period flow the day after another period-flow day is not a new start',
    () async {
      await repository.save(
        periodStartLog(date: DateTime.utc(2026, 3, 1), flow: PeriodFlow.light),
      );

      final saved = await repository.save(
        periodStartLog(date: DateTime.utc(2026, 3, 2), flow: PeriodFlow.medium),
      );

      expect(saved.isPeriodStart, isFalse);
    },
  );

  test('saving twice for the same date updates, not duplicates', () async {
    final date = DateTime.utc(2026, 3, 1);
    await repository.save(emptyLog(date: date).copyWith(note: 'light day'));
    await repository.save(
      emptyLog(date: date).copyWith(periodFlow: PeriodFlow.heavy),
    );

    final rows = await db.query(cycleDayLogsTable);
    final result = await repository.getByDate(date);

    expect(rows, hasLength(1));
    expect(result?.periodFlow, PeriodFlow.heavy);
    expect(result?.note, isNull);
  });

  test('symptom sets round-trip through storage', () async {
    final log = symptomOnlyLog(
      date: DateTime.utc(2026, 3, 1),
      symptoms: {Symptom.cramps, Symptom.headache, Symptom.bloating},
    );

    await repository.save(log);
    final result = await repository.getByDate(log.date);

    expect(result?.symptoms, {
      Symptom.cramps,
      Symptom.headache,
      Symptom.bloating,
    });
  });
}
