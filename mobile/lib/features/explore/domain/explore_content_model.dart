// lib/features/explore/domain/explore_content_model.dart
// Typed models for the GET /explore response from backend.

import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/explore/domain/search_model.dart';

/// Video channel model returned in the explore channels section.
class ExploreChannelDto {
  final String id;
  final String? name;
  final String? description;
  final String? avatarUrl;
  final int subscribersCount;

  const ExploreChannelDto({
    required this.id,
    this.name,
    this.description,
    this.avatarUrl,
    this.subscribersCount = 0,
  });

  factory ExploreChannelDto.fromJson(Map<String, dynamic> json) {
    return ExploreChannelDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      description: json['description'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      subscribersCount: json['subscribersCount'] as int? ?? 0,
    );
  }
}

/// Live stream summary for the Explore "Live Now" & "Scheduled" sections.
class ExploreStreamDto {
  final String id;
  final String? title;
  final String? status;
  final int viewerCount;
  final String? creatorUsername;
  final String? createdById;
  final String? videoChannelId;
  final String? scheduledAt;
  final String? startedAt;
  final String? thumbnailUrl;
  final String? hlsUrl;
  final String? channelName;

  const ExploreStreamDto({
    required this.id,
    this.title,
    this.status,
    this.viewerCount = 0,
    this.creatorUsername,
    this.createdById,
    this.videoChannelId,
    this.scheduledAt,
    this.startedAt,
    this.thumbnailUrl,
    this.hlsUrl,
    this.channelName,
  });

  bool get isLive => status?.toUpperCase() == 'LIVE';
  bool get isScheduled => status?.toUpperCase() == 'SCHEDULED';

  DateTime? get scheduledDateTime =>
      scheduledAt != null ? DateTime.tryParse(scheduledAt!) : null;

  bool get isDueToStart =>
      isScheduled &&
      scheduledDateTime != null &&
      DateTime.now().isAfter(scheduledDateTime!);

  bool get effectivelyLive => isLive || isDueToStart;

  ExploreStreamDto copyWith({
    String? id,
    String? title,
    String? status,
    int? viewerCount,
    String? creatorUsername,
    String? createdById,
    String? videoChannelId,
    String? scheduledAt,
    String? startedAt,
    String? thumbnailUrl,
    String? hlsUrl,
    String? channelName,
  }) {
    return ExploreStreamDto(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      viewerCount: viewerCount ?? this.viewerCount,
      creatorUsername: creatorUsername ?? this.creatorUsername,
      createdById: createdById ?? this.createdById,
      videoChannelId: videoChannelId ?? this.videoChannelId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      hlsUrl: hlsUrl ?? this.hlsUrl,
      channelName: channelName ?? this.channelName,
    );
  }

  factory ExploreStreamDto.fromJson(Map<String, dynamic> json) {
    final createdBy = json['createdBy'] as Map<String, dynamic>?;
    final videoChannel = json['videoChannel'] as Map<String, dynamic>?;
    return ExploreStreamDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String?,
      status: json['status'] as String?,
      viewerCount: json['currentViewerCount'] as int? ?? 0,
      creatorUsername: createdBy?['username'] as String?,
      createdById: (json['createdById'] as String?) ?? (createdBy?['id'] as String?),
      videoChannelId: (json['videoChannelId'] as String?) ?? (videoChannel?['id'] as String?),
      scheduledAt: json['scheduledAt'] as String?,
      startedAt: json['startedAt'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      hlsUrl: json['hlsUrl'] as String?,
      channelName: videoChannel?['name'] as String?,
    );
  }
}

/// Aggregated explore content returned by `GET /explore`.
class ExploreContentDto {
  final List<VideoResponseDto> trendingVideos;
  final List<ExploreChannelDto> trendingChannels;
  final List<ExploreStreamDto> trendingStreams;
  final List<SearchReelDto> trendingReels;

  const ExploreContentDto({
    this.trendingVideos = const [],
    this.trendingChannels = const [],
    this.trendingStreams = const [],
    this.trendingReels = const [],
  });

  factory ExploreContentDto.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(dynamic raw, T Function(Map<String, dynamic>) f) {
      if (raw == null || raw is! List) return const [];
      final result = <T>[];
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          try {
            result.add(f(item));
          } catch (_) {}
        }
      }
      return result;
    }

    return ExploreContentDto(
      trendingVideos: parseList(
        json['trendingVideos'],
        VideoResponseDto.fromJson,
      ),
      trendingChannels: parseList(
        json['trendingChannels'],
        ExploreChannelDto.fromJson,
      ),
      trendingStreams: parseList(
        json['trendingStreams'],
        ExploreStreamDto.fromJson,
      ),
      trendingReels: parseList(json['trendingReels'], SearchReelDto.fromJson),
    );
  }
}
