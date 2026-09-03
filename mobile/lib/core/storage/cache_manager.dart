// lib/core/storage/cache_manager.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mobile/core/database/app_database.dart';

class StorageBreakdown {
  final int videoBytes;
  final int chatMediaBytes;
  final int imageCacheBytes;
  final int tempBytes;

  const StorageBreakdown({
    this.videoBytes = 0,
    this.chatMediaBytes = 0,
    this.imageCacheBytes = 0,
    this.tempBytes = 0,
  });

  int get totalBytes =>
      videoBytes + chatMediaBytes + imageCacheBytes + tempBytes;

  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get formattedVideo => formatBytes(videoBytes);
  String get formattedChat => formatBytes(chatMediaBytes);
  String get formattedCache => formatBytes(imageCacheBytes);
  String get formattedTemp => formatBytes(tempBytes);
  String get formattedTotal => formatBytes(totalBytes);
}

class AppCacheManager {
  final AppDatabase _db;

  AppCacheManager(this._db);

  /// Calculates storage usage across all categories
  Future<StorageBreakdown> calculateUsage() async {
    if (kIsWeb) {
      return const StorageBreakdown();
    }

    int videoBytes = 0;
    int chatBytes = 0;
    int imageBytes = 0;
    int tempBytes = 0;

    try {
      final docDir = await getApplicationDocumentsDirectory();

      // 1. Video storage (/videos/)
      final videosDir = Directory('${docDir.path}/videos');
      if (await videosDir.exists()) {
        videoBytes = await _getDirSize(videosDir);
      }

      // 2. Chat media (/chat/)
      final chatDir = Directory('${docDir.path}/chat');
      if (await chatDir.exists()) {
        chatBytes = await _getDirSize(chatDir);
      }

      // 3. Cache directory (Image cache & network files)
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        imageBytes = await _getDirSize(cacheDir);
      }

      // 4. Incomplete download files (.tmp)
      if (await videosDir.exists()) {
        await for (final file in videosDir.list(recursive: true)) {
          if (file is File && file.path.endsWith('.tmp')) {
            tempBytes += await file.length();
          }
        }
      }
    } catch (e) {
      debugPrint('[AppCacheManager] Storage calculation error: $e');
    }

    return StorageBreakdown(
      videoBytes: videoBytes,
      chatMediaBytes: chatBytes,
      imageCacheBytes: imageBytes,
      tempBytes: tempBytes,
    );
  }

  /// Clears temporary cache (images, temporary files).
  /// NEVER deletes downloaded videos!
  Future<void> clearCache() async {
    if (kIsWeb) return;

    try {
      // Clear DefaultCacheManager
      await DefaultCacheManager().emptyCache();

      // Clear temp directory
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list()) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }

      // Clear .tmp files in videos directory
      final docDir = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${docDir.path}/videos');
      if (await videosDir.exists()) {
        await for (final file in videosDir.list(recursive: true)) {
          if (file is File && file.path.endsWith('.tmp')) {
            try {
              await file.delete();
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('[AppCacheManager] Clear cache error: $e');
    }
  }

  /// Deletes user-selected offline downloads.
  /// Only called when the user explicitly chooses "Delete Downloads".
  Future<void> clearDownloads() async {
    if (kIsWeb) return;

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${docDir.path}/videos');
      if (await videosDir.exists()) {
        await videosDir.delete(recursive: true);
      }

      // Update local database records
      final downloaded = await _db.videosDao.getDownloadedVideos();
      for (final video in downloaded) {
        await _db.videosDao.updateDownloadStatus(
          video.id,
          'none',
          localFilePath: null,
          fileSizeBytes: 0,
        );
      }
    } catch (e) {
      debugPrint('[AppCacheManager] Clear downloads error: $e');
    }
  }

  /// Scans video directory and removes files that are not referenced in the database
  Future<void> cleanOrphanedFiles() async {
    if (kIsWeb) return;

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${docDir.path}/videos');
      if (!await videosDir.exists()) return;

      final dbVideos = await _db.videosDao.getDownloadedVideos();
      final validPaths = dbVideos
          .map((v) => v.localFilePath)
          .whereType<String>()
          .toSet();

      await for (final entity in videosDir.list(recursive: true)) {
        if (entity is File &&
            !entity.path.endsWith('.tmp') &&
            !entity.path.endsWith('metadata.json')) {
          if (!validPaths.contains(entity.path)) {
            try {
              await entity.delete();
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('[AppCacheManager] Orphan clean error: $e');
    }
  }

  Future<int> _getDirSize(Directory dir) async {
    int total = 0;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
    } catch (_) {}
    return total;
  }
}
