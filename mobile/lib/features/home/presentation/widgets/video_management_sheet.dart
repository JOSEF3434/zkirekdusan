// lib/features/home/presentation/widgets/video_management_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/download_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/home/data/video_repository.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/social/presentation/providers/save_provider.dart';
import 'package:mobile/features/social/presentation/widgets/share_button.dart';
import 'package:mobile/features/library/presentation/widgets/save_to_playlist_sheet.dart';

class VideoManagementSheet extends ConsumerWidget {
  final VideoResponseDto video;
  final VoidCallback? onVideoDeleted;
  final VoidCallback? onVideoUpdated;

  const VideoManagementSheet({
    super.key,
    required this.video,
    this.onVideoDeleted,
    this.onVideoUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required VideoResponseDto video,
    VoidCallback? onVideoDeleted,
    VoidCallback? onVideoUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => VideoManagementSheet(
        video: video,
        onVideoDeleted: onVideoDeleted,
        onVideoUpdated: onVideoUpdated,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id;
    final isAuthor = currentUserId != null &&
        (currentUserId == video.author.id ||
            currentUserId == video.uploadedById ||
            authState.user?.role == 'ADMIN' ||
            authState.user?.role == 'SUPER_ADMIN');
    final saveStateMap = ref.watch(saveProvider);
    final isSaved = saveStateMap[video.id] ?? (video.isSaved ?? false);
    final theme = Theme.of(context);
    final downloadUrl = video.renditions.isNotEmpty
        ? video.renditions.first.url
        : (video.hlsUrl ?? video.dashUrl);
    final canDownload = video.isDownloadable &&
        downloadUrl != null &&
        downloadUrl.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 50,
                      height: 32,
                      color: Colors.grey.shade900,
                      child: video.thumbnailUrl != null
                          ? Image.network(
                              video.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.play_circle_outline,
                                size: 18,
                                color: Colors.white54,
                              ),
                            )
                          : const Icon(
                              Icons.play_circle_outline,
                              size: 18,
                              color: Colors.white54,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${video.author.displayName ?? video.author.username ?? "Channel"} • ${video.viewsCount} views',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),

            // ── Creator / Author Actions ──────────────────────────────────
            if (isAuthor) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Video Details'),
                subtitle: const Text('Title, description, and visibility'),
                onTap: () => _showEditVideoDialog(context, ref),
              ),
              if (video.channelId != null) ...[
                ListTile(
                  leading: const Icon(Icons.analytics_outlined),
                  title: const Text('Video Analytics'),
                  subtitle: const Text('Views, watch time, and engagement'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(
                      '/creator/dashboard/channel/${video.channelId}/analytics',
                      extra: {
                        'groupId': '',
                        'channelName': video.channelName ?? 'Channel',
                      },
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.comment_outlined),
                  title: const Text('Moderate Comments'),
                  subtitle: const Text('Review and filter viewer comments'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(
                      '/creator/dashboard/video/${video.channelId}/${video.id}/comments',
                    );
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Video', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Permanently delete this video'),
                onTap: () => _showDeleteConfirmDialog(context, ref),
              ),
              const Divider(height: 16),
            ],

            // ── Viewer / General Actions ────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('Play Video'),
              onTap: () {
                Navigator.pop(context);
                context.push('/video/${video.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Download Offline'),
              enabled: canDownload,
              subtitle: !canDownload
                  ? const Text('Download disabled for this video')
                  : null,
              onTap: () {
                Navigator.pop(context);
                if (canDownload) {
                  ref.read(downloadServiceProvider.notifier).startDownload(
                    videoId: video.id,
                    url: downloadUrl,
                    title: video.title,
                    thumbnailUrl: video.thumbnailUrl,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Starting download...')),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Download not available for this video'),
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Save to Playlist'),
              subtitle: const Text('Add or remove from your playlists'),
              onTap: () {
                Navigator.pop(context);
                SaveToPlaylistSheet.show(
                  context,
                  videoId: video.id,
                  videoTitle: video.title,
                );
              },
            ),
            ListTile(
              leading: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? Colors.amber : null,
              ),
              title: Text(isSaved ? 'Remove from Saved' : 'Save / Bookmark Video'),
              subtitle: const Text('Save to your watch later & bookmarks'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(saveProvider.notifier).toggleSave(video.id, isVideo: true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isSaved ? 'Removed from saved' : 'Saved to library',
                      ),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share Video'),
              onTap: () {
                Navigator.pop(context);
                ShareButton(postId: video.id, title: video.title);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(
                  ClipboardData(text: 'https://zikrekidusan.onrender.com/video/${video.id}'),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Video link copied to clipboard')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditVideoDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController(text: video.title);
    final descController = TextEditingController(text: video.description ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Video Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Video Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newTitle = titleController.text.trim();
              final newDesc = descController.text.trim();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogCtx);
              if (context.mounted) {
                Navigator.pop(context);
              }
              try {
                final dio = ref.read(apiClientProvider);
                final channelId = video.channelId;
                if (channelId != null && channelId.isNotEmpty) {
                  await dio.patch(
                    '/video-channels/$channelId/videos/${video.id}',
                    data: {
                      'title': newTitle,
                      'description': newDesc,
                    },
                  );
                } else {
                  await dio.patch(
                    '/videos/${video.id}',
                    data: {
                      'title': newTitle,
                      'description': newDesc,
                    },
                  );
                }
                onVideoUpdated?.call();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Video updated successfully')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to update video: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Video?'),
        content: Text(
          'Are you sure you want to delete "${video.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              if (context.mounted) {
                Navigator.pop(context);
              }
              try {
                final repo = ref.read(videoRepositoryProvider);
                await repo.deleteVideo(video.id, channelId: video.channelId);
                onVideoDeleted?.call();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Video deleted successfully')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to delete video: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
