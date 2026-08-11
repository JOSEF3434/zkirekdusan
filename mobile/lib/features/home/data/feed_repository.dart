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
        'authorId': ?authorId,
        'groupId': ?groupId,
        'hashtag': ?hashtag,
      },
      cancelToken: cancelToken,
    );

    return FeedResponseDto.fromJson(response.data);
  }
}
