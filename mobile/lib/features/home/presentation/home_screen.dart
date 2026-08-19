import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/home/presentation/providers/video_feed_provider.dart';
import 'package:mobile/features/home/presentation/providers/subscription_feed_provider.dart';
import 'package:mobile/features/home/presentation/widgets/video_card.dart';
import 'package:mobile/features/home/presentation/widgets/feed_skeleton.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/profile/presentation/providers/profile_providers.dart';
import 'package:mobile/core/presentation/widgets/responsive_layout.dart';
import 'package:mobile/features/media_experience/presentation/providers/continue_watching_provider.dart';
import 'package:mobile/features/media_experience/presentation/widgets/continue_watching_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _recScrollController = ScrollController();
  final ScrollController _subScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _recScrollController.addListener(() => _onScroll(_recScrollController, isRec: true));
    _subScrollController.addListener(() => _onScroll(_subScrollController, isRec: false));
    
    // Load profile silently if authenticated
    Future.microtask(() {
      if (ref.read(authProvider).status == AuthStatus.authenticated) {
        ref.read(profileProvider.notifier).loadMyProfile();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recScrollController.dispose();
    _subScrollController.dispose();
    super.dispose();
  }

  void _onScroll(ScrollController controller, {required bool isRec}) {
    if (controller.position.pixels >= controller.position.maxScrollExtent - 500) {
      if (isRec) {
        ref.read(videoFeedProvider.notifier).loadMore();
      } else {
        if (ref.read(authProvider).status == AuthStatus.authenticated) {
          ref.read(subscriptionFeedProvider.notifier).loadNextPage();
        }
      }
    }
  }

  Future<void> _onRefresh() async {
    if (_tabController.index == 0) {
      ref.read(videoFeedProvider.notifier).refresh();
    } else {
      if (ref.read(authProvider).status == AuthStatus.authenticated) {
        ref.read(subscriptionFeedProvider.notifier).refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);
    final authStatus = ref.watch(authProvider).status;
    final isAuthenticated = authStatus == AuthStatus.authenticated;
    final profileState = ref.watch(profileProvider);
    final continueWatchingState = ref.watch(continueWatchingProvider);

    return Scaffold(
      body: ResponsiveLayout.maxReadingWidth(
        maxWidth: 1200,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                floating: true,
                pinned: true,
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
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () {},
                  ),
                  if (isAuthenticated)
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0, left: 8.0),
                      child: GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: profileState.profile?.avatarUrl != null
                              ? NetworkImage(profileState.profile!.avatarUrl!)
                              : null,
                          child: profileState.profile?.avatarUrl == null
                              ? Text(
                                  (profileState.profile?.displayName?.isNotEmpty == true
                                          ? profileState.profile!.displayName![0]
                                          : (profileState.profile?.username?.isNotEmpty == true
                                              ? profileState.profile!.username![0]
                                              : '?'))
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextButton(
                        onPressed: () => context.push('/login'),
                        child: Text(tr('auth.login')),
                      ),
                    ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: tr('home.recommended')),
                    if (isAuthenticated) Tab(text: tr('home.subscriptions')),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // Recommendations Tab
              RefreshIndicator(
                onRefresh: _onRefresh,
                child: CustomScrollView(
                  controller: _recScrollController,
                  slivers: [
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
                      const SliverToBoxAdapter(child: Divider(height: 32)),
                    ],
                    Consumer(
                      builder: (context, ref, _) {
                        final feedStateAsync = ref.watch(videoFeedProvider);
                        return feedStateAsync.when(
                          data: (feedState) => _buildFeedGrid(feedState.videos, feedState.isLoadingMore, feedState.error, true),
                          loading: () => const SliverFillRemaining(child: FeedSkeleton()),
                          error: (error, stack) => _buildErrorState(error.toString(), theme),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Subscriptions Tab (Only if authenticated)
              if (isAuthenticated)
                RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: CustomScrollView(
                    controller: _subScrollController,
                    slivers: [
                      Consumer(
                        builder: (context, ref, _) {
                          final subStateAsync = ref.watch(subscriptionFeedProvider);
                          return subStateAsync.when(
                            data: (state) {
                              if (state.videos.isEmpty) {
                                return const SliverFillRemaining(
                                  child: Center(
                                    child: Text('No recent videos from your subscriptions'),
                                  ),
                                );
                              }
                              return _buildFeedGrid(state.videos, false, null, false);
                            },
                            loading: () => const SliverFillRemaining(child: FeedSkeleton()),
                            error: (error, stack) => _buildErrorState(error.toString(), theme),
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedGrid(List<dynamic> videos, bool isLoadingMore, String? error, bool isRec) {
    if (videos.isEmpty && !isLoadingMore) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text('No videos found'),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 320,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < videos.length) {
            return VideoCard(video: videos[index]);
          } else if (error != null) {
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
          } else if (isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox.shrink();
        },
        childCount: videos.length + (isLoadingMore || error != null ? 1 : 0),
      ),
    );
  }

  Widget _buildErrorState(String error, ThemeData theme) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Something went wrong', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
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
    );
  }
}
