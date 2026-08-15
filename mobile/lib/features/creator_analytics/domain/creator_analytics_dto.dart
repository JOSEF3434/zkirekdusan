// lib/features/creator_analytics/domain/creator_analytics_dto.dart

/// Channel analytics response from
/// GET /api/groups/{groupId}/video-channels/{channelId}/analytics
/// The schema is untyped in Swagger (200: {}), so we handle it defensively.
class CreatorChannelAnalyticsDto {
  final int totalVideos;
  final String totalViews;
  final int totalSubscribers;
  final int totalLikes;
  final int totalComments;
  final int totalShares;
  final int totalDownloads;
  // Raw map for any extra fields the backend may return
  final Map<String, dynamic> raw;

  const CreatorChannelAnalyticsDto({
    required this.totalVideos,
    required this.totalViews,
    required this.totalSubscribers,
    required this.totalLikes,
    required this.totalComments,
    required this.totalShares,
    required this.totalDownloads,
    required this.raw,
  });

  factory CreatorChannelAnalyticsDto.fromJson(Map<String, dynamic> json) {
    return CreatorChannelAnalyticsDto(
      totalVideos: (json['totalVideos'] as num?)?.toInt() ?? 0,
      totalViews: json['totalViews']?.toString() ?? '0',
      totalSubscribers:
          (json['totalSubscribers'] as num?)?.toInt() ??
          (json['subscribersCount'] as num?)?.toInt() ??
          0,
      totalLikes: (json['totalLikes'] as num?)?.toInt() ?? 0,
      totalComments: (json['totalComments'] as num?)?.toInt() ?? 0,
      totalShares: (json['totalShares'] as num?)?.toInt() ?? 0,
      totalDownloads: (json['totalDownloads'] as num?)?.toInt() ?? 0,
      raw: json,
    );
  }
}

/// Stream analytics from GET /api/streams/{streamId}/analytics
/// Also untyped in Swagger — handled defensively.
class CreatorStreamAnalyticsDto {
  final int peakViewers;
  final int totalViewers;
  final int chatMessagesCount;
  final int durationSeconds;
  final String? streamId;
  final Map<String, dynamic> raw;

  const CreatorStreamAnalyticsDto({
    required this.peakViewers,
    required this.totalViewers,
    required this.chatMessagesCount,
    required this.durationSeconds,
    this.streamId,
    required this.raw,
  });

  factory CreatorStreamAnalyticsDto.fromJson(Map<String, dynamic> json) {
    return CreatorStreamAnalyticsDto(
      peakViewers: (json['peakViewers'] as num?)?.toInt() ?? 0,
      totalViewers: (json['totalViewers'] as num?)?.toInt() ?? 0,
      chatMessagesCount: (json['chatMessagesCount'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      streamId: json['streamId'] as String?,
      raw: json,
    );
  }

  String get durationFormatted {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

/// Admin platform metrics from GET /api/admin/dashboard/metrics
class AdminDashboardMetricsDto {
  final int totalUsers;
  final int totalVideos;
  final int totalGroups;
  final int activeStreams;
  final Map<String, dynamic> raw;

  const AdminDashboardMetricsDto({
    required this.totalUsers,
    required this.totalVideos,
    required this.totalGroups,
    required this.activeStreams,
    required this.raw,
  });

  factory AdminDashboardMetricsDto.fromJson(Map<String, dynamic> json) {
    return AdminDashboardMetricsDto(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalVideos: (json['totalVideos'] as num?)?.toInt() ?? 0,
      totalGroups: (json['totalGroups'] as num?)?.toInt() ?? 0,
      activeStreams: (json['activeStreams'] as num?)?.toInt() ?? 0,
      raw: json,
    );
  }
}

/// Admin report from GET /api/admin/reports
class AdminReportDto {
  final String id;
  final String reason;
  final String? description;
  final String status;
  final String reportedContentType;
  final String? reportedContentId;
  final String? reportedById;
  final DateTime createdAt;

  const AdminReportDto({
    required this.id,
    required this.reason,
    this.description,
    required this.status,
    required this.reportedContentType,
    this.reportedContentId,
    this.reportedById,
    required this.createdAt,
  });

  factory AdminReportDto.fromJson(Map<String, dynamic> json) {
    return AdminReportDto(
      id: json['id'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      reportedContentType: json['reportedContentType'] as String? ?? '',
      reportedContentId: json['reportedContentId'] as String?,
      reportedById: json['reportedById'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
