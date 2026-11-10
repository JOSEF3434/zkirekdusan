// lib/core/rich_text/repository/mention_repository.dart
//
// HTTP layer for @ mention autocomplete (users, groups, channels).
// Properly unwraps the NestJS { success, data, timestamp } envelope and
// propagates errors cleanly instead of silently discarding them.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';

class MentionRepository {
  final Dio _dio;

  const MentionRepository(this._dio);

  /// GET /api/mentions/suggest?q=&limit=10
  /// Returns combined users + groups + channels for @ autocomplete.
  Future<List<MentionSuggestion>> suggestMentions(
    String query, {
    int limit = 10,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await _dio.get<dynamic>(
        '/mentions/suggest',
        queryParameters: {'q': query, 'limit': limit},
        cancelToken: cancelToken,
      );

      // Unwrap NestJS ResponseInterceptor { success, data: [...] }
      final list = parseEnvelopeList(resp.data);
      return list
          .map((e) => safeMap(e))
          .whereType<Map<String, dynamic>>()
          .map(MentionSuggestion.fromJson)
          .where((s) => s.id.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      throw AppException(_friendlyDioError(e));
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to load mention suggestions.');
    }
  }

  String _friendlyDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final msg = data['message'];
      return msg is List ? msg.join(', ') : msg.toString();
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Tap Retry.';
      case DioExceptionType.connectionError:
        return 'Network unavailable. Tap Retry.';
      default:
        return 'Could not load suggestions (${e.response?.statusCode ?? 'error'}).';
    }
  }
}

final mentionRepositoryProvider = Provider<MentionRepository>((ref) {
  return MentionRepository(ref.watch(apiClientProvider));
});
