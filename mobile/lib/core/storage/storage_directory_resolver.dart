// lib/core/storage/storage_directory_resolver.dart
// Production-grade storage directory resolver conforming to Android Scoped Storage,
// iOS Documents, Desktop Downloads, and Web.
// Defaults to "Internal storage/Zikire Kdusan/" organized into:
// - Images
// - Videos
// - Audio
// - Documents
// - Other

import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum MediaCategory {
  images,
  videos,
  audio,
  documents,
  other,
}

extension MediaCategoryExtension on MediaCategory {
  String get folderName {
    switch (this) {
      case MediaCategory.images:
        return 'Images';
      case MediaCategory.videos:
        return 'Videos';
      case MediaCategory.audio:
        return 'Audio';
      case MediaCategory.documents:
        return 'Documents';
      case MediaCategory.other:
        return 'Other';
    }
  }

  static MediaCategory fromMimeOrExtension(String? mimeType, String? extension) {
    final mime = (mimeType ?? '').toLowerCase();
    final ext = (extension ?? '').toLowerCase().replaceAll('.', '');

    if (mime.startsWith('image/') ||
        ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'heic'].contains(ext)) {
      return MediaCategory.images;
    }
    if (mime.startsWith('video/') ||
        ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v', '3gp'].contains(ext)) {
      return MediaCategory.videos;
    }
    if (mime.startsWith('audio/') ||
        ['mp3', 'm4a', 'wav', 'aac', 'ogg', 'flac'].contains(ext)) {
      return MediaCategory.audio;
    }
    if (mime.contains('pdf') ||
        mime.contains('word') ||
        mime.contains('document') ||
        ['pdf', 'doc', 'docx', 'txt', 'epub', 'xls', 'xlsx', 'ppt', 'pptx'].contains(ext)) {
      return MediaCategory.documents;
    }
    return MediaCategory.other;
  }
}

class StorageDirectoryResolver {
  static const String rootFolderName = 'Zikire Kdusan';

  /// Resolves the base root directory for Zikire Kdusan downloads.
  static Future<Directory> getRootDownloadDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Filesystem directories are not available on web platform');
    }

    if (Platform.isAndroid) {
      // Primary candidate: Shared internal storage Downloads/Zikire Kdusan or root Zikire Kdusan
      try {
        final publicDownloadDir = Directory('/storage/emulated/0/Download/$rootFolderName');
        if (await publicDownloadDir.exists()) {
          return publicDownloadDir;
        }
        await publicDownloadDir.create(recursive: true);
        return publicDownloadDir;
      } catch (_) {
        // Fallback 1: Direct shared internal storage
        try {
          final sharedInternal = Directory('/storage/emulated/0/$rootFolderName');
          if (!await sharedInternal.exists()) {
            await sharedInternal.create(recursive: true);
          }
          return sharedInternal;
        } catch (_) {}
      }

      // Fallback 2: External storage directory from path_provider
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final target = Directory('${extDir.path}/$rootFolderName');
          if (!await target.exists()) {
            await target.create(recursive: true);
          }
          return target;
        }
      } catch (_) {}
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Desktop: User Downloads folder / Zikire Kdusan
      try {
        final dlDir = await getDownloadsDirectory();
        if (dlDir != null) {
          final target = Directory('${dlDir.path}/$rootFolderName');
          if (!await target.exists()) {
            await target.create(recursive: true);
          }
          return target;
        }
      } catch (_) {}
    }

    // Standard Fallback for iOS and other targets
    final docDir = await getApplicationDocumentsDirectory();
    final target = Directory('${docDir.path}/$rootFolderName');
    if (!await target.exists()) {
      await target.create(recursive: true);
    }
    return target;
  }

  /// Resolves the categorized destination folder (Images, Videos, Audio, Documents, Other).
  static Future<Directory> getCategoryDirectory(MediaCategory category) async {
    final root = await getRootDownloadDirectory();
    final categoryDir = Directory('${root.path}/${category.folderName}');
    if (!await categoryDir.exists()) {
      await categoryDir.create(recursive: true);
    }
    return categoryDir;
  }

  /// Creates a temporary processing file to guarantee no incomplete or unwatermarked files
  /// are ever saved into user-facing storage.
  static Future<File> createTempProcessingFile(String extension) async {
    final tempDir = await getTemporaryDirectory();
    final cleanExt = extension.startsWith('.') ? extension : '.$extension';
    final randomSuffix = Random().nextInt(1000000);
    final tempPath =
        '${tempDir.path}/zk_proc_${DateTime.now().millisecondsSinceEpoch}_$randomSuffix$cleanExt';
    return File(tempPath);
  }

  /// Safely finalizes a temporary file by moving it to the destination directory.
  static Future<File> finalizeDownload({
    required File tempFile,
    required String targetFileName,
    required MediaCategory category,
    bool overwrite = true,
  }) async {
    if (!await tempFile.exists()) {
      throw Exception('Temporary download file does not exist: ${tempFile.path}');
    }

    final length = await tempFile.length();
    if (length == 0) {
      try {
        await tempFile.delete();
      } catch (_) {}
      throw Exception('Downloaded file is empty (0 bytes).');
    }

    final categoryDir = await getCategoryDirectory(category);
    final sanitizedName = targetFileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final destinationPath = '${categoryDir.path}/$sanitizedName';
    final destinationFile = File(destinationPath);

    if (await destinationFile.exists()) {
      if (overwrite) {
        await destinationFile.delete();
      } else {
        // Disambiguate name with timestamp
        final extIndex = sanitizedName.lastIndexOf('.');
        final nameWithoutExt = extIndex > 0 ? sanitizedName.substring(0, extIndex) : sanitizedName;
        final ext = extIndex > 0 ? sanitizedName.substring(extIndex) : '';
        final uniquePath =
            '${categoryDir.path}/${nameWithoutExt}_${DateTime.now().millisecondsSinceEpoch}$ext';
        return await tempFile.rename(uniquePath);
      }
    }

    try {
      return await tempFile.rename(destinationPath);
    } catch (_) {
      // If cross-device filesystem move fails, copy then delete
      final copied = await tempFile.copy(destinationPath);
      try {
        await tempFile.delete();
      } catch (_) {}
      return copied;
    }
  }

  /// Cleans up any leftover temporary files.
  static Future<void> cleanupTemp(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[StorageDirectoryResolver] Failed to cleanup temp file: $e');
    }
  }
}
