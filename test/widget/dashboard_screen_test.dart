import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/cycle_day_log_repository.dart';
import 'package:inner_flare/features/dashboard/screens/dashboard_screen.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/period_flow.dart';
import 'package:inner_flare/models/symptom.dart';
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

  List<Override> overridesFor(DateTime Function() now) {
    return [
      nowProvider.overrideWithValue(now),
      cycleDayLogRepositoryProvider.overrideWith((ref) async {
        final db = await openInMemoryTestDatabase(onCreate: onCreate);
        openDb = db;
        return CycleDayLogRepository(db);
      }),
    ];
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
          symptoms: const {Symptom.cramps},
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
      expect(saved?.symptoms, {Symptom.cramps});
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
      expect(saved?.symptoms, {Symptom.fatigue});

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

  testWidgets('customize entry point is discoverable', (tester) async {
    await pumpTestApp(
      tester,
      const DashboardScreen(),
      overrides: overridesFor(() => DateTime(2026, 1, 1, 9)),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Customize dashboard'), findsOneWidget);
  });
}
