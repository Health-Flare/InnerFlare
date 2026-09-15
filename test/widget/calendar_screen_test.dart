import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/providers/tracked_symptoms_repository_provider.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/cycle_day_log_repository.dart';
import 'package:inner_flare/data/repositories/tracked_symptoms_repository.dart';
import 'package:inner_flare/features/calendar/screens/calendar_screen.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/period_flow.dart';
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

  Future<CycleDayLogRepository> seededRepository(List<CycleDayLog> logs) async {
    final db = await openInMemoryTestDatabase(onCreate: onCreate);
    openDb = db;
    final repository = CycleDayLogRepository(db);
    for (final log in logs) {
      await repository.save(log);
    }
    return repository;
  }

  // Tapping a day opens the log screen, which reads the tracked symptom
  // catalog; every override list needs this so it resolves to an
  // in-memory db instead of the real (biometric-gated) one.
  Override symptomsOverride() {
    return trackedSymptomsRepositoryProvider.overrideWith((ref) async {
      final db = await openInMemoryTestDatabase(onCreate: onCreate);
      return TrackedSymptomsRepository(db);
    });
  }

  List<Override> overridesFor(
    CycleDayLogRepository repository,
    DateTime Function() now,
  ) {
    return [
      nowProvider.overrideWithValue(now),
      cycleDayLogRepositoryProvider.overrideWith((ref) async => repository),
      symptomsOverride(),
    ];
  }

  testWidgets(
    'period days are marked, and flow intensity is visually distinguishable',
    (tester) async {
      final repository = await seededRepository([
        CycleDayLog(date: DateTime(2026, 1, 1), periodFlow: PeriodFlow.light),
        CycleDayLog(date: DateTime(2026, 1, 2), periodFlow: PeriodFlow.heavy),
      ]);

      await pumpTestApp(
        tester,
        const CalendarScreen(),
        overrides: overridesFor(repository, () => DateTime(2026, 1, 5, 9)),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('1/1 — period day (light)'), findsOneWidget);
      expect(find.byTooltip('1/2 — period day (heavy)'), findsOneWidget);
    },
  );

  testWidgets('a symptom-only day is marked differently from a period day', (
    tester,
  ) async {
    final repository = await seededRepository([
      CycleDayLog(date: DateTime(2026, 1, 3), symptoms: const {'cramps'}),
      CycleDayLog(date: DateTime(2026, 1, 4), periodFlow: PeriodFlow.medium),
    ]);

    await pumpTestApp(
      tester,
      const CalendarScreen(),
      overrides: overridesFor(repository, () => DateTime(2026, 1, 5, 9)),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('1/3 — symptoms logged'), findsOneWidget);
    expect(find.byTooltip('1/4 — period day (medium)'), findsOneWidget);
  });

  testWidgets(
    'tapping any day, past or future, opens the log screen for that date',
    (tester) async {
      final repository = await seededRepository([]);

      await pumpTestApp(
        tester,
        const CalendarScreen(),
        overrides: overridesFor(repository, () => DateTime(2026, 1, 5, 9)),
      );
      await tester.pumpAndSettle();

      // A past day.
      await tester.tap(find.byKey(ValueKey(DateTime(2026, 1, 2))));
      await tester.pumpAndSettle();
      expect(find.text('Edit a previous day'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Heavy'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();

      final past = await repository.getByDate(DateTime(2026, 1, 2));
      expect(past?.periodFlow, PeriodFlow.heavy);

      // A future day.
      await tester.tap(find.byKey(ValueKey(DateTime(2026, 1, 20))));
      await tester.pumpAndSettle();
      expect(find.text('Edit a previous day'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Spotting'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();

      final future = await repository.getByDate(DateTime(2026, 1, 20));
      expect(future?.periodFlow, PeriodFlow.spotting);
    },
  );

  testWidgets(
    'predicted next period and fertile window show on an upcoming month, '
    'labeled as estimates',
    (tester) async {
      // Two period starts 28 days apart establishes one complete cycle;
      // "now" is the day of the second start so the prediction lands in
      // February.
      final repository = await seededRepository([
        CycleDayLog(date: DateTime(2026, 1, 1), periodFlow: PeriodFlow.medium),
        CycleDayLog(date: DateTime(2026, 1, 29), periodFlow: PeriodFlow.medium),
      ]);

      await pumpTestApp(
        tester,
        const CalendarScreen(),
        overrides: overridesFor(repository, () => DateTime(2026, 1, 29, 9)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();

      expect(find.text('February 2026'), findsOneWidget);
      // Predicted next start: Jan 29 + 28 days = Feb 26.
      expect(
        find.byTooltip('2/26 — predicted period (estimate)'),
        findsOneWidget,
      );
      // Predicted fertile window ends 14 days before that (ovulation day).
      expect(
        find.byTooltip('2/12 — predicted fertile window (estimate)'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'navigating away and back to the current month keeps today in view',
    (tester) async {
      final repository = await seededRepository([]);

      await pumpTestApp(
        tester,
        const CalendarScreen(),
        overrides: overridesFor(repository, () => DateTime(2026, 3, 15, 9)),
      );
      await tester.pumpAndSettle();

      expect(find.text('March 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(find.text('February 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('March 2026'), findsOneWidget);
      expect(find.byKey(ValueKey(DateTime(2026, 3, 15))), findsOneWidget);
    },
  );

  testWidgets(
    'an empty calendar marks nothing and guides the user to log a first '
    'day',
    (tester) async {
      final repository = await seededRepository([]);

      await pumpTestApp(
        tester,
        const CalendarScreen(),
        overrides: overridesFor(repository, () => DateTime(2026, 1, 5, 9)),
      );
      await tester.pumpAndSettle();

      // The month grid can be taller than the test viewport, pushing the
      // legend and guidance text below the fold. The grid is a second,
      // non-scrolling Scrollable in its own right (GridView), so the
      // outer one has to be picked explicitly.
      await tester.scrollUntilVisible(
        find.textContaining('Nothing logged yet'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Nothing logged yet'), findsOneWidget);

      final tooltipMessages = tester
          .widgetList<Tooltip>(find.byType(Tooltip))
          .map((tooltip) => tooltip.message ?? '')
          .toList();
      expect(
        tooltipMessages.where((message) => message.contains('period day')),
        isEmpty,
      );
      expect(
        tooltipMessages.where((message) => message.contains('symptoms logged')),
        isEmpty,
      );
      expect(
        tooltipMessages.where((message) => message.contains('predicted')),
        isEmpty,
      );
    },
  );
}
