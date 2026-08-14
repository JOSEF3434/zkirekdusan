import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/explore/presentation/providers/trending_provider.dart';
import 'package:mobile/features/home/presentation/widgets/video_card.dart';
import 'package:mobile/features/home/presentation/widgets/feed_skeleton.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
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
      ref.read(trendingProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final trendingStateAsync = ref.watch(trendingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.live_tv, color: Colors.red),
            tooltip: 'Live Streams',
            onPressed: () => context.push('/live/discover'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(trendingProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Trending Now',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            trendingStateAsync.when(
              data: (state) {
                if (state.videos.isEmpty && !state.isLoadingMore) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No trending videos found')),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < state.videos.length) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: VideoCard(video: state.videos[index]),
                        );
                      } else if (state.error != null) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextButton(
                            onPressed: () =>
                                ref.read(trendingProvider.notifier).loadMore(),
                            child: const Text('Retry loading more'),
                          ),
                        );
                      } else if (state.isLoadingMore) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    childCount:
                        state.videos.length +
                        (state.isLoadingMore || state.error != null ? 1 : 0),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: FeedSkeleton()),
              error: (e, st) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $e'),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(trendingProvider.notifier).refresh(),
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
