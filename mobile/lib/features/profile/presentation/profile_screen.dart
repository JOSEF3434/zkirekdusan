import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/profile/data/models/profile_model.dart';
import 'package:mobile/features/profile/presentation/providers/profile_providers.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.error != null && state.profile == null) {
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

    final profile = state.profile;
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
                  icon: const Icon(Icons.video_library_outlined),
                  onPressed: () => context.push('/library'),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: profile.avatarUrl != null
                          ? NetworkImage(profile.avatarUrl!)
                          : null,
                      backgroundColor: cs.primaryContainer,
                      child: profile.avatarUrl == null
                          ? Text(
                              _initials(profile),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimaryContainer,
                              ),
                            )
                          : null,
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
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (profile.username != null)
                            Text(
                              '@${profile.username}',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '${profile.stats.followersCount} ${tr('profile.followers')}',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '${profile.stats.followingCount} ${tr('profile.following')}',
                                style: TextStyle(color: cs.onSurfaceVariant),
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      Text(profile.bio!),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: () =>
                                context.push('/profile/edit', extra: profile),
                            child: Text(
                              isProfileIncomplete
                                  ? tr('profile.setup_profile')
                                  : tr('profile.edit_profile'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            child: Text(tr('profile.view_channel')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: [
                    Tab(text: tr('profile.videos')),
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
            _buildEmptyState(tr('state.empty')), // Videos
            _buildEmptyState(tr('state.empty')), // Playlists
            _buildEmptyState(tr('state.empty')), // Posts
            _buildAboutTab(profile, authState, tr), // About
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Text(
        msg,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildAboutTab(
    ProfileModel profile,
    AuthState authState,
    String Function(String) tr,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.email_outlined),
          title: const Text('Email'),
          subtitle: Text(authState.user?.email ?? '—'),
        ),
        if (profile.website != null)
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Website'),
            subtitle: Text(profile.website!),
          ),
        if (profile.country != null)
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Country'),
            subtitle: Text(profile.country!),
          ),
      ],
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
