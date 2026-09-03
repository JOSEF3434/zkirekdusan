// lib/core/storage/video_source_resolver.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';

enum VideoSourceType {
  localFile,
  remoteStream,
  unavailable,
}

class ResolvedVideoSource {
  final VideoSourceType type;
  final String? urlOrPath;
  final String? message;

  const ResolvedVideoSource({
    required this.type,
    this.urlOrPath,
    this.message,
  });

  bool get isLocal => type == VideoSourceType.localFile;
  bool get isRemote => type == VideoSourceType.remoteStream;
  bool get isUnavailable => type == VideoSourceType.unavailable;
}

class VideoSourceResolver {
  final AppDatabase _db;
  final Ref _ref;

  VideoSourceResolver(this._db, this._ref);

  /// Resolves where to play the video from:
  /// 1. Local downloaded file if present and intact on disk.
  /// 2. Remote Cloudinary / server stream if online.
  /// 3. Unavailable state if offline and not downloaded.
  Future<ResolvedVideoSource> resolve({
    required String videoId,
    String? remoteHlsOrVideoUrl,
  }) async {
    // 1. Check local database for completed download
    try {
      final localVideo = await _db.videosDao.getVideoById(videoId);
      if (localVideo != null &&
          localVideo.isDownloaded &&
          localVideo.downloadStatus == 'completed' &&
          localVideo.localFilePath != null &&
          localVideo.localFilePath!.isNotEmpty) {
        if (!kIsWeb) {
          final file = File(localVideo.localFilePath!);
          if (await file.exists() && (await file.length()) > 0) {
            return ResolvedVideoSource(
              type: VideoSourceType.localFile,
              urlOrPath: localVideo.localFilePath,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[VideoSourceResolver] Local video lookup error: $e');
    }

    // 2. Check network connectivity
    final isOnline = _ref.read(connectivityProvider).isOnline;
    if (isOnline) {
      if (remoteHlsOrVideoUrl != null && remoteHlsOrVideoUrl.trim().isNotEmpty) {
        final resolved = MediaUrlResolver.resolve(remoteHlsOrVideoUrl);
        if (resolved != null && resolved.isNotEmpty) {
          return ResolvedVideoSource(
            type: VideoSourceType.remoteStream,
            urlOrPath: resolved,
          );
        }
      }
    }

    // 3. Offline and not downloaded
    return const ResolvedVideoSource(
      type: VideoSourceType.unavailable,
      message: 'This video is not downloaded and you are currently offline.',
    );
  }
}
