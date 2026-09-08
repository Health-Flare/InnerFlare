import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/cycle_day_log_repository.dart';
import 'package:inner_flare/main.dart';

import 'helpers/test_database.dart';

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  testWidgets('app boots through the loading screen to the dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nowProvider.overrideWithValue(() => DateTime(2026, 1, 1, 9)),
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
    await tester.pumpAndSettle(); // flush the dashboard's async providers

    expect(find.text('InnerFlare'), findsOneWidget);
    expect(find.text('Log today'), findsWidgets);
  });
}
