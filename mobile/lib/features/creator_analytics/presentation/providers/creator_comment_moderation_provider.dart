// lib/features/creator_analytics/presentation/providers/creator_comment_moderation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/creator_analytics/data/creator_analytics_repository.dart';
import 'package:mobile/features/creator_analytics/domain/creator_comment_dto.dart';

final creatorCommentModerationProvider = StateNotifierProvider.autoDispose
    .family<
      CreatorCommentModerationNotifier,
      CreatorCommentModerationState,
      String
    >((ref, videoId) {
      return CreatorCommentModerationNotifier(
        ref.watch(creatorAnalyticsRepositoryProvider),
        videoId,
      );
    });

class CreatorCommentModerationState {
  final bool isLoading;
  final bool isPaginating;
  final String? error;
  final List<CreatorCommentDto> comments;
  final int currentPage;
  final bool hasMore;

  const CreatorCommentModerationState({
    this.isLoading = true,
    this.isPaginating = false,
    this.error,
    this.comments = const [],
    this.currentPage = 1,
    this.hasMore = false,
  });

  CreatorCommentModerationState copyWith({
    bool? isLoading,
    bool? isPaginating,
    String? error,
    List<CreatorCommentDto>? comments,
    int? currentPage,
    bool? hasMore,
    bool clearError = false,
  }) => CreatorCommentModerationState(
    isLoading: isLoading ?? this.isLoading,
    isPaginating: isPaginating ?? this.isPaginating,
    error: clearError ? null : (error ?? this.error),
    comments: comments ?? this.comments,
    currentPage: currentPage ?? this.currentPage,
    hasMore: hasMore ?? this.hasMore,
  );
}

class CreatorCommentModerationNotifier
    extends StateNotifier<CreatorCommentModerationState> {
  final CreatorAnalyticsRepository _repo;
  final String _videoId;

  CreatorCommentModerationNotifier(this._repo, this._videoId)
    : super(const CreatorCommentModerationState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.getVideoComments(videoId: _videoId, page: 1);
      state = state.copyWith(
        isLoading: false,
        comments: result.items,
        currentPage: result.currentPage,
        hasMore: result.hasNextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> refresh() => load();

  Future<void> loadMore() async {
    if (state.isLoading || state.isPaginating || !state.hasMore) return;
    state = state.copyWith(isPaginating: true, clearError: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = await _repo.getVideoComments(
        videoId: _videoId,
        page: nextPage,
      );
      state = state.copyWith(
        isPaginating: false,
        comments: [...state.comments, ...result.items],
        currentPage: result.currentPage,
        hasMore: result.hasNextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isPaginating: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> deleteComment(String commentId) async {
    final prev = List<CreatorCommentDto>.from(state.comments);
    state = state.copyWith(
      comments: state.comments.where((c) => c.id != commentId).toList(),
    );
    try {
      await _repo.deleteComment(videoId: _videoId, commentId: commentId);
    } catch (e) {
      state = state.copyWith(
        comments: prev,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> togglePin(String commentId) async {
    final prev = List<CreatorCommentDto>.from(state.comments);
    state = state.copyWith(
      comments: state.comments.map((c) {
        if (c.id == commentId) {
          return c.copyWith(isPinned: !c.isPinned);
        }
        return c;
      }).toList(),
    );
    try {
      await _repo.togglePinComment(videoId: _videoId, commentId: commentId);
    } catch (e) {
      state = state.copyWith(
        comments: prev,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }
}
