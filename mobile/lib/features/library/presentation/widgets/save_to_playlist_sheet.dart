// lib/features/library/presentation/widgets/save_to_playlist_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/library/data/repositories/playlist_repository.dart';
import 'package:mobile/features/library/presentation/playlists_screen.dart';

class SaveToPlaylistSheet extends ConsumerStatefulWidget {
  final String videoId;
  final String? videoTitle;

  const SaveToPlaylistSheet({
    super.key,
    required this.videoId,
    this.videoTitle,
  });

  static Future<void> show(
    BuildContext context, {
    required String videoId,
    String? videoTitle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          SaveToPlaylistSheet(videoId: videoId, videoTitle: videoTitle),
    );
  }

  @override
  ConsumerState<SaveToPlaylistSheet> createState() =>
      _SaveToPlaylistSheetState();
}

class _SaveToPlaylistSheetState extends ConsumerState<SaveToPlaylistSheet> {
  final Set<String> _selectedPlaylistIds = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(myPlaylistsProvider);
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

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
            // Handle bar
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
                Text(
                  tr('playlist.save_to_hint'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showNewPlaylistDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(tr('playlist.new_btn')),
                ),
              ],
            ),
            const Divider(height: 12),

            playlistsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Failed to load playlists: $err'),
                ),
              ),
              data: (playlists) {
                if (playlists.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.playlist_add,
                            size: 48,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(tr('playlist.no_playlists')),
                          const SizedBox(height: 8),
                          FilledButton.tonalIcon(
                            onPressed: () => _showNewPlaylistDialog(context),
                            icon: const Icon(Icons.add),
                            label: Text(tr('playlist.create_first')),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (ctx, idx) {
                      final p = playlists[idx];
                      final isSelected = _selectedPlaylistIds.contains(p.id);

                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(
                          p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${p.privacy.toUpperCase()} • ${p.items.length} videos',
                          style: const TextStyle(fontSize: 11),
                        ),
                        secondary: const Icon(Icons.playlist_play),
                        onChanged: _isLoading
                            ? null
                            : (val) async {
                                final messenger = ScaffoldMessenger.of(context);
                                setState(() {
                                  _isLoading = true;
                                  if (val == true) {
                                    _selectedPlaylistIds.add(p.id);
                                  } else {
                                    _selectedPlaylistIds.remove(p.id);
                                  }
                                });

                                try {
                                  final repo = ref.read(
                                    playlistRepositoryProvider,
                                  );
                                  if (val == true) {
                                    await repo.addVideoToPlaylist(
                                      p.id,
                                      widget.videoId,
                                    );
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          tr('playlist.added_to', {
                                            'title': p.title,
                                          }),
                                        ),
                                      ),
                                    );
                                  } else {
                                    await repo.removeVideoFromPlaylist(
                                      p.id,
                                      widget.videoId,
                                    );
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          tr('playlist.removed_from', {
                                            'title': p.title,
                                          }),
                                        ),
                                      ),
                                    );
                                  }
                                  ref.invalidate(myPlaylistsProvider);
                                } catch (e) {
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        tr('playlist.action_failed', {
                                          'error': e.toString(),
                                        }),
                                      ),
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              },
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
                child: Text(tr('playlist.done')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewPlaylistDialog(BuildContext context) {
    final tr = ref.read(trProvider);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String privacy = 'PUBLIC';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(tr('playlist.create_title')),
          content: Column(
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
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: tr('playlist.desc_label'),
                  hintText: tr('playlist.desc_hint'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: privacy,
                decoration: InputDecoration(
                  labelText: tr('playlist.privacy'),
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
                  if (val != null) setDialogState(() => privacy = val);
                },
              ),
            ],
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
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(dialogCtx);

                try {
                  final repo = ref.read(playlistRepositoryProvider);
                  final created = await repo.createPlaylist(
                    title: title,
                    description: descCtrl.text.trim().isEmpty
                        ? null
                        : descCtrl.text.trim(),
                    visibility: privacy.toUpperCase(),
                  );
                  await repo.addVideoToPlaylist(created.id, widget.videoId);
                  ref.invalidate(myPlaylistsProvider);
                  if (!mounted) return;
                  setState(() {
                    _selectedPlaylistIds.add(created.id);
                  });
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        tr('playlist.created_added', {'title': created.title}),
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        tr('playlist.create_failed_short', {
                          'error': e.toString(),
                        }),
                      ),
                    ),
                  );
                }
              },
              child: Text(tr('playlist.create')),
            ),
          ],
        ),
      ),
    );
  }
}
