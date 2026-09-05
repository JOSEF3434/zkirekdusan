import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/storage/download_service.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/home/data/video_repository.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/home/presentation/widgets/video_card.dart';
import 'package:mobile/features/library/data/repositories/playlist_repository.dart';
import 'package:mobile/features/library/domain/playlist_dto.dart';
import 'package:mobile/features/library/presentation/playlists_screen.dart';
import 'package:mobile/features/library/presentation/watch_history_screen.dart';
import 'package:mobile/features/profile/data/models/profile_model.dart';
import 'package:mobile/features/profile/presentation/providers/profile_providers.dart';
import 'package:mobile/features/profile/presentation/providers/profile_videos_provider.dart';
import 'package:mobile/features/profile/presentation/widgets/profile_posts_list.dart';
import 'package:mobile/features/social/presentation/providers/save_provider.dart';
import 'package:mobile/features/social/presentation/widgets/share_button.dart';
import 'package:mobile/features/stories/data/models/story_model.dart';
import 'package:mobile/features/stories/data/models/story_feed_group_model.dart';
import 'package:mobile/features/stories/presentation/providers/story_feed_provider.dart';
import 'package:mobile/features/stories/presentation/screens/story_viewer_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    Future.microtask(() => ref.read(profileProvider.notifier).loadMyProfile());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final authState = ref.watch(authProvider);
    final tr = ref.watch(trProvider);
    final cs = Theme.of(context).colorScheme;

    final feedAsync = ref.watch(storyFeedProvider);
    final profile = state.profile;
    final myStoriesGroup = (profile != null && feedAsync.valueOrNull != null)
        ? feedAsync.valueOrNull!.firstWhere(
            (g) => g.owner.id == profile.userId,
            orElse: () => StoryFeedGroupModel(
              owner: StoryAuthorModel(id: profile.userId),
              stories: [],
              hasUnseen: false,
              latestStoryAt: DateTime.now(),
              totalStories: 0,
            ),
          )
        : null;
    final hasActiveStories =
        myStoriesGroup != null && myStoriesGroup.stories.isNotEmpty;

    if (state.isLoading && profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.error != null && profile == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: cs.error),
              const SizedBox(height: 16),
              Text(
                '${tr('state.error')}\n${state.error!}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(profileProvider.notifier).loadMyProfile(),
                child: Text(tr('common.retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (profile == null) {
      return Scaffold(body: Center(child: Text(tr('state.empty'))));
    }

    final isProfileIncomplete =
        profile.username == null || profile.displayName == null;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: Text(
                profile.username ??
                    authState.user?.displayIdentifier ??
                    tr('profile.my_profile'),
              ),
              pinned: true,
              floating: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () => context.push('/notifications'),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => context.push('/search'),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
            // User Avatar & Stats Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: hasActiveStories
                          ? () {
                              context.push(
                                '/story-viewer',
                                extra: StoryViewerArgs(
                                  groups: [myStoriesGroup],
                                  initialGroupIndex: 0,
                                ),
                              );
                            }
                          : null,
                      child: Container(
                        padding: EdgeInsets.all(hasActiveStories ? 3.0 : 0.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: hasActiveStories
                              ? LinearGradient(
                                  colors: [cs.primary, cs.tertiary],
                                )
                              : null,
                        ),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundImage: profile.avatarUrl != null
                              ? NetworkImage(
                                  MediaUrlResolver.resolve(
                                        profile.avatarUrl!,
                                      ) ??
                                      profile.avatarUrl!,
                                )
                              : null,
                          backgroundColor: cs.primaryContainer,
                          child: profile.avatarUrl == null
                              ? Text(
                                  _initials(profile),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: cs.onPrimaryContainer,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.displayName ??
                                _fullName(profile) ??
                                profile.username ??
                                'User',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                          ),
                          if (profile.username != null)
                            Text(
                              '@${profile.username}',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.push(
                                  '/profile/${profile.userId}/followers',
                                ),
                                child: Text(
                                  '${profile.stats.followersCount} ${tr('profile.followers')}',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () => context.push(
                                  '/profile/${profile.userId}/following',
                                ),
                                child: Text(
                                  '${profile.stats.followingCount} ${tr('profile.following')}',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
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
            ),
            // Profile Actions (Edit Profile & View Channel)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      Text(profile.bio!, style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: () =>
                                context.push('/profile/edit', extra: profile),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: Text(
                              isProfileIncomplete
                                  ? tr('profile.setup_profile')
                                  : tr('profile.edit_profile'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // View channels with RBAC permissions -> Creator Workspace / Channels
                              context.push('/creator/workspace');
                            },
                            icon: const Icon(
                              Icons.smart_display_outlined,
                              size: 18,
                            ),
                            label: Text(tr('profile.view_channel')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // ── Watch History Section (Above Tabs) ──────────────────────────
            SliverToBoxAdapter(child: _WatchHistoryCarousel()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            // ── Tabs Header ────────────────────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: tr('profile.videos')),
                    const Tab(text: 'Streaming'),
                    Tab(text: tr('library.playlists')),
                    Tab(text: tr('profile.posts')),
                    const Tab(text: 'About'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _ProfileVideosTab(userId: profile.userId),
            _ProfileStreamsTab(userId: profile.userId),
            _ProfilePlaylistsTab(),
            ProfilePostsList(userId: profile.userId, isMyProfile: true),
            _ProfileAboutTab(profile: profile, authState: authState),
          ],
        ),
      ),
    );
  }

  String _initials(ProfileModel profile) {
    if (profile.firstName != null && profile.lastName != null) {
      return '${profile.firstName![0]}${profile.lastName![0]}'.toUpperCase();
    }
    if (profile.username != null && profile.username!.isNotEmpty) {
      return profile.username![0].toUpperCase();
    }
    return '?';
  }

  String? _fullName(ProfileModel profile) {
    if (profile.firstName != null || profile.lastName != null) {
      return '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim();
    }
    return null;
  }
}

// ── Watch History Carousel (Above Tabs) ──────────────────────────────────────

class _WatchHistoryCarousel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final historyAsync = ref.watch(watchHistoryProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => context.push('/library/history'),
                child: Row(
                  children: [
                    Text(
                      tr('library.history'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push('/library/history'),
                child: Text(
                  'View all',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        historyAsync.when(
          data: (response) {
            if (response.data.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  'No watched videos yet.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              );
            }
            return SizedBox(
              height: 165,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: response.data.length,
                itemBuilder: (context, index) {
                  final video = response.data[index];
                  return _HistoryItemCard(video: video);
                },
              ),
            );
          },
          loading: () => const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _HistoryItemCard extends ConsumerWidget {
  final VideoResponseDto video;

  const _HistoryItemCard({required this.video});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resolvedThumb = MediaUrlResolver.resolve(video.thumbnailUrl);

    return Container(
      width: 170,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/video/${video.id}'),
        onLongPress: () => _showVideoActionModal(context, ref, video),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.grey.shade900,
                      child: resolvedThumb != null
                          ? Image.network(
                              resolvedThumb,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(
                                      Icons.play_circle_outline,
                                      color: Colors.white54,
                                    ),
                                  ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                color: Colors.white54,
                              ),
                            ),
                    ),
                  ),
                  if (video.duration > 0)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(video.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        video.author.displayName ??
                            video.author.username ??
                            'Channel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showVideoActionModal(context, ref, video),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 2.0),
                    child: Icon(Icons.more_vert, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoActionModal(
    BuildContext context,
    WidgetRef ref,
    VideoResponseDto video,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow_outlined),
              title: const Text('Play Video'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/video/${video.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Download'),
              onTap: () {
                Navigator.pop(ctx);
                if (video.renditions.isNotEmpty) {
                  ref
                      .read(downloadServiceProvider.notifier)
                      .startDownload(
                        videoId: video.id,
                        url: video.renditions.first.url,
                        title: video.title,
                        thumbnailUrl: video.thumbnailUrl,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Downloading video...')),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Download not available for this video'),
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('Save to Bookmarks / Library'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(saveProvider.notifier)
                    .toggleSave(video.id, isVideo: true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved to your library')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(ctx);
                ShareButton(postId: video.id, title: video.title);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Remove from Watch History',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(videoRepositoryProvider)
                      .removeFromWatchHistory(video.id);
                  ref.invalidate(watchHistoryProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Removed from watch history'),
                      ),
                    );
                  }
                } catch (_) {
                  ref.invalidate(watchHistoryProvider);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

// ── Videos Tab ───────────────────────────────────────────────────────────────

class _ProfileVideosTab extends ConsumerWidget {
  final String userId;

  const _ProfileVideosTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(profileVideosProvider(userId));
    final theme = Theme.of(context);

    return videosAsync.when(
      data: (videos) {
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(profileVideosProvider(userId)),
          child: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            children: [
              // Library shortcuts at the top
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.download_done,
                          color: Colors.blue,
                        ),
                      ),
                      title: const Text(
                        'Downloads',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => context.push('/library/downloads'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.thumb_up_alt_outlined,
                          color: Colors.red,
                        ),
                      ),
                      title: const Text(
                        'Liked videos',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Private',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => context.push('/library/liked'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.bookmark_outline,
                          color: Colors.amber,
                        ),
                      ),
                      title: const Text(
                        'Bookmarked videos',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => context.push('/library/bookmarks'),
                    ),
                    const Divider(height: 24),
                  ],
                ),
              ),
              // Videos list
              if (videos.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 56,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nothing to see here yet.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...videos.map(
                  (video) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: VideoCard(
                      video: video,
                      onVideoDeleted: () {
                        ref.invalidate(profileVideosProvider(userId));
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading videos: $err')),
    );
  }
}

// ── Streaming Tab (Recorded Live Streams & VODs) ─────────────────────────────

class _ProfileStreamsTab extends ConsumerWidget {
  final String userId;

  const _ProfileStreamsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamsAsync = ref.watch(profileStreamsProvider(userId));
    final theme = Theme.of(context);

    return streamsAsync.when(
      data: (streams) {
        if (streams.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.live_tv_outlined,
                  size: 56,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No streaming recordings yet.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Recorded live streams will automatically appear here.',
                  style: TextStyle(
                    color: theme.colorScheme.outline,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(profileStreamsProvider(userId)),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: streams.length,
            itemBuilder: (context, index) {
              final video = streams[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: VideoCard(
                  video: video,
                  onVideoDeleted: () {
                    ref.invalidate(profileStreamsProvider(userId));
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text('Error loading streams: $err'),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => ref.invalidate(profileStreamsProvider(userId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Playlists Tab ────────────────────────────────────────────────────────────

class _ProfilePlaylistsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(myPlaylistsProvider);
    final theme = Theme.of(context);

    return playlistsAsync.when(
      data: (playlists) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created Playlists',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Create Playlist',
                  onPressed: () => _showCreatePlaylistDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (playlists.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No playlists created yet.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ...playlists.map(
                (playlist) => _PlaylistCardTile(playlist: playlist),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading playlists: $err')),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: 'Playlist Title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                Navigator.pop(dialogCtx);
                try {
                  await ref
                      .read(playlistRepositoryProvider)
                      .createPlaylist(title: title);
                  ref.invalidate(myPlaylistsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Playlist created')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create playlist: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _PlaylistCardTile extends StatelessWidget {
  final PlaylistDto playlist;

  const _PlaylistCardTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstThumb = playlist.items.isNotEmpty
        ? playlist.items.first.videoThumbnailUrl
        : null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 80,
          height: 48,
          color: theme.colorScheme.surfaceContainerHighest,
          child: firstThumb != null && firstThumb.isNotEmpty
              ? Image.network(
                  firstThumb,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.playlist_play, size: 28)),
                )
              : const Center(child: Icon(Icons.playlist_play, size: 28)),
        ),
      ),
      title: Text(
        playlist.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${playlist.items.length} ${playlist.items.length == 1 ? "video" : "videos"} • ${playlist.visibility}',
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () => context.push('/playlists/${playlist.id}'),
    );
  }
}

// ── About Tab ────────────────────────────────────────────────────────────────

class _ProfileAboutTab extends StatelessWidget {
  final ProfileModel profile;
  final AuthState authState;

  const _ProfileAboutTab({required this.profile, required this.authState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'About',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.email_outlined),
          title: const Text('Email'),
          subtitle: Text(authState.user?.email ?? '—'),
        ),
        if (profile.website != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.link),
            title: const Text('Website'),
            subtitle: Text(profile.website!),
          ),
        if (profile.country != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Country'),
            subtitle: Text(profile.country!),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today_outlined),
          title: const Text('Joined'),
          subtitle: Text(profile.createdAt.toString().split(' ')[0]),
        ),
        const Divider(height: 32),
        Text(
          'Channel Statistics',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(label: 'Videos', value: '${profile.stats.videosCount}'),
            _StatItem(label: 'Posts', value: '${profile.stats.postsCount}'),
            _StatItem(
              label: 'Followers',
              value: '${profile.stats.followersCount}',
            ),
            _StatItem(
              label: 'Following',
              value: '${profile.stats.followingCount}',
            ),
          ],
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── Sliver App Bar Delegate ──────────────────────────────────────────────────

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
