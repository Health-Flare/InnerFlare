import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/dashboard_card_preferences_repository_provider.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/dashboard_card_preferences_repository.dart';
import 'package:inner_flare/features/dashboard/screens/dashboard_customize_screen.dart';
import 'package:inner_flare/models/dashboard_card.dart';
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
      await tester.scrollUntilVisible(
        find.widgetWithText(SwitchListTile, 'Insights'),
        200,
      );

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

  testWidgets('hiding every card is allowed: none is unremovable', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const DashboardCustomizeScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(SwitchListTile, 'Insights'),
      200,
    );

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
      await tester.scrollUntilVisible(
        find.widgetWithText(SwitchListTile, 'Calendar'),
        200,
      );

      // Hide Calendar, then re-show it.
      await tester.tap(find.widgetWithText(SwitchListTile, 'Calendar'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(SwitchListTile, 'Calendar'),
        200,
      );
      await tester.tap(find.widgetWithText(SwitchListTile, 'Calendar'));
      await tester.pumpAndSettle();

      final saved = await DashboardCardPreferencesRepository(openDb!).getAll();
      // The two quick stats and Insights (never hidden) keep their
      // original order; re-shown Calendar moved to the end instead of
      // keeping its original position.
      expect(saved.map((p) => p.id).toList(), [
        'quick-stat-0',
        'quick-stat-1',
        'insights',
        'calendar',
      ]);
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
    await tester.scrollUntilVisible(
      find.widgetWithText(SwitchListTile, 'Insights'),
      200,
    );

    await tester.tap(find.widgetWithText(SwitchListTile, 'Insights'));
    await tester.pumpAndSettle();

    final saved = await DashboardCardPreferencesRepository(openDb!).getAll();
    final insightsPref = saved.firstWhere((p) => p.kind.name == 'insights');
    expect(insightsPref.visible, isFalse);
  });

  group('resizing (docs/features/dashboard_grid_layout.feature)', () {
    /// Simulates the resize handle's long-press-then-drag gesture: presses
    /// at the handle, waits past the long-press threshold, drags by
    /// [offset], then releases.
    Future<void> dragResizeHandle(
      WidgetTester tester,
      String cardId,
      Offset offset,
    ) async {
      final handle = find.byKey(ValueKey('resize-handle-$cardId'));
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 700));
      await gesture.moveBy(offset);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets(
      'a live preview grid shows a resize handle for every visible card',
      (tester) async {
        await pumpTestApp(
          tester,
          const DashboardCustomizeScreen(),
          overrides: overrides(),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('resize-handle-quick-stat-0')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('resize-handle-calendar')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('resize-handle-insights')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'dragging a corner right widens the card to full width, persisted',
      (tester) async {
        await pumpTestApp(
          tester,
          const DashboardCustomizeScreen(),
          overrides: overrides(),
        );
        await tester.pumpAndSettle();

        await dragResizeHandle(tester, 'calendar', const Offset(80, 0));

        final saved = await DashboardCardPreferencesRepository(
          openDb!,
        ).getAll();
        final calendar = saved.firstWhere((p) => p.id == 'calendar');
        expect(calendar.columnSpan, 2);
        expect(calendar.rowSpan, 1);
      },
    );

    testWidgets('dragging a corner down makes the card taller, persisted', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const DashboardCustomizeScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      await dragResizeHandle(tester, 'insights', const Offset(0, 80));

      final saved = await DashboardCardPreferencesRepository(openDb!).getAll();
      final insights = saved.firstWhere((p) => p.id == 'insights');
      expect(insights.rowSpan, 2);
      expect(insights.columnSpan, 1);
    });

    testWidgets(
      'resizing cannot go past the grid\'s bounds in either direction',
      (tester) async {
        await pumpTestApp(
          tester,
          const DashboardCustomizeScreen(),
          overrides: overrides(),
        );
        await tester.pumpAndSettle();

        // Drag far down, more than enough steps to overshoot the row cap.
        await dragResizeHandle(tester, 'insights', const Offset(0, 500));
        var saved = await DashboardCardPreferencesRepository(openDb!).getAll();
        expect(
          saved.firstWhere((p) => p.id == 'insights').rowSpan,
          dashboardGridMaxRowSpan,
        );

        // A card already at its minimum column span can't be dragged
        // smaller.
        await dragResizeHandle(tester, 'calendar', const Offset(-500, 0));
        saved = await DashboardCardPreferencesRepository(openDb!).getAll();
        expect(
          saved.firstWhere((p) => p.id == 'calendar').columnSpan,
          dashboardGridMinColumnSpan,
        );
      },
    );
  });
}
