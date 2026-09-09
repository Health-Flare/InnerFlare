import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/tracked_symptoms_repository_provider.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/tracked_symptoms_repository.dart';
import 'package:inner_flare/features/settings/screens/symptom_settings_screen.dart';
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
      trackedSymptomsRepositoryProvider.overrideWith((ref) async {
        final db = await openInMemoryTestDatabase(onCreate: onCreate);
        openDb = db;
        return TrackedSymptomsRepository(db);
      }),
    ];
  }

  testWidgets('every default symptom starts listed and enabled', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const SymptomSettingsScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();

    final crampsSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Cramps'),
    );
    expect(crampsSwitch.value, isTrue);
  });

  testWidgets('disabling a symptom persists immediately to the database', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const SymptomSettingsScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SwitchListTile, 'Acne'));
    await tester.pumpAndSettle();

    final acneSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Acne'),
    );
    expect(acneSwitch.value, isFalse);

    final saved = await TrackedSymptomsRepository(openDb!).getAll();
    expect(saved.firstWhere((s) => s.id == 'acne').enabled, isFalse);
  });

  testWidgets('adding a custom symptom lists it, enabled, by default', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const SymptomSettingsScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add a symptom'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Back pain');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    final backPainSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Back pain'),
    );
    expect(backPainSwitch.value, isTrue);

    final saved = await TrackedSymptomsRepository(openDb!).getAll();
    expect(
      saved.where((s) => s.label == 'Back pain' && s.isCustom),
      hasLength(1),
    );
  });

  testWidgets('renaming a symptom updates its label everywhere it appears', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const SymptomSettingsScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(SwitchListTile, 'Cramps'),
        matching: find.byTooltip('Rename'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Cramping');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Cramps'), findsNothing);
    expect(find.text('Cramping'), findsOneWidget);

    final saved = await TrackedSymptomsRepository(openDb!).getAll();
    expect(saved.firstWhere((s) => s.id == 'cramps').label, 'Cramping');
  });
}
