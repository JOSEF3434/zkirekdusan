// lib/features/live/data/live_streaming_repository.dart
// HTTP repository for all live-streaming REST endpoints.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/home/domain/feed_response.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';

final liveStreamingRepositoryProvider = Provider<LiveStreamingRepository>((
  ref,
) {
  return LiveStreamingRepository(ref.read(apiClientProvider));
});

class LiveStreamingRepository {
  final Dio _dio;

  LiveStreamingRepository(this._dio);

  // ─── Discovery ─────────────────────────────────────────────────────────────

  /// GET /streams/live — paginated list of all currently LIVE public streams.
  Future<PaginatedStreams> getLiveStreams({
    int page = 1,
    int limit = 20,
    String? category,
    CancelToken? cancelToken,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (category != null && category.trim().isNotEmpty && category.trim().toLowerCase() != 'all') {
        queryParams['category'] = category.trim();
      }
      final response = await _dio.get(
        '/streams/live',
        queryParameters: queryParams,
        cancelToken: cancelToken,
      );
      return _parsePaginatedStreams(response.data);
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  /// GET /streams/scheduled — upcoming scheduled streams.
  Future<PaginatedStreams> getScheduledStreams({
    int page = 1,
    int limit = 20,
    String? category,
    CancelToken? cancelToken,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (category != null && category.trim().isNotEmpty && category.trim().toLowerCase() != 'all') {
        queryParams['category'] = category.trim();
      }
      final response = await _dio.get(
        '/streams/scheduled',
        queryParameters: queryParams,
        cancelToken: cancelToken,
      );
      return _parsePaginatedStreams(response.data);
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }


  // ─── Stream Details ────────────────────────────────────────────────────────

  /// GET /streams/:id
  Future<LiveStreamDto> getStreamById(String streamId) async {
    try {
      final response = await _dio.get('/streams/$streamId');
      final data = parseEnvelope(response.data);
      return LiveStreamDto.fromJson(data);
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  // ─── Channel Streams ───────────────────────────────────────────────────────

  /// GET /video-channels/:channelId/streams
  Future<PaginatedStreams> getChannelStreams(
    String channelId, {
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        '/video-channels/$channelId/streams',
        queryParameters: {'page': page, 'limit': limit},
        cancelToken: cancelToken,
      );
      return _parsePaginatedStreams(response.data);
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  /// GET /streams/user/:userId — paginated list of all live streams created by a user.
  Future<PaginatedStreams> getUserStreams(
    String userId, {
    int page = 1,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        '/streams/user/$userId',
        queryParameters: {'page': page, 'limit': limit},
        cancelToken: cancelToken,
      );
      return _parsePaginatedStreams(response.data);
    } on DioException catch (e) {
      // Fallback: If 404 or endpoint unavailable, attempt to combine public live & scheduled streams
      try {
        final live = await getLiveStreams(limit: 50, cancelToken: cancelToken);
        final scheduled = await getScheduledStreams(limit: 50, cancelToken: cancelToken);
        final combined = [...live.items, ...scheduled.items];
        final filtered = combined.where((s) => s.createdById == userId).toList();
        return PaginatedStreams(items: filtered);
      } catch (_) {
        throw AppException(_parseDioError(e));
      }
    }
  }

  // ─── Broadcaster Operations ────────────────────────────────────────────────

  /// POST /video-channels/:channelId/streams
  Future<LiveStreamDto> createStream(
    String channelId,
    CreateLiveStreamRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/video-channels/$channelId/streams',
        data: request.toJson(),
      );
      final data = parseEnvelope(response.data);
      return LiveStreamDto.fromJson(data);
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  /// PATCH /streams/:id
  Future<LiveStreamDto> updateStream(
    String streamId,
    Map<String, dynamic> fields,
  ) async {
    try {
      final response = await _dio.patch('/streams/$streamId', data: fields);
      final data = parseEnvelope(response.data);
      return LiveStreamDto.fromJson(data);
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  /// DELETE /video-channels/:channelId/streams/:id or /streams/:id
  Future<void> deleteStream(String streamId, {String? channelId}) async {
    try {
      if (channelId != null && channelId.isNotEmpty) {
        await _dio.delete('/video-channels/$channelId/streams/$streamId');
      } else {
        await _dio.delete('/streams/$streamId');
      }
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  /// POST /streams/:id/go-live
  /// Returns the updated stream. The backend may embed a `streamKey` field
  /// (plain-text Cloudinary key) in the response — we extract and cache it.
  Future<({LiveStreamDto stream, String? streamKey})> startStream(
    String streamId,
  ) async {
    try {
      final response = await _dio.post('/streams/$streamId/go-live');
      final data = parseEnvelope(response.data);
      final stream = LiveStreamDto.fromJson(data);
      final rawKey = data['streamKey'] as String? ?? data['rawKey'] as String?;
      return (stream: stream, streamKey: rawKey);
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  /// POST /streams/:id/end
  Future<LiveStreamDto> endStream(String streamId) async {
    try {
      final response = await _dio.post('/streams/$streamId/end');
      final data = parseEnvelope(response.data);
      return LiveStreamDto.fromJson(data);
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  /// POST /streams/:id/publish-vod
  Future<LiveStreamDto> publishVod(String streamId) async {
    try {
      final response = await _dio.post('/streams/$streamId/publish-vod');
      final data = parseEnvelope(response.data);
      return LiveStreamDto.fromJson(data);
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  // ─── Stream Key ────────────────────────────────────────────────────────────

  /// GET /video-channels/:channelId/streams/key
  Future<StreamKeyDto> getStreamKey(String channelId) async {
    try {
      final response = await _dio.get('/video-channels/$channelId/streams/key');
      final data = parseEnvelope(response.data);
      return StreamKeyDto.fromJson(data);
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  /// POST /video-channels/:channelId/streams/key/regenerate
  Future<StreamKeyDto> regenerateStreamKey(String channelId) async {
    try {
      final response = await _dio.post(
        '/video-channels/$channelId/streams/key/regenerate',
      );
      final data = parseEnvelope(response.data);
      return StreamKeyDto.fromJson(data);
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  /// Upload a thumbnail image file to /uploads/media and return its id and url.
  Future<({String id, String url})> uploadThumbnail(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final filename = file.name.isNotEmpty ? file.name : 'thumbnail.jpg';
      final mimeType = filename.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(mimeType),
        ),
      });

      final response = await _dio.post(
        '/uploads/media',
        data: formData,
        options: Options(
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

      final envelope = parseEnvelope(response.data);
      final id = envelope['id']?.toString() ?? '';
      final url = envelope['url']?.toString() ?? '';
      return (id: id, url: url);
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  PaginatedStreams _parsePaginatedStreams(dynamic raw) {
    final map = parsePaginatedEnvelope(raw);
    final itemsJson = (map['data'] as List?) ?? [];
    final items = itemsJson
        .map((e) => LiveStreamDto.fromJson(e as Map<String, dynamic>))
        .toList();
    FeedMetaDto? meta;
    if (map['meta'] != null) {
      meta = FeedMetaDto.fromJson(map['meta'] as Map<String, dynamic>);
    }
    return PaginatedStreams(items: items, meta: meta);
  }

  String _parseDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'] ?? data['error'];
      if (msg is String) return msg;
      if (msg is List) return (msg).join(', ');
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout => 'Connection timed out.',
      DioExceptionType.connectionError => 'Could not connect to the server.',
      _ => 'An unexpected error occurred.',
    };
  }
}

class PaginatedStreams {
  final List<LiveStreamDto> items;
  final FeedMetaDto? meta;

  const PaginatedStreams({required this.items, this.meta});

  bool get hasNext => meta?.hasNext ?? false;
  int get total => meta?.total ?? items.length;
}
