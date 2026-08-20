// lib/features/groups/presentation/providers/channel_videos_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/groups/data/group_repository.dart';
import 'package:mobile/features/groups/domain/channel_video_dto.dart';

class ChannelVideosState {
  final List<ChannelVideoDto> videos;
  final bool isLoading;
  final bool isFetchingMore;
  final String? error;
  final bool hasMore;
  final String? nextCursor;
  final int total;

  const ChannelVideosState({
    this.videos = const [],
    this.isLoading = false,
    this.isFetchingMore = false,
    this.error,
    this.hasMore = false,
    this.nextCursor,
    this.total = 0,
  });

  ChannelVideosState copyWith({
    List<ChannelVideoDto>? videos,
    bool? isLoading,
    bool? isFetchingMore,
    String? error,
    bool? hasMore,
    String? nextCursor,
    int? total,
    bool clearError = false,
  }) {
    return ChannelVideosState(
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor ?? this.nextCursor,
      total: total ?? this.total,
    );
  }
}

final channelVideosProvider =
    StateNotifierProvider.family<
      ChannelVideosNotifier,
      ChannelVideosState,
      String
    >(
      (ref, channelId) =>
          ChannelVideosNotifier(ref.watch(groupRepositoryProvider), channelId),
    );

class ChannelVideosNotifier extends StateNotifier<ChannelVideosState> {
  final GroupRepository _repository;
  final String _channelId;

  ChannelVideosNotifier(this._repository, this._channelId)
    : super(const ChannelVideosState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repository.getChannelVideos(_channelId, limit: 20);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        videos: res.items,
        hasMore: res.hasMore,
        nextCursor: res.nextCursor,
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
      final res = await _repository.getChannelVideos(_channelId, limit: 20);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isFetchingMore: false,
        videos: res.items,
        hasMore: res.hasMore,
        nextCursor: res.nextCursor,
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
    if (state.isLoading ||
        state.isFetchingMore ||
        !state.hasMore ||
        state.nextCursor == null) {
      return;
    }
    state = state.copyWith(isFetchingMore: true, clearError: true);
    try {
      final res = await _repository.getChannelVideos(
        _channelId,
        cursor: state.nextCursor,
        limit: 20,
      );
      if (!mounted) return;
      state = state.copyWith(
        isFetchingMore: false,
        videos: [...state.videos, ...res.items],
        hasMore: res.hasMore,
        nextCursor: res.nextCursor,
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
}
