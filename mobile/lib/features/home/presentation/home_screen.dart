import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/storage/download_service.dart';
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
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/features/home/presentation/providers/home_refresh_provider.dart';
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

  void _scrollToTop() {
    if (_tabController.index == 0 && _recScrollController.hasClients) {
      _recScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else if (_tabController.index == 1 && _latestScrollController.hasClients) {
      _latestScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else if (_tabController.index == 2 && _subScrollController.hasClients) {
      _subScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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

    // Listen to Home icon taps to scroll to top and refresh
    ref.listen<int>(homeRefreshSignalProvider, (previous, next) {
      if (next > (previous ?? 0)) {
        _scrollToTop();
        _onRefresh();
      }
    });

    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);
    final authStatus = ref.watch(authProvider).status;
    final isAuthenticated = authStatus == AuthStatus.authenticated;
    _syncTabController(isAuthenticated);
    final continueWatchingState = ref.watch(continueWatchingProvider);
    final connectivity = ref.watch(connectivityProvider);
    final isOffline = connectivity.isOffline;
    final downloadState = ref.watch(downloadServiceProvider);
    final downloads = downloadState.downloads.values.toList();
    return Scaffold(
      body: ResponsiveLayout.maxReadingWidth(
        maxWidth: 1200,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                floating: true,
                pinned: true,
                title: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _scrollToTop();
                    _onRefresh();
                  },
                  child: Row(
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
                    if (isOffline)
                      _buildOfflineDownloadsSliver(downloads, theme)
                    else ...[
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
                      // Offline Downloaded Videos Shelf (Display alongside online videos when online)
                      if (downloads.isNotEmpty)
                        _buildDownloadedShelfSliver(downloads, theme),
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
                  ],
                ),
              ),

              // Latest Videos Tab
              RefreshIndicator(
                onRefresh: () async {
                  if (isOffline) {
                    await ref.read(downloadServiceProvider.notifier).loadLocalDownloads();
                  } else {
                    await ref
                        .read(videoFeedProvider.notifier)
                        .setCategory(VideoFeedCategory.latest);
                  }
                },
                child: CustomScrollView(
                  controller: _latestScrollController,
                  slivers: [
                    if (isOffline)
                      _buildOfflineDownloadsSliver(downloads, theme)
                    else
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
    final connectivity = ref.watch(connectivityProvider);
    final downloadState = ref.watch(downloadServiceProvider);
    final downloads = downloadState.downloads.values.toList();

    // Only fallback to offline downloads if the device is actually offline
    if (connectivity.isOffline) {
      return _buildOfflineDownloadsSliver(downloads, theme);
    }

    // Online error state - DO NOT claim the user is offline!
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_queue_rounded, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Unable to load content',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Could not load videos from server. Pull down to refresh or tap Retry.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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

  Widget _buildOfflineDownloadsSliver(
    List<DownloadMetadata> downloads,
    ThemeData theme,
  ) {
    if (downloads.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No Connection • Offline Mode',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Download videos while online to watch them anytime offline without data.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Connection'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        // Offline status banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, size: 20, color: Colors.orange),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Offline Mode • Showing your downloads',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              TextButton.icon(
                onPressed: _onRefresh,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(50, 32),
                ),
              ),
            ],
          ),
        ),

        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your downloads',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${downloads.length} video(s)',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Downloaded video list matching YouTube offline downloads
        ...downloads.map((item) => _buildOfflineVideoTile(item, theme)),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _buildDownloadedShelfSliver(
    List<DownloadMetadata> downloads,
    ThemeData theme,
  ) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.download_done_rounded,
                        size: 20, color: Color(0xFFE5A93B)),
                    const SizedBox(width: 8),
                    Text(
                      'Downloaded Videos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${downloads.length} offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 125,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: downloads.length,
              itemBuilder: (context, index) {
                final item = downloads[index];
                return _buildOfflineShelfCard(item, theme);
              },
            ),
          ),
          const Divider(height: 24, thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildOfflineShelfCard(DownloadMetadata item, ThemeData theme) {
    final sizeMb = (item.sizeBytes / (1024 * 1024)).toStringAsFixed(1);
    return Card(
      margin: const EdgeInsets.only(right: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: () => context.push('/video/${item.videoId}'),
        child: SizedBox(
          width: 170,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty)
                      item.thumbnailUrl!.startsWith('/') ||
                              item.thumbnailUrl!.startsWith('file://')
                          ? Image.file(
                              File(item.thumbnailUrl!.replaceFirst('file://', '')),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(color: Colors.black54),
                            )
                          : Image.network(
                              item.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(color: Colors.black54),
                            )
                    else
                      Container(color: Colors.black87),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 10, color: Color(0xFFE5A93B)),
                            SizedBox(width: 3),
                            Text('Downloaded', style: TextStyle(color: Colors.white, fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '$sizeMb MB • Offline',
                      style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
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

  Widget _buildOfflineVideoTile(DownloadMetadata item, ThemeData theme) {
    final sizeMb = (item.sizeBytes / (1024 * 1024)).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push('/video/${item.videoId}');
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 120,
                  height: 68,
                  color: Colors.black87,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty)
                        item.thumbnailUrl!.startsWith('/') ||
                                item.thumbnailUrl!.startsWith('file://')
                            ? Image.file(
                                File(item.thumbnailUrl!.replaceFirst('file://', '')),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(Icons.video_library_rounded, color: Colors.white54),
                                ),
                              )
                            : Image.network(
                                item.thumbnailUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(Icons.video_library_rounded, color: Colors.white54),
                                ),
                              )
                      else
                        const Center(
                          child: Icon(Icons.video_library_rounded, color: Colors.white54),
                        ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Video info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_circle_down_rounded,
                          size: 14,
                          color: Color(0xFF00C6FF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$sizeMb MB • Offline ready',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Options menu
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () {
                  _showOfflineVideoOptions(item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOfflineVideoOptions(DownloadMetadata item) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_circle_outline, color: Colors.teal),
              title: const Text('Play Offline'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push('/video/${item.videoId}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete from downloads'),
              onTap: () {
                Navigator.of(ctx).pop();
                ref.read(downloadServiceProvider.notifier).deleteDownload(item.videoId);
              },
            ),
          ],
        ),
      ),
    );
  }
}
