// lib/core/utils/media_save_helper.dart
// Platform-agnostic interface for saving media files

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports
import 'media_save_helper_stub.dart'
    if (dart.library.io) 'media_save_helper_io.dart'
    if (dart.library.html) 'media_save_helper_web.dart';

/// Platform-agnostic helper for saving media files
class MediaSaveHelper {
  /// Saves bytes to platform storage
  /// - Web: triggers browser download with proper MIME type
  /// - Mobile/Desktop: saves to public ZikreKdusan folder in File Manager
  static Future<void> saveFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (kIsWeb) {
      return saveFileWeb(bytes: bytes, fileName: fileName);
    } else {
      return saveFileNative(bytes: bytes, fileName: fileName);
    }
  }

  /// Direct URL download for Web fallback (e.g. if CORS prevents byte fetching)
  static Future<void> downloadUrl({
    required String url,
    required String fileName,
  }) async {
    if (kIsWeb) {
      return downloadUrlWeb(url: url, fileName: fileName);
    }
  }
}
