// lib/features/groups/presentation/screens/tabs/group_playlists_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/groups/domain/group_context_dto.dart';
import 'package:mobile/features/groups/presentation/providers/channel_playlists_provider.dart';
import 'package:mobile/features/groups/presentation/widgets/channel_playlist_card.dart';

class GroupPlaylistsTab extends ConsumerWidget {
  final GroupContextDto groupContext;
  final VideoChannelSummaryDto? activeChannel;

  const GroupPlaylistsTab({
    super.key,
    required this.groupContext,
    required this.activeChannel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = activeChannel ?? groupContext.primaryChannel;
    final theme = Theme.of(context);

    if (channel == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_play, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('No video channel available', style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    final state = ref.watch(channelPlaylistsProvider(channel.id));

    if (state.isLoading && state.playlists.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () =>
                  ref.read(channelPlaylistsProvider(channel.id).notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.playlists.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(channelPlaylistsProvider(channel.id).notifier).refresh(),
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                children: [
                  Icon(Icons.playlist_play, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No playlists created yet', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Group playlists help organize channel videos into collections.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                  ),
                  if (groupContext.capabilities.canCreatePlaylist) ...[
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _showCreatePlaylistDialog(context, ref, channel),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Playlist'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1024 ? 3 : (width > 600 ? 2 : 1);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(channelPlaylistsProvider(channel.id).notifier).refresh(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
              ref.read(channelPlaylistsProvider(channel.id).notifier).loadMore();
            }
            return false;
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: crossAxisCount == 1 ? 16 / 12 : 16 / 13,
            ),
            itemCount: state.playlists.length + (state.isFetchingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.playlists.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final playlist = state.playlists[index];
              return ChannelPlaylistCard(playlist: playlist);
            },
          ),
        ),
      ),
      floatingActionButton: groupContext.capabilities.canCreatePlaylist
          ? FloatingActionButton.extended(
              onPressed: () => _showCreatePlaylistDialog(context, ref, channel),
              icon: const Icon(Icons.playlist_add),
              label: const Text('New Playlist'),
            )
          : null,
    );
  }

  void _showCreatePlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    VideoChannelSummaryDto channel,
  ) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Create Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Playlist Title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(dialogCtx);
              try {
                await ref
                    .read(channelPlaylistsProvider(channel.id).notifier)
                    .createPlaylist(
                      title: title,
                      description: descController.text.trim(),
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlist created successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
