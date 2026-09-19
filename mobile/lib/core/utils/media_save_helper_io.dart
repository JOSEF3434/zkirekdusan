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

Future<void> saveFileNative({
  required Uint8List bytes,
  required String fileName,
}) async {
  try {
    // Get documents directory
    final dir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${dir.path}/ZkireKdusan_Downloads');

    // Create directory if it doesn't exist
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    // Save file
    final filePath = '${downloadsDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    debugPrint('[MediaSaveHelper] Saved to: $filePath');
  } catch (e) {
    debugPrint('[MediaSaveHelper] Native save error: $e');
    rethrow;
  }
}
