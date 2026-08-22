import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/home/data/video_repository.dart';
import 'package:mobile/features/home/domain/feed_response.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/home/data/feed_repository.dart';

import 'package:mobile/features/home/domain/post_model.dart';

extension PostResponseDtoToVideo on PostResponseDto {
  VideoResponseDto toVideoResponseDto() {
    return VideoResponseDto(
      id: id,
      title: content ?? 'Recommended Video',
      description: content,
      status: VideoStatus.ready, // Assumption for recommendations
      visibility: visibility,
      author: author,
      viewsCount: viewsCount,
      likesCount: likesCount,
      commentsCount: commentsCount,
      isLiked: isLiked,
      isSaved: isSaved,
      thumbnailUrl: media.isNotEmpty && media.first.fileType.startsWith('image')
          ? media.first.url
          : null,
      hlsUrl: media.isNotEmpty && media.first.fileType.startsWith('video')
          ? media.first.url
          : null,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class VideoFeedState {
  final List<VideoResponseDto> videos;
  final FeedMetaDto? meta;
  final VideoFeedCategory category;
  final bool isLoadingMore;
  final String? error;

  const VideoFeedState({
    this.videos = const [],
    this.meta,
    this.category = VideoFeedCategory.all,
    this.isLoadingMore = false,
    this.error,
  });

  VideoFeedState copyWith({
    List<VideoResponseDto>? videos,
    FeedMetaDto? meta,
    VideoFeedCategory? category,
    bool? isLoadingMore,
    String? error,
  }) {
    return VideoFeedState(
      videos: videos ?? this.videos,
      meta: meta ?? this.meta,
      category: category ?? this.category,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

final videoFeedProvider =
    AsyncNotifierProvider<VideoFeedNotifier, VideoFeedState>(() {
      return VideoFeedNotifier();
    });

class VideoFeedNotifier extends AsyncNotifier<VideoFeedState> {
  CancelToken? _cancelToken;
  VideoFeedCategory _currentCategory = VideoFeedCategory.recommended;

  @override
  FutureOr<VideoFeedState> build() async {
    _cancelToken = CancelToken();
    ref.onDispose(() {
      _cancelToken?.cancel();
    });

    return _fetchInitial(_currentCategory);
  }

  Future<VideoFeedState> _fetchInitial(VideoFeedCategory category) async {
    final repo = ref.read(videoRepositoryProvider);
    final feedRepo = ref.read(feedRepositoryProvider);
    VideoListResponseDto response;

    if (category == VideoFeedCategory.recommended) {
      try {
        final feedResponse = await feedRepo.getRecommendations(
          page: 1,
          limit: 10,
          cancelToken: _cancelToken,
        );
        final videos = feedResponse.data
            .map((p) => p.toVideoResponseDto())
            .toList();
        if (videos.isNotEmpty) {
          response = VideoListResponseDto(
            data: videos,
            meta: feedResponse.meta,
          );
        } else {
          // If recommendation feed is empty, fallback to latest published videos
          response = await repo.getLatestVideos(
            page: 1,
            limit: 10,
            cancelToken: _cancelToken,
          );
        }
      } catch (_) {
        try {
          response = await repo.getLatestVideos(
            page: 1,
            limit: 10,
            cancelToken: _cancelToken,
          );
        } catch (_) {
          response = await repo.searchVideos(
            page: 1,
            limit: 10,
            cancelToken: _cancelToken,
          );
        }
      }
    } else if (category == VideoFeedCategory.latest) {
      response = await repo.getLatestVideos(
        page: 1,
        limit: 10,
        cancelToken: _cancelToken,
      );
    } else if (category == VideoFeedCategory.all) {
      response = await repo.getLatestVideos(
        page: 1,
        limit: 10,
        cancelToken: _cancelToken,
      );
    } else if (category == VideoFeedCategory.trending) {
      response = await repo.getTrending(
        page: 1,
        limit: 10,
        cancelToken: _cancelToken,
      );
    } else {
      response = await repo.searchVideos(
        category: category.apiCategory,
        page: 1,
        limit: 10,
        cancelToken: _cancelToken,
      );
    }

    return VideoFeedState(
      videos: response.data,
      meta: response.meta,
      category: category,
    );
  }

  Future<void> setCategory(VideoFeedCategory category) async {
    if (_currentCategory == category) return;

    _currentCategory = category;
    state = const AsyncValue.loading();
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    try {
      final newState = await _fetchInitial(category);
      state = AsyncValue.data(newState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    try {
      final newState = await _fetchInitial(_currentCategory);
      state = AsyncValue.data(newState);
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
      final repo = ref.read(videoRepositoryProvider);
      final feedRepo = ref.read(feedRepositoryProvider);
      final nextPage = (currentState.meta?.page ?? 0) + 1;

      VideoListResponseDto response;
      if (_currentCategory == VideoFeedCategory.recommended) {
        try {
          final feedResponse = await feedRepo.getRecommendations(
            page: nextPage,
            limit: 10,
            cancelToken: _cancelToken,
          );
          final videos = feedResponse.data
              .map((p) => p.toVideoResponseDto())
              .toList();
          if (videos.isNotEmpty) {
            response = VideoListResponseDto(
              data: videos,
              meta: feedResponse.meta,
            );
          } else {
            response = await repo.getLatestVideos(
              page: nextPage,
              limit: 10,
              cancelToken: _cancelToken,
            );
          }
        } catch (_) {
          try {
            response = await repo.getLatestVideos(
              page: nextPage,
              limit: 10,
              cancelToken: _cancelToken,
            );
          } catch (_) {
            response = await repo.searchVideos(
              page: nextPage,
              limit: 10,
              cancelToken: _cancelToken,
            );
          }
        }
      } else if (_currentCategory == VideoFeedCategory.latest ||
          _currentCategory == VideoFeedCategory.all) {
        response = await repo.getLatestVideos(
          page: nextPage,
          limit: 10,
          cancelToken: _cancelToken,
        );
      } else if (_currentCategory == VideoFeedCategory.trending) {
        response = await repo.getTrending(
          page: nextPage,
          limit: 10,
          cancelToken: _cancelToken,
        );
      } else {
        response = await repo.searchVideos(
          category: _currentCategory.apiCategory,
          page: nextPage,
          limit: 10,
          cancelToken: _cancelToken,
        );
      }

      state = AsyncValue.data(
        VideoFeedState(
          videos: [...currentState.videos, ...response.data],
          meta: response.meta,
          category: currentState.category,
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
