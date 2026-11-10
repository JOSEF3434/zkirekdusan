// lib/core/rich_text/providers/content_search_provider.dart
//
// Riverpod state provider for # content search — directly reuses the
// application's Global Search `SearchRepository` (`/api/search`),
// `SearchResultsDto`, and `recentSearchesProvider` so Global Search and
// `#` composer search share identical APIs, permissions, ranking, and parsing.

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';
import 'package:mobile/features/explore/data/search_repository.dart';
import 'package:mobile/features/explore/domain/search_model.dart';
import 'package:mobile/features/explore/presentation/providers/search_provider.dart';

class ContentSearchState {
  final String query;
  final SearchEntityType? selectedType;
  final List<ContentSearchItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const ContentSearchState({
    this.query = '',
    this.selectedType,
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.error,
  });

  ContentSearchState copyWith({
    String? query,
    SearchEntityType? selectedType,
    bool clearType = false,
    List<ContentSearchItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    bool clearError = false,
  }) =>
      ContentSearchState(
        query: query ?? this.query,
        selectedType: clearType ? null : (selectedType ?? this.selectedType),
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        currentPage: currentPage ?? this.currentPage,
        error: clearError ? null : (error ?? this.error),
      );
}

class ContentSearchNotifier extends StateNotifier<ContentSearchState> {
  final Ref _ref;
  Timer? _debounce;
  CancelToken? _cancelToken;
  int _requestSeq = 0;

  ContentSearchNotifier(this._ref) : super(const ContentSearchState());

  void search(String query) {
    _debounce?.cancel();
    _cancelToken?.cancel('superseded');
    _requestSeq++;

    if (query.trim().isEmpty) {
      state = ContentSearchState(selectedType: state.selectedType);
      return;
    }

    state = state.copyWith(
      query: query,
      isLoading: true,
      isLoadingMore: false,
      currentPage: 1,
      hasMore: false,
      clearError: true,
    );

    final seq = _requestSeq;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query.trim(), page: 1, seq: seq);
    });
  }

  void setType(SearchEntityType? type) {
    if (state.selectedType == type) return;
    _debounce?.cancel();
    _cancelToken?.cancel('type_changed');
    _requestSeq++;

    state = state.copyWith(
      selectedType: type,
      clearType: type == null,
      items: const [],
      currentPage: 1,
      hasMore: false,
      clearError: true,
    );

    final cleanQ = state.query.trim();
    if (cleanQ.isNotEmpty) {
      final seq = _requestSeq;
      state = state.copyWith(isLoading: true);
      _performSearch(cleanQ, page: 1, seq: seq);
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final cleanQ = state.query.trim();
    if (cleanQ.isEmpty) return;

    final seq = _requestSeq;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    await _performSearch(
      cleanQ,
      page: state.currentPage + 1,
      seq: seq,
      isLoadMore: true,
    );
  }

  Future<void> retry() async {
    final cleanQ = state.query.trim();
    if (cleanQ.isEmpty) return;
    _debounce?.cancel();
    _cancelToken?.cancel('retry');
    _requestSeq++;
    final seq = _requestSeq;
    state = state.copyWith(isLoading: true, clearError: true, currentPage: 1);
    await _performSearch(cleanQ, page: 1, seq: seq);
  }

  Future<void> _performSearch(
    String cleanQ, {
    required int page,
    required int seq,
    bool isLoadMore = false,
  }) async {
    final token = CancelToken();
    _cancelToken = token;

    try {
      final repo = _ref.read(searchRepositoryProvider);
      final resp = await repo.search(
        query: cleanQ,
        type: state.selectedType,
        page: page,
        limit: state.selectedType != null ? 20 : 12,
        cancelToken: token,
      );

      if (!mounted || seq != _requestSeq || token.isCancelled) return;

      final mapped = _flattenResults(resp.results);
      final merged = isLoadMore ? _dedupMerge(state.items, mapped) : mapped;

      final hasMore = state.selectedType != null
          ? mapped.length >= 20
          : resp.results.totalCount >= 10 && mapped.isNotEmpty;

      state = state.copyWith(
        items: merged,
        isLoading: false,
        isLoadingMore: false,
        currentPage: page,
        hasMore: hasMore,
        clearError: true,
      );

      if (page == 1 && mapped.isNotEmpty) {
        _ref.read(recentSearchesProvider.notifier).add(cleanQ);
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (!mounted || seq != _requestSeq) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Search failed. Check your connection and retry.',
      );
    } catch (e) {
      if (!mounted || seq != _requestSeq) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: 'Search failed: ${e.toString()}',
      );
    }
  }

  List<ContentSearchItem> _flattenResults(SearchResultsDto r) {
    return [
      ...r.videos.map(ContentSearchItem.fromVideo),
      ...r.books.map(ContentSearchItem.fromBook),
      ...r.channels.map(ContentSearchItem.fromChannel),
      ...r.groups.map(ContentSearchItem.fromGroup),
      ...r.users.map(ContentSearchItem.fromUser),
      ...r.posts.map(ContentSearchItem.fromPost),
      ...r.streams.map(ContentSearchItem.fromStream),
      ...r.reels.map(ContentSearchItem.fromReel),
    ];
  }

  List<ContentSearchItem> _dedupMerge(
    List<ContentSearchItem> existing,
    List<ContentSearchItem> incoming,
  ) {
    final keys = existing.map((e) => '${e.entityType}:${e.id}').toSet();
    return [
      ...existing,
      ...incoming.where((e) => !keys.contains('${e.entityType}:${e.id}')),
    ];
  }

  void clear() {
    _debounce?.cancel();
    _cancelToken?.cancel('cleared');
    _cancelToken = null;
    _requestSeq++;
    state = ContentSearchState(selectedType: state.selectedType);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel('disposed');
    super.dispose();
  }
}

final contentSearchProvider = StateNotifierProvider.autoDispose<
    ContentSearchNotifier, ContentSearchState>((ref) {
  return ContentSearchNotifier(ref);
});
