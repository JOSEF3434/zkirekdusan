import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/explore/domain/search_model.dart';
import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/social/data/social_repository.dart';
import 'package:mobile/features/home/domain/feed_response.dart';

final exploreRepositoryProvider = Provider<ExploreRepository>((ref) {
  return ExploreRepository(ref.read(apiClientProvider));
});

class ExploreRepository {
  final Dio _dio;

  ExploreRepository(this._dio);

  Future<SearchResponseDto> search({
    String? query,
    SearchEntityType? type,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/search',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (type != null) 'type': type.name.toUpperCase(),
        'page': page,
        'limit': limit,
      },
      cancelToken: cancelToken,
    );
    final data = parseEnvelope(response.data);
    return SearchResponseDto.fromJson(data);
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
    final meta = FeedMetaDto.fromJson(dataMap['meta'] as Map<String, dynamic>);
    return PaginatedResponse(data: items, meta: meta);
  }

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
    final meta = FeedMetaDto.fromJson(dataMap['meta'] as Map<String, dynamic>);
    return PaginatedResponse(data: items, meta: meta);
  }
}
