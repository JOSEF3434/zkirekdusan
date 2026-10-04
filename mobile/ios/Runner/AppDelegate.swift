import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  // Privacy protection overlay view — shown when app transitions to background
  // to prevent iOS from capturing a screenshot of sensitive content for the
  // app switcher. Mirrors Telegram's approach on iOS.
  private var privacyOverlayWindow: UIWindow?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // ── App Lifecycle — Privacy Snapshot Protection ─────────────────────────

  /// Called just before the app becomes inactive (enters task switcher).
  /// Display a privacy overlay so iOS captures it — not app content.
  override func applicationWillResignActive(_ application: UIApplication) {
    super.applicationWillResignActive(application)
    showPrivacyOverlay()
  }

  /// Called after the app returns to the foreground.
  /// Remove the overlay once the user has authenticated.
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    // Remove overlay after a brief delay to allow lock screen to render first.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
      self?.hidePrivacyOverlay()
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  private func showPrivacyOverlay() {
    guard privacyOverlayWindow == nil else { return }

    let screen = UIScreen.main
    let window = UIWindow(frame: screen.bounds)
    window.windowLevel = .alert + 1
    window.backgroundColor = .black
    window.isHidden = false

    // Simple icon + lock indicator
    let containerView = UIView(frame: window.bounds)
    containerView.backgroundColor = UIColor(red: 0.04, green: 0.05, blue: 0.09, alpha: 1)

    let lockIcon = UIImageView(image: UIImage(systemName: "lock.fill"))
    lockIcon.tintColor = UIColor.white.withAlphaComponent(0.6)
    lockIcon.contentMode = .scaleAspectFit
    lockIcon.frame = CGRect(
      x: (screen.bounds.width - 40) / 2,
      y: (screen.bounds.height - 40) / 2 + 30,
      width: 40,
      height: 40
    )
    containerView.addSubview(lockIcon)

    window.addSubview(containerView)
    window.makeKeyAndVisible()
    privacyOverlayWindow = window
  }

  private func hidePrivacyOverlay() {
    privacyOverlayWindow?.isHidden = true
    privacyOverlayWindow = nil
  }
}
