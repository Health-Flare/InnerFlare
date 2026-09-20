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
import 'package:inner_flare/features/dashboard/screens/dashboard_screen.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/period_flow.dart';
import 'package:inner_flare/models/quick_stat.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../helpers/test_app_builder.dart';
import '../helpers/test_database.dart';

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  // sqflite caches open databases by path, and every in-memory test
  // database shares the same ":memory:" path — without closing it, the
  // next test's `openDatabase` call would silently reuse the previous
  // test's connection (and its rows).
  Database? openDb;
  tearDown(() async {
    await openDb?.close();
    openDb = null;
  });

  // Dashboard screen also reads the dashboard card layout; every override
  // list needs this so it resolves to an in-memory db instead of the real
  // (biometric-gated) one. Caches by the shared ":memory:" path, so this
  // reuses whichever in-memory db a test already opened for the cycle log
  // repository above.
  Override dashboardPrefsOverride() {
    return dashboardCardPreferencesRepositoryProvider.overrideWith((ref) async {
      final db = await openInMemoryTestDatabase(onCreate: onCreate);
      return DashboardCardPreferencesRepository(db);
    });
  }

  // The log screen (opened via "Log today" or the calendar) reads the
  // tracked symptom catalog; every override list needs this so it
  // resolves to an in-memory db instead of the real (biometric-gated)
  // one.
  Override symptomsOverride() {
    return trackedSymptomsRepositoryProvider.overrideWith((ref) async {
      final db = await openInMemoryTestDatabase(onCreate: onCreate);
      return TrackedSymptomsRepository(db);
    });
  }

  List<Override> overridesFor(DateTime Function() now) {
    return [
      nowProvider.overrideWithValue(now),
      cycleDayLogRepositoryProvider.overrideWith((ref) async {
        final db = await openInMemoryTestDatabase(onCreate: onCreate);
        openDb = db;
        return CycleDayLogRepository(db);
      }),
      dashboardPrefsOverride(),
      symptomsOverride(),
    ];
  }

  /// Saves a period that started on [start] and logged period flow for
  /// each of [flowDays] consecutive days from there (default: just the
  /// start day itself).
  Future<void> savePeriod(
    CycleDayLogRepository repository,
    DateTime start, {
    int flowDays = 1,
  }) async {
    for (var i = 0; i < flowDays; i++) {
      final date = start.add(Duration(days: i));
      await repository.save(
        CycleDayLog(
          date: date,
          periodFlow: PeriodFlow.medium,
          isPeriodStart: i == 0,
        ),
      );
    }
  }

  testWidgets('shows a greeting, the log-today entry point, and honest '
      'empty states for calendar and insights', (tester) async {
    await pumpTestApp(
      tester,
      const DashboardScreen(),
      overrides: overridesFor(() => DateTime(2026, 1, 1, 9)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('Log today'), findsWidgets);

    await tester.scrollUntilVisible(find.text('Calendar'), 200);
    expect(find.text('Calendar'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Insights'), 200);
    expect(find.text('Insights'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('No cloud. No accounts. Just you.'),
      200,
    );
    expect(find.text('No cloud. No accounts. Just you.'), findsOneWidget);
  });

  testWidgets(
    'tapping the FAB opens the log screen; confirming with zero input '
    'still saves today',
    (tester) async {
      await pumpTestApp(
        tester,
        const DashboardScreen(),
        overrides: overridesFor(() => DateTime(2026, 1, 1, 9)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FloatingActionButton, 'Log today'));
      await tester.pumpAndSettle();
      expect(find.text('Log today'), findsWidgets); // screen app bar title

      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Logged today.'), findsOneWidget);
      expect(find.text('Today is logged'), findsOneWidget);
    },
  );

  testWidgets(
    'once today is logged, the entry point reopens the same entry for '
    'editing, not a duplicate',
    (tester) async {
      late CycleDayLogRepository repository;
      await pumpTestApp(
        tester,
        const DashboardScreen(),
        overrides: [
          nowProvider.overrideWithValue(() => DateTime(2026, 1, 1, 9)),
          cycleDayLogRepositoryProvider.overrideWith((ref) async {
            final db = await openInMemoryTestDatabase(onCreate: onCreate);
            openDb = db;
            repository = CycleDayLogRepository(db);
            return repository;
          }),
          dashboardPrefsOverride(),
          symptomsOverride(),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FloatingActionButton, 'Log today'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Logged today.'), findsOneWidget);

      await tester.tap(find.widgetWithText(FloatingActionButton, 'Log today'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();

      final saved = await repository.getByDate(DateTime(2026, 1, 1));
      expect(saved?.periodFlow, PeriodFlow.medium);

      final rows = await openDb!.query(cycleDayLogsTable);
      expect(rows, hasLength(1));
    },
  );

  testWidgets(
    'reopening a logged day pre-fills its flow, symptoms, and note, and '
    'editing updates the same row',
    (tester) async {
      final db = await openInMemoryTestDatabase(onCreate: onCreate);
      openDb = db;
      final repository = CycleDayLogRepository(db);
      await repository.save(
        CycleDayLog(
          date: DateTime(2026, 1, 1),
          periodFlow: PeriodFlow.light,
          symptoms: const {'cramps'},
          note: 'feeling off',
        ),
      );

      await pumpTestApp(
        tester,
        const DashboardScreen(),
        overrides: [
          nowProvider.overrideWithValue(() => DateTime(2026, 1, 1, 9)),
          cycleDayLogRepositoryProvider.overrideWith((ref) async {
            return repository;
          }),
          dashboardPrefsOverride(),
          symptomsOverride(),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FloatingActionButton, 'Log today'));
      await tester.pumpAndSettle();

      final lightChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Light'),
      );
      final crampsChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Cramps'),
      );
      expect(lightChip.selected, isTrue);
      expect(crampsChip.selected, isTrue);
      expect(find.text('feeling off'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Heavy'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();

      final saved = await repository.getByDate(DateTime(2026, 1, 1));
      expect(saved?.periodFlow, PeriodFlow.heavy);
      expect(saved?.symptoms, {'cramps'});
      expect(saved?.note, 'feeling off');

      final rows = await openDb!.query(cycleDayLogsTable);
      expect(rows, hasLength(1));
    },
  );

  testWidgets(
    'flow and symptom chips persist immediately, without pressing Done',
    (tester) async {
      late CycleDayLogRepository repository;
      await pumpTestApp(
        tester,
        const DashboardScreen(),
        overrides: [
          nowProvider.overrideWithValue(() => DateTime(2026, 1, 1, 9)),
          cycleDayLogRepositoryProvider.overrideWith((ref) async {
            final db = await openInMemoryTestDatabase(onCreate: onCreate);
            openDb = db;
            repository = CycleDayLogRepository(db);
            return repository;
          }),
          dashboardPrefsOverride(),
          symptomsOverride(),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FloatingActionButton, 'Log today'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Medium'));
      await tester.pumpAndSettle();
      var saved = await repository.getByDate(DateTime(2026, 1, 1));
      expect(saved?.periodFlow, PeriodFlow.medium);

      await tester.tap(find.widgetWithText(FilterChip, 'Fatigue'));
      await tester.pumpAndSettle();
      saved = await repository.getByDate(DateTime(2026, 1, 1));
      expect(saved?.symptoms, {'fatigue'});

      // Tapping a selected symptom chip again removes it.
      await tester.tap(find.widgetWithText(FilterChip, 'Fatigue'));
      await tester.pumpAndSettle();
      saved = await repository.getByDate(DateTime(2026, 1, 1));
      expect(saved?.symptoms, isEmpty);
    },
  );

  testWidgets(
    'log a previous day opens the calendar; tapping a date opens the same '
    'log screen for that date, without touching today\'s entry',
    (tester) async {
      late CycleDayLogRepository repository;
      await pumpTestApp(
        tester,
        const DashboardScreen(),
        overrides: [
          nowProvider.overrideWithValue(() => DateTime(2026, 1, 15, 9)),
          cycleDayLogRepositoryProvider.overrideWith((ref) async {
            final db = await openInMemoryTestDatabase(onCreate: onCreate);
            openDb = db;
            repository = CycleDayLogRepository(db);
            return repository;
          }),
          dashboardPrefsOverride(),
          symptomsOverride(),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Log a previous day'), findsOneWidget);
      await tester.tap(find.text('Log a previous day'));
      await tester.pumpAndSettle();

      // The calendar opens on the current month; tap the 10th.
      expect(find.text('January 2026'), findsOneWidget);
      await tester.tap(find.byKey(ValueKey(DateTime(2026, 1, 10))));
      await tester.pumpAndSettle();

      // Same single-screen log UI, now for Jan 10 instead of today.
      expect(find.text('Edit a previous day'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Heavy'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();

      // Back on the calendar.
      expect(find.text('January 2026'), findsOneWidget);

      final backLogged = await repository.getByDate(DateTime(2026, 1, 10));
      expect(backLogged?.periodFlow, PeriodFlow.heavy);

      final todayEntry = await repository.getByDate(DateTime(2026, 1, 15));
      expect(todayEntry, isNull);
    },
  );

  testWidgets(
    'reopening a back-logged day from the calendar pre-fills it and edits '
    'update the same row',
    (tester) async {
      final db = await openInMemoryTestDatabase(onCreate: onCreate);
      openDb = db;
      final repository = CycleDayLogRepository(db);
      await repository.save(
        CycleDayLog(
          date: DateTime(2026, 1, 10),
          periodFlow: PeriodFlow.spotting,
        ),
      );

      await pumpTestApp(
        tester,
        const DashboardScreen(),
        overrides: [
          nowProvider.overrideWithValue(() => DateTime(2026, 1, 15, 9)),
          cycleDayLogRepositoryProvider.overrideWith((ref) async {
            return repository;
          }),
          dashboardPrefsOverride(),
          symptomsOverride(),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log a previous day'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey(DateTime(2026, 1, 10))));
      await tester.pumpAndSettle();

      final spottingChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Spotting'),
      );
      expect(spottingChip.selected, isTrue);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Light'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();

      final saved = await repository.getByDate(DateTime(2026, 1, 10));
      expect(saved?.periodFlow, PeriodFlow.light);

      final rows = await openDb!.query(
        cycleDayLogsTable,
        where: 'date = ?',
        whereArgs: ['2026-01-10'],
      );
      expect(rows, hasLength(1));
    },
  );

  testWidgets('customize entry point is discoverable and opens customization', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const DashboardScreen(),
      overrides: overridesFor(() => DateTime(2026, 1, 1, 9)),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Customize dashboard'), findsOneWidget);

    await tester.tap(find.byTooltip('Customize dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Customize dashboard'), findsWidgets);
  });

  testWidgets(
    'hiding a card in customization removes it from the dashboard and '
    'persists after the app is reopened',
    (tester) async {
      final overrides = overridesFor(() => DateTime(2026, 1, 1, 9));
      await pumpTestApp(tester, const DashboardScreen(), overrides: overrides);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Insights'), 200);
      expect(find.text('Insights'), findsOneWidget);

      await tester.tap(find.byTooltip('Customize dashboard'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.widgetWithText(SwitchListTile, 'Insights'),
        200,
      );
      await tester.tap(find.widgetWithText(SwitchListTile, 'Insights'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Insights'), findsNothing);
      // The persistent log entry point stays reachable even with a card
      // hidden.
      expect(find.text('Log today'), findsWidgets);

      // "Reopening the app": rebuild the same widget tree fresh, reusing
      // the same overrides (and therefore the same in-memory db) so the
      // saved preference is read back rather than recreated.
      await pumpTestApp(tester, const DashboardScreen(), overrides: overrides);
      await tester.pumpAndSettle();

      expect(find.text('Insights'), findsNothing);
      expect(find.text('Calendar'), findsOneWidget);
    },
  );

  group('quick stats (docs/features/quick_stats.feature)', () {
    testWidgets(
      'both default quick stats appear below the log-today area, in the '
      'same grid as Calendar and Insights (docs/features/'
      'dashboard_grid_layout.feature)',
      (tester) async {
        final db = await openInMemoryTestDatabase(onCreate: onCreate);
        openDb = db;
        final repository = CycleDayLogRepository(db);
        await savePeriod(repository, DateTime(2026, 7, 27), flowDays: 5);
        await savePeriod(repository, DateTime(2026, 8, 24), flowDays: 3);

        await pumpTestApp(
          tester,
          const DashboardScreen(),
          overrides: [
            nowProvider.overrideWithValue(() => DateTime(2026, 9, 3, 9)),
            cycleDayLogRepositoryProvider.overrideWith((ref) async {
              return repository;
            }),
            dashboardPrefsOverride(),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.text('Log a previous day'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Days since last period'),
          200,
        );
        expect(find.text('Days since last period'), findsOneWidget);
        expect(find.text('Est. days to next period'), findsOneWidget);
        expect(find.text('Calendar'), findsOneWidget);
        expect(find.text('Insights'), findsOneWidget);
      },
    );

    testWidgets(
      'computes both defaults from real logged history: end-of-period '
      'days-since and an average-based estimate',
      (tester) async {
        final db = await openInMemoryTestDatabase(onCreate: onCreate);
        openDb = db;
        final repository = CycleDayLogRepository(db);
        // Two period starts 28 days apart; the most recent one logged
        // flow for 3 days (24th-26th), then stopped.
        await savePeriod(repository, DateTime(2026, 7, 27), flowDays: 5);
        await savePeriod(repository, DateTime(2026, 8, 24), flowDays: 3);

        await pumpTestApp(
          tester,
          const DashboardScreen(),
          overrides: [
            nowProvider.overrideWithValue(() => DateTime(2026, 9, 3, 9)),
            cycleDayLogRepositoryProvider.overrideWith((ref) async {
              return repository;
            }),
            dashboardPrefsOverride(),
          ],
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('since it ended'), 200);

        // Default reference point is the end of the last period (the
        // 26th) — 8 days before "now" (Sept 3rd).
        expect(find.text('8'), findsOneWidget);
        expect(find.text('since it ended'), findsOneWidget);
        // Average cycle length is 28 days; 10 days after the last start
        // (the 24th) leaves 18 estimated days to go.
        expect(find.text('18'), findsOneWidget);
      },
    );

    testWidgets(
      'a period still being logged today shows 0 days since it ended, '
      'not a stale count',
      (tester) async {
        final db = await openInMemoryTestDatabase(onCreate: onCreate);
        openDb = db;
        final repository = CycleDayLogRepository(db);
        await savePeriod(repository, DateTime(2026, 7, 27), flowDays: 5);
        // Flow logged every day from the last start through today.
        await savePeriod(repository, DateTime(2026, 8, 24), flowDays: 4);

        await pumpTestApp(
          tester,
          const DashboardScreen(),
          overrides: [
            nowProvider.overrideWithValue(() => DateTime(2026, 8, 27, 9)),
            cycleDayLogRepositoryProvider.overrideWith((ref) async {
              return repository;
            }),
            dashboardPrefsOverride(),
          ],
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Days since last period'),
          200,
        );

        expect(find.text('0'), findsOneWidget);
      },
    );

    testWidgets(
      'no period ever logged shows an honest empty state on both stats, '
      'never a fabricated number',
      (tester) async {
        await pumpTestApp(
          tester,
          const DashboardScreen(),
          overrides: overridesFor(() => DateTime(2026, 1, 1, 9)),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Not enough data yet').first,
          200,
        );

        expect(find.text('Not enough data yet'), findsNWidgets(2));
      },
    );

    testWidgets(
      'a first-ever period has no prior cycle to average, so only the '
      'estimate is "not enough data yet"',
      (tester) async {
        final db = await openInMemoryTestDatabase(onCreate: onCreate);
        openDb = db;
        final repository = CycleDayLogRepository(db);
        await savePeriod(repository, DateTime(2026, 8, 24), flowDays: 3);

        await pumpTestApp(
          tester,
          const DashboardScreen(),
          overrides: [
            nowProvider.overrideWithValue(() => DateTime(2026, 9, 3, 9)),
            cycleDayLogRepositoryProvider.overrideWith((ref) async {
              return repository;
            }),
            dashboardPrefsOverride(),
          ],
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('an estimate'), 200);

        expect(find.text('8'), findsOneWidget); // days since it ended
        expect(find.text('Not enough data yet'), findsOneWidget);
      },
    );

    testWidgets('an overdue period is labeled as overdue, not shown as a bare '
        'negative number', (tester) async {
      final db = await openInMemoryTestDatabase(onCreate: onCreate);
      openDb = db;
      final repository = CycleDayLogRepository(db);
      // 28-day average; last start was 31 days before "now" — 3 days
      // overdue.
      await savePeriod(repository, DateTime(2026, 7, 27), flowDays: 5);
      await savePeriod(repository, DateTime(2026, 8, 24), flowDays: 3);

      await pumpTestApp(
        tester,
        const DashboardScreen(),
        overrides: [
          nowProvider.overrideWithValue(() => DateTime(2026, 9, 24, 9)),
          cycleDayLogRepositoryProvider.overrideWith((ref) async {
            return repository;
          }),
          dashboardPrefsOverride(),
        ],
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('3 days overdue'), 200);

      expect(find.text('-3'), findsNothing);
      expect(find.text('3 days overdue'), findsOneWidget);
    });

    testWidgets(
      'quick stats are reconfigured the same way as any other card, from '
      'Customize dashboard, and it persists after the app is reopened',
      (tester) async {
        final overrides = overridesFor(() => DateTime(2026, 9, 3, 9));
        await pumpTestApp(
          tester,
          const DashboardScreen(),
          overrides: overrides,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Customize dashboard'));
        await tester.pumpAndSettle();

        // Slot 0 defaults to "days since last period", whose reference-
        // point selector is shown inline, same as gauge/trend mode
        // selectors.
        await tester.tap(
          find.byKey(const ValueKey('quick-stat-0-refpoint-periodStart')),
        );
        await tester.pumpAndSettle();

        // "Reopening the app": rebuild fresh, reusing the same overrides
        // (and therefore the same in-memory db) so the saved preference
        // is read back rather than recreated.
        await pumpTestApp(
          tester,
          const DashboardScreen(),
          overrides: overrides,
        );
        await tester.pumpAndSettle();

        final saved = await DashboardCardPreferencesRepository(
          openDb!,
        ).getAll();
        final slot0 = saved.firstWhere((c) => c.id == 'quick-stat-0');
        expect(
          slot0.quickStatReferencePoint,
          QuickStatReferencePoint.periodStart,
        );
      },
    );
  });
}
