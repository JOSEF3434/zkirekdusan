// lib/features/library/data/repositories/playlist_repository.dart
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
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/video-playlists',
        queryParameters: {'page': page, 'limit': limit},
      );
      final rawData = response.data['data'] ?? response.data;
      if (rawData is List) {
        return rawData
            .map((json) => PlaylistDto.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load playlists: $e');
    }
  }

  Future<PlaylistDto> createPlaylist({
    required String title,
    String? description,
    String visibility = 'PUBLIC',
    String? videoChannelId,
  }) async {
    try {
      final response = await _dio.post(
        '/video-playlists',
        data: {
          'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          'visibility': visibility.toUpperCase(),
          'videoChannelId': ?videoChannelId,
        },
      );
      final raw = response.data['data'] ?? response.data;
      return PlaylistDto.fromJson(raw as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create playlist: $e');
    }
  }

  Future<void> addVideoToPlaylist(String playlistId, String videoId) async {
    try {
      await _dio.post(
        '/video-playlists/$playlistId/items',
        data: {'videoId': videoId},
      );
    } catch (e) {
      throw Exception('Failed to add video to playlist: $e');
    }
  }

  Future<void> removeVideoFromPlaylist(
    String playlistId,
    String videoId,
  ) async {
    try {
      await _dio.delete('/video-playlists/$playlistId/items/$videoId');
    } catch (e) {
      throw Exception('Failed to remove video from playlist: $e');
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _dio.delete('/video-playlists/$playlistId');
    } catch (e) {
      throw Exception('Failed to delete playlist: $e');
    }
  }

  Future<PlaylistDto> updatePlaylist(
    String playlistId, {
    String? title,
    String? description,
    String? visibility,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (visibility != null) data['visibility'] = visibility.toUpperCase();

      final response = await _dio.patch(
        '/video-playlists/$playlistId',
        data: data,
      );
      final raw = response.data['data'] ?? response.data;
      return PlaylistDto.fromJson(raw as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update playlist: $e');
    }
  }

  Future<PlaylistDto> getPlaylistDetails(String playlistId) async {
    try {
      final response = await _dio.get('/video-playlists/$playlistId');
      final raw = response.data['data'] ?? response.data;
      return PlaylistDto.fromJson(raw as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get playlist details: $e');
    }
  }
}
