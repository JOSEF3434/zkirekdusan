import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/features/home/domain/video_model.dart';

enum SearchEntityType {
  users,
  groups,
  channels,
  posts,
  books,
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
  final bool isVerified;

  const SearchUserDto({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.isVerified = false,
  });

  factory SearchUserDto.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    final avatar = profile?['avatar'] as Map<String, dynamic>?;
    return SearchUserDto(
      id: json['id'] as String? ?? '',
      username: json['username'] as String?,
      displayName:
          json['displayName'] as String? ?? profile?['displayName'] as String?,
      avatarUrl: avatar?['url'] as String? ?? json['avatarUrl'] as String?,
      isVerified:
          json['isVerified'] as bool? ??
          profile?['isVerified'] as bool? ??
          false,
    );
  }
}

// ── Group ─────────────────────────────────────────────────────────────────────

class SearchGroupDto {
  final String id;
  final String? name;
  final String? slug;
  final String? description;
  final String? avatarUrl;
  final int membersCount;

  const SearchGroupDto({
    required this.id,
    this.name,
    this.slug,
    this.description,
    this.avatarUrl,
    this.membersCount = 0,
  });

  factory SearchGroupDto.fromJson(Map<String, dynamic> json) {
    return SearchGroupDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      membersCount: (json['membersCount'] as num?)?.toInt() ?? 0,
    );
  }
}

// ── Channel ───────────────────────────────────────────────────────────────────

class SearchChannelDto {
  final String id;
  final String? name;
  final String? handle;
  final String? description;
  final String? avatarUrl;
  final int subscribersCount;
  final bool isVerified;

  const SearchChannelDto({
    required this.id,
    this.name,
    this.handle,
    this.description,
    this.avatarUrl,
    this.subscribersCount = 0,
    this.isVerified = false,
  });

  String? get cleanHandle => handle?.replaceFirst(RegExp(r'^@+'), '');

  factory SearchChannelDto.fromJson(Map<String, dynamic> json) {
    final avatarFile = json['avatarFile'] as Map<String, dynamic>?;
    return SearchChannelDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      handle: json['handle'] as String?,
      description: json['description'] as String?,
      avatarUrl: avatarFile?['url'] as String? ?? json['avatarUrl'] as String?,
      subscribersCount: (json['subscribersCount'] as num?)?.toInt() ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}

// ── Book & Dictionary ─────────────────────────────────────────────────────────

class SearchBookDto {
  final String id;
  final String title;
  final String? titleAm;
  final String? titleGez;
  final String? subtitle;
  final String? author;
  final String? coverUrl;
  final String? language;
  final String? format;
  final bool isDictionary;
  final String? dictionaryName;
  final String? categoryName;
  final int? totalEntries;
  final int viewsCount;

  const SearchBookDto({
    required this.id,
    required this.title,
    this.titleAm,
    this.titleGez,
    this.subtitle,
    this.author,
    this.coverUrl,
    this.language,
    this.format,
    this.isDictionary = false,
    this.dictionaryName,
    this.categoryName,
    this.totalEntries,
    this.viewsCount = 0,
  });

  factory SearchBookDto.fromJson(Map<String, dynamic> json) {
    final coverFile = json['coverFile'] as Map<String, dynamic>?;
    final category = json['category'] as Map<String, dynamic>?;
    final dictConfig = json['dictionaryConfig'] as Map<String, dynamic>?;
    return SearchBookDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Book',
      titleAm: json['titleAm'] as String?,
      titleGez: json['titleGez'] as String?,
      subtitle: json['subtitle'] as String?,
      author: json['author'] as String?,
      coverUrl: json['coverUrl'] as String? ?? coverFile?['url'] as String?,
      language: json['language'] as String?,
      format: json['format'] as String?,
      isDictionary: json['isDictionary'] as bool? ?? false,
      dictionaryName:
          json['dictionaryName'] as String? ??
          dictConfig?['dictionaryName'] as String?,
      categoryName:
          json['categoryName'] as String? ?? category?['name'] as String?,
      totalEntries:
          (json['totalEntries'] as num?)?.toInt() ??
          (dictConfig?['totalEntries'] as num?)?.toInt(),
      viewsCount: (json['viewsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

// ── Post ──────────────────────────────────────────────────────────────────────

class SearchPostDto {
  final String id;
  final String content;
  final String? thumbnailUrl;
  final String? authorId;
  final String? authorUsername;
  final String? authorDisplayName;
  final String? authorAvatarUrl;
  final int likesCount;
  final int commentsCount;
  final DateTime? createdAt;

  const SearchPostDto({
    required this.id,
    required this.content,
    this.thumbnailUrl,
    this.authorId,
    this.authorUsername,
    this.authorDisplayName,
    this.authorAvatarUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.createdAt,
  });

  factory SearchPostDto.fromJson(Map<String, dynamic> json) {
    final authorRaw = json['author'] as Map<String, dynamic>?;
    final author = authorRaw != null ? PostAuthorDto.fromJson(authorRaw) : null;
    final media = json['media'] as List<dynamic>?;
    String? firstThumb = json['thumbnailUrl'] as String?;
    if (firstThumb == null && media != null && media.isNotEmpty) {
      final firstItem = media.first;
      if (firstItem is Map) {
        final file = firstItem['file'];
        if (file is Map) {
          firstThumb = file['url'] as String?;
        }
      }
    }

    return SearchPostDto(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      thumbnailUrl: firstThumb,
      authorId: author?.id,
      authorUsername: author?.username,
      authorDisplayName: author?.displayName,
      authorAvatarUrl: author?.avatarUrl,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
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
  final String? creatorDisplayName;
  final String? thumbnailUrl;
  final String? channelName;
  final DateTime? scheduledAt;
  final String? createdById;
  final String? videoChannelId;

  const SearchStreamDto({
    required this.id,
    this.title,
    this.status,
    this.viewerCount,
    this.creatorUsername,
    this.creatorDisplayName,
    this.thumbnailUrl,
    this.channelName,
    this.scheduledAt,
    this.createdById,
    this.videoChannelId,
  });

  bool get isLive => status?.toUpperCase() == 'LIVE';
  bool get isScheduled => status?.toUpperCase() == 'SCHEDULED';

  factory SearchStreamDto.fromJson(Map<String, dynamic> json) {
    final createdBy = json['createdBy'] as Map<String, dynamic>?;
    final createdByProfile = createdBy?['profile'] as Map<String, dynamic>?;
    final videoChannel = json['videoChannel'] as Map<String, dynamic>?;
    final thumbFile = json['thumbnailFile'] as Map<String, dynamic>?;
    return SearchStreamDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String?,
      status: json['status'] as String?,
      viewerCount: (json['currentViewerCount'] as num?)?.toInt(),
      creatorUsername: createdBy?['username'] as String?,
      creatorDisplayName: createdByProfile?['displayName'] as String?,
      channelName: videoChannel?['name'] as String?,
      thumbnailUrl:
          json['thumbnailUrl'] as String? ?? thumbFile?['url'] as String?,
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'].toString())
          : null,
      createdById:
          json['createdById'] as String? ?? createdBy?['id'] as String?,
      videoChannelId:
          json['videoChannelId'] as String? ?? videoChannel?['id'] as String?,
    );
  }
}

// ── Reel ──────────────────────────────────────────────────────────────────────

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
      description:
          json['description'] as String? ?? json['caption'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      viewsCount: (json['viewsCount'] as num?)?.toInt(),
      authorUsername: author?['username'] as String?,
    );
  }
}

// ── Aggregated Results ────────────────────────────────────────────────────────

class SearchResultsDto {
  final List<SearchUserDto> users;
  final List<VideoResponseDto> videos;
  final List<SearchBookDto> books;
  final List<SearchGroupDto> groups;
  final List<SearchChannelDto> channels;
  final List<SearchPostDto> posts;
  final List<SearchStreamDto> streams;
  final List<SearchReelDto> reels;

  const SearchResultsDto({
    this.users = const [],
    this.videos = const [],
    this.books = const [],
    this.groups = const [],
    this.channels = const [],
    this.posts = const [],
    this.streams = const [],
    this.reels = const [],
  });

  bool get isEmpty =>
      users.isEmpty &&
      videos.isEmpty &&
      books.isEmpty &&
      groups.isEmpty &&
      channels.isEmpty &&
      posts.isEmpty &&
      streams.isEmpty &&
      reels.isEmpty;

  int get totalCount =>
      users.length +
      videos.length +
      books.length +
      groups.length +
      channels.length +
      posts.length +
      streams.length +
      reels.length;

  factory SearchResultsDto.fromJson(Map<String, dynamic> json) {
    return SearchResultsDto(
      users: _parseList(json['users'], SearchUserDto.fromJson),
      videos: _parseList(json['videos'], VideoResponseDto.fromJson),
      books: _parseList(json['books'], SearchBookDto.fromJson),
      groups: _parseList(json['groups'], SearchGroupDto.fromJson),
      channels: _parseList(json['channels'], SearchChannelDto.fromJson),
      posts: _parseList(json['posts'], SearchPostDto.fromJson),
      streams: _parseList(json['streams'], SearchStreamDto.fromJson),
      reels: _parseList(json['reels'], SearchReelDto.fromJson),
    );
  }
}

List<T> _parseList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
  if (raw == null || raw is! List) return const [];
  final result = <T>[];
  for (final item in raw) {
    if (item is Map<String, dynamic>) {
      try {
        result.add(fromJson(item));
      } catch (_) {
        // Skip malformed items without crashing remaining results
      }
    } else if (item is Map) {
      try {
        result.add(fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {}
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
    final rawResults = json['results'];
    final Map<String, dynamic> resultsMap = rawResults is Map<String, dynamic>
        ? rawResults
        : (rawResults is Map
              ? Map<String, dynamic>.from(rawResults)
              : {});

    return SearchResponseDto(
      results: SearchResultsDto.fromJson(resultsMap),
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
    );
  }
}
