// A clean way to run the app for recording your own videos or taking
// screenshots by hand. Not shipped: nothing in lib/ references it. Launch
// it with scripts/video_mode.sh, which also sets the simulator status bar.
//
// The iOS Simulator can only run debug builds, so "non-debug" here means
// the app looks like a release build:
//   - SCREENSHOT_MODE (passed by the script) hides the debug-only UI:
//     the dashboard database indicator, Settings' Database and Demo data
//     sections (lib/core/debug/debug_chrome.dart).
//   - The DEBUG ribbon is switched off.
//   - The database is the real encrypted file, opened with
//     AlwaysAllowBiometricGate, and the app-lock cover uses the same fake:
//     no Face ID prompt, so tapping Unlock is safe and instant. The
//     unlock screen still appears first on launch, like a real launch.
//   - The first-run disclaimer is already acknowledged.
//   - The demo dataset (Jane Doe, see lib/core/debug/demo_data.dart) and
//     the "customized" dashboard layout are seeded through the real
//     repositories, same as the store screenshots.
//
// Dart defines (via the script's flags):
//   VIDEO_RESEED=false     keep whatever is already in the app's database
//                          instead of replacing it with the demo data
//   VIDEO_FRESH=true       out-of-box experience: seed nothing and leave the
//                          first-run disclaimer unacknowledged, so the app
//                          starts as on a first install (the script also
//                          uninstalls the app first, so its database and
//                          settings are gone)
//   VIDEO_FIXED_CLOCK=true freeze "now" at the spec's 2026-09-25 09:41
//                          (docs/marketing/specs/datasets.yaml)

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/core/providers/biometric_gate_provider.dart';
import 'package:inner_flare/core/providers/database_provider.dart';
import 'package:inner_flare/core/providers/disclaimer_acknowledged_provider.dart';
import 'package:inner_flare/core/providers/now_provider.dart';
import 'package:inner_flare/core/security/biometric_gate.dart';
import 'package:inner_flare/data/database/app_database.dart';
import 'package:inner_flare/main.dart';

import '../integration_test/capture_helpers.dart';

const _reseed = bool.fromEnvironment('VIDEO_RESEED', defaultValue: true);
const _fresh = bool.fromEnvironment('VIDEO_FRESH');
const _fixedClock = bool.fromEnvironment('VIDEO_FIXED_CLOCK');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsApp.debugAllowBannerOverride = false;

  final container = ProviderContainer(
    overrides: [
      if (_fixedClock) nowProvider.overrideWithValue(() => fixedNow),
      biometricGateProvider.overrideWithValue(const AlwaysAllowBiometricGate()),
      appDatabaseProvider.overrideWith(
        (ref) =>
            AppDatabase(biometricGate: const AlwaysAllowBiometricGate()).open(),
      ),
    ],
  );

  // Fresh: touch nothing, so the database isn't even opened until the
  // user taps Unlock, exactly as on a first install.
  if (!_fresh) {
    if (_reseed) {
      await seedDemoData(container);
      await seedDashboardLayout(container, customized: true);
    }

    // Auto-disposed provider: hold a listener so acknowledge() can still
    // set its state after its awaited write.
    final acknowledgement = container.listen(
      disclaimerAcknowledgedProvider,
      (_, _) {},
    );
    await container.read(disclaimerAcknowledgedProvider.future);
    await container.read(disclaimerAcknowledgedProvider.notifier).acknowledge();
    acknowledgement.close();
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const InnerFlareApp(),
    ),
  );
}
