import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/social/data/social_repository.dart';

class LikeState {
  final bool isLiked;
  final int likesCount;

  const LikeState({required this.isLiked, required this.likesCount});

  LikeState copyWith({bool? isLiked, int? likesCount}) {
    return LikeState(
      isLiked: isLiked ?? this.isLiked,
      likesCount: likesCount ?? this.likesCount,
    );
  }
}

final likesProvider = NotifierProvider<LikesNotifier, Map<String, LikeState>>(
  () {
    return LikesNotifier();
  },
);

class LikesNotifier extends Notifier<Map<String, LikeState>> {
  @override
  Map<String, LikeState> build() {
    return {};
  }

  void seed(String postId, bool isLiked, int likesCount) {
    if (!state.containsKey(postId)) {
      // Use Future.microtask to avoid modifying state during build
      Future.microtask(() {
        state = {
          ...state,
          postId: LikeState(isLiked: isLiked, likesCount: likesCount),
        };
      });
    }
  }

  Future<void> toggleLike(String postId, {bool isVideo = false}) async {
    final currentState = state[postId];
    if (currentState == null) return;

    final wasLiked = currentState.isLiked;
    final newCount = wasLiked
        ? currentState.likesCount - 1
        : currentState.likesCount + 1;

    // Optimistic update
    state = {
      ...state,
      postId: currentState.copyWith(isLiked: !wasLiked, likesCount: newCount),
    };

    try {
      final repo = ref.read(socialRepositoryProvider);
      if (isVideo) {
        await repo.toggleVideoLike(postId, liked: !wasLiked);
      } else {
        await repo.togglePostLike(postId);
      }
    } catch (e) {
      // Revert on error
      state = {...state, postId: currentState};
    }
  }
}
