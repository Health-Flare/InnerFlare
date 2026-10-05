import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/nudges/dashboard_nudges.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/dashboard_card_preferences_provider.dart';
import 'package:inner_flare/core/providers/dashboard_card_preferences_repository_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/providers/nudge_state_repository_provider.dart';
import 'package:inner_flare/core/providers/tracked_symptoms_repository_provider.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/cycle_day_log_repository.dart';
import 'package:inner_flare/data/repositories/dashboard_card_preferences_repository.dart';
import 'package:inner_flare/data/repositories/nudge_state_repository.dart';
import 'package:inner_flare/data/repositories/tracked_symptoms_repository.dart';
import 'package:inner_flare/features/dashboard/screens/dashboard_screen.dart';
import 'package:inner_flare/features/dashboard/widgets/nudge_banner.dart';
import 'package:inner_flare/core/nudges/nudge_rules.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/dashboard_card.dart';
import 'package:inner_flare/models/period_flow.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../helpers/test_app_builder.dart';
import '../helpers/test_database.dart';

// docs/features/dashboard_nudges.feature and the nudge scenarios in
// docs/features/dashboard_visualizations.feature, on the real dashboard
// screen over a real (in-memory) database: nothing about the nudge
// selection or storage is faked.

final _now = DateTime(2026, 10, 4, 9);

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  late Database db;
  setUp(() async {
    db = await openInMemoryTestDatabase(
      onCreate: onCreate,
      version: schemaVersion,
    );
  });
  tearDown(() => db.close());

  List<Override> overrides({bool nudgeStorageFails = false}) => [
    nowProvider.overrideWithValue(() => _now),
    cycleDayLogRepositoryProvider.overrideWith(
      (ref) async => CycleDayLogRepository(db),
    ),
    dashboardCardPreferencesRepositoryProvider.overrideWith(
      (ref) async => DashboardCardPreferencesRepository(db),
    ),
    trackedSymptomsRepositoryProvider.overrideWith(
      (ref) async => TrackedSymptomsRepository(db),
    ),
    nudgeStateRepositoryProvider.overrideWith(
      (ref) async => nudgeStorageFails
          ? throw StateError('nudge storage unavailable')
          : NudgeStateRepository(db),
    ),
  ];

  /// Logs [count] one-day periods, 28 days apart, ending well before now.
  Future<void> logPeriods(int count) async {
    final repository = CycleDayLogRepository(db);
    final first = DateTime(
      2026,
      9,
      20,
    ).subtract(Duration(days: 28 * (count - 1)));
    for (var i = 0; i < count; i++) {
      await repository.save(
        CycleDayLog(
          date: first.add(Duration(days: 28 * i)),
          periodFlow: PeriodFlow.medium,
        ),
      );
    }
  }

  Future<void> addCards(List<DashboardCardInstance> extra) async {
    final repository = DashboardCardPreferencesRepository(db);
    final current = await repository.getAll();
    await repository.saveAll([...current, ...extra]);
  }

  DashboardCardInstance gauge(int order) => newGaugeCardInstance(order: order);

  Future<void> pumpDashboard(WidgetTester tester) async {
    await pumpTestApp(tester, const DashboardScreen(), overrides: overrides());
    await tester.pumpAndSettle();
  }

  testWidgets('no nudge on a fresh install with nothing logged', (
    tester,
  ) async {
    await pumpDashboard(tester);
    expect(find.byType(NudgeBanner), findsNothing);
  });

  testWidgets('one logged period suggests a gauge card, below "Log today" '
      'and above the cards', (tester) async {
    await logPeriods(1);
    await pumpDashboard(tester);

    expect(find.byType(NudgeBanner), findsOneWidget);
    expect(find.text('Add gauge'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    expect(find.text("Don't suggest this again"), findsOneWidget);

    final banner = tester.getTopLeft(find.byType(NudgeBanner)).dy;
    final logToday = tester.getTopLeft(find.text('Log a previous day')).dy;
    expect(banner, greaterThan(logToday));
  });

  testWidgets('"Add gauge" adds the card and the nudge goes away', (
    tester,
  ) async {
    await logPeriods(1);
    await pumpDashboard(tester);

    await tester.tap(find.text('Add gauge'));
    await tester.pumpAndSettle();

    final cards = await DashboardCardPreferencesRepository(db).getAll();
    expect(cards.where((c) => c.kind == DashboardCardKind.gauge), hasLength(1));
    expect(find.text('Add gauge'), findsNothing);
  });

  testWidgets('"Don\'t suggest this again" retires it for good, across a '
      'restart', (tester) async {
    await logPeriods(1);
    await pumpDashboard(tester);

    await tester.tap(find.text("Don't suggest this again"));
    await tester.pumpAndSettle();
    expect(find.byType(NudgeBanner), findsNothing);

    final stored = await NudgeStateRepository(db).getAll();
    expect(
      stored[DashboardNudge.suggestGauge.storageKey]!.disposition,
      NudgeDisposition.dismissedPermanently,
    );

    // A fresh widget tree over the same database: the app reopening.
    await tester.pumpWidget(const SizedBox());
    await pumpDashboard(tester);
    expect(find.text('Add gauge'), findsNothing);
  });

  testWidgets('"Not now" on a suggestion snoozes it for about two cycles', (
    tester,
  ) async {
    await logPeriods(1);
    await pumpDashboard(tester);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.byType(NudgeBanner), findsNothing);

    final state = (await NudgeStateRepository(
      db,
    ).getAll())[DashboardNudge.suggestGauge.storageKey]!;
    expect(state.disposition, NudgeDisposition.snoozed);
    // One period logged: no average yet, so twice the 28-day fallback.
    expect(state.snoozedUntil, DateTime.utc(2026, 11, 29));
  });

  testWidgets('after a gauge is dismissed, the trend suggestion takes its '
      'place when there is enough history', (tester) async {
    await logPeriods(3);
    await pumpDashboard(tester);
    expect(find.text('Add gauge'), findsOneWidget);

    await tester.tap(find.text("Don't suggest this again"));
    await tester.pumpAndSettle();

    expect(find.text('Add trend chart'), findsOneWidget);
  });

  testWidgets('duplicate cards: the cleanup nudge names them and "Remove '
      'extra" removes only the extra', (tester) async {
    await addCards([gauge(10), gauge(11)]);
    await pumpDashboard(tester);

    expect(find.textContaining('Days since last period'), findsWidgets);
    expect(find.text('Remove extra'), findsOneWidget);

    await tester.tap(find.text('Remove extra'));
    await tester.pumpAndSettle();

    final cards = await DashboardCardPreferencesRepository(db).getAll();
    expect(cards.where((c) => c.kind == DashboardCardKind.gauge), hasLength(1));
    expect(
      cards.where((c) => c.kind == DashboardCardKind.calendar),
      hasLength(1),
    );
    expect(find.text('Remove extra'), findsNothing);
  });

  testWidgets('a snoozed cleanup nudge comes back after the next card is '
      'added, if it still applies', (tester) async {
    await addCards([
      gauge(10),
      newTrendCardInstance(order: 11),
      newTrendCardInstance(order: 12, metric: TrendCardMetric.flowIntensity),
    ]);
    await pumpDashboard(tester);
    expect(find.text('Review'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Review'), findsNothing);

    // Still snoozed on a fresh open: no card added yet.
    await tester.pumpWidget(const SizedBox());
    await pumpDashboard(tester);
    expect(find.text('Review'), findsNothing);

    // Adding a card the normal way ends that snooze.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DashboardScreen)),
    );
    await container
        .read(dashboardCardPreferencesProvider.notifier)
        .addCard(
          newTrendCardInstance(
            order: 13,
            metric: TrendCardMetric.symptomFrequency,
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('Review'), findsOneWidget);
  });

  test('adding a card still works when nudge storage fails', () async {
    final container = ProviderContainer(
      overrides: overrides(nudgeStorageFails: true),
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);

    await container
        .read(dashboardCardPreferencesProvider.notifier)
        .addCard(gauge(10));

    final cards = await DashboardCardPreferencesRepository(db).getAll();
    expect(cards.where((c) => c.kind == DashboardCardKind.gauge), hasLength(1));
  });
}
