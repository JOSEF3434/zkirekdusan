import Flutter
import UIKit
import AVFAudio
import AVKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var pipChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure audio session for background playback and PiP
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers, .allowAirPlay])
      try session.setActive(true)
    } catch {
      print("[AppDelegate] AVAudioSession setup error: \(error)")
    }

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    pipChannel = FlutterMethodChannel(name: "com.zikrekidusan.mobile/pip", binaryMessenger: controller.binaryMessenger)
    pipChannel?.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "isPipSupported":
        result(AVPictureInPictureController.isPictureInPictureSupported())
      case "enableAutoPip", "disableAutoPip", "updatePlaybackState":
        result(true)
      case "enterPip":
        result(false)
      case "isInPip":
        result(false)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
