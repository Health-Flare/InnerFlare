import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/app_restart.dart';
import 'package:inner_flare/core/providers/biometric_gate_provider.dart';
import 'package:inner_flare/core/providers/data_eraser_provider.dart';
import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/core/providers/reauthenticating_provider.dart';
import 'package:inner_flare/core/security/app_unlock_gate.dart';
import 'package:inner_flare/core/security/biometric_gate.dart';
import 'package:inner_flare/core/security/data_eraser.dart';
import 'package:inner_flare/core/security/db_passphrase_store.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/security_settings_repository.dart';
import 'package:inner_flare/features/export/screens/export_screen.dart';
import 'package:inner_flare/features/first_run/screens/first_run_screen.dart';
import 'package:inner_flare/features/settings/screens/settings_screen.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../helpers/test_database.dart';

/// docs/features/erase_data.feature, through the real Settings screen,
/// unlock gate and first-run gate. The database is a real in-memory one;
/// the device unlock and the eraser are fakes so the test can see what
/// ran and when.

class _FakeGate implements BiometricGate {
  _FakeGate(this.result, this.flag);
  final bool result;
  final ReauthenticationFlag Function() flag;
  final flagDuringPrompt = <bool>[];
  var calls = 0;

  @override
  Future<bool> authenticate() async {
    calls += 1;
    flagDuringPrompt.add(flag().inProgress);
    return result;
  }
}

class _FakeEraser extends DataEraser {
  _FakeEraser({this.failOnKey = false})
    : super(
        passphraseStore: DbPassphraseStore(),
        supportDirectory: () async => Directory.systemTemp,
        clearTemporaryExports: () async {},
      );

  final bool failOnKey;
  var erased = 0;

  @override
  Future<void> erase({Future<void> Function()? closeDatabase}) async {
    if (failOnKey) {
      throw EraseKeyDeletionFailed(Exception('keystore refused (test)'));
    }
    erased += 1;
    await closeDatabase?.call();
  }
}

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  late int opens;
  late Database? openDb;
  late _FakeEraser eraser;
  late _FakeGate gate;
  ProviderContainer? container;

  setUp(() {
    opens = 0;
    openDb = null;
  });

  tearDown(() async {
    if (openDb?.isOpen ?? false) await openDb!.close();
  });

  /// The app's real shape from the unlock screen on, with Settings in
  /// place of the dashboard. The first open seeds a logged day and the
  /// first-run acknowledgement; any later open gets the empty database
  /// a fresh install would.
  Future<void> pumpApp(
    WidgetTester tester, {
    bool unlockResult = true,
    bool failOnKey = false,
  }) async {
    eraser = _FakeEraser(failOnKey: failOnKey);
    gate = _FakeGate(
      unlockResult,
      () => container!.read(reauthenticationFlagProvider),
    );
    await tester.pumpWidget(
      AppRestartScope(
        child: ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) async {
              final db = await openInMemoryTestDatabase(
                onCreate: onCreate,
                version: schemaVersion,
              );
              opens += 1;
              if (opens == 1) {
                await db.insert(cycleDayLogsTable, {
                  'date': '2026-09-01',
                  'period_flow': 'medium',
                });
                await SecuritySettingsRepository(
                  db,
                ).setDisclaimerAcknowledged();
              }
              openDb = db;
              return db;
            }),
            biometricGateProvider.overrideWithValue(gate),
            dataEraserProvider.overrideWithValue(eraser),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: AppUnlockGate(
                  child: FirstRunGate(child: SettingsScreen()),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  }

  Future<void> tapErase(WidgetTester tester) async {
    final tile = find.widgetWithText(ListTile, 'Erase all data');
    await tester.scrollUntilVisible(
      tile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }

  Future<int> loggedDays() async =>
      (await openDb!.query(cycleDayLogsTable)).length;

  testWidgets('Erase all data sits in its own section at the end of '
      'Settings', (tester) async {
    await pumpApp(tester);
    final tile = find.widgetWithText(ListTile, 'Erase all data');
    await tester.scrollUntilVisible(
      tile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tile, findsOneWidget);
    expect(find.text('Start over'), findsOneWidget);
    expect(
      find.text('Delete everything Inner Flare has stored on this phone.'),
      findsOneWidget,
    );
  });

  testWidgets('the device unlock comes first, with the relock guard set '
      'while it is open', (tester) async {
    await pumpApp(tester);
    await tapErase(tester);

    expect(gate.calls, 1);
    expect(gate.flagDuringPrompt, [true]);
    expect(container!.read(reauthenticationFlagProvider).inProgress, isFalse);
    expect(find.text('Erase all data?'), findsOneWidget);
  });

  testWidgets('a cancelled or failed device unlock shows no dialog and '
      'erases nothing', (tester) async {
    await pumpApp(tester, unlockResult: false);
    await tapErase(tester);

    expect(gate.calls, 1);
    expect(find.text('Erase all data?'), findsNothing);
    expect(eraser.erased, 0);
    expect(await tester.runAsync(loggedDays), 1);
    expect(container!.read(reauthenticationFlagProvider).inProgress, isFalse);
  });

  testWidgets('the dialog says what will be lost and offers three '
      'choices', (tester) async {
    await pumpApp(tester);
    await tapErase(tester);

    expect(find.text('Erase all data?'), findsOneWidget);
    expect(
      find.text(
        "This deletes every day you've logged, your symptoms, notes and "
        "settings from this phone. It can't be undone.",
      ),
      findsOneWidget,
    );
    expect(
      find.text("Backups you've already exported aren't affected."),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
    expect(
      find.widgetWithText(TextButton, 'Export a backup first'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Erase'), findsOneWidget);
  });

  testWidgets('Cancel closes the dialog and leaves the data alone', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapErase(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Erase all data?'), findsNothing);
    expect(find.text('Settings'), findsOneWidget);
    expect(eraser.erased, 0);
    expect(await tester.runAsync(loggedDays), 1);
  });

  testWidgets('"Export a backup first" opens Export data and erases '
      'nothing', (tester) async {
    await pumpApp(tester);
    await tapErase(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Export a backup first'));
    await tester.pumpAndSettle();

    expect(find.byType(ExportScreen), findsOneWidget);
    expect(find.text('Erase all data?'), findsNothing);
    expect(eraser.erased, 0);
    expect(await tester.runAsync(loggedDays), 1);
  });

  testWidgets('Erase closes the database and lands on a fresh install: '
      'unlock, then welcome, with nothing logged', (tester) async {
    await pumpApp(tester);
    final before = openDb!;
    await tapErase(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Erase'));
    await tester.pumpAndSettle();

    expect(eraser.erased, 1);
    expect(before.isOpen, isFalse);
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Inner Flare is locked'), findsOneWidget);

    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(opens, 2);
    expect(find.text('Welcome to Inner Flare'), findsOneWidget);
    expect(await tester.runAsync(loggedDays), 0);
  });

  testWidgets('if the key cannot be deleted, the user is told and stays on '
      'Settings with the data open', (tester) async {
    await pumpApp(tester, failOnKey: true);
    await tapErase(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Erase'));
    await tester.pumpAndSettle();

    expect(
      find.text("Couldn't erase. Your data is still here."),
      findsOneWidget,
    );
    expect(find.text('Settings'), findsOneWidget);
    expect(openDb!.isOpen, isTrue);
    expect(await tester.runAsync(loggedDays), 1);
    expect(opens, 1);
  });

  testWidgets('regression guard: the lock and unlock screens offer no '
      'erase', (tester) async {
    eraser = _FakeEraser();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dataEraserProvider.overrideWithValue(eraser)],
        child: const MaterialApp(home: AppUnlockGate(child: SizedBox())),
      ),
    );
    expect(find.text('Inner Flare is locked'), findsOneWidget);
    expect(find.textContaining('Erase'), findsNothing);
  });
}
