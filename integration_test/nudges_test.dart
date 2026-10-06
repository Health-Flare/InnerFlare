// Runs the dashboard nudges end to end on a simulator or device, against
// the real encrypted on-device database (docs/features/dashboard_nudges
// .feature). Same setup as screenshot_test.dart: the biometric prompt is
// replaced with AlwaysAllowBiometricGate, everything else is real.
//
//   flutter test integration_test/nudges_test.dart -d <simulator-id>
//
// It wipes this device's logs and nudge choices first, so run it on a
// simulator, not a phone with data you care about.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/nudges/dashboard_nudges.dart';
import 'package:inner_flare/core/nudges/nudge_rules.dart';
import 'package:inner_flare/core/providers/dashboard_card_preferences_provider.dart';
import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/providers/nudge_state_provider.dart';
import 'package:inner_flare/core/providers/nudge_state_repository_provider.dart';
import 'package:inner_flare/core/security/biometric_gate.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/data/database/app_database.dart';
import 'package:inner_flare/features/dashboard/screens/dashboard_screen.dart';
import 'package:inner_flare/features/dashboard/widgets/nudge_banner.dart';
import 'package:inner_flare/models/dashboard_card.dart';
import 'package:integration_test/integration_test.dart';

import 'capture_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    container = ProviderContainer(
      overrides: [
        nowProvider.overrideWithValue(() => fixedNow),
        appDatabaseProvider.overrideWith(
          (ref) => AppDatabase(
            biometricGate: const AlwaysAllowBiometricGate(),
          ).open(),
        ),
      ],
    );
    // Clean slate: demo history, default layout, no nudge choices.
    await seedDemoData(container);
    await seedDashboardLayout(container, customized: false);
    final nudges = await container.read(nudgeStateRepositoryProvider.future);
    await nudges.deleteAll();
    container.invalidate(nudgeStatesProvider);
  });

  tearDown(() => container.dispose());

  Future<void> showDashboard(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('demo history suggests a gauge card, and accepting it adds '
      'the card', (tester) async {
    await showDashboard(tester);

    expect(find.byType(NudgeBanner), findsOneWidget);
    await tester.tap(find.text('Add gauge'));
    await tester.pumpAndSettle();

    final cards = await container.read(dashboardCardPreferencesProvider.future);
    expect(cards.where((c) => c.kind == DashboardCardKind.gauge), hasLength(1));
    // Demo data has several cycles, so the trend suggestion is next.
    expect(find.text('Add trend chart'), findsOneWidget);
  });

  testWidgets('choices survive the database being reopened', (tester) async {
    await showDashboard(tester);
    await tester.tap(find.text("Don't suggest this again"));
    await tester.pumpAndSettle();

    // Drop every cached provider: the next read goes back to the file.
    container.invalidate(nudgeStateRepositoryProvider);
    container.invalidate(nudgeStatesProvider);
    await showDashboard(tester);

    final states = await container.read(nudgeStatesProvider.future);
    expect(
      states[DashboardNudge.suggestGauge]!.disposition,
      NudgeDisposition.dismissedPermanently,
    );
    expect(find.text('Add gauge'), findsNothing);
  });

  testWidgets('duplicate cards: "Remove extra" from the nudge', (tester) async {
    // The provider is autoDispose: with no screen watching it yet, it
    // would be torn down mid-save. Hold it open the way the dashboard does.
    final keepAlive = container.listen(
      dashboardCardPreferencesProvider,
      (_, _) {},
    );
    addTearDown(keepAlive.close);
    final prefs = container.read(dashboardCardPreferencesProvider.notifier);
    await prefs.addCard(newGaugeCardInstance(order: 10));
    await prefs.addCard(newGaugeCardInstance(order: 11));
    await showDashboard(tester);

    expect(find.text('Remove extra'), findsOneWidget);
    await tester.tap(find.text('Remove extra'));
    await tester.pumpAndSettle();

    final cards = await container.read(dashboardCardPreferencesProvider.future);
    expect(cards.where((c) => c.kind == DashboardCardKind.gauge), hasLength(1));
  });
}
