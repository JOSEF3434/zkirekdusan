// lib/core/rich_text/providers/mention_suggestions_provider.dart
//
// Riverpod providers for @ mention autocomplete state.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';
import 'package:mobile/core/rich_text/repository/mention_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class MentionSuggestionsState {
  final String query;
  final List<MentionSuggestion> suggestions;
  final bool isLoading;

  const MentionSuggestionsState({
    this.query = '',
    this.suggestions = const [],
    this.isLoading = false,
  });

  MentionSuggestionsState copyWith({
    String? query,
    List<MentionSuggestion>? suggestions,
    bool? isLoading,
  }) =>
      MentionSuggestionsState(
        query: query ?? this.query,
        suggestions: suggestions ?? this.suggestions,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class MentionSuggestionsNotifier
    extends StateNotifier<MentionSuggestionsState> {
  final MentionRepository _repo;
  Timer? _debounce;

  MentionSuggestionsNotifier(this._repo)
      : super(const MentionSuggestionsState());

  void search(String query) {
    _debounce?.cancel();

    if (query.isEmpty) {
      state = const MentionSuggestionsState();
      return;
    }

    state = state.copyWith(query: query, isLoading: true);

    _debounce = Timer(const Duration(milliseconds: 280), () async {
      final results = await _repo.suggestMentions(query, limit: 8);
      if (mounted) {
        state = state.copyWith(suggestions: results, isLoading: false);
      }
    });
  }

  void clear() {
    _debounce?.cancel();
    state = const MentionSuggestionsState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final mentionSuggestionsProvider = StateNotifierProvider.autoDispose<
    MentionSuggestionsNotifier, MentionSuggestionsState>((ref) {
  return MentionSuggestionsNotifier(ref.watch(mentionRepositoryProvider));
});
