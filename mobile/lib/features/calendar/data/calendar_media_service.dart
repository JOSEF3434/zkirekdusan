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

  /// Upload a file to the calendar media endpoint, sniffing MIME from bytes
  /// when the file has no extension (image_picker on Android returns UUID names).
  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final xFile = XFile(filePath);
    final bytes = await xFile.readAsBytes();
    final originalName = xFile.name.isNotEmpty ? xFile.name : p.basename(filePath);

    // Resolve MIME: prefer OS-detected type, fall back to magic bytes
    final rawMime = xFile.mimeType ?? lookupMimeType(originalName);
    final mimeType =
        (rawMime == null || rawMime == 'application/octet-stream')
            ? (_resolveMimeFromBytes(bytes) ?? 'application/octet-stream')
            : rawMime;

    // Ensure filename has an extension so Cloudinary knows what to do with it
    String filename = originalName;
    if (p.extension(filename).isEmpty) {
      final ext = _extensionFromMime(mimeType);
      if (ext.isNotEmpty) filename = '$filename.$ext';
    }

    FormData buildForm() => FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: filename,
            contentType: DioMediaType.parse(mimeType),
          ),
        });

    final response = await _dio.post(
      '/uploads/calendar',
      data: buildForm(),
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

  /// Detects MIME type from the first bytes of a buffer (magic bytes).
  String? _resolveMimeFromBytes(List<int> bytes) {
    if (bytes.length < 4) return null;
    final h = bytes;

    // JPEG
    if (h[0] == 0xff && h[1] == 0xd8 && h[2] == 0xff) return 'image/jpeg';
    // PNG
    if (h[0] == 0x89 && h[1] == 0x50 && h[2] == 0x4e && h[3] == 0x47) {
      return 'image/png';
    }
    // GIF
    if (h[0] == 0x47 && h[1] == 0x49 && h[2] == 0x46) return 'image/gif';
    // BMP
    if (h[0] == 0x42 && h[1] == 0x4d) return 'image/bmp';
    // WebP
    if (bytes.length >= 12 &&
        h[0] == 0x52 && h[1] == 0x49 && h[2] == 0x46 && h[3] == 0x46 &&
        h[8] == 0x57 && h[9] == 0x45 && h[10] == 0x42 && h[11] == 0x50) {
      return 'image/webp';
    }
    // HEIC / MP4 / MOV — ftyp box at bytes 4-7
    if (bytes.length >= 12 &&
        h[4] == 0x66 && h[5] == 0x74 && h[6] == 0x79 && h[7] == 0x70) {
      final brand = String.fromCharCodes(bytes.sublist(8, 12));
      if (['heic', 'heix', 'mif1'].contains(brand)) return 'image/heic';
      if (['isom', 'mp41', 'mp42'].contains(brand)) return 'video/mp4';
      if (brand == 'qt  ') return 'video/quicktime';
      return 'video/mp4';
    }
    return null;
  }

  String _extensionFromMime(String mimeType) {
    switch (mimeType) {
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/gif':
        return 'gif';
      case 'image/webp':
        return 'webp';
      case 'image/heic':
        return 'heic';
      case 'image/bmp':
        return 'bmp';
      case 'video/mp4':
        return 'mp4';
      case 'video/quicktime':
        return 'mov';
      case 'audio/mpeg':
        return 'mp3';
      default:
        return '';
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
