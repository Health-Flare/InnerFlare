import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/debug/debug_chrome.dart';
import 'package:inner_flare/core/nudges/dashboard_nudges.dart';
import 'package:inner_flare/core/nudges/nudge_rules.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/providers/nudge_state_repository_provider.dart';
import 'package:inner_flare/data/database/schema.dart';
import 'package:inner_flare/data/repositories/nudge_state_repository.dart';
import 'package:inner_flare/features/settings/widgets/nudge_debug_section.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../helpers/test_app_builder.dart';
import '../helpers/test_database.dart';

// docs/features/dashboard_nudges.feature, "Debug builds can reset and
// inspect nudges". The section itself is pumped directly so every test
// runs under plain `flutter test`; whether Settings shows it at all is
// covered by the showDebugChrome test at the bottom.

void main() {
  setUpAll(useInMemoryTestDatabaseFactory);

  late Database db;
  late NudgeStateRepository repository;
  setUp(() async {
    db = await openInMemoryTestDatabase(
      onCreate: onCreate,
      version: schemaVersion,
    );
    repository = NudgeStateRepository(db);
  });
  tearDown(() => db.close());

  Future<void> pumpSection(WidgetTester tester) async {
    await pumpTestApp(
      tester,
      const Scaffold(body: SingleChildScrollView(child: NudgeDebugSection())),
      overrides: [
        nowProvider.overrideWithValue(() => DateTime(2026, 10, 4, 9)),
        nudgeStateRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists every nudge with its current state', (tester) async {
    await repository.save(
      DashboardNudge.cleanup.storageKey,
      const NudgeState(disposition: NudgeDisposition.snoozedUntilCardAdded),
    );
    await repository.save(
      DashboardNudge.suggestGauge.storageKey,
      NudgeState(
        disposition: NudgeDisposition.snoozed,
        snoozedUntil: DateTime(2026, 12, 1),
      ),
    );
    await repository.save(
      DashboardNudge.suggestTrend.storageKey,
      const NudgeState(disposition: NudgeDisposition.dismissedPermanently),
    );
    await pumpSection(tester);

    expect(find.text('Snoozed until a card is added'), findsOneWidget);
    expect(find.text('Snoozed until 2026-12-01'), findsOneWidget);
    expect(find.text('Dismissed'), findsOneWidget);
  });

  testWidgets('a nudge never acted on says so', (tester) async {
    await pumpSection(tester);
    expect(
      find.text('Never acted on'),
      findsNWidgets(DashboardNudge.values.length),
    );
  });

  testWidgets('"End snoozes now" clears snoozes and keeps dismissals', (
    tester,
  ) async {
    await repository.save(
      DashboardNudge.cleanup.storageKey,
      const NudgeState(disposition: NudgeDisposition.snoozedUntilCardAdded),
    );
    await repository.save(
      DashboardNudge.suggestTrend.storageKey,
      const NudgeState(disposition: NudgeDisposition.dismissedPermanently),
    );
    await pumpSection(tester);

    await tester.tap(find.text('End snoozes now'));
    await tester.pumpAndSettle();

    expect((await repository.getAll()).keys, [
      DashboardNudge.suggestTrend.storageKey,
    ]);
    expect(find.text('Snoozed until a card is added'), findsNothing);
  });

  testWidgets('"Reset all nudges" forgets everything', (tester) async {
    await repository.save(
      DashboardNudge.suggestTrend.storageKey,
      const NudgeState(disposition: NudgeDisposition.dismissedPermanently),
    );
    await pumpSection(tester);

    await tester.tap(find.text('Reset all nudges'));
    await tester.pumpAndSettle();

    expect(await repository.getAll(), isEmpty);
    expect(
      find.text('Never acted on'),
      findsNWidgets(DashboardNudge.values.length),
    );
  });

  test('the Settings screen shows the section only with debug chrome', () {
    // showDebugChrome is a compile-time constant (kDebugMode and not
    // SCREENSHOT_MODE); release/TestFlight builds compile the section out.
    expect(NudgeDebugSection.shownInSettings, showDebugChrome);
  });
}
