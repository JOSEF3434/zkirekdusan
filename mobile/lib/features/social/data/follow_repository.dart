import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/social/domain/follow_model.dart';
import 'package:mobile/features/social/domain/owned_channel_model.dart';
import 'package:mobile/features/social/data/social_repository.dart';
import 'package:mobile/features/home/domain/feed_response.dart';

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository(ref.read(apiClientProvider));
});

class FollowRepository {
  final Dio _dio;

  FollowRepository(this._dio);

  Future<void> followUser(String userId) async {
    final response = await _dio.post('/users/$userId/follow');
    parseEnvelope(response.data);
  }

  Future<void> unfollowUser(String userId) async {
    final response = await _dio.delete('/users/$userId/follow');
    parseEnvelope(response.data);
  }

  Future<FollowStatusDto> getFollowStatus(String userId) async {
    final response = await _dio.get('/users/$userId/follow-status');
    final data = parseEnvelope(response.data);
    return FollowStatusDto.fromJson(data);
  }

  Future<PaginatedResponse<FollowerDto>> getFollowers(
    String userId, {
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/users/$userId/followers',
      queryParameters: {'page': page, 'limit': limit},
      cancelToken: cancelToken,
    );
    final dataMap = parsePaginatedEnvelope(response.data);
    final items =
        (dataMap['data'] as List?)
            ?.map((e) => FollowerDto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final meta = FeedMetaDto.fromJson(dataMap['meta'] as Map<String, dynamic>);
    return PaginatedResponse(data: items, meta: meta);
  }

  Future<PaginatedResponse<FollowerDto>> getFollowing(
    String userId, {
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/users/$userId/following',
      queryParameters: {'page': page, 'limit': limit},
      cancelToken: cancelToken,
    );
    final dataMap = parsePaginatedEnvelope(response.data);
    final items =
        (dataMap['data'] as List?)
            ?.map((e) => FollowerDto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final meta = FeedMetaDto.fromJson(dataMap['meta'] as Map<String, dynamic>);
    return PaginatedResponse(data: items, meta: meta);
  }

  /// Fetches suggested/popular video channels from the backend.
  /// Uses GET /video-channels with sorting by subscriber count.
  Future<List<SuggestedChannelDto>> getSuggestedChannels({
    int page = 1,
    int limit = 30,
    String sortBy = 'subscribersCount',
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/video-channels',
      queryParameters: {
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'order': 'DESC',
      },
      cancelToken: cancelToken,
    );
    // Backend may return envelope or direct list
    dynamic raw;
    try {
      raw = parseEnvelope(response.data);
    } catch (_) {
      raw = response.data;
    }

    List<dynamic> list = [];
    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      list =
          (raw['data'] as List?) ??
          (raw['channels'] as List?) ??
          (raw['items'] as List?) ??
          [];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => SuggestedChannelDto.fromJson(e))
        .toList();
  }

  Future<List<OwnedChannelModel>> getMyOwnedChannels({
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/video-channels/my',
      cancelToken: cancelToken,
    );
    final list = parseEnvelopeList(response.data);
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => OwnedChannelModel.fromJson(e))
        .toList();
  }

  /// Fetches the list of video channels the current user has subscribed to.
  /// Tries GET /video-subscriptions first, then GET /video-channels/subscribed
  /// as a fallback, normalising both response shapes.
  Future<List<SuggestedChannelDto>> getMySubscribedChannels({
    int page = 1,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    // Try primary endpoint: GET /video-subscriptions
    try {
      final response = await _dio.get(
        '/video-subscriptions',
        queryParameters: {'page': page, 'limit': limit},
        cancelToken: cancelToken,
      );
      return _parseChannelList(response.data);
    } catch (_) {}

    // Fallback endpoint: GET /video-channels/subscribed
    try {
      final response = await _dio.get(
        '/video-channels/subscribed',
        queryParameters: {'page': page, 'limit': limit},
        cancelToken: cancelToken,
      );
      return _parseChannelList(response.data);
    } catch (_) {}

    return [];
  }

  /// Normalises various API response shapes into a list of [SuggestedChannelDto].
  List<SuggestedChannelDto> _parseChannelList(dynamic raw) {
    List<dynamic> list = [];
    if (raw is Map) {
      // { success, data: [...] }  or  { data: [...], meta: {...} }
      final inner = raw['data'];
      if (inner is List) {
        list = inner;
      } else if (inner is Map) {
        // { data: { data: [...] } }
        final nested = inner['data'];
        if (nested is List) list = nested;
      } else if (raw['channels'] is List) {
        list = raw['channels'] as List;
      } else if (raw['items'] is List) {
        list = raw['items'] as List;
      }
    } else if (raw is List) {
      list = raw;
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map((item) {
          // Some endpoints nest the channel under a 'channel' key
          final ch = (item['channel'] as Map<String, dynamic>?) ?? item;
          return SuggestedChannelDto.fromJson(ch);
        })
        .where((ch) => ch.id.isNotEmpty)
        .toList();
  }
}

/// Lightweight model for a suggested/popular video channel.
class SuggestedChannelDto {
  final String id;
  final String? name;
  final String? description;
  final String? avatarUrl;
  final String? ownerUsername;
  final int subscribersCount;
  final int videosCount;
  final bool isSubscribed;

  const SuggestedChannelDto({
    required this.id,
    this.name,
    this.description,
    this.avatarUrl,
    this.ownerUsername,
    this.subscribersCount = 0,
    this.videosCount = 0,
    this.isSubscribed = false,
  });

  factory SuggestedChannelDto.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    final createdBy = json['createdBy'] as Map<String, dynamic>?;
    return SuggestedChannelDto(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String?,
      description: json['description'] as String?,
      avatarUrl: (json['avatarUrl'] ?? json['avatar']) as String?,
      ownerUsername:
          (owner?['username'] ?? createdBy?['username']) as String?,
      subscribersCount:
          (json['subscribersCount'] ?? json['subscribers'] ?? 0) as int,
      videosCount: (json['videosCount'] ?? json['videoCount'] ?? 0) as int,
      isSubscribed: json['isSubscribed'] as bool? ?? false,
    );
  }
}
