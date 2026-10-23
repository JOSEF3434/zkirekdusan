// lib/app/env/env.dart
// Dynamic URL selection:
//   - Android emulator  → http://10.0.2.2:3000/api
//   - iOS/Web local dev → http://localhost:3000/api
//   - Release build     → https://zikrekidusan.onrender.com/api

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
      _initialized = true;
    }
  }

  /// Production API URL (used in release builds and when explicitly overridden).
  static const _productionUrl = 'https://zikrekidusan.onrender.com/api';

  /// Production Frontend / Web URL
  static const _productionFrontendUrl = 'https://zikire-kdusan.onrender.com';

  /// Android emulator loopback to host machine
  static const _androidEmulatorUrl = 'https://zikrekidusan.onrender.com/api';

  /// iOS simulator / Web / desktop loopback
  static const _localUrl = 'https://zikrekidusan.onrender.com/api';

  static String get frontendBaseUrl {
    const defineUrl = String.fromEnvironment('FRONTEND_BASE_URL');
    if (defineUrl.isNotEmpty) return defineUrl;

    if (dotenv.isInitialized) {
      final envOverride =
          dotenv.env['FRONTEND_BASE_URL'] ?? dotenv.env['WEB_BASE_URL'];
      if (envOverride != null && envOverride.trim().isNotEmpty) {
        return envOverride.trim();
      }
    }

    return _productionFrontendUrl;
  }

  static String get apiBaseUrl {
    const defineUrl = String.fromEnvironment(
      'BACKEND_API_BASE_URL',
      defaultValue: String.fromEnvironment('API_BASE_URL'),
    );
    if (defineUrl.isNotEmpty) return defineUrl;

    // Allow explicit override via .env for CI / staging
    if (dotenv.isInitialized) {
      final envOverride =
          dotenv.env['BACKEND_API_BASE_URL'] ?? dotenv.env['API_BASE_URL'];
      if (envOverride != null && envOverride.isNotEmpty) return envOverride;
    }

    // Release builds always use production
    if (kReleaseMode) return _productionUrl;

    // Debug builds use platform-specific local URL
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidEmulatorUrl;
    }
    return _localUrl;
  }

  static String get appName =>
      dotenv.isInitialized ? (dotenv.env['APP_NAME'] ?? 'ዝክረ ክዱሳን') : 'ዝክረ ክዱሳን';

  static String get rtmpServerUrl {
    if (dotenv.isInitialized) {
      final envOverride = dotenv.env['RTMP_SERVER_URL'];
      if (envOverride != null && envOverride.isNotEmpty) return envOverride;
    }

    return 'rtmp://live.cloudinary.com/streams';
  }
}
