// lib/features/groups/presentation/screens/playlist_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/groups/domain/channel_playlist_dto.dart';
import 'package:mobile/features/groups/presentation/providers/playlist_detail_provider.dart';
import 'package:mobile/features/library/data/repositories/playlist_repository.dart';
import 'package:mobile/features/library/presentation/playlists_screen.dart';
import 'package:mobile/features/home/data/video_repository.dart';
import 'package:mobile/features/home/domain/video_model.dart';

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
        title: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('library.playlists'))),
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

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.playlist_add),
                      tooltip: 'Add videos to playlist',
                      onPressed: () => _showAddVideosSheet(
                        context,
                        ref,
                        playlist,
                        currentUserId,
                      ),
                    ),
                    PopupMenuButton<String>(
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
                  child: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('common.retry'))),
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
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (playlist.items.isNotEmpty)
                        FilledButton.icon(
                          onPressed: () => context.push(
                            '/video/${playlist.items.first.videoId}',
                          ),
                          icon: const Icon(Icons.play_arrow),
                          label: Consumer(
                            builder: (context, ref, child) =>
                                Text(ref.watch(trProvider)('video.play')),
                          ),
                        ),
                      if (isOwner)
                        FilledButton.tonalIcon(
                          onPressed: () => _showAddVideosSheet(
                            context,
                            ref,
                            playlist,
                            currentUserId,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Videos'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Videos List
          if (playlist.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
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
                    if (isOwner) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _showAddVideosSheet(
                          context,
                          ref,
                          playlist,
                          currentUserId,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Videos to Playlist'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else if (isOwner)
            SliverReorderableList(
              itemCount: playlist.items.length,
              onReorder: (oldIndex, newIndex) async {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final items = List<ChannelPlaylistItemDto>.from(playlist.items);
                final moved = items.removeAt(oldIndex);
                items.insert(newIndex, moved);
                final videoIds = items.map((e) => e.videoId).toList();
                try {
                  await ref
                      .read(playlistDetailProvider(playlistId).notifier)
                      .reorderVideos(videoIds);
                  ref.invalidate(myPlaylistsProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to reorder: $e')),
                    );
                  }
                }
              },
              itemBuilder: (context, index) {
                final item = playlist.items[index];
                return Material(
                  key: ValueKey(item.videoId),
                  color: Colors.transparent,
                  child: ListTile(
                    leading: Container(
                      width: 28,
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.titleSmall?.copyWith(
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
                            width: 72,
                            height: 42,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: item.videoThumbnailUrl != null
                                ? Image.network(
                                    item.videoThumbnailUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.play_circle_outline),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Remove from playlist',
                          onPressed: () async {
                            try {
                              await ref
                                  .read(
                                    playlistDetailProvider(playlistId).notifier,
                                  )
                                  .removeVideo(item.videoId);
                              ref.invalidate(myPlaylistsProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Removed "${item.videoTitle ?? "video"}" from playlist',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to remove: $e'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: Icon(Icons.drag_handle, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    onTap: () => context.push('/video/${item.videoId}'),
                  ),
                );
              },
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
                  trailing: ClipRRect(
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
          title: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('playlist.edit_title'))),
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
              child: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('common.cancel'))),
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
              child: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('common.save'))),
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
        title: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('playlist.delete_title'))),
        content: Text(
          'Are you sure you want to delete "${playlist.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('common.cancel'))),
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
            child: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('common.delete'))),
          ),
        ],
      ),
    );
  }

  void _showAddVideosSheet(
    BuildContext context,
    WidgetRef ref,
    ChannelPlaylistDto playlist,
    String? currentUserId,
  ) {
    if (currentUserId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddVideosSheet(
        playlist: playlist,
        userId: currentUserId,
      ),
    );
  }
}

class _AddVideosSheet extends ConsumerStatefulWidget {
  final ChannelPlaylistDto playlist;
  final String userId;

  const _AddVideosSheet({
    required this.playlist,
    required this.userId,
  });

  @override
  ConsumerState<_AddVideosSheet> createState() => _AddVideosSheetState();
}

class _AddVideosSheetState extends ConsumerState<_AddVideosSheet> {
  final Set<String> _pendingVideoIds = {};
  String _search = '';
  late Future<VideoListResponseDto> _videosFuture;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  void _loadVideos() {
    _videosFuture = ref.read(videoRepositoryProvider).getUserVideos(
      userId: widget.userId,
      limit: 50,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPlaylist =
        ref.watch(playlistDetailProvider(widget.playlist.id)).valueOrNull ??
        widget.playlist;
    final inPlaylistIds = currentPlaylist.items.map((i) => i.videoId).toSet();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 12,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Videos to Playlist',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.playlist.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextField(
                onChanged: (val) => setState(() => _search = val),
                decoration: InputDecoration(
                  hintText: 'Search your uploaded videos...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            FutureBuilder<VideoListResponseDto>(
              future: _videosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text('Failed to load your videos: ${snapshot.error}'),
                          const SizedBox(height: 8),
                          FilledButton.tonal(
                            onPressed: () => setState(() => _loadVideos()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allVideos = snapshot.data?.data ?? [];
                if (allVideos.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text('You have not uploaded any videos yet.'),
                    ),
                  );
                }

                final filteredVideos = _search.trim().isEmpty
                    ? allVideos
                    : allVideos
                        .where(
                          (v) => v.title.toLowerCase().contains(
                            _search.toLowerCase(),
                          ),
                        )
                        .toList();

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: filteredVideos.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final video = filteredVideos[idx];
                      final isAdded = inPlaylistIds.contains(video.id);
                      final isBusy = _pendingVideoIds.contains(video.id);

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 60,
                            height: 36,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: video.thumbnailUrl != null
                                ? Image.network(
                                    video.thumbnailUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(
                                    Icons.play_circle_outline,
                                    size: 20,
                                  ),
                          ),
                        ),
                        title: Text(
                          video.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: video.duration > 0
                            ? Text('${(video.duration / 60).floor()}m')
                            : null,
                        trailing: isBusy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : FilledButton.tonal(
                                style: FilledButton.styleFrom(
                                  backgroundColor: isAdded
                                      ? theme.colorScheme.primaryContainer
                                      : null,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                                onPressed: () async {
                                  setState(
                                    () => _pendingVideoIds.add(video.id),
                                  );
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  try {
                                    final notifier = ref.read(
                                      playlistDetailProvider(
                                        widget.playlist.id,
                                      ).notifier,
                                    );
                                    if (isAdded) {
                                      await notifier.removeVideo(video.id);
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Removed "${video.title}" from playlist',
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    } else {
                                      await notifier.addVideo(video.id);
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Added "${video.title}" to playlist',
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                    ref.invalidate(myPlaylistsProvider);
                                  } catch (e) {
                                    messenger.showSnackBar(
                                      SnackBar(content: Text('Failed: $e')),
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(
                                        () => _pendingVideoIds.remove(video.id),
                                      );
                                    }
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isAdded ? Icons.check : Icons.add,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(isAdded ? 'Added' : 'Add'),
                                  ],
                                ),
                              ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



