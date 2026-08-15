// lib/features/creator_analytics/domain/creator_video_dto.dart

/// Full VideoResponseDto mapping with all creator-visible fields.
class CreatorVideoDto {
  final String id;
  final String videoChannelId;
  final String uploadedById;
  final String title;
  final String slug;
  final String? description;
  final CreatorVideoStatus status;
  final CreatorVideoVisibility visibility;
  final List<String> categories;
  final List<String> tags;
  final List<String> hashtags;
  final String downloadPermission;
  final bool isDownloadable;
  final String viewsCount;
  final int likesCount;
  final int dislikesCount;
  final int commentsCount;
  final int sharesCount;
  final int bookmarksCount;
  final int downloadsCount;
  final DateTime? publishedAt;
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailUrl;
  final String? seoTitle;
  final String? seoDescription;

  const CreatorVideoDto({
    required this.id,
    required this.videoChannelId,
    required this.uploadedById,
    required this.title,
    required this.slug,
    this.description,
    required this.status,
    required this.visibility,
    required this.categories,
    required this.tags,
    required this.hashtags,
    required this.downloadPermission,
    required this.isDownloadable,
    required this.viewsCount,
    required this.likesCount,
    required this.dislikesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.bookmarksCount,
    required this.downloadsCount,
    this.publishedAt,
    this.scheduledAt,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailUrl,
    this.seoTitle,
    this.seoDescription,
  });

  factory CreatorVideoDto.fromJson(Map<String, dynamic> json) {
    return CreatorVideoDto(
      id: json['id'] as String? ?? '',
      videoChannelId: json['videoChannelId'] as String? ?? '',
      uploadedById: json['uploadedById'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      status: CreatorVideoStatus.fromString(json['status'] as String?),
      visibility: CreatorVideoVisibility.fromString(
        json['visibility'] as String?,
      ),
      categories: _parseStringList(json['categories']),
      tags: _parseStringList(json['tags']),
      hashtags: _parseStringList(json['hashtags']),
      downloadPermission:
          json['downloadPermission'] as String? ?? 'MEMBERS_ONLY',
      isDownloadable: json['isDownloadable'] as bool? ?? false,
      viewsCount: json['viewsCount']?.toString() ?? '0',
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      dislikesCount: (json['dislikesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      sharesCount: (json['sharesCount'] as num?)?.toInt() ?? 0,
      bookmarksCount: (json['bookmarksCount'] as num?)?.toInt() ?? 0,
      downloadsCount: (json['downloadsCount'] as num?)?.toInt() ?? 0,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'] as String)
          : null,
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'] as String)
          : null,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      seoTitle: json['seoTitle'] as String?,
      seoDescription: json['seoDescription'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'videoChannelId': videoChannelId,
    'uploadedById': uploadedById,
    'title': title,
    'slug': slug,
    if (description != null) 'description': description,
    'status': status.value,
    'visibility': visibility.value,
    'categories': categories,
    'tags': tags,
    'hashtags': hashtags,
    'downloadPermission': downloadPermission,
    'isDownloadable': isDownloadable,
    'viewsCount': viewsCount,
    'likesCount': likesCount,
    'dislikesCount': dislikesCount,
    'commentsCount': commentsCount,
    'sharesCount': sharesCount,
    'bookmarksCount': bookmarksCount,
    'downloadsCount': downloadsCount,
    if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
    if (scheduledAt != null) 'scheduledAt': scheduledAt!.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  CreatorVideoDto copyWith({
    String? title,
    String? description,
    CreatorVideoStatus? status,
    CreatorVideoVisibility? visibility,
    List<String>? categories,
    List<String>? tags,
    List<String>? hashtags,
    String? downloadPermission,
    bool? isDownloadable,
    String? seoTitle,
    String? seoDescription,
    DateTime? scheduledAt,
  }) => CreatorVideoDto(
    id: id,
    videoChannelId: videoChannelId,
    uploadedById: uploadedById,
    title: title ?? this.title,
    slug: slug,
    description: description ?? this.description,
    status: status ?? this.status,
    visibility: visibility ?? this.visibility,
    categories: categories ?? this.categories,
    tags: tags ?? this.tags,
    hashtags: hashtags ?? this.hashtags,
    downloadPermission: downloadPermission ?? this.downloadPermission,
    isDownloadable: isDownloadable ?? this.isDownloadable,
    viewsCount: viewsCount,
    likesCount: likesCount,
    dislikesCount: dislikesCount,
    commentsCount: commentsCount,
    sharesCount: sharesCount,
    bookmarksCount: bookmarksCount,
    downloadsCount: downloadsCount,
    publishedAt: publishedAt,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    thumbnailUrl: thumbnailUrl,
    seoTitle: seoTitle ?? this.seoTitle,
    seoDescription: seoDescription ?? this.seoDescription,
  );

  static List<String> _parseStringList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return [];
  }
}

enum CreatorVideoStatus {
  uploading('UPLOADING'),
  queued('QUEUED'),
  processing('PROCESSING'),
  ready('READY'),
  failed('FAILED'),
  deleted('DELETED');

  const CreatorVideoStatus(this.value);
  final String value;

  static CreatorVideoStatus fromString(String? s) {
    return CreatorVideoStatus.values.firstWhere(
      (e) => e.value == s?.toUpperCase(),
      orElse: () => CreatorVideoStatus.uploading,
    );
  }

  bool get isTerminal =>
      this == CreatorVideoStatus.ready || this == CreatorVideoStatus.failed;
  bool get isActive => this == CreatorVideoStatus.ready;
  bool get isProcessing =>
      this == CreatorVideoStatus.queued ||
      this == CreatorVideoStatus.processing ||
      this == CreatorVideoStatus.uploading;
  bool get canPublish => this == CreatorVideoStatus.ready;
  bool get canDelete => this != CreatorVideoStatus.deleted;
  bool get canRetry => this == CreatorVideoStatus.failed;
}

enum CreatorVideoVisibility {
  public('PUBLIC'),
  private('PRIVATE'),
  unlisted('UNLISTED'),
  groupOnly('GROUP_ONLY'),
  scheduled('SCHEDULED');

  const CreatorVideoVisibility(this.value);
  final String value;

  static CreatorVideoVisibility fromString(String? s) {
    return CreatorVideoVisibility.values.firstWhere(
      (e) => e.value == s?.toUpperCase(),
      orElse: () => CreatorVideoVisibility.private,
    );
  }
}
