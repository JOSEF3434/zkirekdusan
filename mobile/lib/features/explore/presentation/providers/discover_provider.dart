// lib/features/explore/presentation/providers/discover_provider.dart
// Fetches GET /explore for the Explore screen's rich discovery sections.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/explore/data/discovery_repository.dart';
import 'package:mobile/features/explore/domain/explore_content_model.dart';

/// State for the Explore discovery feed.
class DiscoverState {
  final ExploreContentDto? content;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;

  const DiscoverState({
    this.content,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
  });

  DiscoverState copyWith({
    ExploreContentDto? content,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
  }) {
    return DiscoverState(
      content: content ?? this.content,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final discoverProvider = AsyncNotifierProvider<DiscoverNotifier, DiscoverState>(
  DiscoverNotifier.new,
);

class DiscoverNotifier extends AsyncNotifier<DiscoverState> {
  @override
  Future<DiscoverState> build() async {
    return _fetch();
  }

  Future<DiscoverState> _fetch() async {
    final repo = ref.read(discoveryRepositoryProvider);
    final content = await repo.getExploreContent();
    return DiscoverState(content: content);
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    state = AsyncValue.data(
      (previous ?? const DiscoverState()).copyWith(isRefreshing: true),
    );
    try {
      final newState = await _fetch();
      state = AsyncValue.data(newState);
    } catch (e) {
      // On refresh failure, keep existing content but surface error
      state = AsyncValue.data(
        (previous ?? const DiscoverState()).copyWith(
          isRefreshing: false,
          error: e.toString(),
        ),
      );
    }
  }
}
