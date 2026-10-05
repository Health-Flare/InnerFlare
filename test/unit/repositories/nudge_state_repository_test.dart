import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/nudge_state_repository.dart';
import 'package:inner_flare/core/nudges/nudge_rules.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../helpers/test_database.dart';

// docs/features/dashboard_nudges.feature: "Nudge choices are stored
// per-device, never synced", "A snoozed cleanup nudge comes back after the
// next card is added" (it stays snoozed across restarts), and the debug
// "Reset all nudges" / "End snoozes now" actions.

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  late Database db;
  tearDown(() => db.close());

  Future<NudgeStateRepository> fresh() async {
    db = await openInMemoryTestDatabase(
      onCreate: onCreate,
      version: schemaVersion,
    );
    return NudgeStateRepository(db);
  }

  test('a fresh install has no nudge choices', () async {
    final repository = await fresh();
    expect(await repository.getAll(), isEmpty);
  });

  test('each kind of choice is saved and read back', () async {
    final repository = await fresh();
    final until = DateTime(2026, 12, 3);

    await repository.save(
      'a',
      const NudgeState(disposition: NudgeDisposition.dismissedPermanently),
    );
    await repository.save(
      'b',
      NudgeState(disposition: NudgeDisposition.snoozed, snoozedUntil: until),
    );
    await repository.save(
      'c',
      const NudgeState(disposition: NudgeDisposition.snoozedUntilCardAdded),
    );

    final all = await repository.getAll();
    expect(all['a']!.disposition, NudgeDisposition.dismissedPermanently);
    expect(all['b']!.disposition, NudgeDisposition.snoozed);
    expect(all['b']!.snoozedUntil, until);
    expect(all['c']!.disposition, NudgeDisposition.snoozedUntilCardAdded);
  });

  test(
    'saving again replaces the earlier choice for that nudge only',
    () async {
      final repository = await fresh();
      await repository.save(
        'a',
        const NudgeState(disposition: NudgeDisposition.snoozedUntilCardAdded),
      );
      await repository.save(
        'b',
        const NudgeState(disposition: NudgeDisposition.dismissedPermanently),
      );
      await repository.save(
        'a',
        const NudgeState(disposition: NudgeDisposition.dismissedPermanently),
      );

      final all = await repository.getAll();
      expect(all.length, 2);
      expect(all['a']!.disposition, NudgeDisposition.dismissedPermanently);
      expect(all['b']!.disposition, NudgeDisposition.dismissedPermanently);
    },
  );

  test(
    'a card being added ends only "until a card is added" snoozes',
    () async {
      final repository = await fresh();
      final until = DateTime(2026, 12, 3);
      await repository.save(
        'cleanup',
        const NudgeState(disposition: NudgeDisposition.snoozedUntilCardAdded),
      );
      await repository.save(
        'suggestion',
        NudgeState(disposition: NudgeDisposition.snoozed, snoozedUntil: until),
      );
      await repository.save(
        'gone',
        const NudgeState(disposition: NudgeDisposition.dismissedPermanently),
      );

      await repository.endCardAddedSnoozes();

      final all = await repository.getAll();
      expect(all.containsKey('cleanup'), isFalse);
      expect(all['suggestion']!.snoozedUntil, until);
      expect(all['gone']!.disposition, NudgeDisposition.dismissedPermanently);
    },
  );

  test(
    'debug: "End snoozes now" clears every snooze, keeps dismissals',
    () async {
      final repository = await fresh();
      await repository.save(
        'cleanup',
        const NudgeState(disposition: NudgeDisposition.snoozedUntilCardAdded),
      );
      await repository.save(
        'suggestion',
        NudgeState(
          disposition: NudgeDisposition.snoozed,
          snoozedUntil: DateTime(2026, 12, 3),
        ),
      );
      await repository.save(
        'gone',
        const NudgeState(disposition: NudgeDisposition.dismissedPermanently),
      );

      await repository.endAllSnoozes();

      expect((await repository.getAll()).keys, ['gone']);
    },
  );

  test('debug: "Reset all nudges" forgets every choice', () async {
    final repository = await fresh();
    await repository.save(
      'gone',
      const NudgeState(disposition: NudgeDisposition.dismissedPermanently),
    );
    await repository.deleteAll();
    expect(await repository.getAll(), isEmpty);
  });

  test('upgrading a schema 9 database adds the nudge table, empty, and '
      'leaves existing data alone', () async {
    db = await openInMemoryTestDatabase(
      onCreate: (oldDb, _) async {
        await oldDb.execute(
          'CREATE TABLE cycle_day_logs (id INTEGER PRIMARY KEY, date TEXT)',
        );
        await oldDb.insert('cycle_day_logs', {'id': 1, 'date': '2026-09-01'});
      },
    );
    await onUpgrade(db, 9, schemaVersion);

    expect(schemaVersion, greaterThanOrEqualTo(10));
    expect(await NudgeStateRepository(db).getAll(), isEmpty);
    expect(await db.query('cycle_day_logs'), hasLength(1));
  });

  test('the upgrade step is safe to run twice', () async {
    final repository = await fresh();
    await repository.save(
      'gone',
      const NudgeState(disposition: NudgeDisposition.dismissedPermanently),
    );
    await onUpgrade(db, 9, schemaVersion);
    expect((await repository.getAll()).keys, ['gone']);
  });
}
