// lib/core/utils/media_save_helper_web.dart
// Web implementation using dart:html

// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;

Future<void> saveFileWeb({
  required Uint8List bytes,
  required String fileName,
}) async {
  try {
    // Create a blob from bytes
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Create anchor element and trigger download
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    // Clean up the blob URL
    html.Url.revokeObjectUrl(url);

    debugPrint('[MediaSaveHelper] Web download triggered: $fileName');
  } catch (e) {
    debugPrint('[MediaSaveHelper] Web download error: $e');
    rethrow;
  }
}

Future<void> saveFileNative({
  required Uint8List bytes,
  required String fileName,
}) async {
  throw UnsupportedError('Native save should not be called on web');
}
