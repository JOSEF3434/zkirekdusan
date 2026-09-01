// lib/features/groups/data/group_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/groups/domain/group_context_dto.dart';
import 'package:mobile/features/groups/domain/group_member_dto.dart';
import 'package:mobile/features/groups/domain/channel_video_dto.dart';
import 'package:mobile/features/groups/domain/channel_playlist_dto.dart';
import 'package:mobile/features/groups/domain/group_enums.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(ref.watch(apiClientProvider));
});

// ---------------------------------------------------------------------------
// Pagination result containers
// ---------------------------------------------------------------------------

class PaginatedVideos {
  final List<ChannelVideoDto> items;
  final bool hasMore;
  final String? nextCursor;
  final int total;
  PaginatedVideos({
    required this.items,
    required this.hasMore,
    this.nextCursor,
    required this.total,
  });
}

class PaginatedPlaylists {
  final List<ChannelPlaylistDto> items;
  final bool hasNext;
  final int total;
  final int page;
  PaginatedPlaylists({
    required this.items,
    required this.hasNext,
    required this.total,
    required this.page,
  });
}

class PaginatedMembers {
  final List<GroupMemberDto> items;
  final bool hasNext;
  final int total;
  final int page;
  PaginatedMembers({
    required this.items,
    required this.hasNext,
    required this.total,
    required this.page,
  });
}

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class GroupRepository {
  final Dio _dio;

  GroupRepository(this._dio);

  // ── Group Context ──────────────────────────────────────────────────────────

  /// Returns the full group context: metadata, video channels, caller
  /// capabilities. Uses the backend's deterministic channel resolution
  /// (oldest active channel = default).
  Future<GroupContextDto> getGroupContext(String groupId) async {
    try {
      final response = await _dio.get('/groups/$groupId/context');
      final data = parseEnvelope(response.data);
      return GroupContextDto.fromJson(data);
    } on DioException catch (e) {
      throw Failure.fromException(e);
    }
  }

  // ── Channel Videos ────────────────────────────────────────────────────────

  /// Fetches a page of videos for [channelId] using cursor-based pagination.
  /// Videos are sorted newest-first (server-side, stable secondary sort on id).
  Future<PaginatedVideos> getChannelVideos(
    String channelId, {
    String? cursor,
    int limit = 20,
    String? statusFilter,
  }) async {
    try {
      final response = await _dio.get(
        '/video-channels/$channelId/videos',
        queryParameters: {
          'limit': limit,
          if (cursor != null) 'cursor': cursor,
          if (statusFilter != null) 'status': statusFilter,
        },
      );
      final envelope = parseEnvelope(response.data);
      // Backend returns: { data: [...], nextCursor, hasMore, total }
      final rawList = (envelope['data'] as List?) ?? [];
      final items = rawList
          .map(
            (e) =>
                ChannelVideoDto.fromJson(_mapVideo(e as Map<String, dynamic>)),
          )
          .toList();
      return PaginatedVideos(
        items: items,
        hasMore: envelope['hasMore'] as bool? ?? false,
        nextCursor: envelope['nextCursor'] as String?,
        total: envelope['total'] as int? ?? items.length,
      );
    } on DioException catch (e) {
      throw Failure.fromException(e);
    }
  }

  // ── Channel Playlists ─────────────────────────────────────────────────────

  Future<PaginatedPlaylists> getChannelPlaylists(
    String channelId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/video-channels/$channelId/playlists',
        queryParameters: {'page': page, 'limit': limit},
      );
      final envelope = parseEnvelope(response.data);
      final rawList = (envelope['data'] as List?) ?? [];
      final items = rawList
          .map((e) => _parsePlaylist(e as Map<String, dynamic>))
          .toList();
      final meta = (envelope['meta'] as Map<String, dynamic>?) ?? {};
      final hasNext = meta['hasNext'] as bool? ?? (items.length == limit);
      return PaginatedPlaylists(
        items: items,
        hasNext: hasNext,
        total: meta['total'] as int? ?? items.length,
        page: page,
      );
    } on DioException catch (e) {
      throw Failure.fromException(e);
    }
  }

  // ── Playlist Detail ───────────────────────────────────────────────────────

  Future<ChannelPlaylistDto> getPlaylistDetail(String playlistId) async {
    try {
      final response = await _dio.get('/video-playlists/$playlistId');
      final data = parseEnvelope(response.data);
      return _parsePlaylist(data);
    } on DioException catch (e) {
      throw Failure.fromException(e);
    }
  }

  Future<ChannelPlaylistDto> createPlaylist({
    required String title,
    String? description,
    String? videoChannelId,
    String visibility = 'PUBLIC',
  }) async {
    try {
      final response = await _dio.post(
        '/video-playlists',
        data: {
          'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (videoChannelId != null) 'videoChannelId': videoChannelId,
          'visibility': visibility,
        },
      );
      final data = parseEnvelope(response.data);
      return _parsePlaylist(data);
    } on DioException catch (e) {
      throw Failure.fromException(e);
    }
  }

  Future<void> addVideoToPlaylist(String playlistId, String videoId) async {
    try {
      await _dio.post(
        '/video-playlists/$playlistId/items',
        data: {'videoId': videoId},
      );
    } on DioException catch (e) {
      throw Failure.fromException(e);
    }
  }

  Future<void> removeVideoFromPlaylist(
    String playlistId,
    String videoId,
  ) async {
    try {
      await _dio.delete('/video-playlists/$playlistId/items/$videoId');
    } on DioException catch (e) {
      throw Failure.fromException(e);
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _dio.delete('/video-playlists/$playlistId');
    } on DioException catch (e) {
      throw Failure.fromException(e);
    }
  }

  // ── Group Members ─────────────────────────────────────────────────────────

  Future<PaginatedMembers> getGroupMembers(
    String groupId, {
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final response = await _dio.get(
        '/groups/$groupId/members',
        queryParameters: {'page': page, 'limit': limit},
      );
      final envelope = parseEnvelope(response.data);
      final rawList = (envelope['data'] as List?) ?? [];
      final items = rawList
          .map((e) => GroupMemberDto.fromJson(e as Map<String, dynamic>))
          .toList();
      final meta = (envelope['meta'] as Map<String, dynamic>?) ?? {};
      return PaginatedMembers(
        items: items,
        hasNext: meta['hasNext'] as bool? ?? false,
        total: meta['total'] as int? ?? items.length,
        page: page,
      );
    } on DioException catch (e) {
      throw Failure.fromException(e);
    }
  }

  Future<void> updateMemberRole(
    String groupId,
    String userId,
    GroupRole newRole,
  ) async {
    try {
      await _dio.patch(
        '/groups/$groupId/members/$userId/role',
        data: {'role': newRole.name.toUpperCase()},
      );
    } on DioException catch (e) {
      throw Failure.fromException(e);
    }
  }

  Future<void> removeMember(String groupId, String userId) async {
    try {
      await _dio.delete('/groups/$groupId/members/$userId');
    } on DioException catch (e) {
      throw Failure.fromException(e);
    }
  }

  // ── Group Settings ────────────────────────────────────────────────────────

  Future<void> updateGroup(
    String groupId, {
    String? name,
    String? description,
    String? visibility,
    String? website,
    String? country,
  }) async {
    try {
      await _dio.patch(
        '/groups/$groupId',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (visibility != null) 'visibility': visibility,
          if (website != null) 'website': website,
          if (country != null) 'country': country,
        },
      );
    } on DioException catch (e) {
      throw Failure.fromException(e);
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await _dio.delete('/groups/$groupId');
    } on DioException catch (e) {
      throw Failure.fromException(e);
    }
  }

  Future<void> repairGroup(String groupId) async {
    try {
      await _dio.post('/groups/$groupId/repair');
    } on DioException catch (e) {
      throw Failure.fromException(e);
    }
  }

  // ── Channel Subscription ──────────────────────────────────────────────────

  Future<void> subscribeToChannel(String groupId, String channelId) async {
    try {
      await _dio.post('/groups/$groupId/video-channels/$channelId/subscribe');
    } on DioException catch (e) {
      throw Failure.fromException(e);
    }
  }

  Future<void> unsubscribeFromChannel(String groupId, String channelId) async {
    try {
      await _dio.delete('/groups/$groupId/video-channels/$channelId/subscribe');
    } on DioException catch (e) {
      throw Failure.fromException(e);
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Normalise the nested videoChannel and uploadedBy shapes that the backend
  /// VIDEO_INCLUDE produces into a flat map compatible with ChannelVideoDto.
  Map<String, dynamic> _mapVideo(Map<String, dynamic> raw) {
    final channel = raw['videoChannel'] as Map<String, dynamic>?;
    final uploader = raw['uploadedBy'] as Map<String, dynamic>?;
    final uploaderProfile = uploader?['profile'] as Map<String, dynamic>?;
    return {
      ...raw,
      'videoChannelId': raw['videoChannelId'] ?? channel?['id'],
      'channelName': channel?['name'],
      'channelHandle': channel?['handle'],
      'groupId': channel?['groupId'],
      'uploadedById': raw['uploadedById'] ?? uploader?['id'],
      'uploaderUsername': uploader?['username'],
      'uploaderDisplayName': uploaderProfile?['displayName'],
      'viewsCount': raw['viewsCount'] ?? 0,
      'likesCount': raw['likesCount'] ?? 0,
      'commentsCount': raw['commentsCount'] ?? 0,
    };
  }

  ChannelPlaylistDto _parsePlaylist(Map<String, dynamic> raw) {
    final owner = raw['owner'] as Map<String, dynamic>?;
    final channel = raw['videoChannel'] as Map<String, dynamic>?;
    final rawItems = (raw['items'] as List?) ?? [];

    final items = rawItems.map((item) {
      final itemMap = item as Map<String, dynamic>;
      final video = itemMap['video'] as Map<String, dynamic>?;
      return ChannelPlaylistItemDto(
        id: itemMap['id'] as String,
        order: itemMap['order'] as int? ?? 0,
        videoId: itemMap['videoId'] as String? ?? video?['id'] as String? ?? '',
        videoTitle: video?['title'] as String?,
        videoSlug: video?['slug'] as String?,
        videoDuration: (video?['duration'] as num?)?.toDouble(),
        videoThumbnailUrl: video?['thumbnailUrl'] as String?,
        videoViewsCount: video?['viewsCount'] as int?,
      );
    }).toList()..sort((a, b) => a.order.compareTo(b.order));

    return ChannelPlaylistDto(
      id: raw['id'] as String,
      title: raw['title'] as String,
      description: raw['description'] as String?,
      visibility: raw['visibility'] as String? ?? 'PUBLIC',
      videosCount: raw['videosCount'] as int? ?? items.length,
      ownerId: raw['ownerId'] as String? ?? owner?['id'] as String? ?? '',
      ownerUsername: owner?['username'] as String?,
      videoChannelId:
          raw['videoChannelId'] as String? ?? channel?['id'] as String?,
      channelName: channel?['name'] as String?,
      items: items,
      createdAt: DateTime.parse(
        raw['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        raw['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
