// lib/features/security/data/secure_window_service.dart
//
// Platform-level privacy protection for the app window.
//
// Android  → FLAG_SECURE via a MethodChannel (prevents screenshots and
//             suppresses the task-switcher preview by making the window
//             content appear black in the system recents).
// iOS      → No Dart-side Flutter mechanism to set UIScreenShot prevention.
//             Protection is implemented in AppDelegate (see ios/Runner/AppDelegate.swift)
//             by blurring the snapshot on applicationWillResignActive.
//             This service class is still called for consistency; on iOS the
//             call is a no-op that logs the intent.
// Web/Desktop → No native screenshot prevention is available; the call is
//             silently ignored to keep the service safe across all platforms.
//
// Usage:
//   ref.read(secureWindowServiceProvider).setSecureMode(true);

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureWindowService {
  static const _channel = MethodChannel('com.zikrekidusan.mobile/security');

  /// Enable or disable platform-level screenshot / task-switcher protection.
  ///
  /// On Android this adds / clears [WindowManager.FLAG_SECURE].
  /// On iOS this is a no-op (privacy handled in AppDelegate natively).
  /// On other platforms (Web, Windows, macOS, Linux) this is a no-op.
  Future<void> setSecureMode(bool enabled) async {
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _channel.invokeMethod<bool>(
          'setSecureMode',
          {'enabled': enabled},
        );
      } on PlatformException catch (e) {
        // Non-fatal: log and continue
        debugPrint('[SecureWindowService] Android setSecureMode failed: ${e.message}');
      }
    }
    // iOS: Privacy overlay is handled natively in AppDelegate.
    // We log here for observability during development.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint('[SecureWindowService] iOS secure mode: $enabled (handled natively)');
    }
  }
}

final secureWindowServiceProvider = Provider<SecureWindowService>((ref) {
  return SecureWindowService();
});
