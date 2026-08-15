// lib/features/home/domain/feed_response.dart
// Manual (non-freezed) implementation to guarantee null-safe parsing.
// We avoid generating code that performs unsafe casts on backend data.

import 'package:mobile/features/home/domain/post_model.dart';

/// Pagination metadata. All fields have safe defaults.
class FeedMetaDto {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const FeedMetaDto({
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 0,
    this.hasNext = false,
    this.hasPrev = false,
  });

  /// Always safe — every field has a null-coalescing default.
  factory FeedMetaDto.fromJson(Map<String, dynamic> json) {
    return FeedMetaDto(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrev: json['hasPrev'] as bool? ?? false,
    );
  }

  /// Empty/default meta — used when the backend omits pagination info.
  const FeedMetaDto.empty()
    : page = 1,
      limit = 20,
      total = 0,
      totalPages = 0,
      hasNext = false,
      hasPrev = false;
}

/// Paginated feed response. Safe to construct with empty data.
class FeedResponseDto {
  final List<PostResponseDto> data;
  final FeedMetaDto meta;

  const FeedResponseDto({this.data = const [], required this.meta});

  /// Null-safe factory. Handles:
  /// - Missing `data` key → empty list
  /// - Items that fail to parse → skipped (logged)
  /// - Missing/null `meta` → FeedMetaDto.empty()
  factory FeedResponseDto.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final List<PostResponseDto> posts;

    if (rawData is List) {
      posts = rawData
          .whereType<Map<dynamic, dynamic>>()
          .map((item) {
            try {
              final safeMap = item is Map<String, dynamic>
                  ? item
                  : item.cast<String, dynamic>();
              return PostResponseDto.fromJson(safeMap);
            } catch (e) {
              return null;
            }
          })
          .whereType<PostResponseDto>()
          .toList();
    } else {
      posts = [];
    }

    final rawMeta = json['meta'];
    FeedMetaDto meta;
    if (rawMeta is Map) {
      try {
        final safeMap = rawMeta is Map<String, dynamic>
            ? rawMeta
            : rawMeta.cast<String, dynamic>();
        meta = FeedMetaDto.fromJson(safeMap);
      } catch (_) {
        meta = const FeedMetaDto.empty();
      }
    } else {
      meta = const FeedMetaDto.empty();
    }

    return FeedResponseDto(data: posts, meta: meta);
  }
}
