// lib/features/profile/presentation/providers/profile_videos_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/home/data/video_repository.dart';
import 'package:mobile/features/home/domain/video_model.dart';

final profileVideosProvider = FutureProvider.family<List<VideoResponseDto>, String>((ref, userId) async {
  final repo = ref.watch(videoRepositoryProvider);
  try {
    final response = await repo.getUserVideos(userId: userId, page: 1, limit: 30);
    return response.data;
  } catch (_) {
    return [];
  }
});
