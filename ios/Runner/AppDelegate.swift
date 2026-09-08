import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Lets the Dart side mark the encrypted database file as excluded from
    // iCloud/iTunes backups — it's already encrypted at rest, but backups
    // are an extra copy of the file outside our control, so we keep it off
    // this device only unless the user explicitly exports it.
    let backupChannel = FlutterMethodChannel(
      name: "com.innerflare/backup_exclusion",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    backupChannel.setMethodCallHandler { call, result in
      guard call.method == "excludeFromBackup",
        let args = call.arguments as? [String: Any],
        let path = args["path"] as? String
      else {
        result(FlutterMethodNotImplemented)
        return
      }

      var url = URL(fileURLWithPath: path)
      var resourceValues = URLResourceValues()
      resourceValues.isExcludedFromBackup = true
      do {
        try url.setResourceValues(resourceValues)
        result(true)
      } catch {
        result(
          FlutterError(
            code: "EXCLUDE_FROM_BACKUP_FAILED",
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    }
  }
}
