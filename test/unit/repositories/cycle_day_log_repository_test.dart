import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/cycle_math/cycle_math.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/cycle_day_log_repository.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/period_flow.dart';
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
      symptoms: {'cramps', 'headache', 'bloating'},
    );

    await repository.save(log);
    final result = await repository.getByDate(log.date);

    expect(result?.symptoms, {'cramps', 'headache', 'bloating'});
  });

  test('getAll returns every logged day, oldest first', () async {
    await repository.save(emptyLog(date: DateTime.utc(2026, 3, 3)));
    await repository.save(emptyLog(date: DateTime.utc(2026, 3, 1)));
    await repository.save(emptyLog(date: DateTime.utc(2026, 3, 2)));

    final all = await repository.getAll();

    expect(all.map((log) => log.date.day).toList(), [1, 2, 3]);
  });

  test('deleteAll removes every row', () async {
    await repository.save(emptyLog(date: DateTime.utc(2026, 3, 1)));
    await repository.save(emptyLog(date: DateTime.utc(2026, 3, 2)));

    await repository.deleteAll();

    expect(await repository.getAll(), isEmpty);
  });

  group('period starts are worked out from the whole log (#101)', () {
    DateTime d(int day) => DateTime.utc(2026, 3, day);
    CycleDayLog flowLog(int day, PeriodFlow? flow) =>
        CycleDayLog(date: d(day), periodFlow: flow);

    test('back-logging the day before a period moves its start', () async {
      await repository.save(flowLog(2, PeriodFlow.medium));
      await repository.save(flowLog(1, PeriodFlow.light));

      expect((await repository.getPeriodStartDates()).map(dateOnly), [d(1)]);
      expect((await repository.getByDate(d(2)))?.isPeriodStart, isFalse);
      expect((await repository.getByDate(d(1)))?.isPeriodStart, isTrue);
    });

    test('clearing flow on the first day moves the start forward', () async {
      await repository.save(flowLog(1, PeriodFlow.medium));
      await repository.save(flowLog(2, PeriodFlow.medium));
      await repository.save(flowLog(1, null));

      expect((await repository.getPeriodStartDates()).map(dateOnly), [d(2)]);
    });

    test('clearing every day of a period removes it', () async {
      await repository.save(flowLog(1, PeriodFlow.medium));
      await repository.save(flowLog(2, PeriodFlow.medium));
      await repository.save(flowLog(1, null));
      await repository.save(flowLog(2, null));

      expect((await repository.getPeriodStartDates()).map(dateOnly), isEmpty);
    });

    test('deleteAll leaves no period starts behind', () async {
      await repository.save(flowLog(1, PeriodFlow.medium));
      await repository.deleteAll();

      expect((await repository.getPeriodStartDates()).map(dateOnly), isEmpty);
    });

    test('spotting alone does not start a period', () async {
      await repository.save(flowLog(15, PeriodFlow.spotting));

      expect((await repository.getPeriodStartDates()).map(dateOnly), isEmpty);
      expect(
        (await repository.getByDate(d(15)))?.periodFlow,
        PeriodFlow.spotting,
      );
    });

    test('one unlogged day inside a period does not split it', () async {
      await repository.save(flowLog(1, PeriodFlow.medium));
      await repository.save(flowLog(2, PeriodFlow.medium));
      await repository.save(flowLog(4, PeriodFlow.light));

      expect((await repository.getPeriodStartDates()).map(dateOnly), [d(1)]);
    });

    test('save order never changes the starts', () async {
      final logs = [
        flowLog(1, PeriodFlow.spotting),
        flowLog(2, PeriodFlow.heavy),
        flowLog(3, PeriodFlow.heavy),
        flowLog(5, PeriodFlow.light),
        flowLog(14, PeriodFlow.spotting),
        flowLog(29, PeriodFlow.medium),
        flowLog(30, PeriodFlow.medium),
      ];
      final orders = [
        logs,
        logs.reversed.toList(),
        [logs[3], logs[0], logs[6], logs[1], logs[4], logs[2], logs[5]],
      ];
      for (final order in orders) {
        await repository.deleteAll();
        for (final log in order) {
          await repository.save(log);
        }
        expect((await repository.getPeriodStartDates()).map(dateOnly), [
          d(2),
          d(29),
        ]);
      }
    });

    test('the value returned by save reflects the whole log', () async {
      await repository.save(flowLog(2, PeriodFlow.medium));
      final saved = await repository.save(flowLog(1, PeriodFlow.spotting));

      expect(saved.isPeriodStart, isFalse);
      expect((await repository.getPeriodStartDates()).map(dateOnly), [d(2)]);
    });

    test('stale flags stored by an older version are ignored', () async {
      // Rows exactly as the old save() left them after back-logging:
      // both days flagged as starts, plus a stray spotting "start".
      for (final row in [
        {'date': '2026-03-01', 'period_flow': 'light', 'is_period_start': 1},
        {'date': '2026-03-02', 'period_flow': 'medium', 'is_period_start': 1},
        {'date': '2026-03-15', 'period_flow': 'spotting', 'is_period_start': 1},
      ]) {
        await db.insert(cycleDayLogsTable, row);
      }

      expect((await repository.getPeriodStartDates()).map(dateOnly), [d(1)]);
      final all = await repository.getAll();
      expect(
        all.where((log) => log.isPeriodStart).map((log) => dateOnly(log.date)),
        [d(1)],
      );
      final inRange = await repository.getInRange(d(1), d(31));
      expect(
        inRange
            .where((log) => log.isPeriodStart)
            .map((log) => dateOnly(log.date)),
        [d(1)],
      );
    });
  });
}
