// lib/features/live/data/stream_highlights_repository.dart
// HTTP calls for stream highlights (create, list, delete).

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/live/domain/stream_highlight_model.dart';

final streamHighlightsRepositoryProvider = Provider<StreamHighlightsRepository>(
  (ref) {
    return StreamHighlightsRepository(ref.read(apiClientProvider));
  },
);

class StreamHighlightsRepository {
  final Dio _dio;

  StreamHighlightsRepository(this._dio);

  /// POST /live-streams/:streamId/highlights
  Future<StreamHighlightDto> createHighlight(
    String streamId, {
    required String title,
    String? description,
    required int startTimeSec,
    required int endTimeSec,
  }) async {
    try {
      final response = await _dio.post(
        '/live-streams/$streamId/highlights',
        data: {
          'title': title,
          if (description != null) 'description': description,
          'startTimeSec': startTimeSec,
          'endTimeSec': endTimeSec,
        },
      );
      final data = parseEnvelope(response.data);
      return StreamHighlightDto.fromJson(data);
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  /// GET /live-streams/:streamId/highlights
  Future<List<StreamHighlightDto>> getHighlights(String streamId) async {
    try {
      final response = await _dio.get('/live-streams/$streamId/highlights');
      final list = parseEnvelopeList(response.data);
      return list
          .map((e) => StreamHighlightDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  /// DELETE /live-streams/:streamId/highlights/:highlightId
  Future<void> deleteHighlight(String streamId, String highlightId) async {
    try {
      await _dio.delete('/live-streams/$streamId/highlights/$highlightId');
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  String _parseDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is String) return msg;
      if (msg is List) return (msg).join(', ');
    }
    return 'An unexpected error occurred.';
  }
}
