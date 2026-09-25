import 'package:flutter/foundation.dart';

/// Whether debug-only UI (the database status indicator, the Settings
/// "Database" and "Demo data" sections) is shown.
///
/// True only in debug builds, and off in a debug build too when it's run
/// with `--dart-define=SCREENSHOT_MODE=true`: the iOS Simulator can only
/// build debug, so without this switch every store screenshot and marketing
/// video captured there would show diagnostics that never ship (see
/// docs/marketing/README.md). `flutter drive` passes `--dart-define`
/// through, see integration_test/screenshot_test.dart.
const bool showDebugChrome =
    kDebugMode && !bool.fromEnvironment('SCREENSHOT_MODE');
