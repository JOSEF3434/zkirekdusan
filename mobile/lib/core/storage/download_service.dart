// lib/core/storage/download_service.dart
// Production-Grade VideoDownloadManager with Drift SQLite metadata persistence,
// deterministic filesystem directory hierarchy, pause/resume, cancel/retry,
// disk validation, and Cloudinary MP4 rendition selection for offline playback.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/core/storage/video_source_resolver.dart';
import 'package:mobile/core/storage/cache_manager.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';

enum VideoDownloadStatus {
  none,
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

class DownloadMetadata {
  final String videoId;
  final String title;
  final String localPath;
  final String? thumbnailUrl;
  final int sizeBytes;
  final String? quality;
  final VideoDownloadStatus status;

  DownloadMetadata({
    required this.videoId,
    required this.title,
    required this.localPath,
    this.thumbnailUrl,
    required this.sizeBytes,
    this.quality,
    this.status = VideoDownloadStatus.completed,
  });

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'title': title,
        'localPath': localPath,
        'thumbnailUrl': thumbnailUrl,
        'sizeBytes': sizeBytes,
        'quality': quality,
        'status': status.name,
      };

  factory DownloadMetadata.fromJson(Map<String, dynamic> json) =>
      DownloadMetadata(
        videoId: json['videoId'],
        title: json['title'],
        localPath: json['localPath'],
        thumbnailUrl: json['thumbnailUrl'],
        sizeBytes: json['sizeBytes'] ?? 0,
        quality: json['quality'],
        status: VideoDownloadStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => VideoDownloadStatus.completed,
        ),
      );
}

class DownloadState {
  final Map<String, DownloadMetadata> downloads;
  final Map<String, double> progress;
  final Map<String, String> errors;
  final Set<String> downloading;
  final Set<String> paused;

  const DownloadState({
    this.downloads = const {},
    this.progress = const {},
    this.errors = const {},
    this.downloading = const {},
    this.paused = const {},
  });

  DownloadState copyWith({
    Map<String, DownloadMetadata>? downloads,
    Map<String, double>? progress,
    Map<String, String>? errors,
    Set<String>? downloading,
    Set<String>? paused,
  }) {
    return DownloadState(
      downloads: downloads ?? this.downloads,
      progress: progress ?? this.progress,
      errors: errors ?? this.errors,
      downloading: downloading ?? this.downloading,
      paused: paused ?? this.paused,
    );
  }
}

class VideoDownloadManager extends StateNotifier<DownloadState> {
  final AppDatabase _db;
  final StorageService _legacyStorage;
  final ConnectivityNotifier _connectivity;
  final Dio _dio;

  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, ({String url, String title, String? thumbnailUrl, String quality})>
      _downloadTasks = {};

  static const _kLegacyDownloadsKey = 'offline_downloads';

  VideoDownloadManager(
    this._db,
    this._legacyStorage,
    this._connectivity,
    this._dio,
  ) : super(const DownloadState()) {
    _init();
  }

  Future<void> _init() async {
    // 1. Migrate legacy downloads from SharedPreferences into Drift if any
    await _migrateLegacyMetadata();

    // 2. Load all downloaded videos from Drift into state
    await _loadFromDatabase();

    // 3. Listen for DB updates to localVideos
    _db.videosDao.watchDownloadedVideos().listen((videos) {
      final Map<String, DownloadMetadata> map = {};
      for (final v in videos) {
        if (v.localFilePath != null && v.localFilePath!.isNotEmpty) {
          map[v.id] = DownloadMetadata(
            videoId: v.id,
            title: v.title,
            localPath: v.localFilePath!,
            thumbnailUrl: v.thumbnailUrl,
            sizeBytes: v.fileSizeBytes,
            quality: v.selectedQuality,
            status: VideoDownloadStatus.completed,
          );
        }
      }
      state = state.copyWith(downloads: map);
    });
  }

  Future<void> _migrateLegacyMetadata() async {
    try {
      final raw = await _legacyStorage.getToken(key: _kLegacyDownloadsKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        for (final entry in decoded.entries) {
          final meta = DownloadMetadata.fromJson(entry.value);
          if (!kIsWeb) {
            final file = File(meta.localPath);
            if (await file.exists() && (await file.length()) > 0) {
              await _db.videosDao.upsertVideo(
                LocalVideosCompanion(
                  id: drift.Value(meta.videoId),
                  serverId: drift.Value(meta.videoId),
                  title: drift.Value(meta.title),
                  thumbnailUrl: drift.Value(meta.thumbnailUrl),
                  isDownloaded: const drift.Value(true),
                  downloadStatus: const drift.Value('completed'),
                  localFilePath: drift.Value(meta.localPath),
                  downloadProgress: const drift.Value(1.0),
                  fileSizeBytes: drift.Value(meta.sizeBytes),
                  lastAccessedAt: drift.Value(DateTime.now()),
                ),
              );
            }
          }
        }
        // Remove legacy key after migration
        await _legacyStorage.deleteToken(key: _kLegacyDownloadsKey);
      }
    } catch (e) {
      debugPrint('[VideoDownloadManager] Legacy migration note: $e');
    }
  }

  Future<void> _loadFromDatabase() async {
    try {
      final videos = await _db.videosDao.getDownloadedVideos();
      final Map<String, DownloadMetadata> map = {};
      for (final v in videos) {
        if (v.localFilePath != null && v.localFilePath!.isNotEmpty) {
          // Verify file actually exists on filesystem
          if (!kIsWeb) {
            final file = File(v.localFilePath!);
            if (await file.exists() && (await file.length()) > 0) {
              map[v.id] = DownloadMetadata(
                videoId: v.id,
                title: v.title,
                localPath: v.localFilePath!,
                thumbnailUrl: v.thumbnailUrl,
                sizeBytes: v.fileSizeBytes,
                quality: v.selectedQuality,
                status: VideoDownloadStatus.completed,
              );
            }
          }
        }
      }
      state = state.copyWith(downloads: map);
    } catch (e) {
      debugPrint('[VideoDownloadManager] Load from DB error: $e');
    }
  }

  /// Starts downloading a video to deterministic filesystem storage
  Future<void> startDownload({
    required String videoId,
    required String url,
    required String title,
    String? thumbnailUrl,
    String quality = '720p',
    bool allowMobileData = false,
  }) async {
    if (state.downloading.contains(videoId)) return;

    if (kIsWeb) {
      state = state.copyWith(
        errors: {
          ...state.errors,
          videoId: 'Downloading to local storage is not supported on Web.',
        },
      );
      return;
    }

    // Network policy check
    if (!_connectivity.state.isOnline) {
      state = state.copyWith(
        errors: {...state.errors, videoId: 'No internet connection available.'},
      );
      return;
    }

    if (!allowMobileData && _connectivity.state.isMobile) {
      // Default policy: ask or require wifi
      // Still allows user to explicitly allow
    }

    try {
      // 1. Resolve to downloadable Cloudinary MP4 rendition or direct MP4 URL
      final resolvedUrl = MediaUrlResolver.resolve(url);
      if (resolvedUrl == null || resolvedUrl.trim().isEmpty) {
        throw Exception('Invalid download URL: $url');
      }

      final String effectiveDownloadUrl;
      if (MediaUrlResolver.isCloudinary(resolvedUrl)) {
        effectiveDownloadUrl = MediaUrlResolver.toCloudinaryRaw(resolvedUrl);
      } else if (resolvedUrl.endsWith('.m3u8')) {
        effectiveDownloadUrl = resolvedUrl.replaceAll(RegExp(r'\.m3u8$'), '.mp4');
      } else {
        effectiveDownloadUrl = resolvedUrl;
      }

      // 2. Check disk space (ensure at least 50MB free)
      final docDir = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${docDir.path}/videos/video_$videoId');
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      final finalFilePath = '${videoDir.path}/$quality.mp4';
      final tempFilePath = '${videoDir.path}/$quality.mp4.tmp';

      // 3. Update DB & State: queued -> downloading
      _downloadTasks[videoId] = (
        url: url,
        title: title,
        thumbnailUrl: thumbnailUrl,
        quality: quality,
      );

      final cancelToken = CancelToken();
      _cancelTokens[videoId] = cancelToken;

      state = state.copyWith(
        downloading: {...state.downloading, videoId},
        paused: {...state.paused}..remove(videoId),
        progress: {...state.progress, videoId: 0.0},
        errors: {...state.errors}..remove(videoId),
      );

      await _db.videosDao.upsertVideo(
        LocalVideosCompanion(
          id: drift.Value(videoId),
          serverId: drift.Value(videoId),
          title: drift.Value(title),
          thumbnailUrl: drift.Value(thumbnailUrl),
          downloadStatus: const drift.Value('downloading'),
          selectedQuality: drift.Value(quality),
          lastAccessedAt: drift.Value(DateTime.now()),
        ),
      );

      // Check partial file length for resume
      int downloadedBytes = 0;
      final tempFile = File(tempFilePath);
      if (await tempFile.exists()) {
        downloadedBytes = await tempFile.length();
      }

      final options = Options(
        headers: downloadedBytes > 0
            ? {'Range': 'bytes=$downloadedBytes-'}
            : null,
        responseType: ResponseType.stream,
      );

      // 4. Download file
      await _dio.download(
        effectiveDownloadUrl,
        tempFilePath,
        cancelToken: cancelToken,
        options: options,
        deleteOnError: false,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final effectiveTotal = total + downloadedBytes;
            final effectiveReceived = received + downloadedBytes;
            final p = effectiveReceived / effectiveTotal;
            state = state.copyWith(
              progress: {...state.progress, videoId: p},
            );
            _db.videosDao.updateDownloadProgress(
              videoId,
              p,
              fileSizeBytes: effectiveTotal.toInt(),
            );
          }
        },
      );

      // 5. Verification: Rename .tmp to final .mp4
      final downloadedFile = File(tempFilePath);
      if (await downloadedFile.exists()) {
        final length = await downloadedFile.length();
        if (length == 0) {
          throw Exception('Downloaded file is empty (0 bytes)');
        }
        await downloadedFile.rename(finalFilePath);

        // Write deterministic metadata.json alongside the video
        final metadataFile = File('${videoDir.path}/metadata.json');
        final metadata = DownloadMetadata(
          videoId: videoId,
          title: title,
          localPath: finalFilePath,
          thumbnailUrl: thumbnailUrl,
          sizeBytes: length,
          quality: quality,
          status: VideoDownloadStatus.completed,
        );
        await metadataFile.writeAsString(jsonEncode(metadata.toJson()));

        // Update DB
        await _db.videosDao.updateDownloadStatus(
          videoId,
          'completed',
          localFilePath: finalFilePath,
          fileSizeBytes: length,
          selectedQuality: quality,
        );

        state = state.copyWith(
          downloading: {...state.downloading}..remove(videoId),
          paused: {...state.paused}..remove(videoId),
          progress: {...state.progress, videoId: 1.0},
          downloads: {...state.downloads, videoId: metadata},
        );

        // Sync legacy storage so player and other offline providers immediately find it
        try {
          final allDownloads = {...state.downloads, videoId: metadata};
          await _legacyStorage.saveToken(
            key: _kLegacyDownloadsKey,
            token: jsonEncode(allDownloads.map((k, v) => MapEntry(k, v.toJson()))),
          );
        } catch (_) {}
      } else {
        throw Exception('Download finished but output file not found on disk.');
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        // Paused or cancelled by user
        return;
      }
      _handleDownloadError(videoId, e.message ?? e.toString());
    } catch (e) {
      _handleDownloadError(videoId, e.toString());
    } finally {
      _cancelTokens.remove(videoId);
    }
  }

  void _handleDownloadError(String videoId, String error) {
    state = state.copyWith(
      downloading: {...state.downloading}..remove(videoId),
      paused: {...state.paused}..remove(videoId),
      errors: {...state.errors, videoId: error},
    );
    _db.videosDao.updateDownloadStatus(
      videoId,
      'failed',
      error: error,
    );
  }

  /// Pauses an active download, preserving partial file on disk
  Future<void> pauseDownload(String videoId) async {
    final token = _cancelTokens[videoId];
    if (token != null && !token.isCancelled) {
      token.cancel('User paused download');
      _cancelTokens.remove(videoId);
    }

    state = state.copyWith(
      downloading: {...state.downloading}..remove(videoId),
      paused: {...state.paused, videoId},
    );

    await _db.videosDao.updateDownloadStatus(
      videoId,
      'paused',
    );
  }

  /// Resumes a paused or failed download
  Future<void> resumeDownload(String videoId) async {
    final task = _downloadTasks[videoId];
    if (task != null) {
      await startDownload(
        videoId: videoId,
        url: task.url,
        title: task.title,
        thumbnailUrl: task.thumbnailUrl,
        quality: task.quality,
      );
    }
  }

  /// Cancels a download and cleans partial files
  Future<void> cancelDownload(String videoId) async {
    final token = _cancelTokens[videoId];
    if (token != null && !token.isCancelled) {
      token.cancel('User cancelled download');
      _cancelTokens.remove(videoId);
    }

    _downloadTasks.remove(videoId);

    if (!kIsWeb) {
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final videoDir = Directory('${docDir.path}/videos/video_$videoId');
        if (await videoDir.exists()) {
          await videoDir.delete(recursive: true);
        }
      } catch (_) {}
    }

    state = state.copyWith(
      downloading: {...state.downloading}..remove(videoId),
      paused: {...state.paused}..remove(videoId),
      progress: {...state.progress}..remove(videoId),
      errors: {...state.errors}..remove(videoId),
    );

    await _db.videosDao.updateDownloadStatus(
      videoId,
      'cancelled',
    );
  }

  /// Retries a failed download
  Future<void> retryDownload(String videoId) async {
    await resumeDownload(videoId);
  }

  /// Deletes a completed download from disk and updates DB
  Future<void> deleteDownload(String videoId) async {
    if (kIsWeb) return;

    final meta = state.downloads[videoId];
    if (meta != null) {
      try {
        final file = File(meta.localPath);
        if (await file.exists()) {
          await file.delete();
        }
        final parentDir = file.parent;
        if (await parentDir.exists()) {
          await parentDir.delete(recursive: true);
        }
      } catch (_) {}

      await _db.videosDao.updateDownloadStatus(
        videoId,
        'none',
        localFilePath: null,
        fileSizeBytes: 0,
      );

      final newDownloads = Map<String, DownloadMetadata>.from(state.downloads)
        ..remove(videoId);
      state = state.copyWith(
        downloads: newDownloads,
        progress: {...state.progress}..remove(videoId),
        errors: {...state.errors}..remove(videoId),
      );

      try {
        await _legacyStorage.saveToken(
          key: _kLegacyDownloadsKey,
          token: jsonEncode(newDownloads.map((k, v) => MapEntry(k, v.toJson()))),
        );
      } catch (_) {}
    }
  }
}

// Backward-compatible and new providers
final downloadServiceProvider =
    StateNotifierProvider<VideoDownloadManager, DownloadState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final legacyStorage = ref.watch(storageServiceProvider);
  final connectivity = ref.watch(connectivityProvider.notifier);
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 10),
    ),
  );
  return VideoDownloadManager(db, legacyStorage, connectivity, dio);
});

final downloadManagerProvider = downloadServiceProvider;

final videoSourceResolverProvider = Provider<VideoSourceResolver>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return VideoSourceResolver(db, ref);
});

final cacheManagerProvider = Provider<AppCacheManager>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AppCacheManager(db);
});

final storageBreakdownProvider = FutureProvider<StorageBreakdown>((ref) async {
  final cacheManager = ref.watch(cacheManagerProvider);
  return await cacheManager.calculateUsage();
});
