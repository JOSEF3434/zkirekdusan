// lib/features/library/domain/playlist_dto.dart

class PlaylistItemDto {
  final String id;
  final int order;
  final String videoId;
  final String? videoTitle;
  final String? videoThumbnailUrl;
  final double? videoDuration;
  final int? videoViewsCount;

  const PlaylistItemDto({
    required this.id,
    this.order = 0,
    required this.videoId,
    this.videoTitle,
    this.videoThumbnailUrl,
    this.videoDuration,
    this.videoViewsCount,
  });

  factory PlaylistItemDto.fromJson(Map<String, dynamic> json) {
    final video = json['video'] as Map<String, dynamic>?;
    return PlaylistItemDto(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      videoId: json['videoId'] as String? ?? video?['id'] as String? ?? '',
      videoTitle: video?['title'] as String?,
      videoThumbnailUrl: video?['thumbnailUrl'] as String?,
      videoDuration: (video?['duration'] as num?)?.toDouble(),
      videoViewsCount: video?['viewsCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order': order,
    'videoId': videoId,
    'videoTitle': videoTitle,
    'videoThumbnailUrl': videoThumbnailUrl,
    'videoDuration': videoDuration,
    'videoViewsCount': videoViewsCount,
  };
}

class PlaylistDto {
  final String id;
  final String ownerId;
  final String? ownerUsername;
  final String title;
  final String? description;
  final String visibility;
  final int videosCount;
  final String? videoChannelId;
  final String? channelName;
  final List<PlaylistItemDto> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Compatibility getter for older references to userId or privacy
  String get userId => ownerId;
  String get privacy => visibility.toLowerCase();

  const PlaylistDto({
    required this.id,
    required this.ownerId,
    this.ownerUsername,
    required this.title,
    this.description,
    this.visibility = 'PUBLIC',
    this.videosCount = 0,
    this.videoChannelId,
    this.channelName,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlaylistDto.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    final channel = json['videoChannel'] as Map<String, dynamic>?;
    final rawItems = (json['items'] as List<dynamic>?) ?? [];

    final items = rawItems
        .map((e) => PlaylistItemDto.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final visibility =
        json['visibility'] as String? ??
        json['privacy'] as String? ??
        'PUBLIC';

    final ownerId =
        json['ownerId'] as String? ??
        json['userId'] as String? ??
        owner?['id'] as String? ??
        '';

    return PlaylistDto(
      id: json['id'] as String? ?? '',
      ownerId: ownerId,
      ownerUsername:
          owner?['username'] as String? ?? json['ownerUsername'] as String?,
      title: json['title'] as String? ?? 'Untitled Playlist',
      description: json['description'] as String?,
      visibility: visibility.toUpperCase(),
      videosCount: json['videosCount'] as int? ?? items.length,
      videoChannelId:
          json['videoChannelId'] as String? ?? channel?['id'] as String?,
      channelName:
          channel?['name'] as String? ?? json['channelName'] as String?,
      items: items,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'ownerUsername': ownerUsername,
    'title': title,
    'description': description,
    'visibility': visibility,
    'videosCount': videosCount,
    'videoChannelId': videoChannelId,
    'channelName': channelName,
    'items': items.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
