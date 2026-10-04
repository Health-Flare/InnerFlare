// The user's own "Period day" choice (issue #103) through the repository,
// against a real (in-memory, FFI) SQLite database.

import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/cycle_math/cycle_math.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/cycle_day_log_repository.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/period_flow.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../helpers/test_database.dart';

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  late Database db;
  late CycleDayLogRepository repository;

  setUp(() async {
    db = await openInMemoryTestDatabase(
      onCreate: onCreate,
      version: schemaVersion,
    );
    repository = CycleDayLogRepository(db);
  });

  tearDown(() => db.close());

  DateTime d(int day) => DateTime.utc(2026, 3, day);
  CycleDayLog log(int day, PeriodFlow? flow, {bool? override}) =>
      CycleDayLog(date: d(day), periodFlow: flow, periodDayOverride: override);

  Future<List<DateTime>> starts() async =>
      (await repository.getPeriodStartDates()).map(dateOnly).toList();

  group('storing the choice', () {
    test('a choice that disagrees with flow is saved and read back', () async {
      await repository.save(log(1, PeriodFlow.spotting, override: true));
      await repository.save(log(10, PeriodFlow.heavy, override: false));

      expect((await repository.getByDate(d(1)))?.periodDayOverride, isTrue);
      expect((await repository.getByDate(d(10)))?.periodDayOverride, isFalse);
    });

    test('a choice that matches flow is stored as no choice', () async {
      await repository.save(log(1, PeriodFlow.medium, override: true));
      await repository.save(log(2, null, override: false));

      expect((await repository.getByDate(d(1)))?.periodDayOverride, isNull);
      expect((await repository.getByDate(d(2)))?.periodDayOverride, isNull);
    });

    test('logging flow that matches an earlier choice clears it', () async {
      await repository.save(log(1, null, override: true));
      await repository.save(log(1, PeriodFlow.light, override: true));

      final saved = await repository.getByDate(d(1));
      expect(saved?.periodDayOverride, isNull);
      expect(saved?.isPeriodDay, isTrue);
    });

    test('the choice never changes flow, symptoms or note', () async {
      await repository.save(
        CycleDayLog(
          date: d(10),
          periodFlow: PeriodFlow.heavy,
          symptoms: const {'cramps'},
          note: 'after the procedure',
          periodDayOverride: false,
        ),
      );

      final saved = await repository.getByDate(d(10));
      expect(saved?.periodFlow, PeriodFlow.heavy);
      expect(saved?.symptoms, {'cramps'});
      expect(saved?.note, 'after the procedure');
    });

    test('getAll and getInRange carry the choice', () async {
      await repository.save(log(1, PeriodFlow.spotting, override: true));

      expect((await repository.getAll()).single.periodDayOverride, isTrue);
      expect(
        (await repository.getInRange(d(1), d(31))).single.periodDayOverride,
        isTrue,
      );
    });
  });

  group('period starts use the choice', () {
    test('spotting marked as a period day starts the period', () async {
      await repository.save(log(1, PeriodFlow.spotting, override: true));
      await repository.save(log(2, PeriodFlow.medium));

      expect(await starts(), [d(1)]);
      expect((await repository.getByDate(d(1)))?.isPeriodStart, isTrue);
      expect((await repository.getByDate(d(2)))?.isPeriodStart, isFalse);
    });

    test('a day with no flow marked as a period day starts one', () async {
      await repository.save(log(1, null, override: true));

      expect(await starts(), [d(1)]);
    });

    test('bleeding marked as not a period is left out', () async {
      await repository.save(log(1, PeriodFlow.medium));
      await repository.save(log(10, PeriodFlow.heavy, override: false));
      await repository.save(log(11, PeriodFlow.heavy, override: false));

      expect(await starts(), [d(1)]);
      final day10 = await repository.getByDate(d(10));
      expect(day10?.isPeriodStart, isFalse);
      expect(day10?.isPeriodDay, isFalse);
      expect(day10?.periodFlow, PeriodFlow.heavy);
    });

    test('marking the first day as not a period moves the start', () async {
      for (final day in [1, 2, 3]) {
        await repository.save(log(day, PeriodFlow.medium));
      }
      await repository.save(log(1, PeriodFlow.medium, override: false));

      expect(await starts(), [d(2)]);
    });

    test('clearing the choice goes back to the flow rule', () async {
      await repository.save(log(1, PeriodFlow.spotting, override: true));
      await repository.save(log(2, PeriodFlow.medium));
      await repository.save(log(1, PeriodFlow.spotting));

      expect(await starts(), [d(2)]);
    });

    test('the value returned by save reflects the choice', () async {
      final saved = await repository.save(
        log(1, PeriodFlow.spotting, override: true),
      );

      expect(saved.isPeriodStart, isTrue);
      expect(saved.isPeriodDay, isTrue);
      expect(saved.periodDayOverride, isTrue);
    });
  });

  group('isPeriodDay', () {
    test('worked out from flow when there is no choice', () async {
      await repository.save(log(1, PeriodFlow.spotting));
      await repository.save(log(2, PeriodFlow.medium));
      await repository.save(log(3, PeriodFlow.spotting));
      await repository.save(log(15, PeriodFlow.spotting));
      await repository.save(log(20, null));

      final byDay = {
        for (final l in await repository.getAll()) l.date.day: l.isPeriodDay,
      };
      expect(byDay, {1: true, 2: true, 3: true, 15: false, 20: false});
    });
  });

  group('days with period flow, for "days since last period"', () {
    test('leave out days marked as not a period', () async {
      await repository.save(log(1, PeriodFlow.medium));
      await repository.save(log(2, PeriodFlow.medium));
      await repository.save(log(3, PeriodFlow.spotting, override: false));

      expect(
        (await repository.getDatesWithPeriodFlow()).map(dateOnly).toSet(),
        {d(1), d(2)},
      );
    });

    test('include days with no flow marked as a period day', () async {
      await repository.save(log(1, PeriodFlow.medium));
      await repository.save(log(2, null, override: true));

      expect(
        (await repository.getDatesWithPeriodFlow()).map(dateOnly).toSet(),
        {d(1), d(2)},
      );
    });
  });

  group('schema', () {
    test(
      'upgrading from schema 8 adds the column and keeps every row',
      () async {
        // Every in-memory database shares the ":memory:" path and sqflite
        // caches by path, so close setUp's database or this reopens it.
        await db.close();
        final oldDb = await openInMemoryTestDatabase(
          onCreate: (oldDb, _) async {
            await oldDb.execute('''
            CREATE TABLE cycle_day_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL UNIQUE,
              period_flow TEXT,
              is_period_start INTEGER NOT NULL DEFAULT 0,
              symptoms TEXT NOT NULL DEFAULT '',
              note TEXT,
              ovulation_test_result TEXT,
              basal_body_temp_celsius REAL
            )
          ''');
            await oldDb.insert('cycle_day_logs', {
              'date': '2026-03-01',
              'period_flow': 'medium',
              'symptoms': 'cramps',
              'note': 'kept',
            });
          },
          version: 8,
        );
        db = oldDb;

        await onUpgrade(oldDb, 8, schemaVersion);

        final columns = await oldDb.rawQuery(
          'PRAGMA table_info(cycle_day_logs)',
        );
        expect(columns.map((c) => c['name']), contains('period_day_override'));
        final migrated = await CycleDayLogRepository(oldDb).getAll();
        expect(migrated.single.periodFlow, PeriodFlow.medium);
        expect(migrated.single.note, 'kept');
        expect(migrated.single.periodDayOverride, isNull);
      },
    );

    test('schema version is bumped past 8', () {
      expect(schemaVersion, greaterThan(8));
    });
  });
}
