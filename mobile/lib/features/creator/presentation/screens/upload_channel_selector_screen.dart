// lib/features/creator/presentation/screens/upload_channel_selector_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/creator/presentation/providers/upload_channels_provider.dart';
import 'package:mobile/features/creator/presentation/widgets/creator_empty_state.dart';
import 'package:mobile/features/creator/presentation/widgets/creator_error_state.dart';
import 'package:mobile/features/creator/presentation/widgets/creator_loading_skeleton.dart';
import 'package:mobile/features/upload/presentation/providers/upload_provider.dart';

class UploadChannelSelectorScreen extends ConsumerWidget {
  final String? initialGroupId;

  const UploadChannelSelectorScreen({super.key, this.initialGroupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uploadChannelsProvider(initialGroupId));
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('creator.select_channel_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: tr('creator.create_channel_tooltip'),
            onPressed: () => context.push('/creator/create-group'),
          ),
        ],
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    UploadChannelsState state,
  ) {
    if (state.isLoading) {
      return const CreatorLoadingSkeleton();
    }

    if (state.error != null) {
      return CreatorErrorState(
        error: state.error!,
        onRetry: () =>
            ref.read(uploadChannelsProvider(initialGroupId).notifier).refresh(),
      );
    }

    if (state.channels.isEmpty) {
      final tr = ref.read(trProvider);
      return Column(
        children: [
          Expanded(
            child: CreatorEmptyState(
              title: tr('creator.no_channels_title'),
              message: tr('creator.no_channels_desc'),
              buttonText: tr('creator.create_channel_btn'),
              onAction: () => context.push('/creator/create-group'),
            ),
          ),
          if (state.pendingGroupsCount > 0)
            _buildPendingNotice(context, state.pendingGroupsCount),
        ],
      );
    }

    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(uploadChannelsProvider(initialGroupId).notifier).refresh(),
      child: ListView.builder(
        itemCount:
            state.channels.length + (state.pendingGroupsCount > 0 ? 2 : 1),
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'Choose a channel where you want to post your video:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          final channelIndex = index - 1;
          if (channelIndex < state.channels.length) {
            final item = state.channels[channelIndex];
            return _buildChannelCard(context, ref, item);
          }

          // Show pending notice at bottom if applicable
          return _buildPendingNotice(context, state.pendingGroupsCount);
        },
      ),
    );
  }

  Widget _buildChannelCard(
    BuildContext context,
    WidgetRef ref,
    PermittedUploadChannel item,
  ) {
    final theme = Theme.of(context);
    final group = item.group;
    final channel = item.channel;
    final title = item.displayName;
    final String subtitle;
    if (channel != null && channel.handle.isNotEmpty) {
      subtitle = channel.handle.startsWith('@')
          ? channel.handle
          : '@${channel.handle}';
    } else if (group.name != title) {
      subtitle = group.name;
    } else if (group.description != null &&
        group.description!.isNotEmpty &&
        group.description != title) {
      subtitle = group.description!;
    } else {
      subtitle = '';
    }

    final avatarLetter = title.isNotEmpty
        ? title.substring(0, 1).toUpperCase()
        : 'C';

    Future<void> handleSelect() async {
      final groupDto = item.toGroupDto();
      final channelDto = await ref
          .read(uploadChannelsProvider(initialGroupId).notifier)
          .resolveChannel(item);

      final currentUploadState = ref.read(uploadProvider);
      final isChangingChannel =
          currentUploadState.file != null || currentUploadState.selectedChannel != null;

      ref.read(uploadProvider.notifier).preselectChannel(groupDto, channelDto);

      if (context.mounted) {
        if (isChangingChannel && Navigator.of(context).canPop()) {
          context.pop();
        } else {
          context.pushReplacement('/upload');
        }
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: handleSelect,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Avatar, Channel Name & Handle, Delete Button
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage:
                        group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                        ? NetworkImage(group.avatarUrl!)
                        : null,
                    child: group.avatarUrl == null || group.avatarUrl!.isEmpty
                        ? Text(
                            avatarLetter,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (item.channel != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: theme.colorScheme.error.withValues(alpha: 0.7),
                      ),
                      tooltip: 'Delete Channel',
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Channel'),
                            content: Text(
                              'Are you sure you want to delete "${item.displayName}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref
                              .read(uploadChannelsProvider(initialGroupId).notifier)
                              .deleteChannel(item);
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              // Bottom row: Status Badge + Select Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 13,
                            color: Colors.green,
                          ),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Ready to upload',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: handleSelect,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                    label: Consumer(
                      builder: (context, ref, _) =>
                          Text(ref.watch(trProvider)('creator.select_btn')),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingNotice(BuildContext context, int pendingCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$pendingCount channel(s) are pending approval and will appear here once approved by an administrator.',
              style: const TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
