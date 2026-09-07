// lib/features/player/data/player_repository.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/home/domain/feed_response.dart';
import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/features/home/domain/video_model.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return PlayerRepository(dio, db, ref);
});

class PlayerRepository {
  final Dio _dio;
  final AppDatabase _db;
  final Ref _ref;

  // In-memory throttling map to prevent hammering local DB / backend on every tick
  final Map<String, DateTime> _lastSaveTime = {};
  static const Duration _throttleInterval = Duration(seconds: 5);

  PlayerRepository(this._dio, this._db, this._ref);

  Future<VideoResponseDto> getVideo(String videoId) async {
    final isOnline = _ref.read(connectivityProvider).isOnline;

    if (isOnline) {
      try {
        Response response;
        try {
          response = await _dio.get('/videos/$videoId');
        } on DioException catch (dioErr) {
          if (dioErr.response?.statusCode == 404 &&
              _dio.options.baseUrl.endsWith('/api')) {
            final rootBase = _dio.options.baseUrl.substring(
              0,
              _dio.options.baseUrl.length - 4,
            );
            response = await _dio.get('$rootBase/videos/$videoId');
          } else {
            rethrow;
          }
        }
        final data = parseEnvelope(response.data);
        final dto = VideoResponseDto.fromJson(data);

        // Cache video metadata locally in Drift
        await _db.videosDao.upsertVideo(
          LocalVideosCompanion(
            id: drift.Value(dto.id),
            serverId: drift.Value(dto.id),
            title: drift.Value(dto.title),
            description: drift.Value(dto.description),
            thumbnailUrl: drift.Value(dto.thumbnailUrl),
            videoUrl: drift.Value(dto.hlsUrl),
            hlsUrl: drift.Value(dto.hlsUrl),
            dashUrl: drift.Value(dto.dashUrl),
            duration: drift.Value(dto.duration),
            creatorId: drift.Value(dto.uploadedById ?? dto.author.id),
            creatorName: drift.Value(dto.author.displayName ?? dto.author.username),
            creatorAvatar: drift.Value(dto.author.avatarUrl),
            createdAt: drift.Value(dto.createdAt),
            updatedAt: drift.Value(dto.updatedAt),
          ),
        );

        return dto;
      } catch (e) {
        debugPrint('[PlayerRepo] Remote getVideo failed: $e, checking local cache');
        final local = await _db.videosDao.getVideoById(videoId);
        if (local != null) {
          return _mapLocalToDto(local);
        }
        if (e is DioException) {
          throw AppException(_parseDioError(e));
        }
        rethrow;
      }
    }

    // Offline fallback from local Drift database
    final local = await _db.videosDao.getVideoById(videoId);
    if (local != null) {
      return _mapLocalToDto(local);
    }

    throw Exception('You are offline and this video is not downloaded.');
  }

  VideoResponseDto _mapLocalToDto(LocalVideoData local) {
    return VideoResponseDto(
      id: local.id,
      title: local.title,
      description: local.description,
      status: VideoStatus.ready,
      visibility: 'PUBLIC',
      duration: local.duration,
      thumbnailUrl: local.thumbnailUrl,
      hlsUrl: local.localFilePath ?? local.hlsUrl,
      dashUrl: local.dashUrl,
      author: PostAuthorDto(
        id: local.creatorId ?? '',
        username: local.creatorName ?? 'Author',
        displayName: local.creatorName,
        avatarUrl: local.creatorAvatar,
      ),
      createdAt: local.createdAt ?? DateTime.now(),
      updatedAt: local.updatedAt ?? DateTime.now(),
    );
  }

  String _parseDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'] ?? data['error'];
      if (msg is String) return msg;
      if (msg is List) return (msg).join(', ');
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout => 'Connection timed out.',
      DioExceptionType.connectionError => 'Could not connect to the server.',
      _ => 'Failed to load video: ${e.message ?? 'Unknown error'}',
    };
  }

  Future<VideoListResponseDto> getRecommended(String videoId) async {
    final isOnline = _ref.read(connectivityProvider).isOnline;
    if (!isOnline) {
      return const VideoListResponseDto(
        data: [],
        meta: FeedMetaDto(total: 0, page: 1, limit: 10, totalPages: 0),
      );
    }

    try {
      final response = await _dio.get(
        '/videos/$videoId/recommended',
        queryParameters: {'limit': 10},
      );
      final data = parsePaginatedEnvelope(response.data);
      return VideoListResponseDto.fromJson(data);
    } catch (_) {
      return const VideoListResponseDto(
        data: [],
        meta: FeedMetaDto(total: 0, page: 1, limit: 10, totalPages: 0),
      );
    }
  }

  /// Gets the local watch position in seconds
  Future<int> getLastPlayedPosition(String videoId) async {
    try {
      final local = await _db.videosDao.getVideoById(videoId);
      if (local != null && local.lastPlayedPosition > 0) {
        return local.lastPlayedPosition;
      }

      final userId = _ref.read(authProvider).user?.id ?? 'anonymous';
      final history = await _db.watchHistoryDao.getVideoHistory(userId, videoId);
      return history?.positionSeconds ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Saves watch progress locally immediately (throttled to 5s) and syncs to backend
  Future<void> saveProgress(
    String videoId,
    int watchedSeconds, {
    int durationSeconds = 0,
    bool force = false,
  }) async {
    final now = DateTime.now();

    // Throttling: only write if at least 5s has elapsed or force is true
    if (!force) {
      final lastTime = _lastSaveTime[videoId];
      if (lastTime != null && now.difference(lastTime) < _throttleInterval) {
        return;
      }
    }
    _lastSaveTime[videoId] = now;

    try {
      // 1. Immediately persist local watch position in SQLite
      await _db.videosDao.updateLastPlayed(videoId, watchedSeconds);

      final userId = _ref.read(authProvider).user?.id ?? 'anonymous';
      final historyId = '${userId}_$videoId';
      final isOnline = _ref.read(connectivityProvider).isOnline;

      final progressRatio = durationSeconds > 0
          ? (watchedSeconds / durationSeconds).clamp(0.0, 1.0)
          : 0.0;

      await _db.watchHistoryDao.upsertWatchHistory(
        LocalWatchHistoryCompanion(
          id: drift.Value(historyId),
          videoId: drift.Value(videoId),
          userId: drift.Value(userId),
          positionSeconds: drift.Value(watchedSeconds),
          durationSeconds: drift.Value(durationSeconds),
          progress: drift.Value(progressRatio),
          watchedAt: drift.Value(now),
          completed: drift.Value(progressRatio >= 0.95),
          synced: drift.Value(isOnline),
        ),
      );

      // 2. Synchronize to server or enqueue in sync queue
      if (isOnline) {
        try {
          await _dio.patch(
            '/videos/$videoId/progress',
            data: {'watchedSeconds': watchedSeconds},
          );
        } catch (_) {
          // If remote call failed, enqueue in persistent sync queue
          await _enqueueWatchHistorySync(historyId, videoId, watchedSeconds, now);
        }
      } else {
        await _enqueueWatchHistorySync(historyId, videoId, watchedSeconds, now);
      }
    } catch (e) {
      debugPrint('[PlayerRepo] saveProgress error: $e');
    }
  }

  Future<void> _enqueueWatchHistorySync(
    String historyId,
    String videoId,
    int watchedSeconds,
    DateTime now,
  ) async {
    await _db.syncQueueDao.enqueue(
      SyncQueueCompanion(
        id: drift.Value(const Uuid().v4()),
        operationType: const drift.Value('UPDATE_WATCH_HISTORY'),
        entityType: const drift.Value('WATCH_HISTORY'),
        entityId: drift.Value(historyId),
        payload: drift.Value(
          jsonEncode({
            'videoId': videoId,
            'watchedSeconds': watchedSeconds,
          }),
        ),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
        status: const drift.Value('pending'),
      ),
    );
  }
}
