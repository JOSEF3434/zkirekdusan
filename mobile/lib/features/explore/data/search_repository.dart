// lib/features/explore/data/search_repository.dart
// Dedicated search repository — queries GET /search only.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/explore/domain/search_model.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.read(apiClientProvider));
});

class SearchRepository {
  final Dio _dio;

  SearchRepository(this._dio);

  /// Performs a global search against `GET /search`.
  /// Records history server-side for authenticated users automatically.
  Future<SearchResponseDto> search({
    required String query,
    SearchEntityType? type,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      '/search',
      queryParameters: {
        'q': query,
        if (type != null) 'type': type.name.toUpperCase(),
        'page': page,
        'limit': limit,
      },
      cancelToken: cancelToken,
    );

    // Unwrap optional NestJS ResponseInterceptor envelope safely via parseEnvelope
    final data = parseEnvelope(response.data);
    return SearchResponseDto.fromJson(data);
  }
}
