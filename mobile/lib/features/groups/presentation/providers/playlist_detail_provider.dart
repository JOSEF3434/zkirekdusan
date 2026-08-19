// lib/features/groups/presentation/providers/playlist_detail_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/groups/data/group_repository.dart';
import 'package:mobile/features/groups/domain/channel_playlist_dto.dart';

final playlistDetailProvider = AsyncNotifierProvider.family<
    PlaylistDetailNotifier, ChannelPlaylistDto, String>(
  PlaylistDetailNotifier.new,
);

class PlaylistDetailNotifier
    extends FamilyAsyncNotifier<ChannelPlaylistDto, String> {
  @override
  Future<ChannelPlaylistDto> build(String arg) async {
    ref.keepAlive();
    final repo = ref.read(groupRepositoryProvider);
    return repo.getPlaylistDetail(arg);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final repo = ref.read(groupRepositoryProvider);
      return repo.getPlaylistDetail(arg);
    });
  }

  Future<void> removeVideo(String videoId) async {
    final repo = ref.read(groupRepositoryProvider);
    await repo.removeVideoFromPlaylist(arg, videoId);
    await refresh();
  }

  Future<void> deletePlaylist() async {
    final repo = ref.read(groupRepositoryProvider);
    await repo.deletePlaylist(arg);
  }
}
