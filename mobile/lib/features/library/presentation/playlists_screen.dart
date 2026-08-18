import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/library/data/repositories/playlist_repository.dart';

final myPlaylistsProvider = FutureProvider((ref) {
  final repo = ref.watch(playlistRepositoryProvider);
  return repo.getMyPlaylists();
});

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final playlistsAsync = ref.watch(myPlaylistsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('library.playlists')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Show create playlist dialog
            },
          ),
        ],
      ),
      body: playlistsAsync.when(
        data: (playlists) {
          if (playlists.isEmpty) {
            return Center(child: Text(tr('state.empty')));
          }
          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return ListTile(
                leading: const Icon(Icons.playlist_play, size: 40),
                title: Text(playlist.title),
                subtitle: Text('${playlist.items.length} videos'),
                onTap: () {
                  // Navigate to playlist detail
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            '${tr('state.error')}\n$err',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
