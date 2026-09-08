import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/dashboard_card_preferences_repository_provider.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/dashboard_card_preferences_repository.dart';
import 'package:inner_flare/features/dashboard/screens/dashboard_customize_screen.dart';
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
      dashboardCardPreferencesRepositoryProvider.overrideWith((ref) async {
        final db = await openInMemoryTestDatabase(onCreate: onCreate);
        openDb = db;
        return DashboardCardPreferencesRepository(db);
      }),
    ];
  }

  testWidgets(
    'every default card starts visible and none is marked mandatory',
    (tester) async {
      await pumpTestApp(
        tester,
        const DashboardCustomizeScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      final calendarSwitch = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Calendar'),
      );
      final insightsSwitch = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Insights'),
      );
      expect(calendarSwitch.value, isTrue);
      expect(insightsSwitch.value, isTrue);
    },
  );

  testWidgets('hiding every card is allowed — none is unremovable', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const DashboardCustomizeScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SwitchListTile, 'Calendar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, 'Insights'));
    await tester.pumpAndSettle();

    final calendarSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Calendar'),
    );
    final insightsSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Insights'),
    );
    expect(calendarSwitch.value, isFalse);
    expect(insightsSwitch.value, isFalse);
  });

  testWidgets(
    're-showing a previously hidden card inserts it at the end of the '
    'current order',
    (tester) async {
      await pumpTestApp(
        tester,
        const DashboardCustomizeScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      // Hide Calendar (the first card), then re-show it.
      await tester.tap(find.widgetWithText(SwitchListTile, 'Calendar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(SwitchListTile, 'Calendar'));
      await tester.pumpAndSettle();

      final saved = await DashboardCardPreferencesRepository(openDb!).getAll();
      // Insights (never hidden) should now lead; re-shown Calendar moved to
      // the end instead of keeping its original leading position.
      expect(saved.map((p) => p.card.name).toList(), ['insights', 'calendar']);
      expect(saved.every((p) => p.visible), isTrue);
    },
  );

  testWidgets('toggling a card persists immediately to the database', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const DashboardCustomizeScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SwitchListTile, 'Insights'));
    await tester.pumpAndSettle();

    final saved = await DashboardCardPreferencesRepository(openDb!).getAll();
    final insightsPref = saved.firstWhere((p) => p.card.name == 'insights');
    expect(insightsPref.visible, isFalse);
  });
}
