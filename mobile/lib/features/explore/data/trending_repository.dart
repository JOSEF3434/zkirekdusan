// lib/features/explore/data/trending_repository.dart
// Dedicated trending repository — queries GET /trending/videos and GET /trending/posts.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/core/network/paginated_response.dart';
import 'package:mobile/features/home/domain/feed_response.dart';

final trendingRepositoryProvider = Provider<TrendingRepository>((ref) {
  return TrendingRepository(ref.read(apiClientProvider));
});

class TrendingRepository {
  final Dio _dio;

  TrendingRepository(this._dio);

  Future<PaginatedResponse<VideoResponseDto>> getTrendingVideos({
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/trending/videos',
      queryParameters: {'page': page, 'limit': limit},
      cancelToken: cancelToken,
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

  Future<PaginatedResponse<PostResponseDto>> getTrendingPosts({
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/trending/posts',
      queryParameters: {'page': page, 'limit': limit},
      cancelToken: cancelToken,
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
}
