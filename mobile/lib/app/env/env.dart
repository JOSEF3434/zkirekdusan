import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await dotenv.load(fileName: '.env');
      _initialized = true;
    } catch (_) {
      // .env may be absent in tests; non-fatal
    }
  }

  static String get apiBaseUrl {
    // Online production URL (release build)
    if (kReleaseMode) {
      return 'https://zikrekidusan.onrender.com/api';
    }

    // Local development URLs
    if (kIsWeb) {
      // Chrome / local web dev
      return 'http://localhost:3000/api';
    }

    // Detect Android without dart:io on web
    // On non-web we can safely use Platform
    return _nativePlatformUrl();
  }

  static String _nativePlatformUrl() {
    // This method is only called on non-web targets
    // Fallback: we detect at runtime via dart:io only on native
    return _resolveNativeUrl();
  }

  static String _resolveNativeUrl() {
    // dart:io is safe on native (non-web) platforms
    try {
      // ignore: unnecessary_import
      if (_isAndroidPlatform()) {
        return 'http://10.0.2.2:3000/api';
      }
    } catch (_) {
      // In test or unsupported platform
    }
    return 'http://localhost:3000/api';
  }

  static bool _isAndroidPlatform() {
    // Safe runtime check without importing dart:io at top level
    try {
      // Dynamic check: works on native, throws/returns false on web
      return _checkAndroid();
    } catch (_) {
      return false;
    }
  }

  // Separated to be tree-shaken on web
  static bool _checkAndroid() {
    // Uses conditional import equivalent via try/catch
    // The Platform class is available on all native targets
    return defaultTargetPlatform == TargetPlatform.android;
  }

  static String get appName => dotenv.env['APP_NAME'] ?? 'StreamHub';
}
