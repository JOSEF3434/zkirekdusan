// lib/features/home/presentation/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/home/presentation/providers/video_feed_provider.dart';
import 'package:mobile/features/home/presentation/widgets/video_card.dart';
import 'package:mobile/features/home/presentation/widgets/category_tab_bar.dart';

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
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.video_library),
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
                IconButton(
                  icon: const Icon(Icons.cast),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {},
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
            
            // Video Feed
            feedStateAsync.when(
              data: (feedState) {
                if (feedState.videos.isEmpty && !feedState.isLoadingMore) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_library_outlined, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
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
                                onPressed: () => ref.read(videoFeedProvider.notifier).loadMore(),
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
                    childCount: feedState.videos.length + (feedState.isLoadingMore || feedState.error != null ? 1 : 0),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $error'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.read(videoFeedProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
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
