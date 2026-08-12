import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/social/domain/follow_model.dart';
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
}
