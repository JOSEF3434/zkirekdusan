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
  ///
  /// Use this when [storageMode] is **both** (in-app + file save).
  static void triggerBrowserDownload({
    required List<int> bytes,
    required String filename,
    required void Function(String blobUrl) onBlobCreated,
  }) {
    try {
      final blobUrl = createBlobOnly(bytes: bytes);
      onBlobCreated(blobUrl);
      _triggerAnchorDownload(blobUrl, filename);
    } catch (_) {}
  }

  /// Creates an object URL blob from [bytes] for in-app playback,
  /// WITHOUT triggering a browser file-save dialog.
  ///
  /// Returns the blob URL. Use this when [storageMode] is **inAppOnly**.
  static String createBlobOnly({required List<int> bytes}) {
    final uint8List = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final jsArray = uint8List.toJS;
    final blobParts = [jsArray].toJS;
    final options = web.BlobPropertyBag(type: 'video/mp4');
    final blob = web.Blob(blobParts, options);
    return web.URL.createObjectURL(blob);
  }

  /// Triggers only the browser "Save file" dialog from [bytes] without
  /// keeping a blob in-app state.
  ///
  /// Use this when [storageMode] is **saveToFile**.
  static void triggerBrowserSaveOnly({
    required List<int> bytes,
    required String filename,
  }) {
    try {
      final blobUrl = createBlobOnly(bytes: bytes);
      _triggerAnchorDownload(blobUrl, filename);
      // Revoke immediately — we only needed it to trigger the download.
      Future.delayed(const Duration(seconds: 30), () => revokeBlob(blobUrl));
    } catch (_) {}
  }

  static void _triggerAnchorDownload(String blobUrl, String filename) {
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = blobUrl
      ..download = filename
      ..style.display = 'none';
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  }

  /// Revokes a previously created object URL to free browser memory.
  static void revokeBlob(String blobUrl) {
    try {
      if (blobUrl.startsWith('blob:')) {
        web.URL.revokeObjectURL(blobUrl);
      }
    } catch (_) {}
  }

  /// Checks if a blob URL is still active and valid in the current browser session.
  static Future<bool> isBlobUrlValid(String blobUrl) async {
    if (!blobUrl.startsWith('blob:')) return false;
    try {
      final response = await web.window.fetch(blobUrl.toJS).toDart;
      return response.ok;
    } catch (_) {
      return false;
    }
  }
}
