import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/cycle_day_log_repository.dart';
import 'package:inner_flare/features/dashboard/screens/dashboard_screen.dart';
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

  testWidgets('tapping the FAB logs today with zero input and confirms it', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const DashboardScreen(),
      overrides: overridesFor(() => DateTime(2026, 1, 1, 9)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Log today'));
    await tester.pumpAndSettle();

    expect(find.text('Logged today.'), findsOneWidget);
    expect(find.text('Today is logged'), findsOneWidget);
  });

  testWidgets('once today is logged, the entry point offers editing instead of '
      're-saving', (tester) async {
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
    expect(find.text('Logged today.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Log today'));
    await tester.pumpAndSettle();
    expect(
      find.text("Editing today's details is coming soon."),
      findsOneWidget,
    );

    final saved = await repository.getByDate(DateTime(2026, 1, 1));
    expect(saved, isNotNull);
  });

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
