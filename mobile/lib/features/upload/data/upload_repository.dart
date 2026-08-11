// lib/features/upload/data/upload_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/upload/domain/group_channel_model.dart';
import 'package:mobile/features/upload/domain/upload_video_model.dart';
import 'package:mobile/features/home/domain/video_model.dart';

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  return UploadRepository(ref.watch(apiClientProvider));
});

class UploadRepository {
  final Dio _dio;

  UploadRepository(this._dio);

  Future<List<GroupDto>> getMyGroups() async {
    // Note: Assuming /groups?memberOf=true returns groups the user is part of.
    // If not, it falls back to public groups for the sake of F3.
    final response = await _dio.get('/groups');
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => GroupDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<VideoChannelDto>> getGroupChannels(String groupId) async {
    final response = await _dio.get('/groups/$groupId/video-channels');
    final data = response.data as List<dynamic>? ?? [];
    return data.map((e) => VideoChannelDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<VideoResponseDto> initiateUpload(String channelId, UploadVideoFormData data) async {
    final response = await _dio.post(
      '/video-channels/$channelId/videos',
      data: data.toJson(),
    );
    return VideoResponseDto.fromJson(response.data);
  }

  Future<void> attachFile({
    required String channelId,
    required String videoId,
    required String filePath,
    required String fileName,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    await _dio.post(
      '/video-channels/$channelId/videos/$videoId/file',
      data: formData,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
      options: Options(
        // Typically timeout should be larger for big file uploads
        sendTimeout: const Duration(minutes: 30),
        receiveTimeout: const Duration(minutes: 30),
      ),
    );
  }

  Future<VideoResponseDto> getStatus(String channelId, String videoId) async {
    final response = await _dio.get('/video-channels/$channelId/videos/$videoId');
    return VideoResponseDto.fromJson(response.data);
  }
}
