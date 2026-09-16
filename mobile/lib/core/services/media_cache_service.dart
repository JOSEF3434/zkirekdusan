import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central service for persistent media and audio file caching in chats.
///
/// Features:
/// - Persistent local storage of audio/voice messages, photos, and files.
/// - Prevents re-downloading media every time the app is restarted or a message reopens.
/// - Configurable auto-download size limit (default: 5 MB).
/// - Completely offline playback/viewing once cached.
class ChatMediaCacheService {
  static const String autoDownloadLimitKey = 'chat_auto_download_limit_bytes';
  static const int defaultLimitBytes = 5 * 1024 * 1024; // 5 MB

  /// Get user's configured auto-download limit in bytes (default 5 MB).
  static Future<int> getAutoDownloadLimitBytes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(autoDownloadLimitKey) ?? defaultLimitBytes;
    } catch (_) {
      return defaultLimitBytes;
    }
  }

  /// Set user's auto-download limit in bytes (e.g. 5 MB = 5 * 1024 * 1024).
  static Future<void> setAutoDownloadLimitBytes(int bytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(autoDownloadLimitKey, bytes);
    } catch (_) {}
  }

  /// Checks if media URL is already available in persistent disk cache.
  static Future<File?> getLocalCachedFile(String url) async {
    if (kIsWeb) return null;
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return null;

    try {
      final fileInfo = await DefaultCacheManager().getFileFromCache(cleanUrl);
      if (fileInfo != null && await fileInfo.file.exists()) {
        return fileInfo.file;
      }
    } catch (_) {}
    return null;
  }

  /// Returns cached local file if available.
  /// If not cached, checks if [sizeBytes] is within auto-download limit.
  /// If within limit (or [forceDownload] is true), downloads and persists to disk.
  static Future<File?> getOrDownloadMedia(
    String url, {
    int? sizeBytes,
    bool forceDownload = false,
  }) async {
    if (kIsWeb) return null;
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return null;

    try {
      // 1. Check local disk cache first
      final cached = await getLocalCachedFile(cleanUrl);
      if (cached != null) return cached;

      // 2. Check auto-download threshold
      if (!forceDownload && sizeBytes != null) {
        final limit = await getAutoDownloadLimitBytes();
        if (sizeBytes > limit) {
          return null; // Exceeds auto-download threshold
        }
      }

      // 3. Download once and store locally
      final fileInfo = await DefaultCacheManager().downloadFile(cleanUrl);
      return fileInfo.file;
    } catch (_) {
      return null;
    }
  }

  /// Force download a file regardless of size (e.g. when user taps download button).
  static Future<File?> forceDownloadMedia(String url) async {
    return getOrDownloadMedia(url, forceDownload: true);
  }

  /// Clears only chat media cache if requested.
  static Future<void> clearCache() async {
    try {
      await DefaultCacheManager().emptyCache();
    } catch (_) {}
  }
}
