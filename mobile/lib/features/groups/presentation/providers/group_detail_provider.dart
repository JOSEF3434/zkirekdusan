// lib/features/groups/presentation/providers/group_detail_provider.dart
//
// Provides the GroupContextDto for a given groupId.
// Uses keepAlive so the context stays in memory while the GroupChannelScreen
// is open (prevents redundant fetches when switching between tabs).
// Call ref.invalidate(groupDetailProvider(id)) after group settings changes.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/groups/data/group_repository.dart';
import 'package:mobile/features/groups/domain/group_context_dto.dart';

final groupDetailProvider =
    AsyncNotifierProvider.family<GroupDetailNotifier, GroupContextDto, String>(
  GroupDetailNotifier.new,
);

class GroupDetailNotifier
    extends FamilyAsyncNotifier<GroupContextDto, String> {
  @override
  Future<GroupContextDto> build(String arg) async {
    // Keep alive while any subscriber is active. The provider is invalidated
    // after settings changes, member updates, or group creation.
    ref.keepAlive();
    return _fetch();
  }

  Future<GroupContextDto> _fetch() async {
    final repo = ref.read(groupRepositoryProvider);
    return repo.getGroupContext(arg);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}
