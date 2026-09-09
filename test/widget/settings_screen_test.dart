import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/security_settings_repository_provider.dart';
import 'package:inner_flare/core/providers/tracked_symptoms_repository_provider.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/security_settings_repository.dart';
import 'package:inner_flare/data/repositories/tracked_symptoms_repository.dart';
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

  testWidgets('defaults to 15 minutes with nothing saved yet', (tester) async {
    await pumpTestApp(tester, const SettingsScreen(), overrides: overrides());
    await tester.pumpAndSettle();

    final radio = tester.widget<RadioListTile<LockTimeout>>(
      find.widgetWithText(RadioListTile<LockTimeout>, 'After 15 minutes'),
    );
    expect(radio.value, LockTimeout.after15Minutes);

    // RadioGroup reports the selected value on the ancestor, not the tile.
    final group = tester.widget<RadioGroup<LockTimeout>>(
      find.byType(RadioGroup<LockTimeout>),
    );
    expect(group.groupValue, LockTimeout.after15Minutes);
  });

  testWidgets('picking a timeout persists it immediately to the database', (
    tester,
  ) async {
    await pumpTestApp(tester, const SettingsScreen(), overrides: overrides());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Never'));
    await tester.pumpAndSettle();

    final group = tester.widget<RadioGroup<LockTimeout>>(
      find.byType(RadioGroup<LockTimeout>),
    );
    expect(group.groupValue, LockTimeout.never);

    final saved = await SecuritySettingsRepository(openDb!).getLockTimeout();
    expect(saved, LockTimeout.never);
  });

  testWidgets('every timeout choice is offered', (tester) async {
    await pumpTestApp(tester, const SettingsScreen(), overrides: overrides());
    await tester.pumpAndSettle();

    for (final timeout in LockTimeout.values) {
      expect(find.text(timeout.label), findsOneWidget);
    }
  });

  testWidgets(
    'the symptoms entry point opens symptom settings '
    '(docs/features/symptom_settings.feature)',
    (tester) async {
      await pumpTestApp(
        tester,
        const SettingsScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      expect(find.text('Symptoms to track'), findsOneWidget);

      await tester.tap(find.text('Symptoms to track'));
      await tester.pumpAndSettle();

      expect(find.byType(SymptomSettingsScreen), findsOneWidget);
    },
  );
}
