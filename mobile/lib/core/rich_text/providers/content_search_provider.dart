// lib/core/rich_text/providers/content_search_provider.dart
//
// Riverpod provider for # content search state.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';
import 'package:mobile/core/rich_text/repository/mention_repository.dart';

class ContentSearchState {
  final String query;
  final List<ContentSearchItem> items;
  final bool isLoading;
  final String? error;

  const ContentSearchState({
    this.query = '',
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  ContentSearchState copyWith({
    String? query,
    List<ContentSearchItem>? items,
    bool? isLoading,
    String? error,
  }) =>
      ContentSearchState(
        query: query ?? this.query,
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class ContentSearchNotifier extends StateNotifier<ContentSearchState> {
  final MentionRepository _repo;
  Timer? _debounce;

  ContentSearchNotifier(this._repo) : super(const ContentSearchState());

  void search(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      state = const ContentSearchState();
      return;
    }

    state = state.copyWith(query: query, isLoading: true, error: null);

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final items = await _repo.searchContent(query, limit: 15);
        if (mounted) {
          state = state.copyWith(items: items, isLoading: false);
        }
      } catch (e) {
        if (mounted) {
          state = state.copyWith(
            isLoading: false,
            error: 'Search failed. Please try again.',
          );
        }
      }
    });
  }

  void clear() {
    _debounce?.cancel();
    state = const ContentSearchState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final contentSearchProvider = StateNotifierProvider.autoDispose<
    ContentSearchNotifier, ContentSearchState>((ref) {
  return ContentSearchNotifier(ref.watch(mentionRepositoryProvider));
});
