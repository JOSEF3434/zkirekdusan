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
    final response = await _dio.get('/videos/$videoId');
    final data = parseEnvelope(response.data);
    return VideoResponseDto.fromJson(data);
  }

  Future<VideoListResponseDto> getRecommended(String videoId) async {
    final response = await _dio.get(
      '/videos/$videoId/recommended',
      queryParameters: {'limit': 10},
    );
    final data = parsePaginatedEnvelope(response.data);
    return VideoListResponseDto.fromJson(data);
  }

  Future<void> saveProgress(String videoId, int watchedSeconds) async {
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
