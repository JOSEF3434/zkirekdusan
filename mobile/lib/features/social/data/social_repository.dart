import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/social/domain/comment_model.dart';
import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/features/home/domain/feed_response.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository(ref.read(apiClientProvider));
});

class SocialRepository {
  final Dio _dio;

  SocialRepository(this._dio);

  // --- LIKES ---
  Future<void> togglePostLike(String postId, {String reaction = 'LIKE'}) async {
    final response = await _dio.post(
      '/posts/$postId/like',
      data: {'reaction': reaction},
    );
    parseEnvelope(response.data);
  }

  Future<void> toggleReelLike(String reelId, {String reaction = 'LIKE'}) async {
    final response = await _dio.post(
      '/reels/$reelId/like',
      data: {'reaction': reaction},
    );
    parseEnvelope(response.data);
  }

  Future<void> toggleCommentLike(String commentId) async {
    final response = await _dio.post('/comments/$commentId/like');
    parseEnvelope(response.data);
  }

  // --- COMMENTS ---
  Future<CommentResponseDto> createComment(
    String postId,
    String content, {
    String? parentId,
  }) async {
    final response = await _dio.post(
      '/posts/$postId/comments',
      data: {'content': content, if (parentId != null) 'parentId': parentId},
    );
    final data = parseEnvelope(response.data);
    return CommentResponseDto.fromJson(data);
  }

  Future<PaginatedResponse<CommentResponseDto>> getComments(
    String postId, {
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/posts/$postId/comments',
      queryParameters: {'page': page, 'limit': limit},
      cancelToken: cancelToken,
    );
    final dataMap = parsePaginatedEnvelope(response.data);
    final items =
        (dataMap['data'] as List?)
            ?.map((e) => CommentResponseDto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final meta = FeedMetaDto.fromJson(dataMap['meta'] as Map<String, dynamic>);
    return PaginatedResponse(data: items, meta: meta);
  }

  Future<void> deleteComment(String commentId) async {
    final response = await _dio.delete('/comments/$commentId');
    parseEnvelope(response.data);
  }

  // --- BOOKMARKS ---
  Future<void> toggleSavePost(String postId) async {
    final response = await _dio.post('/posts/$postId/save');
    parseEnvelope(response.data);
  }

  Future<PaginatedResponse<PostResponseDto>> getSavedPosts({
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/posts/saved/my',
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
}

class PaginatedResponse<T> {
  final List<T> data;
  final FeedMetaDto meta;

  PaginatedResponse({required this.data, required this.meta});
}
