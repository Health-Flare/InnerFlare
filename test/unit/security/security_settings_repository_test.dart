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
    expect(await repository.getLockTimeout(), LockTimeout.after15Minutes);
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
