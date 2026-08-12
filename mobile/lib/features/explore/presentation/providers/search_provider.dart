import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/explore/data/explore_repository.dart';
import 'package:mobile/features/explore/domain/search_model.dart';
import 'package:dio/dio.dart';

class SearchState {
  final String query;
  final SearchEntityType? type;
  final SearchResultsDto? results;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.query = '',
    this.type,
    this.results,
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    SearchEntityType? type,
    SearchResultsDto? results,
    bool? isLoading,
    String? error,
    bool clearResults = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      type: type ?? this.type,
      results: clearResults ? null : (results ?? this.results),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(() {
  return SearchNotifier();
});

class SearchNotifier extends Notifier<SearchState> {
  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  @override
  SearchState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _cancelToken?.cancel();
    });
    return const SearchState();
  }

  void setType(SearchEntityType? type) {
    if (state.type == type) return;
    state = state.copyWith(type: type);
    _performSearch();
  }

  void setQuery(String query) {
    if (state.query == query) return;
    state = state.copyWith(query: query);

    if (query.trim().isEmpty) {
      _debounceTimer?.cancel();
      _cancelToken?.cancel();
      state = state.copyWith(isLoading: false, clearResults: true, error: null);
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch();
    });
  }

  void clear() {
    _debounceTimer?.cancel();
    _cancelToken?.cancel();
    state = const SearchState();
  }

  Future<void> _performSearch() async {
    final query = state.query.trim();
    if (query.isEmpty) return;

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(exploreRepositoryProvider);
      final response = await repo.search(
        query: query,
        type: state.type,
        cancelToken: _cancelToken,
      );

      // Verify that this is still the active search (avoid race conditions)
      if (_cancelToken?.isCancelled ?? false) return;

      state = state.copyWith(results: response.results, isLoading: false);
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;

      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
