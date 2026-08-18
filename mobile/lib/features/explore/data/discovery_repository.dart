// lib/features/explore/data/discovery_repository.dart
// Dedicated discovery repository for /explore, /recommendations/home, and /video-subscriptions/feed.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/explore/domain/explore_content_model.dart';
import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/features/home/domain/feed_response.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/core/network/paginated_response.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DiscoveryRepository(ref.read(apiClientProvider));
});

class DiscoveryRepository {
  final Dio _dio;

  DiscoveryRepository(this._dio);

  /// GET /explore — unified explore content from backend.
  Future<ExploreContentDto> getExploreContent() async {
    final response = await _dio.get('/explore');
    final data = parseEnvelope(response.data);
    return ExploreContentDto.fromJson(data);
  }

  /// GET /recommendations/home — personalised or popularity-ranked posts.
  /// NOTE: Backend returns Posts only. Trending videos are separate.
  Future<PaginatedResponse<PostResponseDto>> getHomeRecommendations({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/recommendations/home',
      queryParameters: {'page': page, 'limit': limit},
    );
    final dataMap = parsePaginatedEnvelope(response.data);
    final items =
        (dataMap['data'] as List?)
            ?.map((e) => PostResponseDto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final meta = FeedMetaDto.fromJson(
      dataMap['meta'] as Map<String, dynamic>? ?? {},
    );
    return PaginatedResponse(data: items, meta: meta);
  }

  /// GET /video-subscriptions/feed — latest videos from subscribed channels (auth required).
  Future<PaginatedResponse<VideoResponseDto>> getSubscriptionFeed({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/video-subscriptions/feed',
      queryParameters: {'page': page, 'limit': limit},
    );
    final dataMap = parsePaginatedEnvelope(response.data);
    final items =
        (dataMap['data'] as List?)
            ?.map((e) => VideoResponseDto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final meta = FeedMetaDto.fromJson(
      dataMap['meta'] as Map<String, dynamic>? ?? {},
    );
    return PaginatedResponse(data: items, meta: meta);
  }
}
