// lib/features/groups/presentation/screens/playlist_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/groups/domain/channel_playlist_dto.dart';
import 'package:mobile/features/groups/presentation/providers/playlist_detail_provider.dart';
import 'package:mobile/features/library/data/repositories/playlist_repository.dart';
import 'package:mobile/features/library/presentation/playlists_screen.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playlistAsync = ref.watch(playlistDetailProvider(playlistId));
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (playlistAsync.valueOrNull != null) ...[
            Builder(
              builder: (ctx) {
                final playlist = playlistAsync.valueOrNull!;
                final isOwner =
                    currentUserId != null &&
                    (currentUserId == playlist.ownerId ||
                        authState.user?.role == 'ADMIN' ||
                        authState.user?.role == 'SUPER_ADMIN');

                if (!isOwner) return const SizedBox.shrink();

                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showEditPlaylistDialog(context, ref, playlist);
                    } else if (val == 'delete') {
                      _showDeleteConfirmDialog(context, ref, playlist);
                    }
                  },
                  itemBuilder: (popupCtx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('Edit Playlist Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Delete Playlist',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
      body: playlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  err
                      .toString()
                      .replaceFirst('Exception: ', '')
                      .replaceFirst('Failure: ', ''),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref
                      .read(playlistDetailProvider(playlistId).notifier)
                      .refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (playlist) => _buildContent(context, ref, playlist, currentUserId),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ChannelPlaylistDto playlist,
    String? currentUserId,
  ) {
    final theme = Theme.of(context);
    final isOwner =
        currentUserId != null &&
        (currentUserId == playlist.ownerId);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(playlistDetailProvider(playlistId).notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          // Playlist Header Banner
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (playlist.ownerUsername != null)
                    Text(
                      'Created by @${playlist.ownerUsername}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${playlist.videosCount} ${playlist.videosCount == 1 ? "video" : "videos"} • ${playlist.visibility}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  if (playlist.description != null &&
                      playlist.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      playlist.description!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (playlist.items.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () => context.push(
                        '/video/${playlist.items.first.videoId}',
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play All'),
                    ),
                ],
              ),
            ),
          ),
          // Videos List
          if (playlist.items.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No videos in this playlist',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = playlist.items[index];
                return ListTile(
                  leading: Container(
                    width: 32,
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    item.videoTitle ?? 'Video',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: item.videoDuration != null
                      ? Text('${(item.videoDuration! / 60).floor()}m')
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 80,
                          height: 45,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: item.videoThumbnailUrl != null
                              ? Image.network(
                                  item.videoThumbnailUrl!,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.play_circle_outline),
                        ),
                      ),
                      if (isOwner)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: 'Remove from playlist',
                          onPressed: () async {
                            try {
                              await ref
                                  .read(playlistDetailProvider(playlistId).notifier)
                                  .removeVideo(item.videoId);
                              ref.invalidate(myPlaylistsProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Removed video from playlist')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to remove: $e')),
                                );
                              }
                            }
                          },
                        ),
                    ],
                  ),
                  onTap: () => context.push('/video/${item.videoId}'),
                );
              }, childCount: playlist.items.length),
            ),
        ],
      ),
    );
  }

  void _showEditPlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    ChannelPlaylistDto playlist,
  ) {
    final titleCtrl = TextEditingController(text: playlist.title);
    final descCtrl = TextEditingController(text: playlist.description ?? '');
    String visibility = playlist.visibility;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Playlist'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: visibility,
                  decoration: const InputDecoration(
                    labelText: 'Visibility',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'PUBLIC', child: Text('Public')),
                    DropdownMenuItem(value: 'UNLISTED', child: Text('Unlisted')),
                    DropdownMenuItem(value: 'PRIVATE', child: Text('Private')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => visibility = val);
                  },
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
                final newTitle = titleCtrl.text.trim();
                if (newTitle.isEmpty) return;
                Navigator.pop(dialogCtx);
                try {
                  await ref.read(playlistRepositoryProvider).updatePlaylist(
                    playlist.id,
                    title: newTitle,
                    description: descCtrl.text.trim(),
                    visibility: visibility,
                  );
                  ref.read(playlistDetailProvider(playlist.id).notifier).refresh();
                  ref.invalidate(myPlaylistsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Playlist updated')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update playlist: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    ChannelPlaylistDto playlist,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Playlist?'),
        content: Text(
          'Are you sure you want to delete "${playlist.title}"? This action cannot be undone.',
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
              try {
                await ref
                    .read(playlistDetailProvider(playlist.id).notifier)
                    .deletePlaylist();
                ref.invalidate(myPlaylistsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlist deleted')),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete playlist: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
