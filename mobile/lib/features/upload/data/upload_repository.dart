// lib/features/upload/data/upload_repository.dart
import 'dart:io';
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
    // Assuming backend returns {success: true, data: [ {id, name...} ]}
    final response = await _dio.get('/groups');
    final data = parseEnvelopeList(response.data);
    return data.map((json) => GroupDto.fromJson(json)).toList();
  }

  Future<List<VideoChannelDto>> getGroupChannels(String groupId) async {
    final response = await _dio.get('/groups/$groupId/channels');
    final data = parseEnvelopeList(response.data);
    return data.map((json) => VideoChannelDto.fromJson(json)).toList();
  }

  Future<UploadInitResponse> initiateUpload(UploadInitRequest request) async {
    final response = await _dio.post(
      '/videos/upload/init',
      data: request.toJson(),
    );
    final data = parseEnvelope(response.data);
    return UploadInitResponse.fromJson(data);
  }

  Future<void> uploadChunk({
    required String uploadUrl,
    required File file,
    required int start,
    required int end,
    required int totalSize,
    required CancelToken cancelToken,
    void Function(int sent, int total)? onProgress,
  }) async {
    final stream = file.openRead(start, end + 1);
    final length = end - start + 1;

    // Direct PUT to upload URL (no envelope processing needed here typically, as it might be S3/GCS directly)
    // If it's your own backend, it might return an envelope.
    await _dio.put(
      uploadUrl,
      data: stream,
      cancelToken: cancelToken,
      options: Options(
        headers: {
          'Content-Length': length,
          'Content-Range': 'bytes $start-$end/$totalSize',
        },
      ),
      onSendProgress: onProgress,
    );
  }

  Future<void> completeUpload(String videoId) async {
    // Envelope parsed but we don't necessarily need the payload if it's just a 200 OK
    final response = await _dio.post('/videos/$videoId/upload/complete');
    parseEnvelope(response.data);
  }

  Future<VideoResponseDto> getStatus(String videoId) async {
    final response = await _dio.get('/videos/$videoId/status');
    final data = parseEnvelope(response.data);
    return VideoResponseDto.fromJson(data);
  }
}
