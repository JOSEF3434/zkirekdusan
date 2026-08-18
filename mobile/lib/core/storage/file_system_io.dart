// lib/core/storage/file_system_io.dart
// Native implementation for dart:io File system operations

import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileSystemHelper {
  static Future<String> getApplicationDocumentsPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  static Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  static Future<int> getFileLength(String path) async {
    return await File(path).length();
  }
}
