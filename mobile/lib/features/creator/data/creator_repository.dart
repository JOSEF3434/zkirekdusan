// lib/features/creator/data/creator_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/creator/domain/creator_channel_dto.dart';
import 'package:mobile/features/creator/domain/creator_group_dto.dart';
import 'package:mobile/features/creator/domain/creator_enums.dart';

final creatorRepositoryProvider = Provider<CreatorRepository>((ref) {
  return CreatorRepository(ref.watch(apiClientProvider));
});

class CreatorRepository {
  final Dio _dio;

  CreatorRepository(this._dio);

  /// Fetch active public groups.
  Future<PaginatedCreatorGroups> getActiveGroups({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/groups',
      queryParameters: {'page': page, 'limit': limit},
    );
    final map = parsePaginatedEnvelope(response.data);
    final itemsJson = (map['data'] as List?) ?? [];
    final items = itemsJson
        .map((e) => CreatorGroupDto.fromJson(e as Map<String, dynamic>))
        .toList();

    // Check if there's a next page from meta
    final meta = map['meta'] as Map<String, dynamic>?;
    final totalPages = meta?['totalPages'] as int?;
    final currentPage = meta?['currentPage'] as int? ?? page;

    final hasNextPage = totalPages != null
        ? currentPage < totalPages
        : items.length == limit;

    return PaginatedCreatorGroups(items: items, hasNextPage: hasNextPage);
  }

  /// Fetch user's own groups (all statuses).
  Future<PaginatedCreatorGroups> getMyGroups({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/groups/my-groups',
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

  /// Get video channels for a group
  Future<List<CreatorChannelDto>> getGroupVideoChannels(String groupId) async {
    final response = await _dio.get('/groups/$groupId/video-channels');
    final data = parseEnvelopeList(response.data);
    return data.map((json) => CreatorChannelDto.fromJson(json)).toList();
  }

  /// Create a new group (starts as PENDING_APPROVAL)
  Future<CreatorGroupDto> createGroup({
    required String name,
    required String slug,
    String? description,
    required GroupVisibility visibility,
  }) async {
    final body = {
      'name': name,
      'slug': slug,
      if (description != null && description.isNotEmpty)
        'description': description,
      // The backend expects specific enum string values (e.g., 'INVITE_ONLY')
      'visibility': visibility == GroupVisibility.inviteOnly
          ? 'INVITE_ONLY'
          : visibility.name.toUpperCase(),
    };

    final response = await _dio.post('/groups', data: body);
    final data = parseEnvelope(response.data);
    return CreatorGroupDto.fromJson(data);
  }

  /// Create a video channel
  Future<CreatorChannelDto> createVideoChannel({
    required String groupId,
    required String name,
    required String slug,
    required String handle,
    String? description,
    UploadPermission uploadPermission = UploadPermission.member,
    String downloadPermission =
        'MEMBERS_ONLY', // We can hardcode or expose if needed
  }) async {
    final body = {
      'name': name,
      'slug': slug,
      'handle': handle,
      if (description != null && description.isNotEmpty)
        'description': description,
      'uploadPermission': uploadPermission
          .toString()
          .split('.')
          .last
          .toUpperCase(),
      'downloadPermission': downloadPermission,
    };

    final response = await _dio.post(
      '/groups/$groupId/video-channels',
      data: body,
    );
    final data = parseEnvelope(response.data);
    return CreatorChannelDto.fromJson(data);
  }
}

class PaginatedCreatorGroups {
  final List<CreatorGroupDto> items;
  final bool hasNextPage;

  PaginatedCreatorGroups({required this.items, required this.hasNextPage});
}
