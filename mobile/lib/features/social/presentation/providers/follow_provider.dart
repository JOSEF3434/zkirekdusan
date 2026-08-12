import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/social/data/follow_repository.dart';
import 'package:mobile/features/social/domain/follow_model.dart';

final followProvider =
    AsyncNotifierProviderFamily<FollowNotifier, FollowStatusDto, String>(() {
      return FollowNotifier();
    });

class FollowNotifier extends FamilyAsyncNotifier<FollowStatusDto, String> {
  @override
  Future<FollowStatusDto> build(String arg) async {
    final repo = ref.read(followRepositoryProvider);
    return repo.getFollowStatus(arg);
  }

  Future<void> follow() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // Optimistic update
    state = AsyncValue.data(
      FollowStatusDto(
        isFollowing: true,
        isFollowedBy: currentState.isFollowedBy,
      ),
    );

    try {
      final repo = ref.read(followRepositoryProvider);
      await repo.followUser(arg);
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(currentState);
      rethrow;
    }
  }

  Future<void> unfollow() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // Optimistic update
    state = AsyncValue.data(
      FollowStatusDto(
        isFollowing: false,
        isFollowedBy: currentState.isFollowedBy,
      ),
    );

    try {
      final repo = ref.read(followRepositoryProvider);
      await repo.unfollowUser(arg);
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(currentState);
      rethrow;
    }
  }
}
