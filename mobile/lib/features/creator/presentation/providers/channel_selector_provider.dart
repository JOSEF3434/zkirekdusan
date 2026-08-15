// lib/features/creator/presentation/providers/channel_selector_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/creator/data/creator_repository.dart';
import 'package:mobile/features/creator/domain/creator_channel_dto.dart';
import 'package:mobile/features/creator/domain/creator_group_dto.dart';
import 'package:mobile/features/creator/domain/creator_permission_service.dart';

final channelSelectorProvider = StateNotifierProvider.autoDispose
    .family<ChannelSelectorNotifier, ChannelSelectorState, CreatorGroupDto>((
      ref,
      group,
    ) {
      return ChannelSelectorNotifier(
        group,
        ref.watch(creatorRepositoryProvider),
        ref.watch(creatorPermissionServiceProvider),
      );
    });

class ChannelSelectorState {
  final bool isLoading;
  final String? error;
  final List<CreatorChannelDto> channels;

  const ChannelSelectorState({
    this.isLoading = true,
    this.error,
    this.channels = const [],
  });

  ChannelSelectorState copyWith({
    bool? isLoading,
    String? error,
    List<CreatorChannelDto>? channels,
    bool clearError = false,
  }) {
    return ChannelSelectorState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      channels: channels ?? this.channels,
    );
  }
}

class ChannelSelectorNotifier extends StateNotifier<ChannelSelectorState> {
  final CreatorGroupDto _group;
  final CreatorRepository _repository;
  final CreatorPermissionService _permissionService;

  ChannelSelectorNotifier(
    this._group,
    this._repository,
    this._permissionService,
  ) : super(const ChannelSelectorState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final channels = await _repository.getGroupVideoChannels(_group.id);
      state = state.copyWith(isLoading: false, channels: channels);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> refresh() async {
    await load();
  }

  Future<void> createChannel({
    required String name,
    required String slug,
    required String handle,
    String? description,
  }) async {
    if (!_permissionService.canCreateChannel(_group)) {
      throw Exception(
        "You don't have permission to create a channel in this group.",
      );
    }

    final newChannel = await _repository.createVideoChannel(
      groupId: _group.id,
      name: name,
      slug: slug,
      handle: handle,
      description: description,
    );

    state = state.copyWith(channels: [...state.channels, newChannel]);
  }
}
