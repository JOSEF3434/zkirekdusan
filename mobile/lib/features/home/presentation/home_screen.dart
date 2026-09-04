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
import 'package:mobile/features/stories/presentation/providers/story_feed_provider.dart';
import 'package:mobile/features/stories/presentation/widgets/story_section.dart';
import 'package:mobile/features/notifications/presentation/providers/unread_count_provider.dart';
import 'package:mobile/features/home/domain/video_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _recScrollController = ScrollController();
  final ScrollController _latestScrollController = ScrollController();
  final ScrollController _subScrollController = ScrollController();
  bool _isAuthenticated = false;

  int get _tabCount => _isAuthenticated ? 3 : 2;

  void _initTabController() {
    _tabController = TabController(length: _tabCount, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      if (_tabController.index == 0) {
        ref.read(videoFeedProvider.notifier).setCategory(VideoFeedCategory.recommended);
      } else if (_tabController.index == 1) {
        ref.read(videoFeedProvider.notifier).setCategory(VideoFeedCategory.latest);
      }
    }
  }

  void _syncTabController(bool isAuthenticated) {
    final tabCount = isAuthenticated ? 3 : 2;
    if (_tabController.length == tabCount) {
      return;
    }

    final initialIndex = _tabController.index.clamp(0, tabCount - 1);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _isAuthenticated = isAuthenticated;
    _tabController = TabController(
      length: tabCount,
      initialIndex: initialIndex,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
  }

  @override
  void initState() {
    super.initState();
    _isAuthenticated =
        ref.read(authProvider).status == AuthStatus.authenticated;
    _initTabController();
    _recScrollController.addListener(() => _onScroll(_recScrollController));
    _latestScrollController.addListener(
      () => _onScroll(_latestScrollController),
    );
    _subScrollController.addListener(() => _onSubScroll(_subScrollController));

    // Load profile silently if authenticated
    Future.microtask(() {
      if (ref.read(authProvider).status == AuthStatus.authenticated) {
        ref.read(profileProvider.notifier).loadMyProfile();
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _recScrollController.dispose();
    _latestScrollController.dispose();
    _subScrollController.dispose();
    super.dispose();
  }

  void _onScroll(ScrollController controller) {
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - 500) {
      ref.read(videoFeedProvider.notifier).loadMore();
    }
  }

  void _onSubScroll(ScrollController controller) {
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - 500) {
      if (ref.read(authProvider).status == AuthStatus.authenticated) {
        ref.read(subscriptionFeedProvider.notifier).loadNextPage();
      }
    }
  }

  Future<void> _onRefresh() async {
    if (_tabController.index == 0) {
      await Future.wait([
        ref.read(videoFeedProvider.notifier).refresh(),
        ref.read(storyFeedProvider.notifier).refresh(),
      ]);
    } else if (_tabController.index == 1) {
      await ref.read(videoFeedProvider.notifier).refresh();
    } else {
      if (ref.read(authProvider).status == AuthStatus.authenticated) {
        ref.read(subscriptionFeedProvider.notifier).refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      final isAuth = next.status == AuthStatus.authenticated;
      if (isAuth != _isAuthenticated) {
        setState(() {
          _isAuthenticated = isAuth;
        });
        if (isAuth) {
          ref.read(profileProvider.notifier).loadMyProfile();
        }
      }
    });

    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);
    final authStatus = ref.watch(authProvider).status;
    final isAuthenticated = authStatus == AuthStatus.authenticated;
    _syncTabController(isAuthenticated);
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo.jpg',
                      height: 32,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.video_library),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        tr('app.name'),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
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
                  Consumer(
                    builder: (context, ref, _) {
                      final unreadCount = ref.watch(
                        unreadNotificationCountProvider,
                      );
                      return IconButton(
                        icon: unreadCount > 0
                            ? Badge(
                                label: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                ),
                              )
                            : const Icon(Icons.notifications_none_rounded),
                        onPressed: () => context.push('/notifications'),
                      );
                    },
                  ),
                  if (!isAuthenticated)
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
                  isScrollable: _tabCount > 2,
                  tabs: [
                    Tab(text: tr('home.recommended')),
                    const Tab(text: 'Latest'),
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
                    // Stories section
                    const SliverToBoxAdapter(child: StorySection()),
                    const SliverToBoxAdapter(
                      child: Divider(height: 1, thickness: 0.5),
                    ),
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
                    // Category filter chips
                    SliverToBoxAdapter(child: _buildCategoryChips()),
                    Consumer(
                      builder: (context, ref, _) {
                        final feedStateAsync = ref.watch(videoFeedProvider);
                        return feedStateAsync.when(
                          data: (feedState) => _buildFeedGrid(
                            feedState.videos,
                            feedState.isLoadingMore,
                            feedState.error,
                            true,
                          ),
                          loading: () =>
                              const SliverFillRemaining(child: FeedSkeleton()),
                          error: (error, stack) =>
                              _buildErrorState(error.toString(), theme),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Latest Videos Tab
              RefreshIndicator(
                onRefresh: () async {
                  await ref
                      .read(videoFeedProvider.notifier)
                      .setCategory(VideoFeedCategory.latest);
                },
                child: CustomScrollView(
                  controller: _latestScrollController,
                  slivers: [
                    Consumer(
                      builder: (context, ref, _) {
                        final feedStateAsync = ref.watch(videoFeedProvider);
                        return feedStateAsync.when(
                          data: (feedState) => _buildFeedGrid(
                            feedState.videos,
                            feedState.isLoadingMore,
                            feedState.error,
                            false,
                          ),
                          loading: () =>
                              const SliverFillRemaining(child: FeedSkeleton()),
                          error: (error, stack) =>
                              _buildErrorState(error.toString(), theme),
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
                          final subStateAsync = ref.watch(
                            subscriptionFeedProvider,
                          );
                          return subStateAsync.when(
                            data: (state) {
                              if (state.videos.isEmpty) {
                                return const SliverFillRemaining(
                                  child: Center(
                                    child: Text(
                                      'No recent videos from your subscriptions',
                                    ),
                                  ),
                                );
                              }
                              return _buildFeedGrid(
                                state.videos,
                                false,
                                null,
                                false,
                              );
                            },
                            loading: () => const SliverFillRemaining(
                              child: FeedSkeleton(),
                            ),
                            error: (error, stack) =>
                                _buildErrorState(error.toString(), theme),
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

  Widget _buildCategoryChips() {
    final currentCategory = ref.watch(
      videoFeedProvider.select(
        (state) => state.valueOrNull?.category ?? VideoFeedCategory.recommended,
      ),
    );

    final categories = [
      VideoFeedCategory.recommended,
      VideoFeedCategory.latest,
      VideoFeedCategory.trending,
      VideoFeedCategory.education,
      VideoFeedCategory.music,
      VideoFeedCategory.gaming,
      VideoFeedCategory.live,
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = currentCategory == cat;

          return FilterChip(
            selected: isSelected,
            label: Text(cat.label, style: const TextStyle(fontSize: 12)),
            onSelected: (_) {
              ref.read(videoFeedProvider.notifier).setCategory(cat);
            },
          );
        },
      ),
    );
  }

  Widget _buildFeedGrid(
    List<dynamic> videos,
    bool isLoadingMore,
    String? error,
    bool isRec,
  ) {
    if (videos.isEmpty && !isLoadingMore) {
      if (isRec) {
        return SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.auto_awesome_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'No recommendations yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back soon — as you watch and interact with videos, we\'ll recommend content tailored for you.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return SliverFillRemaining(
        child: Center(
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
              const Text('No videos found'),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 360,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index < videos.length) {
          return VideoCard(video: videos[index]);
        } else if (error != null) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('Failed to load more videos.'),
                TextButton(
                  onPressed: () =>
                      ref.read(videoFeedProvider.notifier).loadMore(),
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
      }, childCount: videos.length + (isLoadingMore || error != null ? 1 : 0)),
    );
  }

  Widget _buildErrorState(String error, ThemeData theme) {
    String friendlyMessage =
        'Unable to load content. Please check your connection.';
    if (error.contains('401') || error.contains('Unauthorized')) {
      friendlyMessage = 'Session expired or sign in required.';
    } else if (error.contains('timeout') || error.contains('connection')) {
      friendlyMessage =
          'Network connection issue. Please check your internet connection.';
    }

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Something went wrong', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                friendlyMessage,
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
    );
  }
}
