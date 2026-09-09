// lib/features/calendar/data/calendar_media_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mime/mime.dart';

final calendarMediaServiceProvider = Provider<CalendarMediaService>((ref) {
  return CalendarMediaService(ref.watch(apiClientProvider));
});

class CalendarMediaService {
  final Dio _dio;

  CalendarMediaService(this._dio);

  /// Upload a file to the server and return the File model
  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final filename = filePath.split(Platform.pathSeparator).last;
    final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse(mimeType),
      ),
    });

    final response = await _dio.post(
      '/uploads',
      data: formData,
      cancelToken: cancelToken,
      options: Options(
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
      onSendProgress: onProgress,
    );

    // Parse envelope response
    final data = response.data;
    if (data is Map && data.containsKey('data')) {
      return data['data'] as Map<String, dynamic>;
    } else if (data is Map) {
      return data as Map<String, dynamic>;
    } else {
      throw Exception('Unexpected response format');
    }
  }

  /// Add media to a calendar note
  Future<Map<String, dynamic>> addMediaToNote({
    required String noteId,
    required String fileId,
    required int order,
    String? caption,
  }) async {
    final response = await _dio.post(
      '/calendar/notes/$noteId/media',
      data: {
        'fileId': fileId,
        'order': order,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
      },
    );

    final data = response.data;
    if (data is Map && data.containsKey('data')) {
      return data['data'] as Map<String, dynamic>;
    } else if (data is Map) {
      return data as Map<String, dynamic>;
    } else {
      throw Exception('Unexpected response format');
    }
  }

  /// Remove media from a calendar note
  Future<void> removeMediaFromNote({
    required String noteId,
    required String mediaId,
  }) async {
    await _dio.delete('/calendar/notes/$noteId/media/$mediaId');
  }

  /// Update media order and caption
  Future<Map<String, dynamic>> updateNoteMedia({
    required String noteId,
    required String mediaId,
    int? order,
    String? caption,
  }) async {
    final response = await _dio.patch(
      '/calendar/notes/$noteId/media/$mediaId',
      data: {'order': ?order, 'caption': ?caption},
    );

    final data = response.data;
    if (data is Map && data.containsKey('data')) {
      return data['data'] as Map<String, dynamic>;
    } else if (data is Map) {
      return data as Map<String, dynamic>;
    } else {
      throw Exception('Unexpected response format');
    }
  }
}
