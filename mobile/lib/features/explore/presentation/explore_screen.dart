// lib/features/explore/presentation/explore_screen.dart
// Rich discovery screen with horizontal carousels for Live, Channels, Videos, Reels.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/presentation/widgets/responsive_layout.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/explore/domain/explore_content_model.dart';
import 'package:mobile/features/explore/presentation/providers/discover_provider.dart';
import 'package:mobile/features/home/presentation/widgets/video_card.dart';
import 'package:mobile/features/live/presentation/providers/scheduled_live_sync_provider.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoverStateAsync = ref.watch(discoverProvider);
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('explore.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: discoverStateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(tr('explore.load_failed')),
              TextButton(
                onPressed: () => ref.read(discoverProvider.notifier).refresh(),
                child: Text(tr('common.retry')),
              ),
            ],
          ),
        ),
        data: (state) {
          final content = state.content;
          if (content == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.explore_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('explore.no_content'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('explore.no_content_desc'),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(discoverProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh),
                    label: Text(tr('explore.refresh')),
                  ),
                ],
              ),
            );
          }

          // Check if all sections are empty
          final hasContent =
              content.trendingStreams.isNotEmpty ||
              content.trendingVideos.isNotEmpty ||
              content.trendingChannels.isNotEmpty;

          if (!hasContent) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('explore.no_trending'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('explore.no_trending_desc'),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(discoverProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh),
                    label: Text(tr('explore.refresh')),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(discoverProvider.notifier).refresh(),
            child: ResponsiveLayout.maxReadingWidth(
              maxWidth: 1200,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  // Separate Live Now and Scheduled streams dynamically
                  ..._buildLiveAndScheduledSections(content.trendingStreams, context, tr, ref),
                  if (content.trendingVideos.isNotEmpty) ...[
                    _SectionHeader(
                      title: tr('explore.trending_videos'),
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                    _buildVideoCarousel(content.trendingVideos, context),
                    const SizedBox(height: 24),
                  ],
                  if (content.trendingChannels.isNotEmpty) ...[
                    _SectionHeader(
                      title: tr('explore.popular_channels'),
                      icon: Icons.star_rounded,
                      color: Colors.amber,
                    ),
                    _buildChannelCarousel(
                      content.trendingChannels,
                      context,
                      tr,
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Add more sections as needed
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildLiveAndScheduledSections(
    List<ExploreStreamDto> streams,
    BuildContext context,
    String Function(String, [Map<String, dynamic>?]) tr,
    WidgetRef ref,
  ) {
    // Watch the real-time ticker to auto-update countdowns and trigger transitions
    ref.watch(scheduledCountdownTickerProvider);

    final liveStreams = streams.where((s) => s.effectivelyLive).toList();
    final scheduledStreams = streams.where((s) => !s.effectivelyLive).toList();

    final widgets = <Widget>[];

    if (liveStreams.isNotEmpty) {
      widgets.add(
        _SectionHeader(
          title: tr('explore.live_now'),
          icon: Icons.sensors,
          color: Colors.red,
        ),
      );
      widgets.add(_buildLiveCarousel(liveStreams, tr));
      widgets.add(const SizedBox(height: 24));
    }

    if (scheduledStreams.isNotEmpty) {
      widgets.add(
        const _SectionHeader(
          title: 'Scheduled Live',
          icon: Icons.calendar_month_rounded,
          color: Colors.blueAccent,
        ),
      );
      widgets.add(_buildScheduledCarousel(scheduledStreams, context, tr));
      widgets.add(const SizedBox(height: 24));
    }

    return widgets;
  }

  Widget _buildLiveCarousel(
    List<ExploreStreamDto> streams,
    String Function(String, [Map<String, dynamic>?]) tr,
  ) {
    return SizedBox(
      height: 195,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: streams.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final stream = streams[index];
          return GestureDetector(
            onTap: () => context.push('/live/${stream.id}'),
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        child: stream.thumbnailUrl != null && stream.thumbnailUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: stream.thumbnailUrl!,
                                width: 160,
                                height: 95,
                                fit: BoxFit.cover,
                                errorWidget: (c, u, e) => _fallbackStreamThumb(),
                              )
                            : _fallbackStreamThumb(),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person, size: 10, color: Colors.white70),
                              const SizedBox(width: 3),
                              Text(
                                '${stream.viewerCount}',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stream.title ?? tr('live.title'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          stream.creatorUsername ?? stream.channelName ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduledCarousel(
    List<ExploreStreamDto> streams,
    BuildContext context,
    String Function(String, [Map<String, dynamic>?]) tr,
  ) {
    return SizedBox(
      height: 195,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: streams.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final stream = streams[index];
          final countdown = _formatCountdown(stream.scheduledDateTime);
          return GestureDetector(
            onTap: () => context.push('/live/${stream.id}'),
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        child: stream.thumbnailUrl != null && stream.thumbnailUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: stream.thumbnailUrl!,
                                width: 160,
                                height: 95,
                                fit: BoxFit.cover,
                                errorWidget: (c, u, e) => _fallbackStreamThumb(),
                              )
                            : _fallbackStreamThumb(),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today, size: 9, color: Colors.white),
                              SizedBox(width: 3),
                              Text(
                                'SCHEDULED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stream.title ?? 'Upcoming Live',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 12, color: Colors.blueAccent),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                countdown,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueAccent,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _fallbackStreamThumb() {
    return Container(
      width: 160,
      height: 95,
      color: const Color(0xFF1E202A),
      child: const Center(
        child: Icon(Icons.live_tv_rounded, size: 32, color: Colors.white38),
      ),
    );
  }

  String _formatCountdown(DateTime? dt) {
    if (dt == null) return 'Scheduled';
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.isNegative) return 'Starting now';
    if (diff.inDays > 1) return 'In ${diff.inDays} days';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inHours > 0) return 'In ${diff.inHours}h ${diff.inMinutes % 60}m';
    if (diff.inMinutes > 0) return 'In ${diff.inMinutes}m';
    return 'In ${diff.inSeconds}s';
  }

  Widget _buildVideoCarousel(List<dynamic> videos, BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return SizedBox(
      height: isDesktop ? 260 : 235,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: videos.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return SizedBox(
            width: isDesktop ? 320 : 260,
            child: VideoCard(
              video: videos[index],
              showActions: false,
              isCompact: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildChannelCarousel(
    List<ExploreChannelDto> channels,
    BuildContext context,
    String Function(String, [Map<String, dynamic>?]) tr,
  ) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: channels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final channel = channels[index];
          return GestureDetector(
            onTap: () {}, // navigation to channel profile
            child: SizedBox(
              width: 100,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: channel.avatarUrl != null
                        ? CachedNetworkImageProvider(channel.avatarUrl!)
                        : null,
                    child: channel.avatarUrl == null
                        ? const Icon(Icons.person, size: 36)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    channel.name ?? tr('video.channel_fallback'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
