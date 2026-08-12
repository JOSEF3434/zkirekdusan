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

  /// Android emulator loopback to host machine
  static const _androidEmulatorUrl = 'http://10.0.2.2:3000/api';

  /// iOS simulator / Web / desktop loopback
  static const _localUrl = 'http://localhost:3000/api';

  static String get apiBaseUrl {
    // Allow explicit override via .env for CI / staging
    final envOverride = dotenv.env['API_BASE_URL'];
    if (envOverride != null && envOverride.isNotEmpty) return envOverride;

    // Release builds always use production
    if (kReleaseMode) return _productionUrl;

    // Debug builds use platform-specific local URL
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidEmulatorUrl;
    }
    return _localUrl;
  }

  static String get appName => dotenv.env['APP_NAME'] ?? 'ዝክረ ክዱሳን';
}
