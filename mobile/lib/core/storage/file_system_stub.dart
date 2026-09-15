// lib/core/storage/file_system_stub.dart
// Web fallback for dart:io File system operations

class FileSystemHelper {
  static Future<String> getApplicationDocumentsPath() async {
    throw UnsupportedError('Not supported on web');
  }

  static Future<void> deleteFile(String path) async {
    // Safe no-op on web; blob revocation is handled by WebDownloadHelper
  }

  static Future<bool> fileExists(String path) async {
    if (path.isEmpty) return false;
    if (path.startsWith('blob:') ||
        path.startsWith('http:') ||
        path.startsWith('https:') ||
        path.startsWith('data:')) {
      return true;
    }
    return true;
  }

  static Future<int> getFileLength(String path) async {
    return 0;
  }
}
