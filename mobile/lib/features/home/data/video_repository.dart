// lib/features/home/data/video_repository.dart
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/home/domain/feed_response.dart';
import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/features/home/domain/video_model.dart';

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return VideoRepository(dio, db, ref);
});

class VideoRepository {
  final Dio _dio;
  final AppDatabase _db;
  final Ref _ref;

  VideoRepository(this._dio, this._db, this._ref);

  Future<VideoListResponseDto> getLatestVideos({
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final isOnline = _ref.read(connectivityProvider).isOnline;

    if (isOnline) {
      try {
        final response = await _dio.get(
          '/videos/latest',
          queryParameters: {'page': page, 'limit': limit},
          cancelToken: cancelToken,
        );
        final data = parsePaginatedEnvelope(response.data);
        final listResponse = VideoListResponseDto.fromJson(data);

        // Cache first page for offline viewing
        if (page == 1 && listResponse.data.isNotEmpty) {
          final now = DateTime.now();
          final feedCompanions = listResponse.data.map((v) {
            return LocalFeedItemsCompanion(
              id: drift.Value(v.id),
              feedType: const drift.Value('LATEST'),
              title: drift.Value(v.title),
              caption: drift.Value(v.description),
              thumbnailUrl: drift.Value(v.thumbnailUrl),
              videoUrl: drift.Value(v.hlsUrl),
              hlsUrl: drift.Value(v.hlsUrl),
              duration: drift.Value(v.duration),
              authorId: drift.Value(v.uploadedById ?? v.author.id),
              authorUsername: drift.Value(v.author.username),
              authorDisplayName: drift.Value(v.author.displayName ?? v.author.username),
              authorAvatarUrl: drift.Value(v.author.avatarUrl),
              viewsCount: drift.Value(v.viewsCount),
              likesCount: drift.Value(v.likesCount),
              commentsCount: drift.Value(v.commentsCount),
              publishedAt: drift.Value(v.publishedAt),
              createdAt: drift.Value(v.createdAt),
              cachedAt: drift.Value(now),
            );
          }).toList();
          await _db.feedDao.upsertFeedItems(feedCompanions);
        }

        return listResponse;
      } catch (e) {
        debugPrint('[VideoRepo] Remote getLatestVideos error: $e, falling back to cache');
      }
    }

    // Offline cache fallback
    final cached = await _db.feedDao.getFeedItems(feedType: 'LATEST', limit: limit);
    if (cached.isNotEmpty) {
      final videos = cached.map(_feedItemToVideo).toList();
      return VideoListResponseDto(
        data: videos,
        meta: FeedMetaDto(
          total: videos.length,
          page: 1,
          limit: limit,
          totalPages: 1,
        ),
      );
    }

    return const VideoListResponseDto(
      data: [],
      meta: FeedMetaDto(total: 0, page: 1, limit: 20, totalPages: 0),
    );
  }

  Future<VideoListResponseDto> getTrending({
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final isOnline = _ref.read(connectivityProvider).isOnline;

    if (isOnline) {
      try {
        final response = await _dio.get(
          '/videos/trending',
          queryParameters: {'page': page, 'limit': limit},
          cancelToken: cancelToken,
        );
        final data = parsePaginatedEnvelope(response.data);
        final listResponse = VideoListResponseDto.fromJson(data);

        if (page == 1 && listResponse.data.isNotEmpty) {
          final now = DateTime.now();
          final feedCompanions = listResponse.data.map((v) {
            return LocalFeedItemsCompanion(
              id: drift.Value(v.id),
              feedType: const drift.Value('TRENDING'),
              title: drift.Value(v.title),
              caption: drift.Value(v.description),
              thumbnailUrl: drift.Value(v.thumbnailUrl),
              videoUrl: drift.Value(v.hlsUrl),
              hlsUrl: drift.Value(v.hlsUrl),
              duration: drift.Value(v.duration),
              authorId: drift.Value(v.uploadedById ?? v.author.id),
              authorUsername: drift.Value(v.author.username),
              authorDisplayName: drift.Value(v.author.displayName ?? v.author.username),
              authorAvatarUrl: drift.Value(v.author.avatarUrl),
              viewsCount: drift.Value(v.viewsCount),
              likesCount: drift.Value(v.likesCount),
              commentsCount: drift.Value(v.commentsCount),
              publishedAt: drift.Value(v.publishedAt),
              createdAt: drift.Value(v.createdAt),
              cachedAt: drift.Value(now),
            );
          }).toList();
          await _db.feedDao.upsertFeedItems(feedCompanions);
        }

        return listResponse;
      } catch (e) {
        debugPrint('[VideoRepo] Remote getTrending error: $e, falling back to cache');
      }
    }

    final cached = await _db.feedDao.getFeedItems(feedType: 'TRENDING', limit: limit);
    if (cached.isNotEmpty) {
      final videos = cached.map(_feedItemToVideo).toList();
      return VideoListResponseDto(
        data: videos,
        meta: FeedMetaDto(
          total: videos.length,
          page: 1,
          limit: limit,
          totalPages: 1,
        ),
      );
    }

    return const VideoListResponseDto(
      data: [],
      meta: FeedMetaDto(total: 0, page: 1, limit: 20, totalPages: 0),
    );
  }

  Future<VideoListResponseDto> searchVideos({
    String? search,
    String? category,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    // Record search query in local history
    if (search != null && search.trim().isNotEmpty) {
      final userId = _ref.read(authProvider).user?.id;
      await _db.searchHistoryDao.addSearchQuery(
        search.trim(),
        category: category,
        userId: userId,
      );
    }

    final isOnline = _ref.read(connectivityProvider).isOnline;

    if (isOnline) {
      try {
        final response = await _dio.get(
          '/videos/search',
          queryParameters: {
            if (search != null && search.isNotEmpty) 'search': search,
            if (category != null && category.isNotEmpty) 'category': category,
            'page': page,
            'limit': limit,
          },
          cancelToken: cancelToken,
        );
        final data = parsePaginatedEnvelope(response.data);
        return VideoListResponseDto.fromJson(data);
      } catch (e) {
        debugPrint('[VideoRepo] Remote search error: $e, falling back to offline search');
      }
    }

    // Offline search through downloaded & cached videos
    final allCached = await _db.videosDao.getAllCachedVideos();
    final query = (search ?? '').toLowerCase();
    final filtered = allCached.where((v) {
      return v.title.toLowerCase().contains(query) ||
          (v.description != null && v.description!.toLowerCase().contains(query));
    }).toList();

    final mapped = filtered.map((v) {
      return VideoResponseDto(
        id: v.id,
        title: v.title,
        description: v.description,
        status: VideoStatus.ready,
        visibility: 'PUBLIC',
        duration: v.duration,
        thumbnailUrl: v.thumbnailUrl,
        hlsUrl: v.localFilePath ?? v.hlsUrl,
        dashUrl: v.dashUrl,
        author: PostAuthorDto(
          id: v.creatorId ?? '',
          username: v.creatorName ?? 'Author',
          displayName: v.creatorName,
          avatarUrl: v.creatorAvatar,
        ),
        createdAt: v.createdAt ?? DateTime.now(),
        updatedAt: v.updatedAt ?? DateTime.now(),
      );
    }).toList();

    return VideoListResponseDto(
      data: mapped,
      meta: FeedMetaDto(
        total: mapped.length,
        page: 1,
        limit: limit,
        totalPages: 1,
      ),
    );
  }

  Future<VideoListResponseDto> getWatchHistory({
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final isOnline = _ref.read(connectivityProvider).isOnline;

    if (isOnline) {
      try {
        final response = await _dio.get(
          '/videos/watch-history',
          queryParameters: {'page': page, 'limit': limit},
          cancelToken: cancelToken,
        );
        final data = parsePaginatedEnvelope(response.data);
        return VideoListResponseDto.fromJson(data);
      } catch (_) {}
    }

    // Offline fallback from local watch history
    final userId = _ref.read(authProvider).user?.id ?? 'anonymous';
    final historyEntries = await _db.watchHistoryDao.getWatchHistory(userId, limit: limit);

    final List<VideoResponseDto> videos = [];
    for (final entry in historyEntries) {
      final v = await _db.videosDao.getVideoById(entry.videoId);
      if (v != null) {
        videos.add(
          VideoResponseDto(
            id: v.id,
            title: v.title,
            description: v.description,
            status: VideoStatus.ready,
            visibility: 'PUBLIC',
            duration: v.duration,
            thumbnailUrl: v.thumbnailUrl,
            hlsUrl: v.localFilePath ?? v.hlsUrl,
            dashUrl: v.dashUrl,
            author: PostAuthorDto(
              id: v.creatorId ?? '',
              username: v.creatorName ?? 'Author',
              displayName: v.creatorName,
              avatarUrl: v.creatorAvatar,
            ),
            createdAt: v.createdAt ?? DateTime.now(),
            updatedAt: v.updatedAt ?? DateTime.now(),
          ),
        );
      }
    }

    return VideoListResponseDto(
      data: videos,
      meta: FeedMetaDto(total: videos.length, page: 1, limit: limit, totalPages: 1),
    );
  }

  Future<VideoListResponseDto> getBookmarks({
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/videos/bookmarks',
      queryParameters: {'page': page, 'limit': limit},
      cancelToken: cancelToken,
    );
    final data = parsePaginatedEnvelope(response.data);
    return VideoListResponseDto.fromJson(data);
  }

  Future<VideoListResponseDto> getLikedVideos({
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/videos/liked',
      queryParameters: {'page': page, 'limit': limit},
      cancelToken: cancelToken,
    );
    final data = parsePaginatedEnvelope(response.data);
    return VideoListResponseDto.fromJson(data);
  }

  Future<VideoListResponseDto> getUserVideos({
    required String userId,
    int page = 1,
    int limit = 20,
    bool? isStream,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/videos',
      queryParameters: {
        'authorId': userId,
        'page': page,
        'limit': limit,
        if (isStream != null) 'isStream': isStream.toString(),
      },
      cancelToken: cancelToken,
    );
    final data = parsePaginatedEnvelope(response.data);
    return VideoListResponseDto.fromJson(data);
  }

  Future<VideoListResponseDto> getUserStreams({
    required String userId,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    return getUserVideos(
      userId: userId,
      page: page,
      limit: limit,
      isStream: true,
      cancelToken: cancelToken,
    );
  }

  Future<void> deleteVideo(String videoId, {String? channelId}) async {
    if (channelId != null && channelId.isNotEmpty) {
      await _dio.delete('/video-channels/$channelId/videos/$videoId');
    } else {
      await _dio.delete('/videos/$videoId');
    }
  }

  Future<void> removeFromWatchHistory(String videoId) async {
    await _dio.delete('/videos/watch-history/$videoId');
    final userId = _ref.read(authProvider).user?.id ?? 'anonymous';
    final historyId = '${userId}_$videoId';
    await _db.watchHistoryDao.deleteHistoryItem(historyId);
  }

  Future<void> clearWatchHistory() async {
    await _dio.delete('/videos/watch-history');
    final userId = _ref.read(authProvider).user?.id ?? 'anonymous';
    await _db.watchHistoryDao.clearUserHistory(userId);
  }

  VideoResponseDto _feedItemToVideo(LocalFeedItemData d) {
    return VideoResponseDto(
      id: d.id,
      title: d.title,
      description: d.caption,
      status: VideoStatus.ready,
      visibility: 'PUBLIC',
      duration: d.duration,
      thumbnailUrl: d.thumbnailUrl,
      hlsUrl: d.hlsUrl ?? d.videoUrl,
      viewsCount: d.viewsCount,
      likesCount: d.likesCount,
      commentsCount: d.commentsCount,
      author: PostAuthorDto(
        id: d.authorId ?? '',
        username: d.authorUsername ?? 'Author',
        displayName: d.authorDisplayName,
        avatarUrl: d.authorAvatarUrl,
      ),
      publishedAt: d.publishedAt,
      createdAt: d.createdAt,
      updatedAt: d.cachedAt,
    );
  }
}
