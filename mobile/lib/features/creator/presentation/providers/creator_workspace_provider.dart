// lib/features/creator/presentation/providers/creator_workspace_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/creator/data/creator_repository.dart';
import 'package:mobile/features/creator/domain/creator_enums.dart';
import 'package:mobile/features/creator/domain/creator_group_dto.dart';
import 'package:mobile/features/creator/domain/creator_permission_service.dart';

enum CreateGroupStatus { idle, loading, success, error }

final creatorWorkspaceProvider = StateNotifierProvider<
  CreatorWorkspaceNotifier,
  CreatorWorkspaceState
>((ref) {
  return CreatorWorkspaceNotifier(
    ref.watch(creatorRepositoryProvider),
    ref.watch(creatorPermissionServiceProvider),
  );
});

class CreatorWorkspaceState {
  final bool isLoading;
  final bool isPaginating;
  final String? error;
  final List<CreatorGroupDto> groups; // Replaces split active/pending lists
  final bool hasNextPage;
  final int currentPage;

  // State for the create operation
  final CreateGroupStatus createGroupStatus;
  final String? createGroupError;
  final CreatorGroupDto? lastCreatedGroup;

  const CreatorWorkspaceState({
    this.isLoading = true,
    this.isPaginating = false,
    this.error,
    this.groups = const [],
    this.hasNextPage = false,
    this.currentPage = 1,
    this.createGroupStatus = CreateGroupStatus.idle,
    this.createGroupError,
    this.lastCreatedGroup,
  });

  CreatorWorkspaceState copyWith({
    bool? isLoading,
    bool? isPaginating,
    String? error,
    List<CreatorGroupDto>? groups,
    bool? hasNextPage,
    int? currentPage,
    bool clearError = false,
    CreateGroupStatus? createGroupStatus,
    String? createGroupError,
    CreatorGroupDto? lastCreatedGroup,
    bool clearCreateState = false,
  }) {
    return CreatorWorkspaceState(
      isLoading: isLoading ?? this.isLoading,
      isPaginating: isPaginating ?? this.isPaginating,
      error: clearError ? null : (error ?? this.error),
      groups: groups ?? this.groups,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      currentPage: currentPage ?? this.currentPage,
      createGroupStatus:
          clearCreateState
              ? CreateGroupStatus.idle
              : (createGroupStatus ?? this.createGroupStatus),
      createGroupError:
          clearCreateState ? null : (createGroupError ?? this.createGroupError),
      lastCreatedGroup:
          clearCreateState ? null : (lastCreatedGroup ?? this.lastCreatedGroup),
    );
  }
}

class CreatorWorkspaceNotifier extends StateNotifier<CreatorWorkspaceState> {
  final CreatorRepository _repository;
  final CreatorPermissionService _permissionService;

  CreatorWorkspaceNotifier(this._repository, this._permissionService)
    : super(const CreatorWorkspaceState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (!_permissionService.canAccessWorkspace()) {
        throw Exception(
          "You must be logged in to access the Creator Workspace.",
        );
      }

      // Fetch first page of ALL user's groups
      final result = await _repository.getMyGroups(page: 1);

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        groups: result.items,
        hasNextPage: result.hasNextPage,
        currentPage: 1,
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
    await loadInitial();
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isPaginating || !state.hasNextPage) return;

    state = state.copyWith(isPaginating: true, clearError: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = await _repository.getMyGroups(page: nextPage);

      if (!mounted) return;
      state = state.copyWith(
        isPaginating: false,
        groups: [...state.groups, ...result.items],
        hasNextPage: result.hasNextPage,
        currentPage: nextPage,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isPaginating: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> createGroup({
    required String name,
    required String slug,
    String? description,
    required GroupVisibility visibility,
  }) async {
    if (!_permissionService.canCreateGroup()) {
      state = state.copyWith(
        createGroupStatus: CreateGroupStatus.error,
        createGroupError: "You don't have permission to create a group.",
      );
      return;
    }

    state = state.copyWith(
      createGroupStatus: CreateGroupStatus.loading,
      clearCreateState: false,
    );

    try {
      final newGroup = await _repository.createGroup(
        name: name,
        slug: slug,
        description: description,
        visibility: visibility,
      );

      if (!mounted) return;

      // Update state to show the new group immediately at the top
      state = state.copyWith(
        groups: [newGroup, ...state.groups],
        createGroupStatus: CreateGroupStatus.success,
        lastCreatedGroup: newGroup,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        createGroupStatus: CreateGroupStatus.error,
        createGroupError: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void resetCreateState() {
    state = state.copyWith(clearCreateState: true);
  }
}
