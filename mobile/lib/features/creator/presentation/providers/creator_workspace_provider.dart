// lib/features/creator/presentation/providers/creator_workspace_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/creator/data/creator_repository.dart';
import 'package:mobile/features/creator/data/pending_groups_storage.dart';
import 'package:mobile/features/creator/domain/creator_enums.dart';
import 'package:mobile/features/creator/domain/creator_group_dto.dart';
import 'package:mobile/features/creator/domain/creator_permission_service.dart';

final creatorWorkspaceProvider =
    StateNotifierProvider.autoDispose<CreatorWorkspaceNotifier, CreatorWorkspaceState>((ref) {
  return CreatorWorkspaceNotifier(
    ref.watch(creatorRepositoryProvider),
    ref.watch(pendingGroupsStorageProvider),
    ref.watch(creatorPermissionServiceProvider),
  );
});

class CreatorWorkspaceState {
  final bool isLoading;
  final bool isPaginating;
  final String? error;
  final List<CreatorGroupDto> activeGroups;
  final List<CreatorGroupDto> pendingGroups;
  final bool hasNextPage;
  final int currentPage;

  const CreatorWorkspaceState({
    this.isLoading = true,
    this.isPaginating = false,
    this.error,
    this.activeGroups = const [],
    this.pendingGroups = const [],
    this.hasNextPage = false,
    this.currentPage = 1,
  });

  CreatorWorkspaceState copyWith({
    bool? isLoading,
    bool? isPaginating,
    String? error,
    List<CreatorGroupDto>? activeGroups,
    List<CreatorGroupDto>? pendingGroups,
    bool? hasNextPage,
    int? currentPage,
    bool clearError = false,
  }) {
    return CreatorWorkspaceState(
      isLoading: isLoading ?? this.isLoading,
      isPaginating: isPaginating ?? this.isPaginating,
      error: clearError ? null : (error ?? this.error),
      activeGroups: activeGroups ?? this.activeGroups,
      pendingGroups: pendingGroups ?? this.pendingGroups,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class CreatorWorkspaceNotifier extends StateNotifier<CreatorWorkspaceState> {
  final CreatorRepository _repository;
  final PendingGroupsStorage _pendingStorage;
  final CreatorPermissionService _permissionService;

  CreatorWorkspaceNotifier(this._repository, this._pendingStorage, this._permissionService)
      : super(const CreatorWorkspaceState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (!_permissionService.canAccessWorkspace()) {
        throw Exception("You must be logged in to access the Creator Workspace.");
      }

      // Load pending groups from local storage
      final pending = await _pendingStorage.getPendingGroups();

      // Fetch first page of active groups
      final result = await _repository.getActiveGroups(page: 1);

      // We might have groups in pending storage that have since been approved and returned in active list.
      // Let's filter out any pending groups that appear in the active list.
      final activeIds = result.items.map((e) => e.id).toSet();
      final validPending = pending.where((p) => !activeIds.contains(p.id)).toList();

      // Clean up storage if some were approved
      if (validPending.length < pending.length) {
        for (final p in pending) {
          if (activeIds.contains(p.id)) {
            await _pendingStorage.removePendingGroup(p.id);
          }
        }
      }

      state = state.copyWith(
        isLoading: false,
        activeGroups: result.items,
        pendingGroups: validPending,
        hasNextPage: result.hasNextPage,
        currentPage: 1,
      );
    } catch (e) {
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
      final result = await _repository.getActiveGroups(page: nextPage);

      final activeIds = result.items.map((e) => e.id).toSet();
      final validPending = state.pendingGroups.where((p) => !activeIds.contains(p.id)).toList();

      state = state.copyWith(
        isPaginating: false,
        activeGroups: [...state.activeGroups, ...result.items],
        pendingGroups: validPending,
        hasNextPage: result.hasNextPage,
        currentPage: nextPage,
      );
    } catch (e) {
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
      throw Exception("You don't have permission to create a group.");
    }
    
    final newGroup = await _repository.createGroup(
      name: name,
      slug: slug,
      description: description,
      visibility: visibility,
    );

    // Save to local pending storage
    await _pendingStorage.addPendingGroup(newGroup);

    // Update state to show the pending group immediately at the top
    state = state.copyWith(
      pendingGroups: [newGroup, ...state.pendingGroups],
    );
  }
}
