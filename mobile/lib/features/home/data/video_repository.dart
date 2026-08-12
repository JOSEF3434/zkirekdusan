// lib/features/home/data/video_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/home/domain/video_model.dart';

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  return VideoRepository(ref.watch(apiClientProvider));
});

class VideoRepository {
  final Dio _dio;

  VideoRepository(this._dio);

  Future<VideoListResponseDto> getTrending({
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/videos/trending',
      queryParameters: {'page': page, 'limit': limit},
      cancelToken: cancelToken,
    );
    final data = parsePaginatedEnvelope(response.data);
    return VideoListResponseDto.fromJson(data);
  }

  Future<VideoListResponseDto> searchVideos({
    String? search,
    String? category,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/videos/search',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
        'page': page,
        'limit': limit,
      },
      cancelToken: cancelToken,
    );
    final data = parsePaginatedEnvelope(response.data);
    return VideoListResponseDto.fromJson(data);
  }

  Future<VideoListResponseDto> getWatchHistory({
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/videos/watch-history',
      queryParameters: {'page': page, 'limit': limit},
      cancelToken: cancelToken,
    );
    final data = parsePaginatedEnvelope(response.data);
    return VideoListResponseDto.fromJson(data);
  }

  Future<VideoListResponseDto> getBookmarks({
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/videos/bookmarks',
      queryParameters: {'page': page, 'limit': limit},
      cancelToken: cancelToken,
    );
    final data = parsePaginatedEnvelope(response.data);
    return VideoListResponseDto.fromJson(data);
  }
}
