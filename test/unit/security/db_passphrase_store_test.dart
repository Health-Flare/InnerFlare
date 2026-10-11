import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/security/biometric_gate.dart';
import 'package:inner_flare/core/security/db_passphrase_store.dart';
import 'package:inner_flare/core/security/screen_lock_probe.dart';
import 'package:inner_flare/core/security/secure_key_store.dart';

/// In-memory [SecureKeyStore] that can be told to fail at a given step,
/// and records every call so tests can assert on order and prompts.
class FakeKeyStore implements SecureKeyStore {
  FakeKeyStore(this.name, {Map<String, String>? initial})
    : values = {...?initial};

  final String name;
  final Map<String, String> values;
  final List<String> calls = [];

  Object? readError;
  Object? writeError;
  Object? deleteError;

  /// Lets a test fail only the Nth read (1-based), e.g. the read-back.
  int? failReadNumber;
  Object? failReadError;
  int _reads = 0;

  /// When set, a write stores this instead of the value asked for
  /// (simulates a read-back that doesn't match).
  String? corruptWritesTo;

  /// Simulates the app being killed: once this many calls have completed
  /// (across this store's lifetime), every later call never returns, the
  /// way nothing after a process kill ever runs.
  int? dieAfterCalls;

  Future<void> _check(String call) async {
    if (dieAfterCalls != null && calls.length >= dieAfterCalls!) {
      await Completer<void>().future;
    }
    calls.add(call);
  }

  @override
  Future<String?> read(String key) async {
    await _check('read');
    _reads++;
    if (failReadNumber == _reads) throw failReadError!;
    if (readError != null) throw readError!;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    await _check('write');
    if (writeError != null) throw writeError!;
    values[key] = corruptWritesTo ?? value;
  }

  @override
  Future<void> delete(String key) async {
    await _check('delete');
    if (deleteError != null) throw deleteError!;
    values.remove(key);
  }
}

class FakeScreenLock implements ScreenLockProbe {
  FakeScreenLock(this.hasLock, {this.error});

  bool hasLock;
  Object? error;
  int calls = 0;

  @override
  Future<bool> hasScreenLock() async {
    calls++;
    if (error != null) throw error!;
    return hasLock;
  }
}

class FakeKeyBinding implements KeyBindingSupport {
  const FakeKeyBinding(this.supported);

  final bool supported;

  @override
  Future<bool> isSupported() async => supported;
}

class CountingGate implements BiometricGate {
  CountingGate({this.result = true});

  bool result;
  int calls = 0;

  @override
  Future<bool> authenticate() async {
    calls++;
    return result;
  }
}

const _k = DbPassphraseStore.key;
const _oldKey = 'existing-user-key';

void main() {
  late FakeKeyStore unbound;
  late FakeKeyStore bound;
  late FakeScreenLock screenLock;
  late CountingGate legacyGate;

  DbPassphraseStore store({bool bindingSupported = true}) => DbPassphraseStore(
    unbound: unbound,
    bound: bound,
    screenLock: screenLock,
    keyBinding: FakeKeyBinding(bindingSupported),
    legacyGate: legacyGate,
    generate: () => 'freshly-generated-key',
  );

  setUp(() {
    unbound = FakeKeyStore('unbound');
    bound = FakeKeyStore('bound');
    screenLock = FakeScreenLock(true);
    legacyGate = CountingGate();
  });

  group('upgrade from an unbound key (phone has a screen lock)', () {
    setUp(() => unbound.values[_k] = _oldKey);

    test('moves the key: write bound, read back, then delete the old copy, '
        'in that order, and opens with the same key', () async {
      final key = await store().unlock(databaseExists: true);

      expect(key.passphrase, _oldKey);
      expect(key.protection, KeyProtection.bound);
      expect(bound.values[_k], _oldKey);
      expect(unbound.values.containsKey(_k), isFalse);
      expect(bound.calls, ['read', 'write', 'read']);
      expect(unbound.calls, ['read', 'delete']);
      // The bound read is the OS prompt; no second, app-level prompt.
      expect(legacyGate.calls, 0);
    });

    test('the bound write fails: the old key is kept and still opens the '
        'data, behind the app prompt', () async {
      bound.writeError = PlatformException(code: 'boom');

      final key = await store().unlock(databaseExists: true);

      expect(key.passphrase, _oldKey);
      expect(key.protection, KeyProtection.promptOnly);
      expect(unbound.values[_k], _oldKey);
      expect(unbound.calls, ['read'], reason: 'never deleted');
      expect(legacyGate.calls, 1);
    });

    test('the read-back does not match: the old key is kept', () async {
      bound.corruptWritesTo = 'something-else';

      final key = await store().unlock(databaseExists: true);

      expect(key.passphrase, _oldKey);
      expect(key.protection, KeyProtection.promptOnly);
      expect(unbound.values[_k], _oldKey);
      expect(unbound.calls, ['read']);
      expect(legacyGate.calls, 1);
    });

    test('the read-back comes back empty: the old key is kept', () async {
      // A write that "succeeds" but stores nothing readable.
      bound.failReadNumber = 2;
      bound.failReadError = PlatformException(code: 'gone');

      final key = await store().unlock(databaseExists: true);

      expect(key.passphrase, _oldKey);
      expect(unbound.values[_k], _oldKey);
      expect(unbound.calls, ['read']);
    });

    test('reading the bound slot fails: the old key is kept', () async {
      bound.readError = PlatformException(code: 'keystore broken');

      final key = await store().unlock(databaseExists: true);

      expect(key.passphrase, _oldKey);
      expect(key.protection, KeyProtection.promptOnly);
      expect(unbound.values[_k], _oldKey);
      expect(bound.calls, ['read'], reason: 'no write after a failed read');
    });

    test('the old copy fails to delete: still opens bound; both copies '
        'match, and next time only the delete is retried', () async {
      unbound.deleteError = PlatformException(code: 'busy');

      final first = await store().unlock(databaseExists: true);
      expect(first.passphrase, _oldKey);
      expect(first.protection, KeyProtection.bound);
      expect(unbound.values[_k], _oldKey);
      expect(bound.values[_k], _oldKey);

      unbound.deleteError = null;
      bound.calls.clear();
      unbound.calls.clear();
      final second = await store().unlock(databaseExists: true);

      expect(second.passphrase, _oldKey);
      expect(second.protection, KeyProtection.bound);
      expect(bound.calls, ['read'], reason: 'no rewrite of a matching copy');
      expect(unbound.calls, ['read', 'delete']);
      expect(unbound.values.containsKey(_k), isFalse);
    });

    // Bound calls in a move: read (pre-check), write, read (read-back).
    // Unbound: read, then delete last. Kill after each step in turn.
    for (final (label, boundCalls, unboundCalls) in [
      ('after reading the old key', 0, 1),
      ('after the bound pre-check', 1, 1),
      ('after the bound write', 2, 1),
      ('after the read-back, before deleting the old copy', 3, 1),
    ]) {
      test('the app is killed $label: the old key is still there, and the '
          'next launch finishes the move', () async {
        bound.dieAfterCalls = boundCalls;
        unbound.dieAfterCalls = unboundCalls;

        // Never completes, like a killed process; let it run as far as
        // it can.
        unawaited(store().unlock(databaseExists: true));
        await pumpEventQueue();

        expect(unbound.values[_k], _oldKey, reason: 'old copy survives');

        // Next launch: a fresh process over whatever was persisted.
        unbound = FakeKeyStore('unbound', initial: unbound.values);
        bound = FakeKeyStore('bound', initial: bound.values);
        final key = await store().unlock(databaseExists: true);

        expect(key.passphrase, _oldKey);
        expect(key.protection, KeyProtection.bound);
        expect(bound.values[_k], _oldKey);
        expect(unbound.values.containsKey(_k), isFalse);
      });
    }

    test('the user cancels the OS prompt during the move: fails closed, '
        'the old key is untouched, and there is no second prompt', () async {
      bound.readError = const KeyStoreAuthenticationFailed('cancelled');

      await expectLater(
        store().unlock(databaseExists: true),
        throwsA(isA<KeyStoreAuthenticationFailed>()),
      );
      expect(unbound.values[_k], _oldKey);
      expect(unbound.calls, ['read']);
      expect(legacyGate.calls, 0, reason: 'no fallback prompt on cancel');
    });

    test('the user cancels the OS prompt on the write: fails closed, old '
        'key untouched', () async {
      bound.writeError = const KeyStoreAuthenticationFailed('cancelled');

      await expectLater(
        store().unlock(databaseExists: true),
        throwsA(isA<KeyStoreAuthenticationFailed>()),
      );
      expect(unbound.values[_k], _oldKey);
      expect(legacyGate.calls, 0);
    });

    test('a failed move that falls back to the app prompt still fails '
        'closed when that prompt is cancelled', () async {
      bound.writeError = PlatformException(code: 'boom');
      legacyGate.result = false;

      await expectLater(
        store().unlock(databaseExists: true),
        throwsA(isA<BiometricAuthenticationFailure>()),
      );
      expect(unbound.values[_k], _oldKey);
      expect(legacyGate.calls, 1, reason: 'exactly one prompt');
    });

    test('a stale, different bound copy is overwritten by the unbound key '
        '(the unbound copy is the one the file was made with)', () async {
      bound.values[_k] = 'stale';

      final key = await store().unlock(databaseExists: true);

      expect(key.passphrase, _oldKey);
      expect(bound.values[_k], _oldKey);
      expect(unbound.values.containsKey(_k), isFalse);
    });
  });

  group('after the move (steady state)', () {
    test('reads only the bound slot: one OS prompt, no app prompt, no '
        'writes', () async {
      bound.values[_k] = _oldKey;

      final key = await store().unlock(databaseExists: true);

      expect(key.passphrase, _oldKey);
      expect(key.protection, KeyProtection.bound);
      expect(bound.calls, ['read']);
      expect(unbound.calls, ['read']);
      expect(legacyGate.calls, 0);
    });

    test('a cancelled OS prompt fails closed and nothing is written', () async {
      bound.values[_k] = _oldKey;
      bound.readError = const KeyStoreAuthenticationFailed('cancelled');

      await expectLater(
        store().unlock(databaseExists: true),
        throwsA(isA<KeyStoreAuthenticationFailed>()),
      );
      expect(bound.calls, ['read']);
      expect(unbound.calls, ['read']);
      expect(unbound.values, isEmpty);
    });

    test('the database exists but no key is found anywhere: refuses to make '
        'a new one', () async {
      await expectLater(
        store().unlock(databaseExists: true),
        throwsA(
          isA<DatabaseKeyUnavailable>().having(
            (e) => e.screenLockOff,
            'screenLockOff',
            isFalse,
          ),
        ),
      );
      expect(bound.calls, ['read']);
      expect(unbound.values, isEmpty);
      expect(bound.values, isEmpty);
    });
  });

  group('first run', () {
    test('with a screen lock: a new key goes straight into the bound slot '
        'and is read back before use', () async {
      final key = await store().unlock(databaseExists: false);

      expect(key.passphrase, 'freshly-generated-key');
      expect(key.protection, KeyProtection.bound);
      expect(bound.values[_k], 'freshly-generated-key');
      expect(unbound.values, isEmpty);
      expect(bound.calls, ['read', 'write', 'read']);
      expect(legacyGate.calls, 0);
    });

    test('with a screen lock, but the bound slot does not work: starts in '
        'the old slot behind the app prompt, to be moved later', () async {
      bound.writeError = PlatformException(code: 'no keystore');

      final key = await store().unlock(databaseExists: false);

      expect(key.protection, KeyProtection.promptOnly);
      expect(unbound.values[_k], 'freshly-generated-key');
      expect(legacyGate.calls, 1);
    });

    test(
      'with a screen lock, cancelling the first OS prompt fails closed',
      () async {
        bound.writeError = const KeyStoreAuthenticationFailed('cancelled');

        await expectLater(
          store().unlock(databaseExists: false),
          throwsA(isA<KeyStoreAuthenticationFailed>()),
        );
        expect(unbound.values, isEmpty);
        expect(legacyGate.calls, 0);
      },
    );

    test('without a screen lock: unbound, no prompt', () async {
      screenLock.hasLock = false;

      final key = await store().unlock(databaseExists: false);

      expect(key.protection, KeyProtection.noScreenLock);
      expect(unbound.values[_k], 'freshly-generated-key');
      expect(bound.calls, isEmpty);
      expect(legacyGate.calls, 0);
    });
  });

  group('no screen lock', () {
    setUp(() => screenLock.hasLock = false);

    test('uses the existing unbound key, never touches the bound slot, and '
        'reports it so the warning can show', () async {
      unbound.values[_k] = _oldKey;

      final key = await store().unlock(databaseExists: true);

      expect(key.passphrase, _oldKey);
      expect(key.protection, KeyProtection.noScreenLock);
      expect(bound.calls, isEmpty);
      expect(legacyGate.calls, 0);
    });

    test('the key was bound and the screen lock was then turned off: '
        'explains it and does NOT make a new key', () async {
      bound.values[_k] = _oldKey;

      await expectLater(
        store().unlock(databaseExists: true),
        throwsA(
          isA<DatabaseKeyUnavailable>().having(
            (e) => e.screenLockOff,
            'screenLockOff',
            isTrue,
          ),
        ),
      );
      expect(unbound.values, isEmpty, reason: 'no new unbound key');
      expect(bound.values[_k], _oldKey, reason: 'bound copy untouched');
      expect(bound.calls, isEmpty);
    });

    test(
      'setting a screen lock later moves the key on the next unlock',
      () async {
        unbound.values[_k] = _oldKey;
        await store().unlock(databaseExists: true);

        screenLock.hasLock = true;
        final key = await store().unlock(databaseExists: true);

        expect(key.passphrase, _oldKey);
        expect(key.protection, KeyProtection.bound);
        expect(bound.values[_k], _oldKey);
        expect(unbound.values.containsKey(_k), isFalse);
      },
    );
  });

  group('screen lock check', () {
    test('an error checking for a screen lock fails closed with a retry, '
        'and touches no key', () async {
      unbound.values[_k] = _oldKey;
      screenLock.error = PlatformException(code: 'boom');

      await expectLater(
        store().unlock(databaseExists: true),
        throwsA(isA<ScreenLockCheckFailure>()),
      );
      expect(unbound.calls, isEmpty);
      expect(bound.calls, isEmpty);
      expect(legacyGate.calls, 0);

      // Retrying once the check works again gets in.
      screenLock.error = null;
      final key = await store().unlock(databaseExists: true);
      expect(key.passphrase, _oldKey);
    });
  });

  group('platforms that cannot bind (Android 9/10, desktop, tests)', () {
    test('the app prompt first, then the unbound key, as before', () async {
      unbound.values[_k] = _oldKey;

      final key = await store(
        bindingSupported: false,
      ).unlock(databaseExists: true);

      expect(key.passphrase, _oldKey);
      expect(key.protection, KeyProtection.promptOnly);
      expect(legacyGate.calls, 1);
      expect(bound.calls, isEmpty);
      expect(screenLock.calls, 0);
    });

    test(
      'a cancelled app prompt fails closed before any key is read',
      () async {
        unbound.values[_k] = _oldKey;
        legacyGate.result = false;

        await expectLater(
          store(bindingSupported: false).unlock(databaseExists: true),
          throwsA(isA<BiometricAuthenticationFailure>()),
        );
        expect(unbound.calls, isEmpty);
      },
    );

    test('first run makes an unbound key', () async {
      final key = await store(
        bindingSupported: false,
      ).unlock(databaseExists: false);

      expect(key.protection, KeyProtection.promptOnly);
      expect(unbound.values[_k], 'freshly-generated-key');
    });

    test(
      'an existing database with no key: refuses to make a new one',
      () async {
        await expectLater(
          store(bindingSupported: false).unlock(databaseExists: true),
          throwsA(isA<DatabaseKeyUnavailable>()),
        );
        expect(unbound.values, isEmpty);
      },
    );
  });

  group('delete (erase all data)', () {
    test('removes the key from both slots', () async {
      unbound.values[_k] = _oldKey;
      bound.values[_k] = _oldKey;

      await store().delete();

      expect(unbound.values, isEmpty);
      expect(bound.values, isEmpty);
    });

    test('still clears the bound slot when the unbound delete fails, then '
        'reports the failure', () async {
      unbound.values[_k] = _oldKey;
      bound.values[_k] = _oldKey;
      unbound.deleteError = PlatformException(code: 'busy');

      await expectLater(store().delete(), throwsA(isA<PlatformException>()));
      expect(bound.values, isEmpty);
    });

    test(
      'reports a bound-slot failure on a phone with a screen lock',
      () async {
        bound.deleteError = PlatformException(code: 'busy');

        await expectLater(store().delete(), throwsA(isA<PlatformException>()));
      },
    );

    test('a bound slot that cannot be opened without a screen lock does not '
        'block the erase', () async {
      screenLock.hasLock = false;
      unbound.values[_k] = _oldKey;
      bound.deleteError = PlatformException(code: 'BIOMETRIC_UNAVAILABLE');

      await store().delete();
      expect(unbound.values, isEmpty);
    });
  });

  group('isAuthenticationFailure', () {
    test('iOS user cancel, auth failed, and interaction not allowed', () {
      for (final status in [-128, -25293, -25308]) {
        expect(
          isAuthenticationFailure(
            PlatformException(
              code: 'Unexpected security result code',
              details: status,
            ),
          ),
          isTrue,
          reason: '$status',
        );
      }
    });

    test('Android prompt errors, as the message or as a cause in the stack '
        'trace', () {
      expect(
        isAuthenticationFailure(
          PlatformException(
            code: 'Exception encountered',
            message: 'Biometric authentication error [10]: Cancelled',
          ),
        ),
        isTrue,
      );
      expect(
        isAuthenticationFailure(
          PlatformException(
            code: 'Exception encountered',
            message: 'Migration cancelled: Biometric authentication failed',
            details:
                'java.lang.Exception: Migration cancelled\n'
                'Caused by: java.lang.Exception: Biometric authentication '
                'error [13]: Cancel',
          ),
        ),
        isTrue,
      );
    });

    test('storage faults are not authentication failures (regression '
        'guard: these must fall back to the old key, not fail closed)', () {
      expect(
        isAuthenticationFailure(
          PlatformException(
            code: 'Unexpected security result code',
            details: -25299, // errSecDuplicateItem
          ),
        ),
        isFalse,
      );
      expect(
        isAuthenticationFailure(
          PlatformException(
            code: 'Exception encountered',
            message: 'BIOMETRIC_UNAVAILABLE: Device has no PIN',
          ),
        ),
        isFalse,
      );
      expect(isAuthenticationFailure(Exception('x')), isFalse);
    });
  });

  group('androidMajorVersion', () {
    test('parses what sqflite_sqlcipher reports', () {
      expect(androidMajorVersion('Android 11'), 11);
      expect(androidMajorVersion('Android 14'), 14);
      expect(androidMajorVersion('Android 10'), 10);
      expect(androidMajorVersion('Android 8.1.0'), 8);
    });

    test('anything else reads as unknown (the safe, unbound path)', () {
      expect(androidMajorVersion(null), isNull);
      expect(androidMajorVersion('Android Tiramisu'), isNull);
      expect(androidMajorVersion('iOS 17'), isNull);
    });
  });

  group('PlatformKeyBindingSupport', () {
    test('binds on iOS', () async {
      expect(
        await PlatformKeyBindingSupport(
          platform: TargetPlatform.iOS,
        ).isSupported(),
        isTrue,
      );
    });

    test('binds on Android 11 and later only', () async {
      for (final (release, expected) in [
        ('Android 9', false),
        ('Android 10', false),
        ('Android 11', true),
        ('Android 15', true),
        (null, false),
      ]) {
        expect(
          await PlatformKeyBindingSupport(
            platform: TargetPlatform.android,
            androidRelease: () async => release,
          ).isSupported(),
          expected,
          reason: '$release',
        );
      }
    });

    test('never binds on desktop', () async {
      for (final p in [
        TargetPlatform.macOS,
        TargetPlatform.linux,
        TargetPlatform.windows,
      ]) {
        expect(
          await PlatformKeyBindingSupport(platform: p).isSupported(),
          isFalse,
        );
      }
    });
  });
}
