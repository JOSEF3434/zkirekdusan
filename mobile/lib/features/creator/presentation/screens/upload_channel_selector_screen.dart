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
    final subtitle = (channel != null && channel.name != group.name)
        ? group.name
        : (group.description != null && group.description!.isNotEmpty
              ? group.description!
              : 'Active channel ready for upload');

    final avatarLetter = title.isNotEmpty
        ? title.substring(0, 1).toUpperCase()
        : 'C';

    Future<void> handleSelect() async {
      final groupDto = item.toGroupDto();
      final channelDto = await ref
          .read(uploadChannelsProvider(initialGroupId).notifier)
          .resolveChannel(item);

      ref.read(uploadProvider.notifier).preselectChannel(groupDto, channelDto);

      if (context.mounted) {
        context.push('/upload');
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: handleSelect,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
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
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 12,
                                color: Colors.green,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Ready to upload',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (channel != null && channel.handle.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            channel.handle.startsWith('@')
                                ? channel.handle
                                : '@${channel.handle}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: handleSelect,
                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                label: Consumer(
                  builder: (context, ref, _) =>
                      Text(ref.watch(trProvider)('creator.select_btn')),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
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
