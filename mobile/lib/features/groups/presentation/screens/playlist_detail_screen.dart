// lib/features/groups/presentation/screens/playlist_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/groups/domain/channel_playlist_dto.dart';
import 'package:mobile/features/groups/presentation/providers/playlist_detail_provider.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playlistAsync = ref.watch(playlistDetailProvider(playlistId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlist'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: playlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                Text(
                  err.toString().replaceFirst('Exception: ', '').replaceFirst('Failure: ', ''),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.read(playlistDetailProvider(playlistId).notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (playlist) => _buildContent(context, ref, playlist),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ChannelPlaylistDto playlist,
  ) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () => ref.read(playlistDetailProvider(playlistId).notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          // Playlist Header Banner
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.title,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                  if (playlist.description != null && playlist.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      playlist.description!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (playlist.items.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () => context.push('/video/${playlist.items.first.videoId}'),
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
                    Icon(Icons.video_library_outlined, size: 48, color: theme.colorScheme.outline),
                    const SizedBox(height: 12),
                    Text('No videos in this playlist', style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
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
                    trailing: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 80,
                        height: 45,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: item.videoThumbnailUrl != null
                            ? Image.network(item.videoThumbnailUrl!, fit: BoxFit.cover)
                            : const Icon(Icons.play_circle_outline),
                      ),
                    ),
                    onTap: () => context.push('/video/${item.videoId}'),
                  );
                },
                childCount: playlist.items.length,
              ),
            ),
        ],
      ),
    );
  }
}
