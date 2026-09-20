// lib/features/security/data/secure_window_service.dart
//
// Manages OS-level window security (e.g. FLAG_SECURE on Android)
// to prevent screenshots and obscure content in the app switcher / recents menu.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureWindowService {
  static const _channel = MethodChannel('com.zikrekidusan.mobile/security');

  /// Enable or disable FLAG_SECURE on Android.
  Future<void> setSecureMode(bool enabled) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('setSecureMode', {'enabled': enabled});
    } on PlatformException catch (e) {
      debugPrint('[SecureWindowService] PlatformException: ${e.message}');
    } catch (e) {
      debugPrint('[SecureWindowService] Error setting secure mode: $e');
    }
  }
}

final secureWindowServiceProvider = Provider<SecureWindowService>((ref) {
  return SecureWindowService();
});
