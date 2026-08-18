// lib/core/storage/file_system_stub.dart
// Web fallback for dart:io File system operations

class FileSystemHelper {
  static Future<String> getApplicationDocumentsPath() async {
    throw UnsupportedError('Not supported on web');
  }

  static Future<void> deleteFile(String path) async {
    throw UnsupportedError('Not supported on web');
  }

  static Future<bool> fileExists(String path) async {
    return false;
  }

  static Future<int> getFileLength(String path) async {
    return 0;
  }
}
