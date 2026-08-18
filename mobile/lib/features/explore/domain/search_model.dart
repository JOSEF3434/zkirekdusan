import 'package:mobile/features/home/domain/video_model.dart';

enum SearchEntityType {
  users,
  groups,
  channels,
  posts,
  videos,
  reels,
  playlists,
  streams,
}

// ── User ──────────────────────────────────────────────────────────────────────

class SearchUserDto {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  const SearchUserDto({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory SearchUserDto.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    final avatar = profile?['avatar'] as Map<String, dynamic>?;
    return SearchUserDto(
      id: json['id'] as String? ?? '',
      username: json['username'] as String?,
      displayName: profile?['displayName'] as String?,
      avatarUrl: avatar?['url'] as String? ?? json['avatarUrl'] as String?,
    );
  }
}

// ── Group ─────────────────────────────────────────────────────────────────────

class SearchGroupDto {
  final String id;
  final String? name;
  final String? slug;
  final String? avatarUrl;

  const SearchGroupDto({
    required this.id,
    this.name,
    this.slug,
    this.avatarUrl,
  });

  factory SearchGroupDto.fromJson(Map<String, dynamic> json) {
    return SearchGroupDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      slug: json['slug'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

// ── Stream ────────────────────────────────────────────────────────────────────

class SearchStreamDto {
  final String id;
  final String? title;
  final String? status;
  final int? viewerCount;
  final String? creatorUsername;
  final DateTime? scheduledAt;

  const SearchStreamDto({
    required this.id,
    this.title,
    this.status,
    this.viewerCount,
    this.creatorUsername,
    this.scheduledAt,
  });

  bool get isLive => status?.toUpperCase() == 'LIVE';

  factory SearchStreamDto.fromJson(Map<String, dynamic> json) {
    final createdBy = json['createdBy'] as Map<String, dynamic>?;
    return SearchStreamDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String?,
      status: json['status'] as String?,
      viewerCount: json['currentViewerCount'] as int?,
      creatorUsername: createdBy?['username'] as String?,
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'] as String)
          : null,
    );
  }
}

// ── Reel ─────────────────────────────────────────────────────────────────────

class SearchReelDto {
  final String id;
  final String? description;
  final String? thumbnailUrl;
  final int? viewsCount;
  final String? authorUsername;

  const SearchReelDto({
    required this.id,
    this.description,
    this.thumbnailUrl,
    this.viewsCount,
    this.authorUsername,
  });

  factory SearchReelDto.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    return SearchReelDto(
      id: json['id'] as String? ?? '',
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      viewsCount: json['viewsCount'] as int?,
      authorUsername: author?['username'] as String?,
    );
  }
}

// ── Aggregated Results ────────────────────────────────────────────────────────

class SearchResultsDto {
  final List<SearchUserDto> users;
  final List<VideoResponseDto> videos;
  final List<SearchGroupDto> groups;
  final List<SearchStreamDto> streams;
  final List<SearchReelDto> reels;

  const SearchResultsDto({
    this.users = const [],
    this.videos = const [],
    this.groups = const [],
    this.streams = const [],
    this.reels = const [],
  });

  bool get isEmpty =>
      users.isEmpty &&
      videos.isEmpty &&
      groups.isEmpty &&
      streams.isEmpty &&
      reels.isEmpty;

  factory SearchResultsDto.fromJson(Map<String, dynamic> json) {
    return SearchResultsDto(
      users: _parseList(json['users'], SearchUserDto.fromJson),
      videos: _parseList(json['videos'], VideoResponseDto.fromJson),
      groups: _parseList(json['groups'], SearchGroupDto.fromJson),
      streams: _parseList(json['streams'], SearchStreamDto.fromJson),
      reels: _parseList(json['reels'], SearchReelDto.fromJson),
    );
  }
}

List<T> _parseList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
  if (raw == null) return const [];
  if (raw is! List) return const [];
  final result = <T>[];
  for (final item in raw) {
    if (item is Map<String, dynamic>) {
      try {
        result.add(fromJson(item));
      } catch (_) {
        // Skip malformed items
      }
    }
  }
  return result;
}

// ── Response ──────────────────────────────────────────────────────────────────

class SearchResponseDto {
  final SearchResultsDto results;
  final int page;
  final int limit;

  const SearchResponseDto({
    required this.results,
    required this.page,
    required this.limit,
  });

  factory SearchResponseDto.fromJson(Map<String, dynamic> json) {
    return SearchResponseDto(
      results: SearchResultsDto.fromJson(
        json['results'] as Map<String, dynamic>? ?? {},
      ),
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
    );
  }
}
