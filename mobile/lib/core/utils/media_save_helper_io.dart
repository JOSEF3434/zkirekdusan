// lib/core/utils/media_save_helper_io.dart
// Native (iOS/Android/Desktop) implementation using dart:io

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';

Future<void> saveFileWeb({
  required Uint8List bytes,
  required String fileName,
}) async {
  throw UnsupportedError('Web save should not be called on native platforms');
}

Future<void> downloadUrlWeb({
  required String url,
  required String fileName,
}) async {
  throw UnsupportedError('Web download should not be called on native platforms');
}

Future<void> saveFileNative({
  required Uint8List bytes,
  required String fileName,
}) async {
  try {
    Directory? targetDir;

    if (Platform.isAndroid) {
      // 1. Primary choice: Public Download directory (/storage/emulated/0/Download/ZikreKdusan)
      // Visible directly in Android File Manager like Telegram
      try {
        final publicDownloadDir = Directory('/storage/emulated/0/Download/ZikreKdusan');
        if (!await publicDownloadDir.exists()) {
          await publicDownloadDir.create(recursive: true);
        }
        targetDir = publicDownloadDir;
      } catch (e) {
        debugPrint('[MediaSaveHelper] Primary public download path not writable: $e');
      }

      // 2. Fallback to external storage directory
      if (targetDir == null) {
        try {
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) {
            final dir = Directory('${extDir.path}/ZikreKdusan');
            if (!await dir.exists()) {
              await dir.create(recursive: true);
            }
            targetDir = dir;
          }
        } catch (e) {
          debugPrint('[MediaSaveHelper] getExternalStorageDirectory failed: $e');
        }
      }
    } else if (Platform.isIOS) {
      // iOS: Documents directory (accessible via Files app)
      final appDocDir = await getApplicationDocumentsDirectory();
      targetDir = Directory('${appDocDir.path}/ZikreKdusan');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
    } else {
      // Windows, macOS, Linux
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        targetDir = Directory('${downloads.path}/ZikreKdusan');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      }
    }

    // Final fallback
    targetDir ??= await getApplicationDocumentsDirectory();
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final filePath = '${targetDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    debugPrint('[MediaSaveHelper] Successfully saved file to: $filePath');
  } catch (e) {
    debugPrint('[MediaSaveHelper] Native save error: $e');
    rethrow;
  }
}
