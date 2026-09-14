// Exercises docs/features/quick_stats.feature's customization scenarios
// against QuickStatCustomizeScreen directly, the same way
// dashboard_customize_screen_test.dart exercises DashboardCustomizeScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/quick_stat_preferences_repository_provider.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/quick_stat_preferences_repository.dart';
import 'package:inner_flare/features/dashboard/screens/quick_stat_customize_screen.dart';
import 'package:inner_flare/models/quick_stat.dart';
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
      quickStatPreferencesRepositoryProvider.overrideWith((ref) async {
        final db = await openInMemoryTestDatabase(onCreate: onCreate);
        openDb = db;
        return QuickStatPreferencesRepository(db);
      }),
    ];
  }

  testWidgets('the two slots default to days-since-last-period and '
      'estimated-days-to-next-period', (tester) async {
    await pumpTestApp(
      tester,
      const QuickStatCustomizeScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();

    final saved = await QuickStatPreferencesRepository(openDb!).getAll();
    final slot0 = saved.firstWhere((p) => p.slot == 0);
    final slot1 = saved.firstWhere((p) => p.slot == 1);
    expect(slot0.type, QuickStatType.daysSinceLastPeriod);
    expect(slot1.type, QuickStatType.estimatedDaysToNextPeriod);
  });

  testWidgets(
    'changing one slot\'s stat type leaves the other slot untouched',
    (tester) async {
      await pumpTestApp(
        tester,
        const QuickStatCustomizeScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey('quick-stat-slot-0-type-estimatedDaysToNextPeriod'),
        ),
      );
      await tester.pumpAndSettle();

      final saved = await QuickStatPreferencesRepository(openDb!).getAll();
      final slot0 = saved.firstWhere((p) => p.slot == 0);
      final slot1 = saved.firstWhere((p) => p.slot == 1);
      expect(slot0.type, QuickStatType.estimatedDaysToNextPeriod);
      expect(slot1.type, QuickStatType.estimatedDaysToNextPeriod);
    },
  );

  testWidgets('both slots are allowed to show the same stat type at once', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const QuickStatCustomizeScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('quick-stat-slot-1-type-daysSinceLastPeriod')),
    );
    await tester.pumpAndSettle();

    final saved = await QuickStatPreferencesRepository(openDb!).getAll();
    expect(
      saved.map((p) => p.type),
      everyElement(QuickStatType.daysSinceLastPeriod),
    );
    // Both are still rendered — nothing crashes or collapses when the
    // slots match.
    expect(
      find.text(QuickStatType.daysSinceLastPeriod.label),
      findsNWidgets(2),
    );
  });

  testWidgets('the reference-point choice only appears for a slot set to days '
      'since last period', (tester) async {
    await pumpTestApp(
      tester,
      const QuickStatCustomizeScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();

    // Slot 0 defaults to daysSinceLastPeriod, so its reference-point
    // choice is present; slot 1 defaults to estimatedDaysToNextPeriod,
    // so it has none.
    expect(
      find.byKey(const ValueKey('quick-stat-slot-0-refpoint-periodEnd')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('quick-stat-slot-1-refpoint-periodEnd')),
      findsNothing,
    );
  });

  testWidgets(
    'changing the reference point from end to start of the last period '
    'persists immediately',
    (tester) async {
      await pumpTestApp(
        tester,
        const QuickStatCustomizeScreen(),
        overrides: overrides(),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('quick-stat-slot-0-refpoint-periodStart')),
      );
      await tester.pumpAndSettle();

      final saved = await QuickStatPreferencesRepository(openDb!).getAll();
      final slot0 = saved.firstWhere((p) => p.slot == 0);
      expect(slot0.referencePoint, QuickStatReferencePoint.periodStart);
    },
  );
}
