// lib/features/social/presentation/providers/follow_provider.dart
// Scoped follow-state provider per user ID with optimistic updates and rollback.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/social/data/follows_repository.dart';

// ── Follow State ──────────────────────────────────────────────────────────────

class FollowState {
  final bool isFollowing;
  final bool isFollowedBy;
  final bool isLoading;
  final String? error;

  const FollowState({
    this.isFollowing = false,
    this.isFollowedBy = false,
    this.isLoading = false,
    this.error,
  });

  FollowState copyWith({
    bool? isFollowing,
    bool? isFollowedBy,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return FollowState(
      isFollowing: isFollowing ?? this.isFollowing,
      isFollowedBy: isFollowedBy ?? this.isFollowedBy,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Family provider scoped per target user ID.
final followProvider =
    AsyncNotifierProviderFamily<FollowNotifier, FollowState, String>(
      FollowNotifier.new,
    );

class FollowNotifier extends FamilyAsyncNotifier<FollowState, String> {
  String get _userId => arg;
  bool _actionInProgress = false;

  @override
  Future<FollowState> build(String arg) async {
    final repo = ref.read(followsRepositoryProvider);
    final status = await repo.getFollowStatus(_userId);
    return FollowState(
      isFollowing: status.isFollowing,
      isFollowedBy: status.isFollowedBy,
    );
  }

  Future<void> follow() async {
    if (_actionInProgress) return;
    final current = state.valueOrNull;
    if (current == null || current.isFollowing) return;

    _actionInProgress = true;

    // Optimistic update
    state = AsyncValue.data(
      current.copyWith(isFollowing: true, isLoading: true),
    );

    try {
      final repo = ref.read(followsRepositoryProvider);
      await repo.followUser(_userId);
      state = AsyncValue.data(
        current.copyWith(isFollowing: true, isLoading: false, clearError: true),
      );
    } catch (e) {
      // Rollback
      state = AsyncValue.data(
        current.copyWith(
          isFollowing: false,
          isLoading: false,
          error: e.toString(),
        ),
      );
    } finally {
      _actionInProgress = false;
    }
  }

  Future<void> unfollow() async {
    if (_actionInProgress) return;
    final current = state.valueOrNull;
    if (current == null || !current.isFollowing) return;

    _actionInProgress = true;

    // Optimistic update
    state = AsyncValue.data(
      current.copyWith(isFollowing: false, isLoading: true),
    );

    try {
      final repo = ref.read(followsRepositoryProvider);
      await repo.unfollowUser(_userId);
      state = AsyncValue.data(
        current.copyWith(
          isFollowing: false,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      // Rollback
      state = AsyncValue.data(
        current.copyWith(
          isFollowing: true,
          isLoading: false,
          error: e.toString(),
        ),
      );
    } finally {
      _actionInProgress = false;
    }
  }

  Future<void> toggle() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.isFollowing) {
      await unfollow();
    } else {
      await follow();
    }
  }
}
