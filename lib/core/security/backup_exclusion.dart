import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Marks a file as excluded from iCloud/iTunes backups on iOS. The database
/// is already encrypted at rest, but a backup is an extra copy of that file
/// outside the app's control, so it's kept device-local by default — the
/// user still gets a copy off-device only via the explicit export feature.
///
/// No-op on platforms without a corresponding native implementation
/// (Android's `allowBackup="false"` manifest flag handles this there
/// instead; see android/app/src/main/AndroidManifest.xml).
Future<void> excludeFromBackup(String path) async {
  if (!defaultTargetPlatform.isIOSOrMacOS) return;

  const channel = MethodChannel('com.innerflare/backup_exclusion');
  try {
    await channel.invokeMethod<bool>('excludeFromBackup', {'path': path});
  } on MissingPluginException {
    // No native handler registered (e.g. running on macOS, or in a test
    // harness) — nothing to do.
  }
}

extension on TargetPlatform {
  bool get isIOSOrMacOS =>
      this == TargetPlatform.iOS || this == TargetPlatform.macOS;
}
