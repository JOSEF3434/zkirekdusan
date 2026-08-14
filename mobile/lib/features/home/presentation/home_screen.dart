// lib/features/home/presentation/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/home/presentation/providers/video_feed_provider.dart';
import 'package:mobile/features/home/presentation/widgets/video_card.dart';
import 'package:mobile/features/home/presentation/widgets/category_tab_bar.dart';
import 'package:mobile/features/home/presentation/widgets/feed_skeleton.dart';
import 'package:mobile/features/live/presentation/providers/live_discovery_provider.dart';
import 'package:mobile/features/live/presentation/widgets/live_card_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      ref.read(videoFeedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedStateAsync = ref.watch(videoFeedProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(videoFeedProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Branded App Bar
            SliverAppBar(
              floating: true,
              pinned: false,
              title: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.jpg',
                    height: 32,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.video_library),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ዝክረ ክዱሳን',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(icon: const Icon(Icons.cast), onPressed: () {}),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push('/notifications'),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => context.push('/search'),
                ),
                const SizedBox(width: 4),
              ],
            ),

            // Category Tabs
            SliverToBoxAdapter(
              child: feedStateAsync.when(
                data: (feedState) => CategoryTabBar(
                  selectedCategory: feedState.category,
                  onCategorySelected: (category) {
                    ref.read(videoFeedProvider.notifier).setCategory(category);
                    // Scroll to top
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                ),
                loading: () => const SizedBox(height: 48),
                error: (_, _) => const SizedBox(height: 48),
              ),
            ),

            // LIVE NOW Section (Horizontal)
            Consumer(
              builder: (context, ref, _) {
                final liveState = ref.watch(liveStreamsProvider);
                if (liveState.streams.isEmpty) {
                  return const SliverToBoxAdapter();
                }

                return SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.live_tv,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'LIVE NOW',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                // Navigate to explore tab and switch to live tab?
                                // For now, we can route them to the LiveDiscoveryScreen or rely on Explore.
                                context.push('/live/discover');
                              },
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('See All'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: liveState.streams.length,
                          itemBuilder: (context, index) {
                            return LiveCardWidget(
                              stream: liveState.streams[index],
                              horizontal: true,
                            );
                          },
                        ),
                      ),
                      const Divider(),
                    ],
                  ),
                );
              },
            ),

            // Video Feed
            feedStateAsync.when(
              data: (feedState) {
                if (feedState.videos.isEmpty && !feedState.isLoadingMore) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.video_library_outlined,
                            size: 64,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('No videos found'),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < feedState.videos.length) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: VideoCard(video: feedState.videos[index]),
                        );
                      } else if (feedState.error != null) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text('Failed to load more videos.'),
                              TextButton(
                                onPressed: () => ref
                                    .read(videoFeedProvider.notifier)
                                    .loadMore(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      } else if (feedState.isLoadingMore) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    childCount:
                        feedState.videos.length +
                        (feedState.isLoadingMore || feedState.error != null
                            ? 1
                            : 0),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: FeedSkeleton()),
              error: (error, stack) => SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () =>
                              ref.read(videoFeedProvider.notifier).refresh(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
