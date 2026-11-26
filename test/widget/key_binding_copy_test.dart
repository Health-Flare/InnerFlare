import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/core/providers/key_protection_provider.dart';
import 'package:inner_flare/core/providers/security_settings_repository_provider.dart';
import 'package:inner_flare/core/providers/tracked_symptoms_repository_provider.dart';
import 'package:inner_flare/core/security/app_unlock_gate.dart';
import 'package:inner_flare/core/security/db_passphrase_store.dart';
import 'package:inner_flare/core/security/screen_lock_probe.dart';
import 'package:inner_flare/core/security/secure_key_store.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/security_settings_repository.dart';
import 'package:inner_flare/data/repositories/tracked_symptoms_repository.dart';
import 'package:inner_flare/features/security/screens/app_unlock_screen.dart';
import 'package:inner_flare/features/settings/screens/settings_screen.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../helpers/test_app_builder.dart';
import '../helpers/test_database.dart';

class _FixedScreenLock implements ScreenLockProbe {
  const _FixedScreenLock(this.hasLock);

  final bool hasLock;

  @override
  Future<bool> hasScreenLock() async => hasLock;
}

class _ThrowingScreenLock implements ScreenLockProbe {
  const _ThrowingScreenLock();

  @override
  Future<bool> hasScreenLock() async => throw Exception('boom');
}

/// docs/features/unlock.feature, key binding scenarios: the "no screen
/// lock" warning on the unlock screen, dashboard and Settings, and copy
/// that doesn't overclaim in that state.
void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  Database? openDb;
  tearDown(() async {
    await openDb?.close();
    openDb = null;
  });

  Override probe(ScreenLockProbe p) =>
      screenLockProbeProvider.overrideWithValue(p);

  group('unlock screen', () {
    testWidgets('a phone with no screen lock: says anyone holding it can '
        'open the app, and does not claim a face or passcode unlock', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const AppUnlockGate(child: Text('dashboard')),
        overrides: [
          probe(const _FixedScreenLock(false)),
          appDatabaseProvider.overrideWith(
            (ref) => Completer<Database>().future,
          ),
        ],
      );
      await tester.pump();

      expect(
        find.text(
          'This phone has no screen lock, so anyone holding it can open '
          'Inner Flare.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Face ID'), findsNothing);
      expect(find.textContaining('fingerprint'), findsNothing);
      expect(find.textContaining('passcode'), findsNothing);
      expect(find.textContaining('screen lock to continue'), findsNothing);
    });

    testWidgets('a phone with a screen lock: no warning, and the unlock '
        'explanation names face, fingerprint, or screen lock', (tester) async {
      await pumpTestApp(
        tester,
        const AppUnlockGate(child: Text('dashboard')),
        overrides: [
          probe(const _FixedScreenLock(true)),
          appDatabaseProvider.overrideWith(
            (ref) => Completer<Database>().future,
          ),
        ],
      );
      await tester.pump();

      expect(find.textContaining('no screen lock'), findsNothing);
      expect(
        find.text(
          'Your cycle data is encrypted on this device. Unlock with your '
          'face, fingerprint, or screen lock to continue.',
        ),
        findsOneWidget,
      );
    });

    testWidgets("can't tell whether there's a screen lock: no warning shown "
        '(the unlock itself fails closed on its own)', (tester) async {
      await pumpTestApp(
        tester,
        const AppUnlockGate(child: Text('dashboard')),
        overrides: [
          probe(const _ThrowingScreenLock()),
          appDatabaseProvider.overrideWith(
            (ref) => Completer<Database>().future,
          ),
        ],
      );
      await tester.pump();

      expect(find.textContaining('no screen lock'), findsNothing);
    });

    testWidgets('the key was tied to a screen lock that is now off: the '
        'unlock screen explains it in place, with a retry', (tester) async {
      await pumpTestApp(
        tester,
        const AppUnlockGate(child: Text('dashboard')),
        overrides: [
          probe(const _FixedScreenLock(false)),
          appDatabaseProvider.overrideWith(
            (ref) async =>
                throw const DatabaseKeyUnavailable(screenLockOff: true),
          ),
        ],
      );
      await tester.pump();
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Inner Flare's key was tied to this phone's screen lock, and the "
          "screen lock is now off. Turn it back on in your phone's settings "
          "and tap Unlock. If your data still doesn't open, the phone "
          'removed the key when the screen lock was turned off, and only a '
          'backup you exported earlier can bring it back.',
        ),
        findsOneWidget,
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('a screen lock check that fails keeps the data locked with a '
        'retry', (tester) async {
      await pumpTestApp(
        tester,
        const AppUnlockGate(child: Text('dashboard')),
        overrides: [
          probe(const _FixedScreenLock(true)),
          appDatabaseProvider.overrideWith(
            (ref) async => throw ScreenLockCheckFailure(Exception('boom')),
          ),
        ],
      );
      await tester.pump();
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(find.text('dashboard'), findsNothing);
      expect(
        find.text(
          "Couldn't check whether this phone has a screen lock, so your data "
          'stays locked. Tap Unlock to try again.',
        ),
        findsOneWidget,
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('a cancelled OS prompt gets the ordinary retry text and is '
        'never retried on its own', (tester) async {
      var attempts = 0;
      await pumpTestApp(
        tester,
        const AppUnlockGate(child: Text('dashboard')),
        overrides: [
          probe(const _FixedScreenLock(true)),
          appDatabaseProvider.overrideWith((ref) async {
            attempts++;
            throw const KeyStoreAuthenticationFailed('cancelled');
          }),
        ],
      );
      await tester.pump();
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(find.text(AppUnlockScreen.failedExplanation), findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
      expect(attempts, 1);
    });
  });

  group('Settings', () {
    List<Override> settingsOverrides(ScreenLockProbe p) => [
      probe(p),
      securitySettingsRepositoryProvider.overrideWith((ref) async {
        final db = await openInMemoryTestDatabase(onCreate: onCreate);
        openDb = db;
        return SecuritySettingsRepository(db);
      }),
      trackedSymptomsRepositoryProvider.overrideWith((ref) async {
        final db = await openInMemoryTestDatabase(onCreate: onCreate);
        return TrackedSymptomsRepository(db);
      }),
    ];

    testWidgets('shows the no-screen-lock warning while there is no screen '
        'lock', (tester) async {
      await pumpTestApp(
        tester,
        const SettingsScreen(),
        overrides: settingsOverrides(const _FixedScreenLock(false)),
      );
      await tester.pumpAndSettle();

      expect(find.text(noScreenLockWarning), findsOneWidget);
    });

    testWidgets('no warning with a screen lock', (tester) async {
      await pumpTestApp(
        tester,
        const SettingsScreen(),
        overrides: settingsOverrides(const _FixedScreenLock(true)),
      );
      await tester.pumpAndSettle();

      expect(find.text(noScreenLockWarning), findsNothing);
    });

    testWidgets('advises exporting a backup before turning the screen lock '
        'off, once the key is tied to it', (tester) async {
      await pumpTestApp(
        tester,
        const SettingsScreen(),
        overrides: [
          ...settingsOverrides(const _FixedScreenLock(true)),
          keyProtectionStateProvider.overrideWithBuild(
            (ref, notifier) => KeyProtection.bound,
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Your data's key is tied to this phone's screen lock. Turning the "
          'screen lock off can delete that key, so export a backup first.',
        ),
        findsOneWidget,
      );
    });
  });
}
