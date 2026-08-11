// lib/features/home/domain/video_model.dart
import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/features/home/domain/feed_response.dart';

enum VideoStatus {
  uploading,
  queued,
  processing,
  ready,
  failed,
}

VideoStatus _parseStatus(String status) {
  switch (status.toUpperCase()) {
    case 'UPLOADING': return VideoStatus.uploading;
    case 'QUEUED': return VideoStatus.queued;
    case 'PROCESSING': return VideoStatus.processing;
    case 'READY': return VideoStatus.ready;
    case 'FAILED': return VideoStatus.failed;
    default: return VideoStatus.failed;
  }
}

class VideoRenditionDto {
  final String id;
  final String quality;
  final int resolution;
  final int bitrate;
  final String format;
  final String status;
  final String url;
  final DateTime createdAt;

  const VideoRenditionDto({
    required this.id,
    required this.quality,
    required this.resolution,
    required this.bitrate,
    required this.format,
    required this.status,
    required this.url,
    required this.createdAt,
  });

  factory VideoRenditionDto.fromJson(Map<String, dynamic> json) {
    return VideoRenditionDto(
      id: json['id'] as String? ?? '',
      quality: json['quality'] as String? ?? '',
      resolution: json['resolution'] as int? ?? 0,
      bitrate: json['bitrate'] as int? ?? 0,
      format: json['format'] as String? ?? '',
      status: json['status'] as String? ?? '',
      url: json['url'] as String? ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}

class VideoResponseDto {
  final String id;
  final String title;
  final String? description;
  final VideoStatus status;
  final String visibility;
  final int duration;
  final String? thumbnailUrl;
  final String? hlsUrl;
  final String? dashUrl;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final PostAuthorDto author; // Using existing author DTO
  final String? channelId;
  final List<VideoRenditionDto> renditions;
  final bool? isLiked;
  final bool? isSaved;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VideoResponseDto({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.visibility,
    this.duration = 0,
    this.thumbnailUrl,
    this.hlsUrl,
    this.dashUrl,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.author,
    this.channelId,
    this.renditions = const [],
    this.isLiked,
    this.isSaved,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VideoResponseDto.fromJson(Map<String, dynamic> json) {
    return VideoResponseDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String?,
      status: _parseStatus(json['status'] as String? ?? ''),
      visibility: json['visibility'] as String? ?? 'PUBLIC',
      duration: json['duration'] as int? ?? 0,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      hlsUrl: json['hlsUrl'] as String?,
      dashUrl: json['dashUrl'] as String?,
      viewsCount: json['viewsCount'] as int? ?? 0,
      likesCount: json['likesCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      author: PostAuthorDto.fromJson(json['author'] as Map<String, dynamic>? ?? {}),
      channelId: json['videoChannelId'] as String?,
      renditions: (json['renditions'] as List<dynamic>?)
          ?.map((e) => VideoRenditionDto.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      isLiked: json['isLiked'] as bool?,
      isSaved: json['isSaved'] as bool?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }
}

class VideoListResponseDto {
  final List<VideoResponseDto> data;
  final FeedMetaDto meta;

  const VideoListResponseDto({
    required this.data,
    required this.meta,
  });

  factory VideoListResponseDto.fromJson(Map<String, dynamic> json) {
    return VideoListResponseDto(
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => VideoResponseDto.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      meta: FeedMetaDto.fromJson(json['meta'] as Map<String, dynamic>? ?? {}),
    );
  }
}

enum VideoFeedCategory {
  all,
  trending,
  latest,
  education,
  music,
  gaming,
  live
}

extension VideoFeedCategoryExt on VideoFeedCategory {
  String get label {
    switch (this) {
      case VideoFeedCategory.all: return 'All';
      case VideoFeedCategory.trending: return 'Trending';
      case VideoFeedCategory.latest: return 'Latest';
      case VideoFeedCategory.education: return 'Education';
      case VideoFeedCategory.music: return 'Music';
      case VideoFeedCategory.gaming: return 'Gaming';
      case VideoFeedCategory.live: return 'Live';
    }
  }

  String? get apiCategory {
    switch (this) {
      case VideoFeedCategory.education: return 'EDUCATION';
      case VideoFeedCategory.music: return 'MUSIC';
      case VideoFeedCategory.gaming: return 'GAMING';
      case VideoFeedCategory.live: return 'LIVE';
      default: return null;
    }
  }
}
