// lib/features/creator_analytics/presentation/providers/creator_video_list_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/creator_analytics/data/creator_analytics_repository.dart';
import 'package:mobile/features/creator_analytics/domain/creator_video_dto.dart';
import 'package:mobile/features/creator_analytics/domain/update_video_form.dart';

/// Args for scoping the provider per-channel + optional filters.
class VideoListArgs {
  final String channelId;
  final String? statusFilter;
  final String? searchQuery;

  const VideoListArgs({
    required this.channelId,
    this.statusFilter,
    this.searchQuery,
  });

  @override
  bool operator ==(Object other) =>
      other is VideoListArgs &&
      channelId == other.channelId &&
      statusFilter == other.statusFilter &&
      searchQuery == other.searchQuery;

  @override
  int get hashCode => Object.hash(channelId, statusFilter, searchQuery);
}

final creatorVideoListProvider = StateNotifierProvider.autoDispose
    .family<CreatorVideoListNotifier, CreatorVideoListState, VideoListArgs>((
      ref,
      args,
    ) {
      return CreatorVideoListNotifier(
        ref.watch(creatorAnalyticsRepositoryProvider),
        args,
      );
    });

class CreatorVideoListState {
  final bool isLoading;
  final bool isPaginating;
  final String? error;
  final List<CreatorVideoDto> videos;
  final String? nextCursor;
  final bool hasMore;

  const CreatorVideoListState({
    this.isLoading = true,
    this.isPaginating = false,
    this.error,
    this.videos = const [],
    this.nextCursor,
    this.hasMore = false,
  });

  CreatorVideoListState copyWith({
    bool? isLoading,
    bool? isPaginating,
    String? error,
    List<CreatorVideoDto>? videos,
    String? nextCursor,
    bool? hasMore,
    bool clearError = false,
    bool clearCursor = false,
  }) => CreatorVideoListState(
    isLoading: isLoading ?? this.isLoading,
    isPaginating: isPaginating ?? this.isPaginating,
    error: clearError ? null : (error ?? this.error),
    videos: videos ?? this.videos,
    nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    hasMore: hasMore ?? this.hasMore,
  );
}

class CreatorVideoListNotifier extends StateNotifier<CreatorVideoListState> {
  final CreatorAnalyticsRepository _repo;
  final VideoListArgs _args;

  CreatorVideoListNotifier(this._repo, this._args)
    : super(const CreatorVideoListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.getChannelVideos(
        channelId: _args.channelId,
        status: _args.statusFilter,
        search: _args.searchQuery,
      );
      state = state.copyWith(
        isLoading: false,
        videos: result.items,
        nextCursor: result.nextCursor,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _cleanError(e));
    }
  }

  Future<void> refresh() => load();

  Future<void> loadMore() async {
    if (state.isLoading || state.isPaginating || !state.hasMore) return;
    state = state.copyWith(isPaginating: true, clearError: true);
    try {
      final result = await _repo.getChannelVideos(
        channelId: _args.channelId,
        cursor: state.nextCursor,
        status: _args.statusFilter,
        search: _args.searchQuery,
      );
      state = state.copyWith(
        isPaginating: false,
        videos: [...state.videos, ...result.items],
        nextCursor: result.nextCursor,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isPaginating: false, error: _cleanError(e));
    }
  }

  /// Optimistic delete with rollback on failure.
  Future<void> deleteVideo(String videoId) async {
    final channelId = _args.channelId;
    final prev = List<CreatorVideoDto>.from(state.videos);
    // Optimistic remove
    state = state.copyWith(
      videos: state.videos.where((v) => v.id != videoId).toList(),
    );
    try {
      await _repo.deleteVideo(channelId: channelId, videoId: videoId);
    } catch (e) {
      // Rollback on failure
      state = state.copyWith(videos: prev, error: _cleanError(e));
      rethrow;
    }
  }

  /// Publish a READY video (optimistic status update).
  Future<void> publishVideo(String videoId) async {
    final channelId = _args.channelId;
    final prev = List<CreatorVideoDto>.from(state.videos);
    // Optimistic update
    state = state.copyWith(
      videos: state.videos.map((v) {
        if (v.id == videoId) {
          return v.copyWith(visibility: CreatorVideoVisibility.public);
        }
        return v;
      }).toList(),
    );
    try {
      await _repo.publishVideo(channelId: channelId, videoId: videoId);
    } catch (e) {
      state = state.copyWith(videos: prev, error: _cleanError(e));
      rethrow;
    }
  }

  /// Update video metadata, refresh with server response.
  Future<void> updateVideo(String videoId, UpdateVideoForm form) async {
    final channelId = _args.channelId;
    final updated = await _repo.updateVideo(
      channelId: channelId,
      videoId: videoId,
      form: form,
    );
    state = state.copyWith(
      videos: state.videos.map((v) => v.id == videoId ? updated : v).toList(),
    );
  }

  String _cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');
}
