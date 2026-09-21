// lib/features/groups/presentation/screens/tabs/group_video_feed_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/groups/domain/group_context_dto.dart';
import 'package:mobile/features/groups/presentation/providers/channel_videos_provider.dart';
import 'package:mobile/features/groups/presentation/widgets/channel_video_card.dart';
import 'package:mobile/features/upload/domain/group_channel_model.dart';
import 'package:mobile/features/upload/presentation/providers/upload_provider.dart';

class GroupVideoFeedTab extends ConsumerWidget {
  final GroupContextDto groupContext;
  final VideoChannelSummaryDto? activeChannel;

  const GroupVideoFeedTab({
    super.key,
    required this.groupContext,
    required this.activeChannel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = activeChannel ?? groupContext.primaryChannel;
    final theme = Theme.of(context);

    if (channel == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No video channel available',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    final state = ref.watch(channelVideosProvider(channel.id));

    if (state.isLoading && state.videos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => ref
                  .read(channelVideosProvider(channel.id).notifier)
                  .refresh(),
              child: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('common.retry'))),
            ),
          ],
        ),
      );
    }

    if (state.videos.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(channelVideosProvider(channel.id).notifier).refresh(),
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No videos uploaded yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Videos published in this channel will appear here.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  if (groupContext.capabilities.canUploadVideo) ...[
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _startUpload(context, ref, channel),
                      icon: const Icon(Icons.upload),
                      label: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('creator.upload_tooltip'))),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Responsive layout computation
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1024 ? 3 : (width > 600 ? 2 : 1);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(channelVideosProvider(channel.id).notifier).refresh(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
              ref.read(channelVideosProvider(channel.id).notifier).loadMore();
            }
            return false;
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: crossAxisCount == 1 ? 16 / 12 : 16 / 13,
            ),
            itemCount: state.videos.length + (state.isFetchingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.videos.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final video = state.videos[index];
              return ChannelVideoCard(video: video);
            },
          ),
        ),
      ),
      floatingActionButton: groupContext.capabilities.canUploadVideo
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => _startUpload(context, ref, channel),
              icon: const Icon(Icons.add),
              label: Consumer(builder: (context, ref, child) => Text(ref.watch(trProvider)('common.upload'))),
            )
          : null,
    );
  }

  void _startUpload(
    BuildContext context,
    WidgetRef ref,
    VideoChannelSummaryDto channel,
  ) {
    final groupDto = GroupDto(
      id: groupContext.id,
      name: groupContext.name,
      description: groupContext.description,
    );
    final channelDto = VideoChannelDto(
      id: channel.id,
      groupId: groupContext.id,
      name: channel.name,
      description: channel.description,
      type: 'VOD',
      uploadPermission: channel.uploadPermission,
    );
    ref.read(uploadProvider.notifier).preselectChannel(groupDto, channelDto);
    context.push('/upload');
  }
}

