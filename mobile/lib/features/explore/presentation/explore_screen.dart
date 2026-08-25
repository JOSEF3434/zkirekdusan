// lib/features/explore/presentation/explore_screen.dart
// Rich discovery screen with horizontal carousels for Live, Channels, Videos, Reels.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/presentation/widgets/responsive_layout.dart';
import 'package:mobile/features/explore/domain/explore_content_model.dart';
import 'package:mobile/features/explore/presentation/providers/discover_provider.dart';
import 'package:mobile/features/home/presentation/widgets/video_card.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoverStateAsync = ref.watch(discoverProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
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
              const Text('Could not load explore content'),
              TextButton(
                onPressed: () => ref.read(discoverProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (state) {
          final content = state.content;
          if (content == null) {
            return const Center(child: Text('No content available'));
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(discoverProvider.notifier).refresh(),
            child: ResponsiveLayout.maxReadingWidth(
              maxWidth: 1200,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  if (content.trendingStreams.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Live Now',
                      icon: Icons.sensors,
                      color: Colors.red,
                    ),
                    _buildLiveCarousel(content.trendingStreams),
                    const SizedBox(height: 24),
                  ],
                  if (content.trendingVideos.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Trending Videos',
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                    _buildVideoCarousel(content.trendingVideos, context),
                    const SizedBox(height: 24),
                  ],
                  if (content.trendingChannels.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Popular Channels',
                      icon: Icons.star_rounded,
                      color: Colors.amber,
                    ),
                    _buildChannelCarousel(content.trendingChannels, context),
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

  Widget _buildLiveCarousel(List<ExploreStreamDto> streams) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: streams.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final stream = streams[index];
          return GestureDetector(
            onTap: () => context.push('/live/${stream.id}'),
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.live_tv, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      stream.title ?? 'Live',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stream.viewerCount} viewers',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoCarousel(List<dynamic> videos, BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return SizedBox(
      height: isDesktop ? 260 : 235,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: videos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
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
  ) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: channels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
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
                    channel.name ?? 'Channel',
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
