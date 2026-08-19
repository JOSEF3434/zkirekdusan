// lib/features/groups/presentation/providers/group_members_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/groups/data/group_repository.dart';
import 'package:mobile/features/groups/domain/group_enums.dart';
import 'package:mobile/features/groups/domain/group_member_dto.dart';

class GroupMembersState {
  final List<GroupMemberDto> members;
  final bool isLoading;
  final bool isFetchingMore;
  final String? error;
  final bool hasNext;
  final int page;
  final int total;

  const GroupMembersState({
    this.members = const [],
    this.isLoading = false,
    this.isFetchingMore = false,
    this.error,
    this.hasNext = false,
    this.page = 1,
    this.total = 0,
  });

  GroupMembersState copyWith({
    List<GroupMemberDto>? members,
    bool? isLoading,
    bool? isFetchingMore,
    String? error,
    bool? hasNext,
    int? page,
    int? total,
    bool clearError = false,
  }) {
    return GroupMembersState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      error: clearError ? null : (error ?? this.error),
      hasNext: hasNext ?? this.hasNext,
      page: page ?? this.page,
      total: total ?? this.total,
    );
  }
}

final groupMembersProvider = StateNotifierProvider.family<
    GroupMembersNotifier, GroupMembersState, String>(
  (ref, groupId) => GroupMembersNotifier(
    ref.watch(groupRepositoryProvider),
    groupId,
  ),
);

class GroupMembersNotifier extends StateNotifier<GroupMembersState> {
  final GroupRepository _repository;
  final String _groupId;

  GroupMembersNotifier(this._repository, this._groupId)
      : super(const GroupMembersState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _repository.getGroupMembers(_groupId, page: 1, limit: 30);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        members: res.items,
        hasNext: res.hasNext,
        page: 1,
        total: res.total,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(clearError: true);
    try {
      final res = await _repository.getGroupMembers(_groupId, page: 1, limit: 30);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isFetchingMore: false,
        members: res.items,
        hasNext: res.hasNext,
        page: 1,
        total: res.total,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isFetchingMore || !state.hasNext) return;
    state = state.copyWith(isFetchingMore: true, clearError: true);
    try {
      final nextPage = state.page + 1;
      final res = await _repository.getGroupMembers(
        _groupId,
        page: nextPage,
        limit: 30,
      );
      if (!mounted) return;
      state = state.copyWith(
        isFetchingMore: false,
        members: [...state.members, ...res.items],
        hasNext: res.hasNext,
        page: nextPage,
        total: res.total,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isFetchingMore: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> updateMemberRole(String userId, GroupRole newRole) async {
    await _repository.updateMemberRole(_groupId, userId, newRole);
    // Optimistically update local list
    state = state.copyWith(
      members: state.members.map((m) {
        if (m.userId == userId) {
          return m.copyWith(role: newRole);
        }
        return m;
      }).toList(),
    );
  }

  Future<void> removeMember(String userId) async {
    await _repository.removeMember(_groupId, userId);
    state = state.copyWith(
      members: state.members.where((m) => m.userId != userId).toList(),
      total: state.total > 0 ? state.total - 1 : 0,
    );
  }
}
