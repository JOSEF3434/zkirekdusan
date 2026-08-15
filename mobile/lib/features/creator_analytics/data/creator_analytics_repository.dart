// lib/features/creator_analytics/data/creator_analytics_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/creator_analytics/domain/creator_analytics_dto.dart';
import 'package:mobile/features/creator_analytics/domain/creator_comment_dto.dart';
import 'package:mobile/features/creator_analytics/domain/creator_video_dto.dart';
import 'package:mobile/features/creator_analytics/domain/update_video_form.dart';

/// Safely cast any map-like to `Map<String, dynamic>`.
Map<String, dynamic> _toStringMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return raw.cast<String, dynamic>();
  return {};
}

final creatorAnalyticsRepositoryProvider = Provider<CreatorAnalyticsRepository>(
  (ref) {
    return CreatorAnalyticsRepository(ref.watch(apiClientProvider));
  },
);

class PaginatedVideos {
  final List<CreatorVideoDto> items;
  final String? nextCursor;
  final bool hasMore;

  const PaginatedVideos({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });
}

class PaginatedComments {
  final List<CreatorCommentDto> items;
  final bool hasNextPage;
  final int currentPage;

  const PaginatedComments({
    required this.items,
    required this.hasNextPage,
    required this.currentPage,
  });
}

class PaginatedReports {
  final List<AdminReportDto> items;
  final bool hasNextPage;
  final int currentPage;

  const PaginatedReports({
    required this.items,
    required this.hasNextPage,
    required this.currentPage,
  });
}

class CreatorAnalyticsRepository {
  final Dio _dio;
  CreatorAnalyticsRepository(this._dio);

  // ─── Video Management ────────────────────────────────────────────────────

  Future<PaginatedVideos> getChannelVideos({
    required String channelId,
    String? cursor,
    String? status,
    String? search,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'cursor': cursor,
      'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final response = await _dio.get(
      '/video-channels/$channelId/videos',
      queryParameters: params,
    );

    final map = parsePaginatedEnvelope(response.data);
    final itemsJson = (map['data'] as List?) ?? [];
    final items = itemsJson
        .map((e) => CreatorVideoDto.fromJson(_toStringMap(e)))
        .toList();

    final meta = _toStringMap(map['meta']);
    final nextCursor = meta['nextCursor'] as String?;
    final totalPages = (meta['totalPages'] as num?)?.toInt();
    final currentPage = (meta['currentPage'] as num?)?.toInt() ?? 1;

    return PaginatedVideos(
      items: items,
      nextCursor: nextCursor,
      hasMore:
          nextCursor != null ||
          (totalPages != null && currentPage < totalPages) ||
          (nextCursor == null && totalPages == null && items.length == limit),
    );
  }

  Future<CreatorVideoDto> getVideo({
    required String channelId,
    required String videoId,
  }) async {
    final response = await _dio.get(
      '/video-channels/$channelId/videos/$videoId',
    );
    final data = parseEnvelope(response.data);
    return CreatorVideoDto.fromJson(data);
  }

  Future<CreatorVideoDto> updateVideo({
    required String channelId,
    required String videoId,
    required UpdateVideoForm form,
  }) async {
    final response = await _dio.patch(
      '/video-channels/$channelId/videos/$videoId',
      data: form.toJson(),
    );
    final data = parseEnvelope(response.data);
    return CreatorVideoDto.fromJson(data);
  }

  Future<void> deleteVideo({
    required String channelId,
    required String videoId,
  }) async {
    await _dio.delete('/video-channels/$channelId/videos/$videoId');
  }

  Future<void> publishVideo({
    required String channelId,
    required String videoId,
  }) async {
    await _dio.post('/video-channels/$channelId/videos/$videoId/publish');
  }

  Future<void> reprocessVideo({required String videoId}) async {
    await _dio.post('/video-processing/$videoId/reprocess');
  }

  // ─── Analytics ───────────────────────────────────────────────────────────

  Future<CreatorChannelAnalyticsDto> getChannelAnalytics({
    required String groupId,
    required String channelId,
  }) async {
    final response = await _dio.get(
      '/groups/$groupId/video-channels/$channelId/analytics',
    );
    final data = parseEnvelope(response.data);
    return CreatorChannelAnalyticsDto.fromJson(data);
  }

  Future<CreatorStreamAnalyticsDto> getStreamAnalytics({
    required String streamId,
  }) async {
    final response = await _dio.get('/streams/$streamId/analytics');
    final data = parseEnvelope(response.data);
    return CreatorStreamAnalyticsDto.fromJson(data);
  }

  Future<AdminDashboardMetricsDto> getAdminMetrics() async {
    final response = await _dio.get('/admin/dashboard/metrics');
    final data = parseEnvelope(response.data);
    return AdminDashboardMetricsDto.fromJson(data);
  }

  // ─── Comment Moderation ──────────────────────────────────────────────────

  Future<PaginatedComments> getVideoComments({
    required String videoId,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/videos/$videoId/comments',
      queryParameters: {'page': page, 'limit': limit},
    );
    final map = parsePaginatedEnvelope(response.data);
    final items = ((map['data'] as List?) ?? [])
        .map(
          (e) => CreatorCommentDto.fromJson(
            e as Map<String, dynamic>,
            videoId: videoId,
          ),
        )
        .toList();

    final meta = map['meta'] as Map<String, dynamic>? ?? {};
    final totalPages = (meta['totalPages'] as num?)?.toInt();
    final currentPage = (meta['currentPage'] as num?)?.toInt() ?? page;

    return PaginatedComments(
      items: items,
      hasNextPage: totalPages != null
          ? currentPage < totalPages
          : items.length == limit,
      currentPage: currentPage,
    );
  }

  Future<void> deleteComment({
    required String videoId,
    required String commentId,
  }) async {
    await _dio.delete('/videos/$videoId/comments/$commentId');
  }

  Future<void> togglePinComment({
    required String videoId,
    required String commentId,
  }) async {
    await _dio.post('/videos/$videoId/comments/$commentId/pin');
  }

  // ─── Admin Moderation ────────────────────────────────────────────────────

  Future<PaginatedReports> getAdminReports({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/admin/reports',
      queryParameters: {'page': page, 'limit': limit},
    );
    final map = parsePaginatedEnvelope(response.data);
    final items = ((map['data'] as List?) ?? [])
        .map((e) => AdminReportDto.fromJson(e as Map<String, dynamic>))
        .toList();

    final meta = map['meta'] as Map<String, dynamic>? ?? {};
    final totalPages = (meta['totalPages'] as num?)?.toInt();
    final currentPage = (meta['currentPage'] as num?)?.toInt() ?? page;

    return PaginatedReports(
      items: items,
      hasNextPage: totalPages != null
          ? currentPage < totalPages
          : items.length == limit,
      currentPage: currentPage,
    );
  }

  Future<void> resolveReport({required String reportId}) async {
    await _dio.patch('/admin/reports/$reportId/resolve');
  }
}
