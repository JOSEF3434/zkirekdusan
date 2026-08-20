import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/admin/data/admin_repository.dart';
import 'package:mobile/features/creator/domain/creator_group_dto.dart';

final pendingGroupsProvider =
    StateNotifierProvider<
      PendingGroupsNotifier,
      AsyncValue<List<CreatorGroupDto>>
    >((ref) {
      return PendingGroupsNotifier(ref.watch(adminRepositoryProvider));
    });

class PendingGroupsNotifier
    extends StateNotifier<AsyncValue<List<CreatorGroupDto>>> {
  final AdminRepository _repository;

  PendingGroupsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPendingGroups();
  }

  Future<void> loadPendingGroups() async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.getPendingGroups(
        limit: 50,
      ); // Get up to 50 for admin
      state = AsyncValue.data(result.items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> approveGroup(String groupId) async {
    try {
      await _repository.approveGroup(groupId);
      // Remove from list
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.where((g) => g.id != groupId).toList(),
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectGroup(String groupId) async {
    try {
      await _repository.rejectGroup(groupId);
      // Remove from list
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.where((g) => g.id != groupId).toList(),
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
