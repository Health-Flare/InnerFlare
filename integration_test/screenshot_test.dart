// Captures app-store screenshots against real, on-device rendering (see
// docs/deployment — this is a one-off tool for producing store assets,
// not a correctness test, so it isn't part of `flutter test`'s default
// run). Seeds the encrypted database with the same demo dataset as the
// debug-only "Load demo data" control in Settings, via the same
// repository real logging goes through, then pumps each primary screen
// directly (rather than tapping/popping through in-app navigation,
// which is already covered by the widget tests in test/widget/ and is
// needlessly flaky here — iOS's full-width swipe-back gesture detector
// can still be layered over the screen for a frame or two after a pop
// settles, stealing the next tap) and takes a screenshot of each.
//
// appDatabaseProvider is overridden to open with AlwaysAllowBiometricGate
// instead of the real device biometric prompt — same fake the rest of
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
//     -d <device-id>
//
// Screenshots land under screenshots/raw/<device-id>/ via
// test_driver/integration_test.dart's onScreenshot handler.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inner_flare/core/debug/demo_data.dart';
import 'package:inner_flare/core/providers/calendar_month_logs_provider.dart';
import 'package:inner_flare/core/providers/cycle_day_log_entry_provider.dart';
import 'package:inner_flare/core/providers/cycle_day_log_repository_provider.dart';
import 'package:inner_flare/core/providers/cycle_insights_provider.dart';
import 'package:inner_flare/core/providers/cycle_prediction_provider.dart';
import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/core/providers/has_any_logs_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/providers/today_log_provider.dart';
import 'package:inner_flare/core/security/biometric_gate.dart';
import 'package:inner_flare/core/theme/app_theme.dart';
import 'package:inner_flare/data/database/app_database.dart';
import 'package:inner_flare/features/calendar/screens/calendar_screen.dart';
import 'package:inner_flare/features/dashboard/screens/dashboard_screen.dart';
import 'package:inner_flare/features/insights/screens/insights_screen.dart';
import 'package:inner_flare/features/log/screens/log_entry_screen.dart';
import 'package:inner_flare/features/settings/screens/settings_screen.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture app store screenshots', (tester) async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith(
          (ref) => AppDatabase(
            biometricGate: const AlwaysAllowBiometricGate(),
          ).open(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final periodStartDate = await _seedDemoData(container);

    // Android needs the Flutter surface converted to a plain image view
    // before takeScreenshot() can capture it; a no-op on every other
    // platform (see integration_test's _callback_io.dart).
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    await _showScreen(tester, container, const DashboardScreen());
    await binding.takeScreenshot('01_dashboard');

    await _showScreen(tester, container, const CalendarScreen());
    await binding.takeScreenshot('02_calendar');

    await _showScreen(tester, container, const InsightsScreen());
    await binding.takeScreenshot('03_insights');

    await _showScreen(tester, container, const SettingsScreen());
    await binding.takeScreenshot('04_settings');

    final repository = await container.read(
      cycleDayLogRepositoryProvider.future,
    );
    final loggedDay = await repository.getByDate(periodStartDate);
    await _showScreen(
      tester,
      container,
      LogEntryScreen(date: periodStartDate, initialLog: loggedDay),
    );
    await binding.takeScreenshot('05_log_entry');
  });
}

/// Pumps [screen] as the root of a fresh [MaterialApp] sharing
/// [container], and settles it. Each screenshot gets its own root widget
/// rather than reaching it via push/pop through the real app shell — see
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
        title: 'InnerFlare',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Seeds [buildDemoCycleLogs] through the real repository, oldest first,
/// then invalidates every provider that reads from it — same as
/// lib/features/settings/screens/settings_screen.dart's debug-only
/// "Load demo data" button, just driven directly from the test instead
/// of tapping through Settings. Returns the most recent period's start
/// date, so the caller can show [LogEntryScreen] for a day that actually
/// has something logged.
Future<DateTime> _seedDemoData(ProviderContainer container) async {
  final repository = await container.read(cycleDayLogRepositoryProvider.future);
  final now = container.read(nowProvider)();
  final logs = buildDemoCycleLogs(now: now)
    ..sort((a, b) => a.date.compareTo(b.date));
  for (final log in logs) {
    await repository.save(log);
  }

  container.invalidate(todayLogProvider);
  container.invalidate(hasAnyLogsProvider);
  container.invalidate(cycleInsightsProvider);
  container.invalidate(cyclePredictionProvider);
  container.invalidate(calendarMonthLogsProvider);
  container.invalidate(cycleDayLogEntryProvider);

  // isPeriodStart is computed by the repository on save, not set on the
  // generator's own CycleDayLog values (which default it to false) — ask
  // the repository, the authoritative source, rather than guessing which
  // of [logs] became a period start.
  final periodStarts = await repository.getPeriodStartDates();
  return periodStarts.last;
}
