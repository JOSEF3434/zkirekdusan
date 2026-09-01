// lib/features/profile/presentation/providers/profile_videos_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/features/home/data/video_repository.dart';
import 'package:mobile/features/home/domain/video_model.dart';

final profileVideosProvider =
    FutureProvider.family<List<VideoResponseDto>, String>((
      ref,
      userId,
    ) async {
      final repo = ref.watch(videoRepositoryProvider);
      try {
        final response = await repo.getUserVideos(
          userId: userId,
          page: 1,
          limit: 50,
          isStream: false,
        );
        return response.data;
      } catch (_) {
        return [];
      }
    });

final profileStreamsProvider =
    FutureProvider.family<List<VideoResponseDto>, String>((
      ref,
      userId,
    ) async {
      final repo = ref.watch(videoRepositoryProvider);
      final storage = ref.watch(storageServiceProvider);
      final cacheKey = 'cached_streams_$userId';

      try {
        final response = await repo.getUserStreams(
          userId: userId,
          page: 1,
          limit: 50,
        );
        // Cache streams locally in storage for offline access
        final listJson = response.data
            .map((v) => {
              'id': v.id,
              'title': v.title,
              'description': v.description,
              'status': v.status.name.toUpperCase(),
              'visibility': v.visibility,
              'duration': v.duration,
              'thumbnailUrl': v.thumbnailUrl,
              'hlsUrl': v.hlsUrl,
              'viewsCount': v.viewsCount,
              'likesCount': v.likesCount,
              'commentsCount': v.commentsCount,
              'isDownloadable': v.isDownloadable,
              'downloadPermission': v.downloadPermission,
              'channelId': v.channelId,
              'channelName': v.channelName,
              'uploadedById': v.uploadedById,
              'createdAt': v.createdAt.toIso8601String(),
              'updatedAt': v.updatedAt.toIso8601String(),
            })
            .toList();
        await storage.saveToken(jsonEncode(listJson), key: cacheKey);
        return response.data;
      } catch (_) {
        // Fallback to local cache if network fails
        final cached = await storage.getToken(key: cacheKey);
        if (cached != null) {
          try {
            final List<dynamic> decoded = jsonDecode(cached);
            return decoded
                .map((e) => VideoResponseDto.fromJson(e as Map<String, dynamic>))
                .toList();
          } catch (_) {}
        }
        return [];
      }
    });
