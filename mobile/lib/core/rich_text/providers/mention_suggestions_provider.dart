// lib/core/rich_text/providers/mention_suggestions_provider.dart
//
// Riverpod state management for @ mention autocomplete:
//   • Debounced requests
//   • CancelToken HTTP cancellation
//   • Monotonic request sequence guard against out-of-order responses
//   • Explicit error state with retry (never closes panel silently)
//   • Keyboard highlight index tracking

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';
import 'package:mobile/core/rich_text/repository/mention_repository.dart';

class MentionSuggestionsState {
  final String query;
  final List<MentionSuggestion> suggestions;
  final bool isLoading;
  final String? error;
  final int highlightedIndex;
  final bool hasSearched;

  const MentionSuggestionsState({
    this.query = '',
    this.suggestions = const [],
    this.isLoading = false,
    this.error,
    this.highlightedIndex = 0,
    this.hasSearched = false,
  });

  MentionSuggestionsState copyWith({
    String? query,
    List<MentionSuggestion>? suggestions,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? highlightedIndex,
    bool? hasSearched,
  }) =>
      MentionSuggestionsState(
        query: query ?? this.query,
        suggestions: suggestions ?? this.suggestions,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        highlightedIndex: highlightedIndex ?? this.highlightedIndex,
        hasSearched: hasSearched ?? this.hasSearched,
      );
}

class MentionSuggestionsNotifier
    extends StateNotifier<MentionSuggestionsState> {
  final MentionRepository _repo;
  Timer? _debounce;
  CancelToken? _cancelToken;
  int _requestSeq = 0;

  MentionSuggestionsNotifier(this._repo)
      : super(const MentionSuggestionsState());

  void search(String query) {
    final cleanQ = query.trim();
    _debounce?.cancel();
    _cancelToken?.cancel('superseded');
    _requestSeq++;

    state = state.copyWith(
      query: cleanQ,
      isLoading: true,
      clearError: true,
      highlightedIndex: 0,
    );

    // Fetch immediately on bare '@' (empty query) or debounce 220ms while typing
    final delay = cleanQ.isEmpty
        ? const Duration(milliseconds: 60)
        : const Duration(milliseconds: 220);

    final seq = _requestSeq;
    _debounce = Timer(delay, () => _executeSearch(cleanQ, seq));
  }

  Future<void> retry() async {
    _debounce?.cancel();
    _cancelToken?.cancel('retry');
    _requestSeq++;
    final seq = _requestSeq;
    final cleanQ = state.query;
    state = state.copyWith(isLoading: true, clearError: true);
    await _executeSearch(cleanQ, seq);
  }

  Future<void> _executeSearch(String query, int seq) async {
    final token = CancelToken();
    _cancelToken = token;

    try {
      final results = await _repo.suggestMentions(
        query,
        limit: 12,
        cancelToken: token,
      );

      if (!mounted || seq != _requestSeq || token.isCancelled) return;

      state = state.copyWith(
        suggestions: results,
        isLoading: false,
        clearError: true,
        highlightedIndex: 0,
        hasSearched: true,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (!mounted || seq != _requestSeq) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load mentions.',
        hasSearched: true,
      );
    } catch (e) {
      if (!mounted || seq != _requestSeq) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('AppException: ', ''),
        hasSearched: true,
      );
    }
  }

  void moveHighlight(int delta) {
    if (state.suggestions.isEmpty) return;
    final len = state.suggestions.length;
    final next = (state.highlightedIndex + delta) % len;
    state = state.copyWith(highlightedIndex: next < 0 ? len - 1 : next);
  }

  MentionSuggestion? get highlightedSuggestion {
    if (state.suggestions.isEmpty) return null;
    final idx = state.highlightedIndex.clamp(0, state.suggestions.length - 1);
    return state.suggestions[idx];
  }

  void clear() {
    _debounce?.cancel();
    _cancelToken?.cancel('cleared');
    _cancelToken = null;
    _requestSeq++;
    state = const MentionSuggestionsState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelToken?.cancel('disposed');
    super.dispose();
  }
}

final mentionSuggestionsProvider = StateNotifierProvider.autoDispose<
    MentionSuggestionsNotifier, MentionSuggestionsState>((ref) {
  return MentionSuggestionsNotifier(ref.watch(mentionRepositoryProvider));
});
