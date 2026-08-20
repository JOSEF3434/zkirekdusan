// lib/features/stories/data/models/story_model.dart

class StoryAuthorModel {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  const StoryAuthorModel({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  String get effectiveName {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!;
    }
    if (username != null && username!.trim().isNotEmpty) {
      return username!;
    }
    return 'User';
  }

  factory StoryAuthorModel.fromJson(Map<String, dynamic> json) {
    return StoryAuthorModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
    };
  }
}

class StoryModel {
  final String id;
  final String type; // 'IMAGE' | 'VIDEO' | 'TEXT'
  final String? mediaUrl;
  final String? content;
  final String? backgroundColor;
  final String? textColor;
  final int viewsCount;
  final int reactionsCount;
  final int commentsCount;
  final bool hasViewedByMe;
  final String? myReaction;
  final StoryAuthorModel author;
  final DateTime expiresAt;
  final DateTime createdAt;

  const StoryModel({
    required this.id,
    required this.type,
    this.mediaUrl,
    this.content,
    this.backgroundColor,
    this.textColor,
    this.viewsCount = 0,
    this.reactionsCount = 0,
    this.commentsCount = 0,
    this.hasViewedByMe = false,
    this.myReaction,
    required this.author,
    required this.expiresAt,
    required this.createdAt,
  });

  bool get isVideo => type.toUpperCase() == 'VIDEO';
  bool get isImage => type.toUpperCase() == 'IMAGE';
  bool get isText => type.toUpperCase() == 'TEXT';
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  StoryModel copyWith({
    String? id,
    String? type,
    String? mediaUrl,
    String? content,
    String? backgroundColor,
    String? textColor,
    int? viewsCount,
    int? reactionsCount,
    int? commentsCount,
    bool? hasViewedByMe,
    String? myReaction,
    StoryAuthorModel? author,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return StoryModel(
      id: id ?? this.id,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      content: content ?? this.content,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      viewsCount: viewsCount ?? this.viewsCount,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      hasViewedByMe: hasViewedByMe ?? this.hasViewedByMe,
      myReaction: myReaction ?? this.myReaction,
      author: author ?? this.author,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'IMAGE',
      mediaUrl: json['mediaUrl'] as String?,
      content: json['content'] as String?,
      backgroundColor: json['backgroundColor'] as String?,
      textColor: json['textColor'] as String?,
      viewsCount: (json['viewsCount'] as num?)?.toInt() ?? 0,
      reactionsCount: (json['reactionsCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      hasViewedByMe: json['hasViewedByMe'] as bool? ?? false,
      myReaction: json['myReaction'] as String?,
      author: StoryAuthorModel.fromJson(
        json['author'] as Map<String, dynamic>? ?? {},
      ),
      expiresAt:
          DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
          DateTime.now().add(const Duration(hours: 24)),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'mediaUrl': mediaUrl,
      'content': content,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'viewsCount': viewsCount,
      'reactionsCount': reactionsCount,
      'commentsCount': commentsCount,
      'hasViewedByMe': hasViewedByMe,
      'myReaction': myReaction,
      'author': author.toJson(),
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
