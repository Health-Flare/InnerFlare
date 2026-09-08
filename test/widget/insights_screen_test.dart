import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/cycle_day_log_repository.dart';
import 'package:inner_flare/features/insights/screens/insights_screen.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../fixtures/cycle_day_log_fixtures.dart';
import '../helpers/test_app_builder.dart';
import '../helpers/test_database.dart';

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  Database? openDb;
  tearDown(() async {
    await openDb?.close();
    openDb = null;
  });

  Future<CycleDayLogRepository> seededRepository(
    List<DateTime> periodStarts,
  ) async {
    final db = await openInMemoryTestDatabase(onCreate: onCreate);
    openDb = db;
    final repository = CycleDayLogRepository(db);
    for (final start in periodStarts) {
      await repository.save(periodStartLog(date: start));
    }
    return repository;
  }

  testWidgets('no history shows the honest empty state, no fabrication', (
    tester,
  ) async {
    final repository = await seededRepository(const []);
    await pumpTestApp(
      tester,
      const InsightsScreen(),
      overrides: [
        cycleDayLogRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Not enough data yet'), findsOneWidget);
    expect(find.textContaining('days'), findsNothing);
  });

  testWidgets('exactly one period start explains a second cycle is needed', (
    tester,
  ) async {
    final repository = await seededRepository([DateTime.utc(2026, 8, 1)]);
    await pumpTestApp(
      tester,
      const InsightsScreen(),
      overrides: [
        cycleDayLogRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('One cycle logged'), findsOneWidget);
    expect(find.textContaining('Average cycle length'), findsNothing);
  });

  testWidgets('two complete cycles show an average and a prediction, but no '
      'variability yet', (tester) async {
    final repository = await seededRepository(
      regularPeriodStarts(firstStart: DateTime.utc(2026, 7, 1), cycleCount: 3),
    );
    await pumpTestApp(
      tester,
      const InsightsScreen(),
      overrides: [
        cycleDayLogRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Average cycle length'), findsOneWidget);
    expect(find.text('28 days'), findsOneWidget);
    expect(find.text('Predicted next period'), findsOneWidget);
    expect(find.text('Cycle variability'), findsNothing);
  });

  testWidgets(
    'three regular complete cycles add a variability figure with zero '
    'spread',
    (tester) async {
      final repository = await seededRepository(
        regularPeriodStarts(
          firstStart: DateTime.utc(2026, 5, 1),
          cycleCount: 4,
        ),
      );
      await pumpTestApp(
        tester,
        const InsightsScreen(),
        overrides: [
          cycleDayLogRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Cycle variability'), findsOneWidget);
      expect(find.text('± 0 days'), findsOneWidget);
      expect(find.textContaining('varied by more than a week'), findsNothing);
    },
  );

  testWidgets('irregular cycles are called out rather than hidden', (
    tester,
  ) async {
    final db = await openInMemoryTestDatabase(onCreate: onCreate);
    openDb = db;
    final repository = CycleDayLogRepository(db);
    // Cycle lengths: 21, 35, 27 — a > 7 day spread within the window.
    for (final start in [
      DateTime.utc(2026, 1, 1),
      DateTime.utc(2026, 1, 22),
      DateTime.utc(2026, 2, 26),
      DateTime.utc(2026, 3, 25),
    ]) {
      await repository.save(periodStartLog(date: start));
    }

    await pumpTestApp(
      tester,
      const InsightsScreen(),
      overrides: [
        cycleDayLogRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Average cycle length'), findsOneWidget);
    expect(find.textContaining('varied by more than a week'), findsOneWidget);
  });
}
