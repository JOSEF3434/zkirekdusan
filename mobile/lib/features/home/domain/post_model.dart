// lib/features/home/domain/post_model.dart
// Manual null-safe implementation (not freezed) to guarantee safe JSON parsing.

class PostAuthorDto {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  const PostAuthorDto({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory PostAuthorDto.fromJson(Map<String, dynamic> json) {
    return PostAuthorDto(
      id: json['id'] as String? ?? '',
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  /// Safe fallback when author field is null or not a map.
  factory PostAuthorDto.empty() => const PostAuthorDto(id: '');
}

class PostMediaItemDto {
  final String id;
  final String url;
  final String fileType;
  final int order;

  const PostMediaItemDto({
    required this.id,
    required this.url,
    required this.fileType,
    required this.order,
  });

  factory PostMediaItemDto.fromJson(Map<String, dynamic> json) {
    return PostMediaItemDto(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      fileType: json['fileType'] as String? ?? 'IMAGE',
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

class PostResponseDto {
  final String id;
  final String type;
  final String visibility;
  final String? content;
  final List<String> hashtags;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final PostAuthorDto author;
  final String? groupId;
  final List<PostMediaItemDto> media;
  final bool? isLiked;
  final bool? isSaved;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PostResponseDto({
    required this.id,
    required this.type,
    required this.visibility,
    this.content,
    required this.hashtags,
    required this.likesCount,
    required this.commentsCount,
    required this.viewsCount,
    required this.author,
    this.groupId,
    required this.media,
    this.isLiked,
    this.isSaved,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostResponseDto.fromJson(Map<String, dynamic> json) {
    // Safe author parsing
    PostAuthorDto author;
    final rawAuthor = json['author'];
    if (rawAuthor is Map) {
      try {
        final safeMap = rawAuthor is Map<String, dynamic>
            ? rawAuthor
            : rawAuthor.cast<String, dynamic>();
        author = PostAuthorDto.fromJson(safeMap);
      } catch (_) {
        author = PostAuthorDto.empty();
      }
    } else {
      author = PostAuthorDto.empty();
    }

    // Safe media list parsing
    final rawMedia = json['media'];
    final List<PostMediaItemDto> media;
    if (rawMedia is List) {
      media = rawMedia
          .whereType<Map<dynamic, dynamic>>()
          .map((item) {
            try {
              final safeMap = item is Map<String, dynamic>
                  ? item
                  : item.cast<String, dynamic>();
              return PostMediaItemDto.fromJson(safeMap);
            } catch (_) {
              return null;
            }
          })
          .whereType<PostMediaItemDto>()
          .toList();
    } else {
      media = [];
    }

    // Safe hashtags
    final rawHashtags = json['hashtags'];
    final hashtags = rawHashtags is List
        ? rawHashtags.whereType<String>().toList()
        : <String>[];

    // Safe dates
    DateTime parseDate(dynamic v) {
      try {
        if (v is String && v.isNotEmpty) return DateTime.parse(v);
      } catch (_) {}
      return DateTime.now();
    }

    return PostResponseDto(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'TEXT',
      visibility: json['visibility'] as String? ?? 'PUBLIC',
      content: json['content'] as String?,
      hashtags: hashtags,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      viewsCount: (json['viewsCount'] as num?)?.toInt() ?? 0,
      author: author,
      groupId: json['groupId'] as String?,
      media: media,
      isLiked: json['isLiked'] as bool?,
      isSaved: json['isSaved'] as bool?,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}
