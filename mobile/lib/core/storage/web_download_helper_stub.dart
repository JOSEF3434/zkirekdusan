// lib/core/storage/web_download_helper_stub.dart

class WebDownloadHelper {
  static void triggerBrowserDownload({
    required List<int> bytes,
    required String filename,
    required void Function(String blobUrl) onBlobCreated,
  }) {}

  static String createBlobOnly({required List<int> bytes}) => '';

  static void triggerBrowserSaveOnly({
    required List<int> bytes,
    required String filename,
  }) {}

  static void revokeBlob(String blobUrl) {}

  static Future<bool> isBlobUrlValid(String blobUrl) async => false;
}
