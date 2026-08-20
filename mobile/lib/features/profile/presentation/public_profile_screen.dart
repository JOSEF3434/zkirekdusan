// lib/features/profile/presentation/public_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/profile/data/models/profile_model.dart';
import 'package:mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:mobile/features/profile/presentation/widgets/profile_posts_list.dart';
import 'package:mobile/features/stories/data/models/story_feed_group_model.dart';
import 'package:mobile/features/stories/data/models/story_model.dart';
import 'package:mobile/features/stories/presentation/providers/story_feed_provider.dart';
import 'package:mobile/features/stories/presentation/screens/story_viewer_screen.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  final String username;

  const PublicProfileScreen({super.key, required this.username});

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(publicProfileProvider(widget.username));
    final feedAsync = ref.watch(storyFeedProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.username)),
      body: profileState.when(
        data: (profile) =>
            _buildBody(context, profile, feedAsync.valueOrNull, cs),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $e'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref
                    .read(publicProfileProvider(widget.username).notifier)
                    .refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProfileModel profile,
    List<StoryFeedGroupModel>? feedGroups,
    ColorScheme cs,
  ) {
    final userStoryGroup = feedGroups?.firstWhere(
      (g) => g.owner.id == profile.userId,
      orElse: () => StoryFeedGroupModel(
        owner: StoryAuthorModel(id: profile.userId),
        stories: [],
        hasUnseen: false,
        latestStoryAt: DateTime.now(),
        totalStories: 0,
      ),
    );
    final hasActiveStories =
        userStoryGroup != null && userStoryGroup.stories.isNotEmpty;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: hasActiveStories
                        ? () {
                            context.push(
                              '/story-viewer',
                              extra: StoryViewerArgs(
                                groups: [userStoryGroup],
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
                            ? LinearGradient(colors: [cs.primary, cs.tertiary])
                            : null,
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundImage: profile.avatarUrl != null
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                        backgroundColor: cs.primaryContainer,
                        child: profile.avatarUrl == null
                            ? Text(
                                profile.username?[0].toUpperCase() ?? '?',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.displayName ?? profile.username ?? 'User',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (profile.username != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${profile.username}',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                  if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      profile.bio!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Stat(
                        value: profile.stats.followersCount,
                        label: 'Followers',
                        onTap: () =>
                            context.push('/profile/${profile.id}/followers'),
                      ),
                      _Stat(
                        value: profile.stats.followingCount,
                        label: 'Following',
                        onTap: () =>
                            context.push('/profile/${profile.id}/following'),
                      ),
                      _Stat(value: profile.stats.postsCount, label: 'Posts'),
                      _Stat(value: profile.stats.videosCount, label: 'Videos'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'About'),
                ],
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          ProfilePostsList(userId: profile.userId, isMyProfile: false),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (profile.country != null)
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Country'),
                  subtitle: Text(profile.country!),
                ),
              if (profile.website != null)
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('Website'),
                  subtitle: Text(profile.website!),
                ),
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Joined'),
                subtitle: Text(
                  '${profile.createdAt.day}/${profile.createdAt.month}/${profile.createdAt.year}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  final VoidCallback? onTap;

  const _Stat({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: overlapsContent ? 1 : 0,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
