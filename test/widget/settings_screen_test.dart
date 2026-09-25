import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/debug/debug_chrome.dart';
import 'package:inner_flare/core/providers/security_settings_repository_provider.dart';
import 'package:inner_flare/core/providers/tracked_symptoms_repository_provider.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/security_settings_repository.dart';
import 'package:inner_flare/data/repositories/tracked_symptoms_repository.dart';
import 'package:inner_flare/features/export/screens/export_screen.dart';
import 'package:inner_flare/features/export/screens/import_screen.dart';
import 'package:inner_flare/features/settings/screens/auto_lock_settings_screen.dart';
import 'package:inner_flare/features/settings/screens/settings_screen.dart';
import 'package:inner_flare/features/settings/screens/symptom_settings_screen.dart';
import 'package:inner_flare/models/lock_timeout.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../helpers/test_app_builder.dart';
import '../helpers/test_database.dart';

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  Database? openDb;
  tearDown(() async {
    await openDb?.close();
    openDb = null;
  });

  List<Override> overrides() {
    return [
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
  }

  Future<void> openAutoLock(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(ListTile, 'Auto-lock'));
    await tester.pumpAndSettle();
  }

  testWidgets('the Database and Demo data sections follow showDebugChrome, '
      'so a SCREENSHOT_MODE capture never shows them', (tester) async {
    await pumpTestApp(tester, const SettingsScreen(), overrides: overrides());
    await tester.pumpAndSettle();

    final matcher = showDebugChrome ? findsOneWidget : findsNothing;
    expect(find.text('Database'), matcher);

    // Last in the list, so off-screen (and unbuilt) until scrolled to.
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('Demo data'), matcher);
  });

  testWidgets('the Auto-lock entry shows the current timeout, defaulting to '
      '15 minutes with nothing saved yet', (tester) async {
    await pumpTestApp(tester, const SettingsScreen(), overrides: overrides());
    await tester.pumpAndSettle();

    final tile = find.widgetWithText(ListTile, 'Auto-lock');
    expect(
      find.descendant(of: tile, matching: find.text('After 15 minutes')),
      findsOneWidget,
    );
    // The options live on their own page, not inline.
    expect(find.byType(RadioListTile<LockTimeout>), findsNothing);
  });

  testWidgets('opening Auto-lock shows its own page with the current option '
      'selected', (tester) async {
    await pumpTestApp(tester, const SettingsScreen(), overrides: overrides());
    await tester.pumpAndSettle();
    await openAutoLock(tester);

    expect(find.byType(AutoLockSettingsScreen), findsOneWidget);

    // RadioGroup reports the selected value on the ancestor, not the tile.
    final group = tester.widget<RadioGroup<LockTimeout>>(
      find.byType(RadioGroup<LockTimeout>),
    );
    expect(group.groupValue, LockTimeout.after15Minutes);
  });

  testWidgets('every timeout choice is offered on the Auto-lock page', (
    tester,
  ) async {
    await pumpTestApp(tester, const SettingsScreen(), overrides: overrides());
    await tester.pumpAndSettle();
    await openAutoLock(tester);

    for (final timeout in LockTimeout.values) {
      expect(
        find.widgetWithText(RadioListTile<LockTimeout>, timeout.label),
        findsOneWidget,
      );
    }
  });

  testWidgets('picking a timeout persists it immediately to the database and '
      'updates the entry on Settings', (tester) async {
    await pumpTestApp(tester, const SettingsScreen(), overrides: overrides());
    await tester.pumpAndSettle();
    await openAutoLock(tester);

    await tester.tap(find.widgetWithText(RadioListTile<LockTimeout>, 'Never'));
    await tester.pumpAndSettle();

    final group = tester.widget<RadioGroup<LockTimeout>>(
      find.byType(RadioGroup<LockTimeout>),
    );
    expect(group.groupValue, LockTimeout.never);

    final saved = await SecuritySettingsRepository(openDb!).getLockTimeout();
    expect(saved, LockTimeout.never);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Auto-lock'),
        matching: find.text('Never'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the symptoms entry point opens symptom settings '
      '(docs/features/symptom_settings.feature)', (tester) async {
    await pumpTestApp(tester, const SettingsScreen(), overrides: overrides());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Symptoms to track'), 200);
    expect(find.text('Symptoms to track'), findsOneWidget);

    await tester.tap(find.text('Symptoms to track'));
    await tester.pumpAndSettle();

    expect(find.byType(SymptomSettingsScreen), findsOneWidget);
  });

  testWidgets('the export entry point opens the export screen '
      '(docs/features/export.feature)', (tester) async {
    await pumpTestApp(tester, const SettingsScreen(), overrides: overrides());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Export data'), 200);
    await tester.tap(find.text('Export data'));
    await tester.pumpAndSettle();

    expect(find.byType(ExportScreen), findsOneWidget);
  });

  testWidgets('the import entry point opens the import screen '
      '(docs/features/export.feature)', (tester) async {
    await pumpTestApp(tester, const SettingsScreen(), overrides: overrides());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Import data'), 200);
    await tester.tap(find.text('Import data'));
    await tester.pumpAndSettle();

    expect(find.byType(ImportScreen), findsOneWidget);
  });
}
