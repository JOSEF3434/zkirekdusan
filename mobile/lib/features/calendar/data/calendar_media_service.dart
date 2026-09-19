import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

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
    final xFile = XFile(filePath);
    final bytes = await xFile.readAsBytes();
    final filename = xFile.name.isNotEmpty ? xFile.name : p.basename(filePath);
    final mimeType = lookupMimeType(filename) ?? 'application/octet-stream';

    FormData createFormData() => FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse(mimeType),
      ),
    });

    Response response;
    try {
      response = await _dio.post(
        '/uploads/media',
        data: createFormData(),
        cancelToken: cancelToken,
        options: Options(
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
        onSendProgress: onProgress,
      );
    } on DioException catch (dioErr) {
      if (dioErr.response?.statusCode == 404) {
        // Fallback to chat upload endpoint if /uploads/media is not routed
        response = await _dio.post(
          '/uploads/chat',
          data: createFormData(),
          cancelToken: cancelToken,
          options: Options(
            sendTimeout: const Duration(minutes: 5),
            receiveTimeout: const Duration(minutes: 5),
          ),
          onSendProgress: onProgress,
        );
      } else {
        rethrow;
      }
    }

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
    final data = <String, dynamic>{};
    if (order != null) data['order'] = order;
    if (caption != null) data['caption'] = caption;

    final response = await _dio.patch(
      '/calendar/notes/$noteId/media/$mediaId',
      data: data,
    );

    final responseData = response.data;
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'] as Map<String, dynamic>;
    } else if (responseData is Map) {
      return responseData as Map<String, dynamic>;
    } else {
      throw Exception('Unexpected response format');
    }
  }
}
