import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/cycle_day_log_repository.dart';
import 'package:inner_flare/main.dart';

import 'helpers/test_database.dart';

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  testWidgets('app boots through the loading screen, unlock screen, and '
      'into the dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nowProvider.overrideWithValue(() => DateTime(2026, 1, 1, 9)),
          // appDatabaseProvider gates the unlock screen (docs/features/unlock.feature);
          // cycleDayLogRepositoryProvider is what the dashboard's widgets
          // actually read from. Both need a database, so both point at
          // one real in-memory one rather than touching platform channels
          // (biometrics, secure storage) this test env doesn't have.
          appDatabaseProvider.overrideWith(
            (ref) => openInMemoryTestDatabase(onCreate: onCreate),
          ),
          cycleDayLogRepositoryProvider.overrideWith((ref) async {
            final db = await openInMemoryTestDatabase(onCreate: onCreate);
            return CycleDayLogRepository(db);
          }),
        ],
        child: const InnerFlareApp(),
      ),
    );
    await tester.pump(); // flush the loading screen's readyFuture
    await tester.pump(const Duration(milliseconds: 1400)); // min display time
    await tester.pump(const Duration(milliseconds: 500)); // page transition

    // The dedicated unlock screen (docs/features/unlock.feature): nothing
    // about the database is touched until this tap.
    expect(find.text('Inner Flare is locked'), findsOneWidget);
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle(); // flush the dashboard's async providers

    expect(find.text('Inner Flare'), findsOneWidget);
    expect(find.text('Log today'), findsWidgets);
  });
}
