import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/creator/domain/creator_group_dto.dart';
import 'package:mobile/features/creator/data/creator_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});

class AdminRepository {
  final Dio _dio;

  AdminRepository(this._dio);

  Future<PaginatedCreatorGroups> getPendingGroups({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/groups/pending',
      queryParameters: {'page': page, 'limit': limit},
    );
    final map = parsePaginatedEnvelope(response.data);
    final itemsJson = (map['data'] as List?) ?? [];
    final items = itemsJson
        .map((e) => CreatorGroupDto.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta = map['meta'] as Map<String, dynamic>?;
    final totalPages = meta?['totalPages'] as int?;
    final currentPage = meta?['currentPage'] as int? ?? page;

    final hasNextPage = totalPages != null
        ? currentPage < totalPages
        : items.length == limit;

    return PaginatedCreatorGroups(items: items, hasNextPage: hasNextPage);
  }

  Future<void> approveGroup(String groupId) async {
    await _dio.patch('/groups/$groupId/approve');
  }

  Future<void> rejectGroup(String groupId) async {
    await _dio.patch('/groups/$groupId/reject');
  }
}

// Helpers
Map<String, dynamic> parsePaginatedEnvelope(dynamic responseData) {
  if (responseData is Map<String, dynamic>) {
    return responseData;
  }
  return {'data': [], 'meta': {}};
}
