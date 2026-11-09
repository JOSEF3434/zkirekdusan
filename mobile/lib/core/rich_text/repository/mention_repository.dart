// lib/core/rich_text/repository/mention_repository.dart
//
// HTTP layer for mention autocomplete and unified content search.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';

class MentionRepository {
  final Dio _dio;

  const MentionRepository(this._dio);

  /// GET /api/mentions/suggest?q=&limit=8
  /// Returns combined users + groups + channels for @ autocomplete.
  Future<List<MentionSuggestion>> suggestMentions(
    String query, {
    int limit = 8,
  }) async {
    try {
      final resp = await _dio.get<dynamic>(
        '/mentions/suggest',
        queryParameters: {'q': query, 'limit': limit},
      );
      final data = resp.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(MentionSuggestion.fromJson)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// GET /api/search/unified?q=&limit=12
  /// Returns flat mixed content for the # content picker.
  Future<List<ContentSearchItem>> searchContent(
    String query, {
    int limit = 12,
  }) async {
    try {
      final resp = await _dio.get<dynamic>(
        '/search/unified',
        queryParameters: {'q': query, 'limit': limit},
      );
      final data = resp.data;
      if (data is Map<String, dynamic>) {
        final items = data['items'];
        if (items is List) {
          return items
              .whereType<Map<String, dynamic>>()
              .map(ContentSearchItem.fromJson)
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}

final mentionRepositoryProvider = Provider<MentionRepository>((ref) {
  return MentionRepository(ref.watch(apiClientProvider));
});
