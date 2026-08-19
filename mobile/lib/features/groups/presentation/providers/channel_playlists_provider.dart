// lib/features/groups/presentation/providers/channel_playlists_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/groups/data/group_repository.dart';
import 'package:mobile/features/groups/domain/channel_playlist_dto.dart';

class ChannelPlaylistsState {
  final List<ChannelPlaylistDto> playlists;
  final bool isLoading;
  final bool isFetchingMore;
  final String? error;
  final bool hasNext;
  final int page;
  final int total;

  const ChannelPlaylistsState({
    this.playlists = const [],
    this.isLoading = false,
    this.isFetchingMore = false,
    this.error,
    this.hasNext = false,
    this.page = 1,
    this.total = 0,
  });

  ChannelPlaylistsState copyWith({
    List<ChannelPlaylistDto>? playlists,
    bool? isLoading,
    bool? isFetchingMore,
    String? error,
    bool? hasNext,
    int? page,
    int? total,
    bool clearError = false,
  }) {
    return ChannelPlaylistsState(
      playlists: playlists ?? this.playlists,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      error: clearError ? null : (error ?? this.error),
      hasNext: hasNext ?? this.hasNext,
      page: page ?? this.page,
      total: total ?? this.total,
    );
  }
}

final channelPlaylistsProvider = StateNotifierProvider.family<
    ChannelPlaylistsNotifier, ChannelPlaylistsState, String>(
  (ref, channelId) => ChannelPlaylistsNotifier(
    ref.watch(groupRepositoryProvider),
    channelId,
  ),
);

class ChannelPlaylistsNotifier extends StateNotifier<ChannelPlaylistsState> {
  final GroupRepository _repository;
  final String _channelId;

  ChannelPlaylistsNotifier(this._repository, this._channelId)
      : super(const ChannelPlaylistsState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repository.getChannelPlaylists(_channelId, page: 1, limit: 20);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        playlists: res.items,
        hasNext: res.hasNext,
        page: 1,
        total: res.total,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(clearError: true);
    try {
      final res = await _repository.getChannelPlaylists(_channelId, page: 1, limit: 20);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isFetchingMore: false,
        playlists: res.items,
        hasNext: res.hasNext,
        page: 1,
        total: res.total,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isFetchingMore || !state.hasNext) return;
    state = state.copyWith(isFetchingMore: true, clearError: true);
    try {
      final nextPage = state.page + 1;
      final res = await _repository.getChannelPlaylists(
        _channelId,
        page: nextPage,
        limit: 20,
      );
      if (!mounted) return;
      state = state.copyWith(
        isFetchingMore: false,
        playlists: [...state.playlists, ...res.items],
        hasNext: res.hasNext,
        page: nextPage,
        total: res.total,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isFetchingMore: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<ChannelPlaylistDto> createPlaylist({
    required String title,
    String? description,
    String visibility = 'PUBLIC',
  }) async {
    final created = await _repository.createPlaylist(
      title: title,
      description: description,
      videoChannelId: _channelId,
      visibility: visibility,
    );
    state = state.copyWith(
      playlists: [created, ...state.playlists],
      total: state.total + 1,
    );
    return created;
  }
}
