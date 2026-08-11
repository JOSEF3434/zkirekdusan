// lib/features/player/data/player_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/home/domain/video_model.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return PlayerRepository(ref.watch(apiClientProvider));
});

class PlayerRepository {
  final Dio _dio;

  PlayerRepository(this._dio);

  Future<VideoResponseDto> getVideo(String videoId) async {
    // Because public discovery endpoints don't strictly require channelId in the URL 
    // for just fetching a video by ID, if we have a direct endpoint we use it.
    // If not, we might need to assume it's publicly accessible or use a workaround for F3.
    // Let's use the standard findById endpoint if it's exposed globally, or through a channel.
    // Assuming backend has /videos/:id for global lookup
    final response = await _dio.get('/videos/$videoId');
    return VideoResponseDto.fromJson(response.data);
  }

  Future<VideoListResponseDto> getRecommended(String videoId) async {
    final response = await _dio.get('/videos/$videoId/recommended', queryParameters: {'limit': 10});
    return VideoListResponseDto.fromJson(response.data);
  }

  Future<void> saveProgress(String videoId, int watchedSeconds) async {
    // Assuming there's a global progress endpoint or we just fire and forget
    try {
      await _dio.patch(
        '/videos/$videoId/progress',
        data: {'watchedSeconds': watchedSeconds},
      );
    } catch (_) {
      // Ignore background save errors
    }
  }
}
