// lib/core/storage/web_download_helper_web.dart
// Uses modern dart:js_interop + package:web instead of deprecated dart:html.
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

class WebDownloadHelper {
  /// Creates a Blob from [bytes], triggers a browser download as [filename],
  /// and calls [onBlobCreated] with the resulting object URL so the caller
  /// can store it for later playback.
  static void triggerBrowserDownload({
    required List<int> bytes,
    required String filename,
    required void Function(String blobUrl) onBlobCreated,
  }) {
    try {
      // Convert the byte list to a JS-compatible Uint8Array
      final uint8List = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      final jsArray = uint8List.toJS;

      // Build the Blob
      final blobParts = [jsArray].toJS;
      final options = web.BlobPropertyBag(type: 'video/mp4');
      final blob = web.Blob(blobParts, options);

      final blobUrl = web.URL.createObjectURL(blob);
      onBlobCreated(blobUrl);

      // Trigger native browser download
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement
        ..href = blobUrl
        ..download = filename
        ..style.display = 'none';
      web.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
    } catch (_) {}
  }

  /// Revokes a previously created object URL to free browser memory.
  static void revokeBlob(String blobUrl) {
    try {
      if (blobUrl.startsWith('blob:')) {
        web.URL.revokeObjectURL(blobUrl);
      }
    } catch (_) {}
  }
}
