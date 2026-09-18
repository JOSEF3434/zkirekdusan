import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/home/data/video_repository.dart';
import 'package:mobile/features/home/presentation/widgets/video_management_sheet.dart';

final watchHistoryProvider = FutureProvider.autoDispose((ref) {
  final repo = ref.watch(videoRepositoryProvider);
  return repo.getWatchHistory(page: 1, limit: 50);
});

class WatchHistoryScreen extends ConsumerWidget {
  const WatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final historyAsync = ref.watch(watchHistoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('library.history')),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) async {
              if (val == 'clear') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(tr('library.clear_history_title')),
                    content: Text(tr('library.clear_history_msg')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(tr('common.cancel')),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(tr('library.clear_history_btn')),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    await ref.read(videoRepositoryProvider).clearWatchHistory();
                    ref.invalidate(watchHistoryProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr('library.history_cleared'))),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            tr('library.history_clear_failed', {
                              'error': e.toString(),
                            }),
                          ),
                        ),
                      );
                    }
                  }
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_sweep_outlined,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tr('library.clear_all_history'),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(watchHistoryProvider);
        },
        child: historyAsync.when(
          data: (response) {
            if (response.data.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('library.no_history'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('library.no_history_desc'),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: response.data.length,
              separatorBuilder: (ctx, idx) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final video = response.data[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 110,
                      height: 62,
                      color: Colors.grey.shade900,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (video.thumbnailUrl != null)
                            Image.network(
                              video.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => const Center(
                                child: Icon(
                                  Icons.play_circle_outline,
                                  color: Colors.white54,
                                ),
                              ),
                            )
                          else
                            const Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                color: Colors.white54,
                              ),
                            ),
                          if (video.duration > 0)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  _formatDuration(video.duration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  title: Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    '${video.author.displayName ?? video.author.username ?? tr("video.channel_fallback")} • ${video.viewsCount} views',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onPressed: () {
                      VideoManagementSheet.show(
                        context,
                        video: video,
                        onVideoDeleted: () =>
                            ref.invalidate(watchHistoryProvider),
                        onVideoUpdated: () =>
                            ref.invalidate(watchHistoryProvider),
                      );
                    },
                  ),
                  onTap: () => context.push('/video/${video.id}'),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    tr('library.history_load_failed'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => ref.invalidate(watchHistoryProvider),
                    child: Text(tr('common.retry')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0:00';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
