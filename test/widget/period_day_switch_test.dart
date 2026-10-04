// The "Period day" switch on the log screen (issue #103,
// docs/features/log.feature), against a real in-memory database.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/providers/tracked_symptoms_repository_provider.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/cycle_day_log_repository.dart';
import 'package:inner_flare/data/repositories/tracked_symptoms_repository.dart';
import 'package:inner_flare/features/calendar/widgets/calendar_day_cell.dart';
import 'package:inner_flare/features/log/screens/log_entry_screen.dart';
import 'package:inner_flare/models/cycle_day_log.dart';
import 'package:inner_flare/models/period_flow.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../helpers/test_app_builder.dart';
import '../helpers/test_database.dart';

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  final day = DateTime.utc(2026, 3, 1);
  final periodDaySwitch = find.widgetWithText(SwitchListTile, 'Period day');
  const workedOut = 'Worked out from your flow. Change it if you know better.';
  const youMarked = 'You marked this day.';
  const resetLabel = 'Work it out from flow';

  Database? openDb;
  tearDown(() async {
    await openDb?.close();
    openDb = null;
  });

  Future<CycleDayLogRepository> seeded(List<CycleDayLog> logs) async {
    final db = await openInMemoryTestDatabase(
      onCreate: onCreate,
      version: schemaVersion,
    );
    openDb = db;
    final repository = CycleDayLogRepository(db);
    for (final log in logs) {
      await repository.save(log);
    }
    return repository;
  }

  List<Override> overrides(CycleDayLogRepository repository) => [
    nowProvider.overrideWithValue(() => DateTime(2026, 3, 5, 9)),
    cycleDayLogRepositoryProvider.overrideWith((ref) async => repository),
    trackedSymptomsRepositoryProvider.overrideWith((ref) async {
      final db = await openInMemoryTestDatabase(onCreate: onCreate);
      return TrackedSymptomsRepository(db);
    }),
  ];

  Future<void> openDay(
    WidgetTester tester,
    CycleDayLogRepository repository,
  ) async {
    final existing = await tester.runAsync(() => repository.getByDate(day));
    await pumpTestApp(
      tester,
      LogEntryScreen(date: day, initialLog: existing),
      overrides: overrides(repository),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }

  bool switchValue(WidgetTester tester) =>
      tester.widget<SwitchListTile>(periodDaySwitch).value;

  testWidgets('medium flow: switch is on and says it was worked out', (
    tester,
  ) async {
    final repository = await seeded([
      CycleDayLog(date: day, periodFlow: PeriodFlow.medium),
    ]);
    await openDay(tester, repository);

    expect(periodDaySwitch, findsOneWidget);
    expect(switchValue(tester), isTrue);
    expect(find.text(workedOut), findsOneWidget);
    expect(find.text(resetLabel), findsNothing);
  });

  testWidgets('spotting alone: switch is off; turning it on is saved', (
    tester,
  ) async {
    final repository = await seeded([
      CycleDayLog(date: day, periodFlow: PeriodFlow.spotting),
    ]);
    await openDay(tester, repository);
    expect(switchValue(tester), isFalse);

    await tapAndSettle(tester, periodDaySwitch);

    final saved = await tester.runAsync(() => repository.getByDate(day));
    expect(saved?.periodDayOverride, isTrue);
    expect(saved?.periodFlow, PeriodFlow.spotting);
    expect(switchValue(tester), isTrue);
    expect(find.text(youMarked), findsOneWidget);
    expect(find.text(resetLabel), findsOneWidget);
  });

  testWidgets('heavy flow turned off keeps the flow', (tester) async {
    final repository = await seeded([
      CycleDayLog(date: day, periodFlow: PeriodFlow.heavy, note: 'kept'),
    ]);
    await openDay(tester, repository);

    await tapAndSettle(tester, periodDaySwitch);

    final saved = await tester.runAsync(() => repository.getByDate(day));
    expect(saved?.periodDayOverride, isFalse);
    expect(saved?.periodFlow, PeriodFlow.heavy);
    expect(saved?.note, 'kept');
    expect(switchValue(tester), isFalse);
  });

  testWidgets('a new day with no flow can be marked as a period day', (
    tester,
  ) async {
    final repository = await seeded([]);
    await openDay(tester, repository);
    expect(switchValue(tester), isFalse);

    await tapAndSettle(tester, periodDaySwitch);

    final saved = await tester.runAsync(() => repository.getByDate(day));
    expect(saved?.periodDayOverride, isTrue);
    expect(saved?.periodFlow, isNull);
  });

  testWidgets('"Work it out from flow" clears the choice', (tester) async {
    final repository = await seeded([
      CycleDayLog(
        date: day,
        periodFlow: PeriodFlow.spotting,
        periodDayOverride: true,
      ),
    ]);
    await openDay(tester, repository);
    expect(switchValue(tester), isTrue);

    await tapAndSettle(tester, find.text(resetLabel));

    final saved = await tester.runAsync(() => repository.getByDate(day));
    expect(saved?.periodDayOverride, isNull);
    expect(switchValue(tester), isFalse);
    expect(find.text(workedOut), findsOneWidget);
  });

  testWidgets('choosing flow after marking a no-flow day keeps the choice '
      'only while it still disagrees', (tester) async {
    final repository = await seeded([]);
    await openDay(tester, repository);
    await tapAndSettle(tester, periodDaySwitch);

    await tapAndSettle(tester, find.widgetWithText(ChoiceChip, 'Light'));

    final saved = await tester.runAsync(() => repository.getByDate(day));
    expect(saved?.periodFlow, PeriodFlow.light);
    expect(saved?.periodDayOverride, isNull);
    expect(switchValue(tester), isTrue);
    expect(find.text(workedOut), findsOneWidget);
  });

  group('calendar day cell', () {
    Future<void> pumpCell(WidgetTester tester, CycleDayLog log) {
      return pumpTestApp(
        tester,
        Scaffold(
          body: SizedBox(
            width: 60,
            child: CalendarDayCell(
              date: log.date,
              log: log,
              isCurrentMonth: true,
              isToday: false,
              isPredictedPeriod: false,
              isPredictedFertile: false,
              onTap: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('bleeding marked as not a period says so', (tester) async {
      await pumpCell(
        tester,
        CycleDayLog(
          date: DateTime.utc(2026, 3, 10),
          periodFlow: PeriodFlow.heavy,
          periodDayOverride: false,
        ),
      );
      expect(
        find.byTooltip('3/10: heavy flow, not counted as a period'),
        findsOneWidget,
      );
    });

    testWidgets('a no-flow day marked as a period day shows as one', (
      tester,
    ) async {
      await pumpCell(
        tester,
        CycleDayLog(
          date: DateTime.utc(2026, 3, 1),
          periodDayOverride: true,
          isPeriodDay: true,
        ),
      );
      expect(find.byTooltip('3/1: period day'), findsOneWidget);
    });
  });
}
