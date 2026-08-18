// lib/features/home/presentation/providers/subscription_feed_provider.dart
// Fetches GET /video-subscriptions/feed for authenticated users.
// Provides pagination support with infinite scroll.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/explore/data/discovery_repository.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

class SubscriptionFeedState {
  final List<VideoResponseDto> videos;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const SubscriptionFeedState({
    this.videos = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  SubscriptionFeedState copyWith({
    List<VideoResponseDto>? videos,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    bool clearError = false,
  }) {
    return SubscriptionFeedState(
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final subscriptionFeedProvider =
    AsyncNotifierProvider<SubscriptionFeedNotifier, SubscriptionFeedState>(
      SubscriptionFeedNotifier.new,
    );

class SubscriptionFeedNotifier extends AsyncNotifier<SubscriptionFeedState> {
  @override
  Future<SubscriptionFeedState> build() async {
    final auth = ref.watch(authProvider);
    // Only load for authenticated users
    if (auth.status != AuthStatus.authenticated) {
      return const SubscriptionFeedState();
    }
    return _fetchPage(1);
  }

  Future<SubscriptionFeedState> _fetchPage(int page) async {
    final repo = ref.read(discoveryRepositoryProvider);
    final response = await repo.getSubscriptionFeed(page: page, limit: 20);
    return SubscriptionFeedState(
      videos: response.data,
      currentPage: page,
      hasMore: response.data.length >= 20,
    );
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final repo = ref.read(discoveryRepositoryProvider);
      final nextPage = current.currentPage + 1;
      final response = await repo.getSubscriptionFeed(
        page: nextPage,
        limit: 20,
      );
      final existingIds = current.videos.map((v) => v.id).toSet();
      final newVideos = response.data
          .where((v) => !existingIds.contains(v.id))
          .toList();

      state = AsyncValue.data(
        current.copyWith(
          videos: [...current.videos, ...newVideos],
          currentPage: nextPage,
          hasMore: response.data.length >= 20,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        current.copyWith(isLoadingMore: false, error: e.toString()),
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _fetchPage(1));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
