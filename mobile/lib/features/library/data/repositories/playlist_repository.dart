import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/library/domain/playlist_dto.dart';

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return PlaylistRepository(dio);
});

class PlaylistRepository {
  final Dio _dio;

  PlaylistRepository(this._dio);

  Future<List<PlaylistDto>> getMyPlaylists({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/video-playlists',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data['data'] as List;
      return data
          .map((json) => PlaylistDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load playlists');
    }
  }

  Future<PlaylistDto> createPlaylist({
    required String title,
    String? description,
    String privacy = 'private',
  }) async {
    try {
      final response = await _dio.post(
        '/video-playlists',
        data: {'title': title, 'description': description, 'privacy': privacy},
      );
      return PlaylistDto.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to create playlist');
    }
  }

  Future<void> addVideoToPlaylist(String playlistId, String videoId) async {
    try {
      await _dio.post(
        '/video-playlists/$playlistId/items',
        data: {'videoId': videoId},
      );
    } catch (e) {
      throw Exception('Failed to add video to playlist');
    }
  }
}
