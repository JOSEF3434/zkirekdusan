// lib/features/explore/presentation/providers/search_provider.dart
// Advanced search provider with: debounce, CancelToken, pagination,
// duplicate prevention, race-condition protection, recent-search history.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:mobile/features/explore/data/search_repository.dart';
import 'package:mobile/features/explore/domain/search_model.dart';

// ── Recent search history ─────────────────────────────────────────────────────

final _kRecentSearchKey = 'f9_recent_searches';
const _kMaxRecentSearches = 15;

final recentSearchesProvider =
    AsyncNotifierProvider<RecentSearchesNotifier, List<String>>(
      RecentSearchesNotifier.new,
    );

class RecentSearchesNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kRecentSearchKey) ?? [];
  }

  Future<void> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_kRecentSearchKey) ?? [];
    // Move to top if duplicate; otherwise prepend
    final updated = [q, ...current.where((s) => s != q)];
    final capped = updated.take(_kMaxRecentSearches).toList();
    await prefs.setStringList(_kRecentSearchKey, capped);
    state = AsyncValue.data(capped);
  }

  Future<void> remove(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_kRecentSearchKey) ?? [];
    final updated = current.where((s) => s != query).toList();
    await prefs.setStringList(_kRecentSearchKey, updated);
    state = AsyncValue.data(updated);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRecentSearchKey);
    state = const AsyncValue.data([]);
  }
}

// ── Search State ──────────────────────────────────────────────────────────────

class SearchState {
  final String query;
  final SearchEntityType? type;
  // All accumulated results across pages (for infinite scroll)
  final SearchResultsDto? results;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const SearchState({
    this.query = '',
    this.type,
    this.results,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  SearchState copyWith({
    String? query,
    SearchEntityType? type,
    SearchResultsDto? results,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    bool clearResults = false,
    bool clearError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      type: type ?? this.type,
      results: clearResults ? null : (results ?? this.results),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Search Notifier ───────────────────────────────────────────────────────────

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);

class SearchNotifier extends Notifier<SearchState> {
  Timer? _debounceTimer;
  CancelToken? _cancelToken;
  bool _isLoadingMoreInProgress = false;

  @override
  SearchState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _cancelToken?.cancel('disposed');
    });
    return const SearchState();
  }

  void setType(SearchEntityType? type) {
    if (state.type == type) return;
    state = state.copyWith(type: type, clearResults: true, currentPage: 1);
    if (state.query.trim().isNotEmpty) {
      _performSearch(page: 1);
    }
  }

  void setQuery(String query) {
    if (state.query == query) return;
    state = state.copyWith(
      query: query,
      clearResults: true,
      currentPage: 1,
      hasMore: true,
      clearError: true,
    );

    if (query.trim().isEmpty) {
      _debounceTimer?.cancel();
      _cancelToken?.cancel('cleared');
      _cancelToken = null;
      state = state.copyWith(isLoading: false, clearResults: true);
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch(page: 1);
    });
  }

  Future<void> loadNextPage() async {
    if (_isLoadingMoreInProgress) return;
    if (!state.hasMore) return;
    if (state.isLoading) return;
    if (state.query.trim().isEmpty) return;

    await _performSearch(page: state.currentPage + 1, isLoadMore: true);
  }

  void clear() {
    _debounceTimer?.cancel();
    _cancelToken?.cancel('cleared');
    _cancelToken = null;
    _isLoadingMoreInProgress = false;
    state = const SearchState();
  }

  Future<void> retry() async {
    if (state.query.trim().isEmpty) return;
    await _performSearch(page: 1);
  }

  Future<void> _performSearch({
    required int page,
    bool isLoadMore = false,
  }) async {
    final query = state.query.trim();
    if (query.isEmpty) return;

    // Cancel any in-flight request
    _cancelToken?.cancel('new_search');
    _cancelToken = CancelToken();
    final localToken = _cancelToken;

    if (isLoadMore) {
      _isLoadingMoreInProgress = true;
      state = state.copyWith(isLoadingMore: true, clearError: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true, currentPage: 1);
    }

    try {
      final repo = ref.read(searchRepositoryProvider);
      final response = await repo.search(
        query: query,
        type: state.type,
        page: page,
        limit: 20,
        cancelToken: localToken,
      );

      // Guard: query changed while we were fetching — discard stale result
      if (state.query.trim() != query || (localToken?.isCancelled ?? false)) {
        return;
      }

      // Merge results for pagination (append), or replace for fresh search
      final newResults = response.results;
      final merged = isLoadMore && state.results != null
          ? _mergeResults(state.results!, newResults)
          : newResults;

      // Determine if there are more pages
      final totalInPage =
          newResults.videos.length +
          newResults.users.length +
          newResults.groups.length +
          newResults.channels.length +
          newResults.streams.length +
          newResults.reels.length;
      final hasMore = totalInPage >= 20;

      state = state.copyWith(
        results: merged,
        isLoading: false,
        isLoadingMore: false,
        currentPage: page,
        hasMore: hasMore,
      );

      // Persist to recent search history (page 1 only, not load-more)
      if (page == 1) {
        ref.read(recentSearchesProvider.notifier).add(query);
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    } finally {
      _isLoadingMoreInProgress = false;
    }
  }

  /// Merges results from a new page into existing results, deduplicating by ID.
  SearchResultsDto _mergeResults(
    SearchResultsDto existing,
    SearchResultsDto newPage,
  ) {
    final existingVideoIds = existing.videos.map((v) => v.id).toSet();
    final existingUserIds = existing.users.map((u) => u.id).toSet();
    final existingGroupIds = existing.groups.map((g) => g.id).toSet();
    final existingChannelIds = existing.channels.map((c) => c.id).toSet();
    final existingStreamIds = existing.streams.map((s) => s.id).toSet();
    final existingReelIds = existing.reels.map((r) => r.id).toSet();

    return SearchResultsDto(
      videos: [
        ...existing.videos,
        ...newPage.videos.where((v) => !existingVideoIds.contains(v.id)),
      ],
      users: [
        ...existing.users,
        ...newPage.users.where((u) => !existingUserIds.contains(u.id)),
      ],
      groups: [
        ...existing.groups,
        ...newPage.groups.where((g) => !existingGroupIds.contains(g.id)),
      ],
      channels: [
        ...existing.channels,
        ...newPage.channels.where((c) => !existingChannelIds.contains(c.id)),
      ],
      streams: [
        ...existing.streams,
        ...newPage.streams.where((s) => !existingStreamIds.contains(s.id)),
      ],
      reels: [
        ...existing.reels,
        ...newPage.reels.where((r) => !existingReelIds.contains(r.id)),
      ],
    );
  }
}
