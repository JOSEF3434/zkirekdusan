// lib/features/creator/presentation/providers/upload_channels_provider.dart
import 'dart:developer' as developer;
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
            final channels = await _repository.getGroupVideoChannels(group.id);

            final validChannels = channels.where((channel) {
              return channel.status == ChannelStatus.active &&
                  _permissionService.canUploadToChannel(group, channel);
            }).toList();

            // Detect and clean up duplicate auto-generated empty channels
            if (validChannels.length > 1) {
              final autoSlugPattern = RegExp(
                r'^' + RegExp.escape(group.slug) + r'-\d+$',
                caseSensitive: false,
              );
              final autoHandlePattern = RegExp(
                r'^@?' +
                    RegExp.escape(group.slug.replaceAll('-', '_')) +
                    r'_\d+$',
                caseSensitive: false,
              );

              final autoChannels = validChannels.where((c) {
                final isAuto = autoSlugPattern.hasMatch(c.slug) ||
                    autoHandlePattern.hasMatch(c.handle);
                return isAuto && c.videosCount == 0;
              }).toList();

              // If multiple auto-generated duplicates exist, keep the oldest/first and clean up the rest
              if (autoChannels.length > 1) {
                final duplicatesToDelete = autoChannels.skip(1).toList();

                for (final dup in duplicatesToDelete) {
                  validChannels.removeWhere((c) => c.id == dup.id);
                  // Soft-delete on the server asynchronously in the background
                  _repository
                      .deleteVideoChannel(groupId: group.id, channelId: dup.id)
                      .catchError((e) {
                    developer.log(
                      '[UploadChannelsNotifier] Failed to prune duplicate channel ${dup.id}: $e',
                    );
                  });
                }
              }
            }

            if (validChannels.isNotEmpty) {
              for (final channel in validChannels) {
                permittedChannels.add(
                  PermittedUploadChannel(group: group, channel: channel),
                );
              }
            } else {
              // Always guarantee the user's active group is shown as an option
              permittedChannels.add(
                PermittedUploadChannel(group: group, channel: null),
              );
            }
          } catch (e, st) {
            developer.log(
              '[UploadChannelsNotifier] Failed to load channels for group ${group.id}: $e',
              error: e,
              stackTrace: st,
            );
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

    // If channel is null, query existing channels for the group without creating duplicates
    try {
      final channels = await _repository.getGroupVideoChannels(item.group.id);
      if (channels.isNotEmpty) {
        return PermittedUploadChannel(
          group: item.group,
          channel: channels.first,
        ).toVideoChannelDto();
      }
    } catch (_) {}

    return item.toVideoChannelDto();
  }

  /// Deletes a channel from the group and removes it from state
  Future<void> deleteChannel(PermittedUploadChannel item) async {
    if (item.channel == null) return;
    try {
      await _repository.deleteVideoChannel(
        groupId: item.group.id,
        channelId: item.channel!.id,
      );
      state = state.copyWith(
        channels: state.channels
            .where((c) => c.channel?.id != item.channel!.id)
            .toList(),
      );
    } catch (e) {
      developer.log('[UploadChannelsNotifier] Failed to delete channel: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadChannels();
  }
}
