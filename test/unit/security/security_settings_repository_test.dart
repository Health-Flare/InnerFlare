import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/security_settings_repository.dart';
import 'package:inner_flare/models/lock_timeout.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../helpers/test_database.dart';

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  late Database db;

  tearDown(() => db.close());

  test('a fresh install has not acknowledged the disclaimer, and saving '
      'the flag does not change the default lock timeout', () async {
    db = await openInMemoryTestDatabase(
      onCreate: onCreate,
      version: schemaVersion,
    );
    final repository = SecuritySettingsRepository(db);

    expect(await repository.getDisclaimerAcknowledged(), isFalse);
    expect(await repository.getLockTimeout(), LockTimeout.defaultValue);

    await repository.setDisclaimerAcknowledged();

    expect(await repository.getDisclaimerAcknowledged(), isTrue);
    expect(await repository.getLockTimeout(), LockTimeout.after1Minute);
  });

  test('picking 15 minutes on a fresh install keeps 15 minutes, even '
      'after the disclaimer is acknowledged', () async {
    db = await openInMemoryTestDatabase(
      onCreate: onCreate,
      version: schemaVersion,
    );
    final repository = SecuritySettingsRepository(db);

    await repository.setLockTimeout(LockTimeout.after15Minutes);
    await repository.setDisclaimerAcknowledged();

    expect(await repository.getLockTimeout(), LockTimeout.after15Minutes);
  });

  group('upgrading from schema 9 (issue #90: default moved to 1 minute)', () {
    /// A schema 9 `security_settings` row as the old code left it. On
    /// schema 9, accepting the disclaimer stored the then-default of 15
    /// minutes, so 15 is the only value that can't be told apart from
    /// "never chosen".
    Future<SecuritySettingsRepository> upgradeFrom9({
      required bool hasRow,
      int? storedMinutes,
    }) async {
      db = await openInMemoryTestDatabase(
        onCreate: (oldDb, _) async {
          await oldDb.execute('''
            CREATE TABLE security_settings (
              id INTEGER PRIMARY KEY CHECK (id = 0),
              lock_timeout_minutes INTEGER,
              disclaimer_acknowledged INTEGER NOT NULL DEFAULT 0
            )
          ''');
          if (hasRow) {
            await oldDb.insert('security_settings', {
              'id': 0,
              'lock_timeout_minutes': storedMinutes,
              'disclaimer_acknowledged': 1,
            });
          }
        },
        version: 9,
      );
      await onUpgrade(db, 9, schemaVersion);
      return SecuritySettingsRepository(db);
    }

    test('no saved row gets the new default', () async {
      final repository = await upgradeFrom9(hasRow: false);
      expect(await repository.getLockTimeout(), LockTimeout.after1Minute);
    });

    test('the old default of 15 minutes moves to the new default', () async {
      final repository = await upgradeFrom9(hasRow: true, storedMinutes: 15);
      expect(await repository.getLockTimeout(), LockTimeout.after1Minute);
    });

    test('choosing 15 minutes again after the upgrade sticks', () async {
      final repository = await upgradeFrom9(hasRow: true, storedMinutes: 15);
      await repository.setLockTimeout(LockTimeout.after15Minutes);
      await repository.setDisclaimerAcknowledged();
      expect(await repository.getLockTimeout(), LockTimeout.after15Minutes);
    });

    // Regression guards: every other stored value was a real choice.
    for (final kept in [
      LockTimeout.immediately,
      LockTimeout.after1Minute,
      LockTimeout.after5Minutes,
      LockTimeout.after30Minutes,
      LockTimeout.after1Hour,
      LockTimeout.never,
    ]) {
      test('a saved "${kept.label}" is kept', () async {
        final repository = await upgradeFrom9(
          hasRow: true,
          storedMinutes: kept.storedMinutes,
        );
        expect(await repository.getLockTimeout(), kept);
        // And acknowledging again (as the first-run screen does) leaves
        // it alone.
        await repository.setDisclaimerAcknowledged();
        expect(await repository.getLockTimeout(), kept);
      });
    }

    test('running the upgrade step twice is harmless', () async {
      final repository = await upgradeFrom9(hasRow: true, storedMinutes: 30);
      await onUpgrade(db, 9, schemaVersion);
      expect(await repository.getLockTimeout(), LockTimeout.after30Minutes);
    });
  });

  test('changing the lock timeout keeps an existing acknowledgement, '
      'including when the timeout is Never', () async {
    db = await openInMemoryTestDatabase(
      onCreate: onCreate,
      version: schemaVersion,
    );
    final repository = SecuritySettingsRepository(db);

    await repository.setLockTimeout(LockTimeout.never);
    await repository.setDisclaimerAcknowledged();
    await repository.setLockTimeout(LockTimeout.after1Minute);

    expect(await repository.getDisclaimerAcknowledged(), isTrue);
    expect(await repository.getLockTimeout(), LockTimeout.after1Minute);

    await repository.setLockTimeout(LockTimeout.never);
    expect(await repository.getDisclaimerAcknowledged(), isTrue);
    expect(await repository.getLockTimeout(), LockTimeout.never);
  });

  test('upgrading a schema 7 database adds the flag as not acknowledged '
      'and keeps the saved lock timeout', () async {
    db = await openInMemoryTestDatabase(
      onCreate: (oldDb, _) async {
        await oldDb.execute('''
          CREATE TABLE security_settings (
            id INTEGER PRIMARY KEY CHECK (id = 0),
            lock_timeout_minutes INTEGER
          )
        ''');
        await oldDb.insert('security_settings', {
          'id': 0,
          'lock_timeout_minutes': 5,
        });
      },
      version: 7,
    );

    await onUpgrade(db, 7, schemaVersion);

    final repository = SecuritySettingsRepository(db);
    expect(await repository.getLockTimeout(), LockTimeout.after5Minutes);
    expect(await repository.getDisclaimerAcknowledged(), isFalse);

    await repository.setDisclaimerAcknowledged();
    await repository.setLockTimeout(LockTimeout.after30Minutes);
    expect(await repository.getDisclaimerAcknowledged(), isTrue);
    expect(await repository.getLockTimeout(), LockTimeout.after30Minutes);
  });
}
