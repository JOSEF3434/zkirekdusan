// lib/features/home/data/feed_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/home/domain/feed_response.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.watch(apiClientProvider));
});

class FeedRepository {
  final Dio _dio;

  FeedRepository(this._dio);

  Future<FeedResponseDto> getFeed({
    int page = 1,
    int limit = 20,
    String? authorId,
    String? groupId,
    String? hashtag,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/posts',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (authorId != null) 'authorId': authorId,
        if (groupId != null) 'groupId': groupId,
        if (hashtag != null) 'hashtag': hashtag,
      },
      cancelToken: cancelToken,
    );

    final data = parsePaginatedEnvelope(response.data);
    return FeedResponseDto.fromJson(data);
  }

  Future<FeedResponseDto> getRecommendations({
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/recommendations/home',
      queryParameters: {'page': page, 'limit': limit},
      cancelToken: cancelToken,
    );
    final data = parsePaginatedEnvelope(response.data);
    return FeedResponseDto.fromJson(data);
  }
}
