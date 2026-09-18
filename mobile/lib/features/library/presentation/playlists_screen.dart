// lib/features/library/presentation/playlists_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/library/data/repositories/playlist_repository.dart';
import 'package:mobile/features/library/domain/playlist_dto.dart';

final myPlaylistsProvider = FutureProvider<List<PlaylistDto>>((ref) {
  final repo = ref.watch(playlistRepositoryProvider);
  return repo.getMyPlaylists();
});

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final playlistsAsync = ref.watch(myPlaylistsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('library.playlists')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: tr('playlist.new_tooltip'),
            onPressed: () => _showCreatePlaylistDialog(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myPlaylistsProvider),
        child: playlistsAsync.when(
          data: (playlists) {
            if (playlists.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.playlist_add,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr('playlist.no_playlists'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr('playlist.no_playlists_desc'),
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () =>
                              _showCreatePlaylistDialog(context, ref),
                          icon: const Icon(Icons.add),
                          label: Text(tr('playlist.create_btn')),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: playlists.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                final firstThumb = playlist.items.isNotEmpty
                    ? playlist.items.first.videoThumbnailUrl
                    : null;

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push('/playlists/${playlist.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail Preview
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 100,
                            height: 62,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (firstThumb != null && firstThumb.isNotEmpty)
                                  Image.network(
                                    firstThumb,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.playlist_play,
                                              size: 32,
                                            ),
                                  )
                                else
                                  const Icon(Icons.playlist_play, size: 32),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    color: Colors.black54,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      '${playlist.items.length} ${playlist.items.length == 1 ? tr('common.video') : tr('common.videos')}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Title & Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playlist.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      playlist.visibility,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: theme
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  if (playlist.description != null &&
                                      playlist.description!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        playlist.description!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Actions Menu
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (val) {
                            if (val == 'edit') {
                              _showEditPlaylistDialog(context, ref, playlist);
                            } else if (val == 'delete') {
                              _showDeleteConfirmDialog(context, ref, playlist);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_outlined, size: 20),
                                  const SizedBox(width: 10),
                                  Text(tr('playlist.edit_details')),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    tr('playlist.delete'),
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${tr('state.error')}\n$err',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(myPlaylistsProvider),
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

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final tr = ref.read(trProvider);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String visibility = 'PUBLIC';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(tr('playlist.create_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: tr('playlist.title_label'),
                    hintText: tr('playlist.title_hint'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: tr('playlist.desc_label'),
                    hintText: tr('playlist.desc_hint'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: visibility,
                  decoration: InputDecoration(
                    labelText: tr('playlist.visibility'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'PUBLIC',
                      child: Text(tr('playlist.public')),
                    ),
                    DropdownMenuItem(
                      value: 'UNLISTED',
                      child: Text(tr('playlist.unlisted')),
                    ),
                    DropdownMenuItem(
                      value: 'PRIVATE',
                      child: Text(tr('playlist.private')),
                    ),
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
              child: Text(tr('common.cancel')),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                Navigator.pop(dialogCtx);
                try {
                  await ref
                      .read(playlistRepositoryProvider)
                      .createPlaylist(
                        title: title,
                        description: descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                        visibility: visibility,
                      );
                  ref.invalidate(myPlaylistsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('playlist.created'))),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          tr('playlist.create_failed', {'error': e.toString()}),
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text(tr('playlist.create')),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    PlaylistDto playlist,
  ) {
    final tr = ref.read(trProvider);
    final titleCtrl = TextEditingController(text: playlist.title);
    final descCtrl = TextEditingController(text: playlist.description ?? '');
    String visibility = playlist.visibility;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(tr('playlist.edit_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: tr('playlist.title_label'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: tr('playlist.desc_label'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: visibility,
                  decoration: InputDecoration(
                    labelText: tr('playlist.visibility'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'PUBLIC',
                      child: Text(tr('playlist.public')),
                    ),
                    DropdownMenuItem(
                      value: 'UNLISTED',
                      child: Text(tr('playlist.unlisted')),
                    ),
                    DropdownMenuItem(
                      value: 'PRIVATE',
                      child: Text(tr('playlist.private')),
                    ),
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
              child: Text(tr('common.cancel')),
            ),
            FilledButton(
              onPressed: () async {
                final newTitle = titleCtrl.text.trim();
                if (newTitle.isEmpty) return;
                Navigator.pop(dialogCtx);
                try {
                  await ref
                      .read(playlistRepositoryProvider)
                      .updatePlaylist(
                        playlist.id,
                        title: newTitle,
                        description: descCtrl.text.trim(),
                        visibility: visibility,
                      );
                  ref.invalidate(myPlaylistsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('playlist.updated'))),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          tr('playlist.update_failed', {'error': e.toString()}),
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text(tr('common.save')),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    PlaylistDto playlist,
  ) {
    final tr = ref.read(trProvider);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(tr('playlist.delete_title')),
        content: Text(tr('playlist.delete_msg', {'title': playlist.title})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(tr('common.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await ref
                    .read(playlistRepositoryProvider)
                    .deletePlaylist(playlist.id);
                ref.invalidate(myPlaylistsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('playlist.deleted'))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        tr('playlist.delete_failed', {'error': e.toString()}),
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(tr('common.delete')),
          ),
        ],
      ),
    );
  }
}
