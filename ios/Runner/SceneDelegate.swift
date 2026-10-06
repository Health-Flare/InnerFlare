import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  /// A plain cover with no data on it, put over the window whenever the
  /// scene stops being active (issue #91). iOS takes the app switcher
  /// snapshot (and saves it to disk under Library/SplashBoard/Snapshots)
  /// after the scene resigns active, so the snapshot shows this instead
  /// of whatever screen was open.
  private var privacyCover: UIView?

  // Observed as notifications rather than by overriding
  // sceneWillResignActive / sceneDidBecomeActive: FlutterSceneDelegate
  // implements those to drive Flutter's own lifecycle but doesn't declare
  // them in its header, so a Swift method with the same selector would
  // replace them with no way to call super. Observing leaves Flutter's
  // handling untouched.
  override init() {
    super.init()
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(sceneWillDeactivate(_:)),
      name: UIScene.willDeactivateNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(sceneDidActivate(_:)),
      name: UIScene.didActivateNotification,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @objc private func sceneWillDeactivate(_ notification: Notification) {
    guard let scene = notification.object as? UIWindowScene,
      let window = window, window.windowScene === scene
    else { return }
    showPrivacyCover(in: window)
  }

  @objc private func sceneDidActivate(_ notification: Notification) {
    guard let scene = notification.object as? UIWindowScene,
      window?.windowScene === scene
    else { return }
    privacyCover?.removeFromSuperview()
    privacyCover = nil
  }

  private func showPrivacyCover(in window: UIWindow) {
    if let cover = privacyCover {
      window.bringSubviewToFront(cover)
      return
    }
    // The Face ID sheet and the passcode screen also make the scene
    // inactive, so this cover sits behind them during every unlock.
    // It uses the lock screen's own colours, so the user sees the same
    // dark background they were already looking at, minus the text, and
    // it goes away as soon as the sheet closes. It never takes touches,
    // and VoiceOver skips it.
    let cover = PrivacyCoverView(frame: window.bounds)
    cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    cover.isUserInteractionEnabled = false
    cover.accessibilityElementsHidden = true
    window.addSubview(cover)
    privacyCover = cover
  }
}

/// The deep teal gradient from AppLockScreen and AppUnlockScreen
/// (0xFF17272C to 0xFF0B1416), with nothing on it.
private class PrivacyCoverView: UIView {
  override class var layerClass: AnyClass { CAGradientLayer.self }

  override init(frame: CGRect) {
    super.init(frame: frame)
    guard let gradient = layer as? CAGradientLayer else { return }
    gradient.colors = [
      UIColor(red: 0x17 / 255.0, green: 0x27 / 255.0, blue: 0x2C / 255.0, alpha: 1).cgColor,
      UIColor(red: 0x0B / 255.0, green: 0x14 / 255.0, blue: 0x16 / 255.0, alpha: 1).cgColor,
    ]
    gradient.startPoint = CGPoint(x: 0.5, y: 0)
    gradient.endPoint = CGPoint(x: 0.5, y: 1)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) is not used")
  }
}
