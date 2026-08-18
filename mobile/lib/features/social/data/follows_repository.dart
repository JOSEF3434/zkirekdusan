// lib/features/social/data/follows_repository.dart
// Dedicated follows repository — wraps all /users/:userId/follow* endpoints.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';

final followsRepositoryProvider = Provider<FollowsRepository>((ref) {
  return FollowsRepository(ref.read(apiClientProvider));
});

class FollowStatusDto {
  final bool isFollowing;
  final bool isFollowedBy;

  const FollowStatusDto({
    required this.isFollowing,
    required this.isFollowedBy,
  });

  factory FollowStatusDto.fromJson(Map<String, dynamic> json) {
    return FollowStatusDto(
      isFollowing: json['isFollowing'] as bool? ?? false,
      isFollowedBy: json['isFollowedBy'] as bool? ?? false,
    );
  }
}

class FollowsRepository {
  final Dio _dio;

  FollowsRepository(this._dio);

  /// POST /users/:userId/follow
  Future<void> followUser(String userId) async {
    await _dio.post('/users/$userId/follow');
  }

  /// DELETE /users/:userId/follow
  Future<void> unfollowUser(String userId) async {
    await _dio.delete('/users/$userId/follow');
  }

  /// GET /users/:userId/follow-status
  Future<FollowStatusDto> getFollowStatus(String userId) async {
    final response = await _dio.get('/users/$userId/follow-status');
    final raw = response.data;
    final Map<String, dynamic> data;
    if (raw is Map<String, dynamic> && raw.containsKey('success')) {
      data = (raw['data'] as Map<String, dynamic>?) ?? {};
    } else if (raw is Map<String, dynamic>) {
      data = raw;
    } else {
      data = {};
    }
    return FollowStatusDto.fromJson(data);
  }

  /// GET /users/:userId/followers
  Future<List<Map<String, dynamic>>> getFollowers(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/users/$userId/followers',
      queryParameters: {'page': page, 'limit': limit},
    );
    final list = parseEnvelopeList(response.data);
    return list.whereType<Map<String, dynamic>>().toList();
  }

  /// GET /users/:userId/following
  Future<List<Map<String, dynamic>>> getFollowing(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/users/$userId/following',
      queryParameters: {'page': page, 'limit': limit},
    );
    final list = parseEnvelopeList(response.data);
    return list.whereType<Map<String, dynamic>>().toList();
  }
}
