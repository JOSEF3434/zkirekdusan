import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/explore/data/explore_repository.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/home/domain/feed_response.dart';

class TrendingState {
  final List<VideoResponseDto> videos;
  final FeedMetaDto? meta;
  final bool isLoadingMore;
  final String? error;

  const TrendingState({
    this.videos = const [],
    this.meta,
    this.isLoadingMore = false,
    this.error,
  });

  TrendingState copyWith({
    List<VideoResponseDto>? videos,
    FeedMetaDto? meta,
    bool? isLoadingMore,
    String? error,
  }) {
    return TrendingState(
      videos: videos ?? this.videos,
      meta: meta ?? this.meta,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

final trendingProvider = AsyncNotifierProvider<TrendingNotifier, TrendingState>(
  () {
    return TrendingNotifier();
  },
);

class TrendingNotifier extends AsyncNotifier<TrendingState> {
  CancelToken? _cancelToken;

  @override
  Future<TrendingState> build() async {
    _cancelToken = CancelToken();
    ref.onDispose(() => _cancelToken?.cancel());

    final repo = ref.read(exploreRepositoryProvider);
    final response = await repo.getTrendingVideos(cancelToken: _cancelToken);

    return TrendingState(videos: response.data, meta: response.meta);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    try {
      final repo = ref.read(exploreRepositoryProvider);
      final response = await repo.getTrendingVideos(cancelToken: _cancelToken);
      state = AsyncValue.data(
        TrendingState(videos: response.data, meta: response.meta),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.isLoadingMore) return;
    if (currentState.meta != null && !currentState.meta!.hasNext) return;

    state = AsyncValue.data(
      currentState.copyWith(isLoadingMore: true, error: null),
    );

    try {
      final repo = ref.read(exploreRepositoryProvider);
      final nextPage = (currentState.meta?.page ?? 0) + 1;
      final response = await repo.getTrendingVideos(
        page: nextPage,
        cancelToken: _cancelToken,
      );

      state = AsyncValue.data(
        currentState.copyWith(
          videos: [...currentState.videos, ...response.data],
          meta: response.meta,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        currentState.copyWith(isLoadingMore: false, error: e.toString()),
      );
    }
  }
}
