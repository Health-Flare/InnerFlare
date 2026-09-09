// Host-side counterpart to integration_test/screenshot_test.dart: writes
// each screenshot it captures to screenshots/raw/<DEVICE_ID>/<name>.png,
// where DEVICE_ID is passed in via `--dart-define` (or defaults to
// "device") so parallel runs against different simulators/emulators
// don't clobber each other's output.

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final deviceId = Platform.environment['SCREENSHOT_DEVICE_ID'] ?? 'device';
  final outDir = Directory('screenshots/raw/$deviceId');
  await outDir.create(recursive: true);

  await integrationDriver(
    onScreenshot:
        (String name, List<int> bytes, [Map<String, Object?>? args]) async {
          final file = File('${outDir.path}/$name.png');
          await file.writeAsBytes(bytes, flush: true);
          return true;
        },
  );
}
