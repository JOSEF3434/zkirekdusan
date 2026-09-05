// lib/features/creator/presentation/providers/upload_channels_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/creator/data/creator_repository.dart';
import 'package:mobile/features/creator/domain/creator_channel_dto.dart';
import 'package:mobile/features/creator/domain/creator_enums.dart';
import 'package:mobile/features/creator/domain/creator_group_dto.dart';
import 'package:mobile/features/creator/domain/creator_permission_service.dart';
import 'package:mobile/features/upload/domain/group_channel_model.dart';

class PermittedUploadChannel {
  final CreatorGroupDto group;
  final CreatorChannelDto? channel;

  const PermittedUploadChannel({
    required this.group,
    this.channel,
  });

  String get displayName {
    if (channel != null &&
        channel!.name.isNotEmpty &&
        channel!.name != '${group.name} Channel') {
      return channel!.name;
    }
    return group.name;
  }

  GroupDto toGroupDto() {
    return GroupDto(
      id: group.id,
      name: group.name,
      description: group.description,
      avatarUrl: group.avatarUrl,
      coverUrl: group.coverUrl,
      status: group.status.name.toUpperCase(),
    );
  }

  VideoChannelDto toVideoChannelDto() {
    if (channel != null) {
      return VideoChannelDto(
        id: channel!.id,
        groupId: channel!.groupId,
        name: channel!.name,
        description: channel!.description,
        type: 'VOD',
        uploadPermission: channel!.uploadPermission
            .toString()
            .split('.')
            .last
            .toUpperCase(),
      );
    }
    return VideoChannelDto(
      id: group.id,
      groupId: group.id,
      name: '${group.name} Channel',
      description: group.description,
      type: 'VOD',
      uploadPermission: 'MEMBER',
    );
  }
}

class UploadChannelsState {
  final bool isLoading;
  final String? error;
  final List<PermittedUploadChannel> channels;
  final int pendingGroupsCount;

  const UploadChannelsState({
    this.isLoading = true,
    this.error,
    this.channels = const [],
    this.pendingGroupsCount = 0,
  });

  UploadChannelsState copyWith({
    bool? isLoading,
    String? error,
    List<PermittedUploadChannel>? channels,
    int? pendingGroupsCount,
    bool clearError = false,
  }) {
    return UploadChannelsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      channels: channels ?? this.channels,
      pendingGroupsCount: pendingGroupsCount ?? this.pendingGroupsCount,
    );
  }
}

final uploadChannelsProvider = StateNotifierProvider.autoDispose
    .family<UploadChannelsNotifier, UploadChannelsState, String?>((
      ref,
      groupIdFilter,
    ) {
      return UploadChannelsNotifier(
        groupIdFilter: groupIdFilter,
        repository: ref.watch(creatorRepositoryProvider),
        permissionService: ref.watch(creatorPermissionServiceProvider),
      );
    });

class UploadChannelsNotifier extends StateNotifier<UploadChannelsState> {
  final String? groupIdFilter;
  final CreatorRepository _repository;
  final CreatorPermissionService _permissionService;

  UploadChannelsNotifier({
    required this.groupIdFilter,
    required CreatorRepository repository,
    required CreatorPermissionService permissionService,
  }) : _repository = repository,
       _permissionService = permissionService,
       super(const UploadChannelsState()) {
    loadChannels();
  }

  Future<void> loadChannels() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (!_permissionService.isAuthenticated) {
        throw Exception('You must be signed in to upload videos.');
      }

      // 1. Fetch user's groups
      final paginatedGroups = await _repository.getMyGroups(
        page: 1,
        limit: 100,
      );
      final allGroups = paginatedGroups.items;

      int pendingCount = 0;
      final activeGroups = <CreatorGroupDto>[];

      for (final g in allGroups) {
        if (g.status == GroupStatus.pendingApproval) {
          pendingCount++;
        } else if (g.status == GroupStatus.active) {
          if (groupIdFilter == null || g.id == groupIdFilter) {
            activeGroups.add(g);
          }
        }
      }

      // 2. Fetch video channels for active groups
      final permittedChannels = <PermittedUploadChannel>[];

      await Future.wait(
        activeGroups.map((group) async {
          try {
            var channels = await _repository.getGroupVideoChannels(group.id);

            // If group doesn't have video channels yet, auto-provision on the fly
            if (channels.isEmpty) {
              try {
                final baseHandle = group.slug
                    .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
                    .toLowerCase();
                final rawHandle =
                    '@${baseHandle.isNotEmpty ? baseHandle : 'channel'}_${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';
                final handle = rawHandle.length > 30
                    ? rawHandle.substring(0, 30)
                    : rawHandle;
                final newChan = await _repository.createVideoChannel(
                  groupId: group.id,
                  name: '${group.name} Channel',
                  slug:
                      '${group.slug}-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
                  handle: handle,
                  description: 'Official video channel for ${group.name}',
                );
                channels = [newChan];
              } catch (_) {
                // Ignore transient creation errors, will fallback to group item
              }
            }

            if (channels.isNotEmpty) {
              for (final channel in channels) {
                if (channel.status == ChannelStatus.active &&
                    _permissionService.canUploadToChannel(group, channel)) {
                  permittedChannels.add(
                    PermittedUploadChannel(group: group, channel: channel),
                  );
                }
              }
            } else {
              // Always guarantee the user's active group is shown as a channel!
              permittedChannels.add(
                PermittedUploadChannel(group: group, channel: null),
              );
            }
          } catch (_) {
            // Even if query fails, ensure user can see and select their active channel
            permittedChannels.add(
              PermittedUploadChannel(group: group, channel: null),
            );
          }
        }),
      );

      // Sort channels alphabetically by display name
      permittedChannels.sort((a, b) {
        return a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
      });

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        channels: permittedChannels,
        pendingGroupsCount: pendingCount,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Ensures a valid VideoChannelDto exists when user selects this channel.
  Future<VideoChannelDto> resolveChannel(PermittedUploadChannel item) async {
    if (item.channel != null) {
      return item.toVideoChannelDto();
    }

    // Attempt to query or provision
    try {
      final channels = await _repository.getGroupVideoChannels(item.group.id);
      if (channels.isNotEmpty) {
        return PermittedUploadChannel(
          group: item.group,
          channel: channels.first,
        ).toVideoChannelDto();
      }
    } catch (_) {}

    try {
      final baseHandle = item.group.slug
          .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
          .toLowerCase();
      final rawHandle =
          '@${baseHandle.isNotEmpty ? baseHandle : 'channel'}_${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';
      final handle =
          rawHandle.length > 30 ? rawHandle.substring(0, 30) : rawHandle;
      final newChan = await _repository.createVideoChannel(
        groupId: item.group.id,
        name: '${item.group.name} Channel',
        slug:
            '${item.group.slug}-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
        handle: handle,
        description: 'Official video channel for ${item.group.name}',
      );
      return PermittedUploadChannel(
        group: item.group,
        channel: newChan,
      ).toVideoChannelDto();
    } catch (_) {
      return item.toVideoChannelDto();
    }
  }

  Future<void> refresh() async {
    await loadChannels();
  }
}
