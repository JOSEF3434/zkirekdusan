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
    return 'http://localhost:3000/api';
  }

  static String get appName => dotenv.env['APP_NAME'] ?? 'ዝክረ ክዱሳን';
}
