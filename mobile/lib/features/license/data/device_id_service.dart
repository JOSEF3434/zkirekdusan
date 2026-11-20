// lib/features/license/data/device_id_service.dart
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceIdService {
  static final DeviceInfoPlugin _plugin = DeviceInfoPlugin();

  /// Returns a stable, unique device identifier.
  /// Android → androidId, iOS → identifierForVendor, Web → constant fallback.
  static Future<String> getDeviceId() async {
    if (kIsWeb) {
      return 'web-browser';
    }
    if (Platform.isAndroid) {
      final info = await _plugin.androidInfo;
      return info.id; // Android ID — stable across reboots, resets on factory reset
    }
    if (Platform.isIOS) {
      final info = await _plugin.iosInfo;
      return info.identifierForVendor ?? 'ios-unknown';
    }
    return 'platform-unknown';
  }

  static Future<String> getPlatform() async {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }
}
