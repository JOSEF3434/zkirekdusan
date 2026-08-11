import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/home/data/feed_repository.dart';
import 'package:mobile/features/home/domain/feed_response.dart';
import 'package:mobile/features/home/domain/post_model.dart';

class FeedState {
  final List<PostResponseDto> posts;
  final FeedMetaDto? meta;
  final bool isLoadingMore;
  final String? error;

  const FeedState({
    this.posts = const [],
    this.meta,
    this.isLoadingMore = false,
    this.error,
  });

  FeedState copyWith({
    List<PostResponseDto>? posts,
    FeedMetaDto? meta,
    bool? isLoadingMore,
    String? error,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      meta: meta ?? this.meta,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error, // Can be set to null
    );
  }
}

final feedProvider = AsyncNotifierProvider<FeedNotifier, FeedState>(() {
  return FeedNotifier();
});

class FeedNotifier extends AsyncNotifier<FeedState> {
  CancelToken? _cancelToken;

  @override
  FutureOr<FeedState> build() async {
    _cancelToken = CancelToken();
    ref.onDispose(() {
      _cancelToken?.cancel();
    });
    
    return _fetchInitial();
  }

  Future<FeedState> _fetchInitial() async {
    final repo = ref.read(feedRepositoryProvider);
    final response = await repo.getFeed(page: 1, limit: 10, cancelToken: _cancelToken);
    return FeedState(posts: response.data, meta: response.meta);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    
    try {
      final newState = await _fetchInitial();
      state = AsyncValue.data(newState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.isLoadingMore) return;
    if (currentState.meta != null && !currentState.meta!.hasNext) return;

    // Set loading more state
    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true, error: null));

    try {
      final repo = ref.read(feedRepositoryProvider);
      final nextPage = (currentState.meta?.page ?? 0) + 1;
      
      final response = await repo.getFeed(
        page: nextPage,
        limit: 10,
        cancelToken: _cancelToken,
      );

      state = AsyncValue.data(
        FeedState(
          posts: [...currentState.posts, ...response.data],
          meta: response.meta,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        currentState.copyWith(
          isLoadingMore: false,
          error: e.toString(),
        ),
      );
    }
  }
}
