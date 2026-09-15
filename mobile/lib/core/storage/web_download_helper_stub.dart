// lib/core/storage/web_download_helper_stub.dart

class WebDownloadHelper {
  static void triggerBrowserDownload({
    required List<int> bytes,
    required String filename,
    required void Function(String blobUrl) onBlobCreated,
  }) {}

  static void revokeBlob(String blobUrl) {}
}
