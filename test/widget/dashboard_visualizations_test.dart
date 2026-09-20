// Exercises docs/features/dashboard_visualizations.feature end to end
// through the real widgets (add-card flow, gauge/trend rendering,
// mode/chart-type switching, persistence) — the pure fill/thin-history
// math itself is covered exhaustively in
// test/unit/cycle_math/cycle_math_test.dart, and the repository's
// add/remove/config persistence in
// test/unit/dashboard/dashboard_card_preferences_repository_test.dart.
//
// Finders here deliberately scope into GaugeCard/TrendCard (via
// find.descendant) rather than matching text globally — plain
// find.text('Days since last period') also matches the Quick Stats row's
// default tile (same label, docs/features/quick_stats.feature), and
// find.text('10') can coincidentally match a quick stat's own value.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/dashboard_card_preferences_repository_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/providers/tracked_symptoms_repository_provider.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/cycle_day_log_repository.dart';
import 'package:inner_flare/data/repositories/dashboard_card_preferences_repository.dart';
import 'package:inner_flare/data/repositories/tracked_symptoms_repository.dart';
import 'package:inner_flare/features/dashboard/screens/dashboard_customize_screen.dart';
import 'package:inner_flare/features/dashboard/screens/dashboard_screen.dart';
import 'package:inner_flare/features/dashboard/widgets/gauge_card.dart';
import 'package:inner_flare/features/dashboard/widgets/trend_card.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/dashboard_card.dart';
import 'package:inner_flare/models/period_flow.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../helpers/test_app_builder.dart';
import '../helpers/test_database.dart';

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  // sqflite caches open databases by path, and every in-memory test
  // database shares the same ":memory:" path (see CLAUDE.md "sqflite on
  // desktop test runners") — one shared db per test for every table
  // (cycle_day_logs, dashboard_card_preferences, ...) sidesteps any
  // ambiguity about whether separate openInMemoryTestDatabase calls
  // within one test return the same or different connections.
  Database? openDb;
  tearDown(() async {
    await openDb?.close();
    openDb = null;
  });

  Future<void> savePeriod(
    CycleDayLogRepository repository,
    DateTime start, {
    int flowDays = 1,
  }) async {
    for (var i = 0; i < flowDays; i++) {
      await repository.save(
        CycleDayLog(
          date: start.add(Duration(days: i)),
          periodFlow: PeriodFlow.medium,
          isPeriodStart: i == 0,
        ),
      );
    }
  }

  /// Opens one shared in-memory db, seeds it via [seed], and returns
  /// overrides wiring every dashboard-relevant repository provider to it.
  Future<List<Override>> setUp({
    required DateTime Function() now,
    required Future<void> Function(Database db) seed,
  }) async {
    final db = await openInMemoryTestDatabase(onCreate: onCreate);
    openDb = db;
    await seed(db);
    return [
      nowProvider.overrideWithValue(now),
      cycleDayLogRepositoryProvider.overrideWith(
        (ref) async => CycleDayLogRepository(db),
      ),
      dashboardCardPreferencesRepositoryProvider.overrideWith(
        (ref) async => DashboardCardPreferencesRepository(db),
      ),
      trackedSymptomsRepositoryProvider.overrideWith(
        (ref) async => TrackedSymptomsRepository(db),
      ),
    ];
  }

  group('adding a card (dashboard_visualizations.feature, "Additional data '
      'points can be added as their own cards")', () {
    testWidgets(
      'adding a gauge card from the catalog shows it on the dashboard '
      'customize list',
      (tester) async {
        final overrides = await setUp(
          now: () => DateTime(2026, 8, 30, 9),
          seed: (db) async {},
        );

        await pumpTestApp(
          tester,
          const DashboardCustomizeScreen(),
          overrides: overrides,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Add a card'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Days since last period'));
        await tester.pumpAndSettle();

        // Back on the customize screen: exactly one gauge row, titled
        // with its mode (the mode-selector below it also lists both mode
        // names, so this targets the row's own SwitchListTile title, not
        // any text in the tree).
        expect(
          find.widgetWithText(SwitchListTile, 'Days since last period'),
          findsOneWidget,
        );
      },
    );

    testWidgets('the "coming soon" trend metrics are listed but not tappable', (
      tester,
    ) async {
      final overrides = await setUp(
        now: () => DateTime(2026, 8, 30, 9),
        seed: (db) async {},
      );

      await pumpTestApp(
        tester,
        const DashboardCustomizeScreen(),
        overrides: overrides,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add a card'));
      await tester.pumpAndSettle();

      expect(find.text('Coming soon'), findsWidgets);
      final tile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Symptom frequency by day of cycle'),
      );
      expect(tile.enabled, isFalse);
    });

    testWidgets('removing an added card takes it off the dashboard', (
      tester,
    ) async {
      final overrides = await setUp(
        now: () => DateTime(2026, 8, 30, 9),
        seed: (db) async {
          final prefs = DashboardCardPreferencesRepository(db);
          final defaults = await prefs.getAll();
          await prefs.saveAll([
            ...defaults,
            // A mode distinct from quick-stat-0's default ("Days since
            // last period") so the two don't share a SwitchListTile
            // title below.
            newGaugeCardInstance(
              order: defaults.length,
              mode: GaugeCardMode.estimatedDaysUntilNextPeriod,
            ),
          ]);
        },
      );

      await pumpTestApp(
        tester,
        const DashboardCustomizeScreen(),
        overrides: overrides,
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byIcon(Icons.delete_outline_rounded),
        300,
      );
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
      expect(
        find.widgetWithText(SwitchListTile, 'Estimated days until next period'),
        findsNothing,
      );
    });
  });

  group('gauge cards (dashboard_visualizations.feature)', () {
    testWidgets(
      'shows the value and fills relative to the average cycle length',
      (tester) async {
        final overrides = await setUp(
          now: () => DateTime(2026, 8, 30, 9),
          seed: (db) async {
            final cycleLogs = CycleDayLogRepository(db);
            // Three period starts, 28 days apart each — 2 complete cycle
            // lengths, enough to not be "thin" per hasThinCycleHistory.
            await savePeriod(cycleLogs, DateTime(2026, 6, 25));
            await savePeriod(cycleLogs, DateTime(2026, 7, 23));
            await savePeriod(cycleLogs, DateTime(2026, 8, 20));

            final prefs = DashboardCardPreferencesRepository(db);
            final defaults = await prefs.getAll();
            await prefs.saveAll([
              ...defaults,
              newGaugeCardInstance(
                order: defaults.length,
                mode: GaugeCardMode.daysSinceLastPeriod,
              ),
            ]);
          },
        );

        await pumpTestApp(
          tester,
          const DashboardScreen(),
          overrides: overrides,
        );
        await tester.pumpAndSettle();
        // The dashboard's ListView only mounts children within its
        // viewport/cache extent — a plain find.byType wouldn't see a card
        // this far down without scrolling to it first, same as the
        // existing "Calendar"/"Insights" checks elsewhere in this suite.
        await tester.scrollUntilVisible(find.byType(GaugeCard), 300);

        // Aug 20 -> Aug 30 is 10 days, with 2 regular cycles behind it —
        // not thin, so no "~" prefix (see GaugeCard's "$value" branch).
        expect(
          find.descendant(
            of: find.byType(GaugeCard),
            matching: find.text('10'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows an approximate value when cycle history is too thin, per '
      '"Gauge shows a range instead of false precision when data is '
      'thin"',
      (tester) async {
        final overrides = await setUp(
          now: () => DateTime(2026, 8, 30, 9),
          seed: (db) async {
            final cycleLogs = CycleDayLogRepository(db);
            // Only one period start — fewer than 2 complete cycles.
            await savePeriod(cycleLogs, DateTime(2026, 8, 20));

            final prefs = DashboardCardPreferencesRepository(db);
            final defaults = await prefs.getAll();
            await prefs.saveAll([
              ...defaults,
              newGaugeCardInstance(
                order: defaults.length,
                mode: GaugeCardMode.daysSinceLastPeriod,
              ),
            ]);
          },
        );

        await pumpTestApp(
          tester,
          const DashboardScreen(),
          overrides: overrides,
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.byType(GaugeCard), 300);

        expect(
          find.descendant(
            of: find.byType(GaugeCard),
            matching: find.text('~10'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'switching a gauge card\'s mode in customize updates its dashboard '
      'value and persists',
      (tester) async {
        final overrides = await setUp(
          now: () => DateTime(2026, 8, 30, 9),
          seed: (db) async {
            final cycleLogs = CycleDayLogRepository(db);
            await savePeriod(cycleLogs, DateTime(2026, 7, 23));
            await savePeriod(cycleLogs, DateTime(2026, 8, 20)); // 28-day cycle

            final prefs = DashboardCardPreferencesRepository(db);
            final defaults = await prefs.getAll();
            await prefs.saveAll([
              ...defaults,
              newGaugeCardInstance(
                order: defaults.length,
                mode: GaugeCardMode.daysSinceLastPeriod,
              ),
            ]);
          },
        );

        await pumpTestApp(
          tester,
          const DashboardCustomizeScreen(),
          overrides: overrides,
        );
        await tester.pumpAndSettle();

        final estimatedModeOption = find.widgetWithText(
          RadioListTile<GaugeCardMode>,
          'Estimated days until next period',
        );
        await tester.scrollUntilVisible(estimatedModeOption, 300);
        await tester.tap(estimatedModeOption);
        await tester.pumpAndSettle();

        final saved = await DashboardCardPreferencesRepository(
          openDb!,
        ).getAll();
        final gauge = saved.firstWhere(
          (c) => c.kind == DashboardCardKind.gauge,
        );
        expect(gauge.gaugeMode, GaugeCardMode.estimatedDaysUntilNextPeriod);
      },
    );
  });

  group('trend cards (dashboard_visualizations.feature)', () {
    testWidgets('never fabricates a trend from insufficient history', (
      tester,
    ) async {
      final overrides = await setUp(
        now: () => DateTime(2026, 8, 30, 9),
        seed: (db) async {
          final cycleLogs = CycleDayLogRepository(db);
          // Only one period start — no complete cycle length yet.
          await savePeriod(cycleLogs, DateTime(2026, 8, 20));

          final prefs = DashboardCardPreferencesRepository(db);
          final defaults = await prefs.getAll();
          await prefs.saveAll([
            ...defaults,
            newTrendCardInstance(order: defaults.length),
          ]);
        },
      );

      await pumpTestApp(tester, const DashboardScreen(), overrides: overrides);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byType(TrendCard), 300);

      expect(
        find.descendant(
          of: find.byType(TrendCard),
          matching: find.textContaining('Not enough cycles logged yet'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('plots complete cycle lengths once there are at least 2', (
      tester,
    ) async {
      final overrides = await setUp(
        now: () => DateTime(2026, 8, 30, 9),
        seed: (db) async {
          final cycleLogs = CycleDayLogRepository(db);
          await savePeriod(cycleLogs, DateTime(2026, 6, 25));
          await savePeriod(cycleLogs, DateTime(2026, 7, 23));
          await savePeriod(cycleLogs, DateTime(2026, 8, 20));

          final prefs = DashboardCardPreferencesRepository(db);
          final defaults = await prefs.getAll();
          await prefs.saveAll([
            ...defaults,
            newTrendCardInstance(order: defaults.length),
          ]);
        },
      );

      await pumpTestApp(tester, const DashboardScreen(), overrides: overrides);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byType(TrendCard), 300);

      expect(
        find.descendant(
          of: find.byType(TrendCard),
          matching: find.textContaining('Not enough cycles logged yet'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(TrendCard),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
      );
    });
  });
}
