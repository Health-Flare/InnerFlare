// SIMULATORS ONLY: writes the real encrypted database and real Keychain
// items for this app. Never run it on a phone with data you care about.
//
// Exercises key binding (docs/features/unlock.feature) against the real
// iOS Keychain and SQLCipher, which unit tests can't reach:
// - first run and a reopen with the app's default unlock path open the
//   same database with the same key;
// - moving a key from the old slot into the user-presence slot never
//   loses the old key, whatever the simulator's Keychain does with a
//   `.userPresence` item.
//
// Run:
//   flutter test integration_test/key_binding_test.dart -d <simulator-id>

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/security/biometric_gate.dart';
import 'package:inner_flare/core/security/db_passphrase_store.dart';
import 'package:inner_flare/core/security/screen_lock_probe.dart';
import 'package:inner_flare/core/security/secure_key_store.dart';
import 'package:inner_flare/data/database/app_database.dart';
import 'package:integration_test/integration_test.dart';

class _Fixed implements ScreenLockProbe {
  const _Fixed(this.value);

  final bool value;

  @override
  Future<bool> hasScreenLock() async => value;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final unbound = FlutterSecureKeyStore.unbound();
  final bound = FlutterSecureKeyStore.bound();
  const key = DbPassphraseStore.key;

  testWidgets('first run and reopen open the same encrypted database', (
    tester,
  ) async {
    final hasLock = await LocalAuthScreenLockProbe().hasScreenLock();
    debugPrint('KEYBINDING simulator hasScreenLock=$hasLock');

    final first = AppDatabase(
      passphraseStore: DbPassphraseStore(
        legacyGate: const AlwaysAllowBiometricGate(),
      ),
    );
    final db1 = await first.open();
    await db1.execute(
      'CREATE TABLE IF NOT EXISTS _kb_probe (id INTEGER PRIMARY KEY)',
    );
    await db1.insert('_kb_probe', {'id': 1});
    await db1.close();
    debugPrint('KEYBINDING first open protection=${first.protection}');

    final second = AppDatabase(
      passphraseStore: DbPassphraseStore(
        legacyGate: const AlwaysAllowBiometricGate(),
      ),
    );
    final db2 = await second.open();
    final rows = await db2.query('_kb_probe');
    debugPrint('KEYBINDING reopen protection=${second.protection}');
    expect(rows, isNotEmpty, reason: 'reopen read the row back');
    await db2.execute('DROP TABLE _kb_probe');
    await db2.close();
    expect(second.protection, first.protection);
  });

  testWidgets('moving the key into the user-presence slot never loses the '
      'old key on a real Keychain', (tester) async {
    final before = await unbound.read(key);
    expect(before, isNotNull, reason: 'set up by the previous test');

    final store = DbPassphraseStore(
      unbound: unbound,
      bound: bound,
      // Pretend there's a screen lock so the move is attempted.
      screenLock: const _Fixed(true),
      keyBinding: PlatformKeyBindingSupport(),
      legacyGate: const AlwaysAllowBiometricGate(),
    );

    DbKey? result;
    Object? error;
    try {
      result = await store.unlock(databaseExists: true);
    } on Object catch (e) {
      error = e;
    }
    debugPrint(
      'KEYBINDING move result=${result?.protection} error=$error '
      'unboundAfter=${await unbound.read(key) != null}',
    );

    if (result != null) {
      expect(result.passphrase, before, reason: 'same key either way');
    }
    if (result?.protection != KeyProtection.bound) {
      // Not moved: the old copy must still be there.
      expect(await unbound.read(key), before);
    }

    // Put the simulator back to the old slot for the next run.
    if (await unbound.read(key) == null && result != null) {
      await unbound.write(key, result.passphrase);
    }
    try {
      await bound.delete(key);
    } on Object catch (e) {
      debugPrint('KEYBINDING bound cleanup: $e');
    }
  });
}
