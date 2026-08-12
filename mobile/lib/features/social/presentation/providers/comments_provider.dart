import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/social/data/social_repository.dart';
import 'package:mobile/features/social/domain/comment_model.dart';
import 'package:mobile/features/home/domain/feed_response.dart';

class CommentsState {
  final List<CommentResponseDto> comments;
  final FeedMetaDto? meta;
  final bool isLoadingMore;
  final String? error;

  const CommentsState({
    this.comments = const [],
    this.meta,
    this.isLoadingMore = false,
    this.error,
  });

  CommentsState copyWith({
    List<CommentResponseDto>? comments,
    FeedMetaDto? meta,
    bool? isLoadingMore,
    String? error,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      meta: meta ?? this.meta,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error, // Can be set to null
    );
  }
}

final commentsProvider =
    AsyncNotifierProviderFamily<CommentsNotifier, CommentsState, String>(() {
      return CommentsNotifier();
    });

class CommentsNotifier extends FamilyAsyncNotifier<CommentsState, String> {
  CancelToken? _cancelToken;

  @override
  Future<CommentsState> build(String arg) async {
    _cancelToken = CancelToken();
    ref.onDispose(() => _cancelToken?.cancel());

    final repo = ref.read(socialRepositoryProvider);
    final response = await repo.getComments(arg, cancelToken: _cancelToken);

    return CommentsState(comments: response.data, meta: response.meta);
  }

  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.isLoadingMore) return;
    if (currentState.meta != null && !currentState.meta!.hasNext) return;

    state = AsyncValue.data(
      currentState.copyWith(isLoadingMore: true, error: null),
    );

    try {
      final repo = ref.read(socialRepositoryProvider);
      final nextPage = (currentState.meta?.page ?? 0) + 1;
      final response = await repo.getComments(
        arg,
        page: nextPage,
        cancelToken: _cancelToken,
      );

      state = AsyncValue.data(
        currentState.copyWith(
          comments: [...currentState.comments, ...response.data],
          meta: response.meta,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        currentState.copyWith(isLoadingMore: false, error: e.toString()),
      );
    }
  }

  Future<void> createComment(String content) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    try {
      final repo = ref.read(socialRepositoryProvider);
      final newComment = await repo.createComment(arg, content);

      state = AsyncValue.data(
        currentState.copyWith(comments: [newComment, ...currentState.comments]),
      );
    } catch (e) {
      // Could throw to UI to show snackbar
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    try {
      final repo = ref.read(socialRepositoryProvider);
      await repo.deleteComment(commentId);

      state = AsyncValue.data(
        currentState.copyWith(
          comments: currentState.comments
              .where((c) => c.id != commentId)
              .toList(),
        ),
      );
    } catch (e) {
      rethrow;
    }
  }
}
