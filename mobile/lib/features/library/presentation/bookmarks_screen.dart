// lib/features/library/presentation/bookmarks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/home/data/video_repository.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/social/presentation/providers/save_provider.dart';

final bookmarkedVideosProvider = FutureProvider<VideoListResponseDto>((
  ref,
) async {
  final repo = ref.watch(videoRepositoryProvider);
  return repo.getBookmarks(page: 1, limit: 50);
});

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final bookmarksAsync = ref.watch(bookmarkedVideosProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(tr('library.bookmarks'))),
      body: bookmarksAsync.when(
        data: (response) {
          if (response.data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('library.no_saved'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('library.no_saved_desc'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(bookmarkedVideosProvider),
            child: ListView.builder(
              itemCount: response.data.length,
              itemBuilder: (context, index) {
                final video = response.data[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
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
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '${video.author.displayName ?? video.author.username ?? tr("library.channel_fallback")} • ${video.viewsCount} views',
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
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('${tr('state.error')}\n$err', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(bookmarkedVideosProvider),
                child: Text(tr('common.retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsSheet(
    BuildContext context,
    WidgetRef ref,
    VideoResponseDto video,
  ) {
    final tr = ref.read(trProvider);
    showModalBottomSheet(
      context: context,
      builder: (bContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: Text(tr('library.play_video')),
              onTap: () {
                Navigator.pop(bContext);
                context.push('/video/${video.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_remove_outlined),
              title: Text(tr('library.remove_from_saved')),
              onTap: () async {
                Navigator.pop(bContext);
                await ref
                    .read(saveProvider.notifier)
                    .toggleSave(video.id, isVideo: true);
                ref.invalidate(bookmarkedVideosProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}
