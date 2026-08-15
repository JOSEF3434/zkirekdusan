// lib/features/creator_analytics/domain/creator_comment_dto.dart

class CreatorCommentDto {
  final String id;
  final String videoId;
  final String? parentId;
  final String content;
  final int likesCount;
  final bool isPinned;
  final CreatorCommentAuthorDto author;
  final DateTime createdAt;

  const CreatorCommentDto({
    required this.id,
    required this.videoId,
    this.parentId,
    required this.content,
    required this.likesCount,
    required this.isPinned,
    required this.author,
    required this.createdAt,
  });

  factory CreatorCommentDto.fromJson(
    Map<String, dynamic> json, {
    String videoId = '',
  }) {
    return CreatorCommentDto(
      id: json['id'] as String? ?? '',
      videoId: (json['videoId'] ?? videoId) as String? ?? '',
      parentId: json['parentId'] as String?,
      content: json['content'] as String? ?? '',
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
      author: CreatorCommentAuthorDto.fromJson(
        json['author'] as Map<String, dynamic>? ?? {},
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  CreatorCommentDto copyWith({bool? isPinned}) => CreatorCommentDto(
    id: id,
    videoId: videoId,
    parentId: parentId,
    content: content,
    likesCount: likesCount,
    isPinned: isPinned ?? this.isPinned,
    author: author,
    createdAt: createdAt,
  );
}

class CreatorCommentAuthorDto {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  const CreatorCommentAuthorDto({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory CreatorCommentAuthorDto.fromJson(Map<String, dynamic> json) {
    return CreatorCommentAuthorDto(
      id: json['id'] as String? ?? '',
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  String get displayHandle => displayName ?? username ?? id;
}
