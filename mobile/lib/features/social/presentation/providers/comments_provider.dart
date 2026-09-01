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
  final Set<String> likedCommentIds;

  const CommentsState({
    this.comments = const [],
    this.meta,
    this.isLoadingMore = false,
    this.error,
    this.likedCommentIds = const {},
  });

  CommentsState copyWith({
    List<CommentResponseDto>? comments,
    FeedMetaDto? meta,
    bool? isLoadingMore,
    String? error,
    Set<String>? likedCommentIds,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      meta: meta ?? this.meta,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      likedCommentIds: likedCommentIds ?? this.likedCommentIds,
    );
  }
}

final commentsProvider =
    AsyncNotifierProviderFamily<CommentsNotifier, CommentsState, (String, bool)>(() {
      return CommentsNotifier();
    });

class CommentsNotifier extends FamilyAsyncNotifier<CommentsState, (String, bool)> {
  CancelToken? _cancelToken;

  @override
  Future<CommentsState> build((String, bool) arg) async {
    _cancelToken = CancelToken();
    ref.onDispose(() => _cancelToken?.cancel());

    final repo = ref.read(socialRepositoryProvider);
    final response = await repo.getComments(
      arg.$1,
      cancelToken: _cancelToken,
      isVideo: arg.$2,
    );

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
        arg.$1,
        page: nextPage,
        cancelToken: _cancelToken,
        isVideo: arg.$2,
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
      final newComment = await repo.createComment(
        arg.$1,
        content,
        isVideo: arg.$2,
      );

      state = AsyncValue.data(
        currentState.copyWith(comments: [newComment, ...currentState.comments]),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleCommentLike(String commentId) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final isCurrentlyLiked = currentState.likedCommentIds.contains(commentId);
    final updatedLikedIds = Set<String>.from(currentState.likedCommentIds);
    if (isCurrentlyLiked) {
      updatedLikedIds.remove(commentId);
    } else {
      updatedLikedIds.add(commentId);
    }

    final updatedComments = currentState.comments.map((comment) {
      if (comment.id == commentId) {
        final newCount = isCurrentlyLiked
            ? (comment.likesCount > 0 ? comment.likesCount - 1 : 0)
            : comment.likesCount + 1;
        return comment.copyWith(likesCount: newCount);
      }
      return comment;
    }).toList();

    state = AsyncValue.data(
      currentState.copyWith(
        comments: updatedComments,
        likedCommentIds: updatedLikedIds,
      ),
    );

    try {
      final repo = ref.read(socialRepositoryProvider);
      await repo.toggleCommentLike(commentId);
    } catch (e) {
      state = AsyncValue.data(currentState);
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

