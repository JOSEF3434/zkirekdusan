// lib/features/upload/data/upload_repository.dart
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/upload/domain/group_channel_model.dart';
import 'package:mobile/features/upload/domain/upload_video_model.dart';

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  return UploadRepository(ref.watch(apiClientProvider));
});

class UploadRepository {
  final Dio _dio;

  UploadRepository(this._dio);

  Future<List<GroupDto>> getMyGroups() async {
    final response = await _dio.get('/groups/my-groups');
    final data = parseEnvelopeList(response.data);
    return data.map((json) => GroupDto.fromJson(json)).toList();
  }

  Future<List<VideoChannelDto>> getGroupChannels(String groupId) async {
    final response = await _dio.get('/groups/$groupId/video-channels');
    final data = parseEnvelopeList(response.data);
    return data.map((json) => VideoChannelDto.fromJson(json)).toList();
  }

  Future<UploadInitResponse> initiateUpload(UploadInitRequest request) async {
    final response = await _dio.post(
      '/video-channels/${request.channelId}/videos',
      data: request.toJson(),
    );
    final data = parseEnvelope(response.data);
    final videoId = (data['id'] ?? data['videoId']) as String;
    return UploadInitResponse(
      videoId: videoId,
      uploadUrl: '/video-channels/${request.channelId}/videos/$videoId/file',
    );
  }

  Future<void> uploadVideoFile({
    required String channelId,
    required String videoId,
    required XFile file,
    required CancelToken cancelToken,
    void Function(int sent, int total)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    final mimeType = _resolveVideoMimeType(ext);

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.name.isNotEmpty ? file.name : 'video.mp4',
        contentType: DioMediaType.parse(mimeType),
      ),
    });

    await _dio.post(
      '/video-channels/$channelId/videos/$videoId/file',
      data: formData,
      cancelToken: cancelToken,
      options: Options(
        sendTimeout: const Duration(minutes: 15),
        receiveTimeout: const Duration(minutes: 15),
      ),
      onSendProgress: onProgress,
    );
  }

  Future<void> uploadThumbnail({
    required String channelId,
    required String videoId,
    required XFile file,
  }) async {
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.name.isNotEmpty ? file.name : 'thumbnail.jpg',
        contentType: DioMediaType.parse(mimeType),
      ),
    });

    await _dio.post(
      '/video-channels/$channelId/videos/$videoId/thumbnail',
      data: formData,
      options: Options(
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
  }

  static String _resolveVideoMimeType(String ext) {
    switch (ext) {
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'mkv':
        return 'video/x-matroska';
      case 'avi':
        return 'video/x-msvideo';
      case '3gp':
        return 'video/3gpp';
      case 'mp4':
      default:
        return 'video/mp4';
    }
  }

  Future<VideoResponseDto> getStatus(
    String videoId, {
    String? channelId,
  }) async {
    final path = channelId != null
        ? '/video-channels/$channelId/videos/$videoId'
        : '/videos/$videoId/status';
    final response = await _dio.get(path);
    final data = parseEnvelope(response.data);
    return VideoResponseDto.fromJson(data);
  }
}
