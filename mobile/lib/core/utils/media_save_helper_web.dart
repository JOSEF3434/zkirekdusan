// lib/core/utils/media_save_helper_web.dart
// Web implementation using dart:html

// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:mime/mime.dart';

Future<void> saveFileWeb({
  required Uint8List bytes,
  required String fileName,
}) async {
  try {
    // 1. Resolve proper MIME type so browser does not treat it as encrypted or raw binary stream
    final mimeType = lookupMimeType(fileName) ?? _getMimeType(fileName);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);

    // 2. Create anchor element with download attribute
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    // 3. Do not immediately revoke object URL synchronously, or browser aborts/corrupts download
    Future.delayed(const Duration(seconds: 30), () {
      html.Url.revokeObjectUrl(url);
    });

    debugPrint('[MediaSaveHelper] Web download triggered: $fileName ($mimeType)');
  } catch (e) {
    debugPrint('[MediaSaveHelper] Web download error: $e');
    rethrow;
  }
}

Future<void> downloadUrlWeb({
  required String url,
  required String fileName,
}) async {
  try {
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..setAttribute('target', '_blank')
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    debugPrint('[MediaSaveHelper] Web direct URL download triggered: $fileName');
  } catch (e) {
    debugPrint('[MediaSaveHelper] Web direct download error: $e');
    html.window.open(url, '_blank');
  }
}

Future<void> saveFileNative({
  required Uint8List bytes,
  required String fileName,
}) async {
  throw UnsupportedError('Native save should not be called on web');
}

String _getMimeType(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.mp4')) return 'video/mp4';
  if (lower.endsWith('.mov')) return 'video/quicktime';
  if (lower.endsWith('.mp3')) return 'audio/mpeg';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  return 'application/octet-stream';
}
