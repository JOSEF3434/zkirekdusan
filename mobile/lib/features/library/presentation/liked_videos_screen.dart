// lib/features/library/presentation/liked_videos_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/home/data/video_repository.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/social/presentation/providers/likes_provider.dart';
import 'package:mobile/features/social/presentation/widgets/share_button.dart';

final likedVideosProvider = FutureProvider<VideoListResponseDto>((ref) async {
  final repo = ref.watch(videoRepositoryProvider);
  return repo.getLikedVideos(page: 1, limit: 50);
});

class LikedVideosScreen extends ConsumerWidget {
  const LikedVideosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final likedAsync = ref.watch(likedVideosProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('library.liked')),
      ),
      body: likedAsync.when(
        data: (response) {
          if (response.data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.thumb_up_alt_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No liked videos yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Videos you like will appear here.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(likedVideosProvider),
            child: ListView.builder(
              itemCount: response.data.length,
              itemBuilder: (context, index) {
                final video = response.data[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 100,
                      height: 56,
                      color: Colors.grey.shade900,
                      child: video.thumbnailUrl != null
                          ? Image.network(
                              video.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.play_circle_outline,
                                color: Colors.white54,
                              ),
                            )
                          : const Icon(
                              Icons.play_circle_outline,
                              color: Colors.white54,
                            ),
                    ),
                  ),
                  title: Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '${video.author.displayName ?? video.author.username ?? "Channel"} • ${video.viewsCount} views',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onPressed: () => _showOptionsSheet(context, ref, video),
                  ),
                  onTap: () => context.push('/video/${video.id}'),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                '${tr('state.error')}\n$err',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(likedVideosProvider),
                child: Text(tr('common.retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsSheet(BuildContext context, WidgetRef ref, VideoResponseDto video) {
    showModalBottomSheet(
      context: context,
      builder: (bContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Play Video'),
              onTap: () {
                Navigator.pop(bContext);
                context.push('/video/${video.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.thumb_down_outlined),
              title: const Text('Remove from Liked Videos'),
              onTap: () async {
                Navigator.pop(bContext);
                await ref.read(likesProvider.notifier).toggleLike(video.id, isVideo: true);
                ref.invalidate(likedVideosProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(bContext);
                ShareButton(postId: video.id, title: video.title);
              },
            ),
          ],
        ),
      ),
    );
  }
}
