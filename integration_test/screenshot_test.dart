// Captures app-store screenshots against real, on-device rendering (see
// docs/deployment; this is a one-off tool for producing store assets,
// not a correctness test, so it isn't part of `flutter test`'s default
// run). Seeds the encrypted database with the same demo dataset as the
// debug-only "Load demo data" control in Settings, via the same
// repository real logging goes through, then pumps each primary screen
// directly (rather than tapping/popping through in-app navigation,
// which is already covered by the widget tests in test/widget/ and is
// needlessly flaky here: iOS's full-width swipe-back gesture detector
// can still be layered over the screen for a frame or two after a pop
// settles, stealing the next tap) and takes a screenshot of each.
//
// appDatabaseProvider is overridden to open with AlwaysAllowBiometricGate
// instead of the real device biometric prompt: same fake the rest of
// the test suite uses (see lib/core/security/biometric_gate.dart) for
// "any environment where a real biometric prompt would hang or isn't
// meaningful", which an unattended screenshot run very much is. The
// database itself is still the real encrypted SQLCipher file with a
// real passphrase from secure storage; only the biometric prompt in
// front of it is swapped out.
//
// Run with:
//
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshot_test.dart \
//     --dart-define=SCREENSHOT_MODE=true \
//     -d <device-id>
//
// SCREENSHOT_MODE hides the debug-only UI (see lib/core/debug/
// debug_chrome.dart) that a debug build, the only kind an iOS Simulator
// can run, would otherwise show in every capture.
//
// Screenshots land under screenshots/raw/<device-id>/ via
// test_driver/integration_test.dart's onScreenshot handler.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/security/biometric_gate.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/data/database/app_database.dart';
import 'package:inner_flare/features/calendar/screens/calendar_screen.dart';
import 'package:inner_flare/features/dashboard/screens/dashboard_customize_screen.dart';
import 'package:inner_flare/features/dashboard/screens/dashboard_screen.dart';
import 'package:inner_flare/features/export/screens/export_screen.dart';
import 'package:inner_flare/features/insights/screens/insights_screen.dart';
import 'package:inner_flare/features/log/screens/log_entry_screen.dart';
import 'package:inner_flare/features/security/screens/app_lock_screen.dart';
import 'package:inner_flare/features/settings/screens/settings_screen.dart';
import 'capture_helpers.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture app store screenshots', (tester) async {
    final container = ProviderContainer(
      overrides: [
        nowProvider.overrideWithValue(() => fixedNow),
        appDatabaseProvider.overrideWith(
          (ref) => AppDatabase(
            biometricGate: const AlwaysAllowBiometricGate(),
          ).open(),
        ),
      ],
    );
    addTearDown(container.dispose);

    // The database is the real on-device file, so it may carry logs from
    // a previous run or manual use: start from empty every time, so the
    // output depends on the dataset alone.
    final periodStartDate = await seedDemoData(container);

    // Android needs the Flutter surface converted to a plain image view
    // before takeScreenshot() can capture it; a no-op on every other
    // platform (see integration_test's _callback_io.dart).
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    // Shot ids and order follow docs/marketing/specs/shots.yaml. The
    // default layout is captured first, before customizing.
    await seedDashboardLayout(container, customized: false);
    await _showScreen(tester, container, const DashboardScreen());
    await binding.takeScreenshot('dashboard_default');

    await seedDashboardLayout(container, customized: true);
    await _showScreen(tester, container, const DashboardScreen());
    // shots.yaml's hero must show a gauge or trend card with real
    // numbers, which sit below the fold on a phone: scroll them into view.
    await tester.scrollUntilVisible(
      find.text('Previous cycle lengths'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await binding.takeScreenshot('dashboard');

    // Capture only: never tap Unlock (real local_auth).
    await _showScreen(tester, container, const AppLockScreen());
    await binding.takeScreenshot('app_lock');

    final repository = await container.read(
      cycleDayLogRepositoryProvider.future,
    );
    final loggedDay = await repository.getByDate(periodStartDate);
    await _showScreen(
      tester,
      container,
      LogEntryScreen(date: periodStartDate, initialLog: loggedDay),
    );
    await binding.takeScreenshot('log_entry');

    await _showScreen(tester, container, const CalendarScreen());
    await binding.takeScreenshot('calendar');

    await _showScreen(tester, container, const InsightsScreen());
    await binding.takeScreenshot('insights');

    await _showScreen(tester, container, const DashboardCustomizeScreen());
    await binding.takeScreenshot('customize');

    await _showScreen(tester, container, const ExportScreen());
    await binding.takeScreenshot('export');

    await _showScreen(tester, container, const SettingsScreen());
    await binding.takeScreenshot('settings');

    // Honesty shot: a fresh install's "not enough data yet".
    await repository.deleteAll();
    invalidateLogDependentProviders(container);
    await _showScreen(tester, container, const InsightsScreen());
    await binding.takeScreenshot('insights_empty');
  });
}

/// Pumps [screen] as the root of a fresh [MaterialApp] sharing
/// [container], and settles it. Each screenshot gets its own root widget
/// rather than reaching it via push/pop through the real app shell. See
/// the file comment above for why.
Future<void> _showScreen(
  WidgetTester tester,
  ProviderContainer container,
  Widget screen,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        title: 'Inner Flare',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
