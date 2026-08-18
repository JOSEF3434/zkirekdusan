// lib/features/home/presentation/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/home/presentation/providers/video_feed_provider.dart';
import 'package:mobile/features/home/presentation/providers/subscription_feed_provider.dart';
import 'package:mobile/features/home/presentation/widgets/video_card.dart';
import 'package:mobile/features/home/presentation/widgets/feed_skeleton.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/media_experience/presentation/providers/continue_watching_provider.dart';
import 'package:mobile/features/media_experience/presentation/widgets/continue_watching_card.dart';
import 'package:mobile/core/presentation/widgets/responsive_layout.dart';

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
      // Load more for subscriptions too if we are near the bottom
      if (ref.read(authProvider).status == AuthStatus.authenticated) {
        ref.read(subscriptionFeedProvider.notifier).loadNextPage();
      }
    }
  }

  Future<void> _onRefresh() async {
    ref.read(videoFeedProvider.notifier).refresh();
    if (ref.read(authProvider).status == AuthStatus.authenticated) {
      ref.read(subscriptionFeedProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);
    final authStatus = ref.watch(authProvider).status;
    final isAuthenticated = authStatus == AuthStatus.authenticated;
    final continueWatchingState = ref.watch(continueWatchingProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ResponsiveLayout.maxReadingWidth(
          maxWidth: 1200,
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
                  Text(
                    tr('app.name'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.cast_rounded),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () => context.push('/search'),
                ),
                const SizedBox(width: 4),
              ],
            ),

            // Subscription Feed Horizontal Carousel (Auth users only)
            if (isAuthenticated) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.subscriptions_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tr('home.subscriptions'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 280,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final subStateAsync = ref.watch(subscriptionFeedProvider);
                      return subStateAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, _) => const Center(
                          child: Text('Failed to load subscriptions'),
                        ),
                        data: (state) {
                          if (state.videos.isEmpty) {
                            return const Center(
                              child: Text(
                                'No recent videos from your subscriptions',
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: state.videos.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              return SizedBox(
                                width: 320,
                                child: VideoCard(video: state.videos[index]),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Divider(height: 32)),
            ],
            // Continue Watching Section
            if (continueWatchingState.items.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    tr('home.continue_watching'),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 106,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: continueWatchingState.items.length,
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 320,
                        child: ContinueWatchingCard(
                          progress: continueWatchingState.items[index],
                          compact: true,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            // Recommended Videos Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.recommend_rounded,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tr('home.recommended'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main Video Feed
            Consumer(
              builder: (context, ref, _) {
                final feedStateAsync = ref.watch(videoFeedProvider);

                return feedStateAsync.when(
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

                    return SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 400,
                            mainAxisExtent: 320,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index < feedState.videos.length) {
                            return VideoCard(video: feedState.videos[index]);
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
                  loading: () =>
                      const SliverFillRemaining(child: FeedSkeleton()),
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
                              onPressed: _onRefresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
