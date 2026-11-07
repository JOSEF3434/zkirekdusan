import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/presentation/widgets/responsive_layout.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/home/domain/feed_response.dart';
import 'package:mobile/features/social/data/follow_repository.dart';
import 'package:mobile/features/social/data/social_repository.dart';
import 'package:mobile/features/social/domain/follow_model.dart';
import 'package:mobile/features/social/domain/owned_channel_model.dart';
import 'package:mobile/features/social/presentation/providers/follow_provider.dart';

final followersProvider =
    FutureProvider.family<PaginatedResponse<FollowerDto>, String>((
      ref,
      userId,
    ) async {
      final repo = ref.read(followRepositoryProvider);
      return repo.getFollowers(userId);
    });

final followingProvider =
    FutureProvider.family<PaginatedResponse<FollowerDto>, String>((
      ref,
      userId,
    ) async {
      final repo = ref.read(followRepositoryProvider);
      return repo.getFollowing(userId);
    });

final suggestedChannelsProvider =
    FutureProvider<PaginatedResponse<FollowerDto>>((ref) async {
      final repo = ref.read(followRepositoryProvider);
      try {
        return await repo.getSuggestedChannels();
      } catch (e) {
        debugPrint('[SuggestedChannels] Error fetching suggested: $e');
        return PaginatedResponse(
          data: [],
          meta: const FeedMetaDto(total: 0, page: 1, limit: 20, totalPages: 0),
        );
      }
    });

final myOwnedChannelsProvider =
    FutureProvider<List<OwnedChannelModel>>((ref) async {
      final repo = ref.read(followRepositoryProvider);
      try {
        return await repo.getMyOwnedChannels();
      } catch (e) {
        debugPrint('[MyOwnedChannels] Error fetching owned channels: $e');
        return [];
      }
    });

class FollowersScreen extends ConsumerWidget {
  final String profileId;
  final int initialTabIndex;

  const FollowersScreen({
    super.key,
    required this.profileId,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final myChannelsAsync = ref.watch(myOwnedChannelsProvider);
    final myChannels = myChannelsAsync.asData?.value ?? [];
    final hasOwnedChannels = myChannels.isNotEmpty;

    final tabCount = hasOwnedChannels ? 3 : 2;
    final safeInitialIndex = initialTabIndex.clamp(0, tabCount - 1);

    return DefaultTabController(
      key: ValueKey('channels_tabs_${hasOwnedChannels}_$safeInitialIndex'),
      length: tabCount,
      initialIndex: safeInitialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('nav.channels', {'fallback': 'Channels'})),
          centerTitle: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: [
                        Tab(
                          text: tr('channels.suggested', {
                            'fallback': 'Suggested Channels',
                          }),
                        ),
                        Tab(text: tr('social.tab_following', {'fallback': 'Following'})),
                        if (hasOwnedChannels)
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tr('channels.my_channels', {
                                    'fallback': 'My Channels',
                                  }),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${myChannels.length}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: ResponsiveLayout.maxReadingWidth(
          maxWidth: 1000,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBarView(
            children: [
              _FollowList(
                provider: suggestedChannelsProvider,
                emptyMessageKey: 'channels.no_suggested',
                emptyFallback: 'No suggested channels found at this time.',
              ),
              _FollowList(
                provider: followingProvider(profileId),
                emptyMessageKey: 'social.not_following',
                emptyFallback: 'Not following anyone yet.',
              ),
              if (hasOwnedChannels)
                _MyChannelsList(
                  channels: myChannels,
                  onRefresh: () async => ref.invalidate(myOwnedChannelsProvider),
                ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _MyChannelsList extends ConsumerWidget {
  final List<OwnedChannelModel> channels;
  final Future<void> Function() onRefresh;

  const _MyChannelsList({
    required this.channels,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    if (channels.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.tv_off_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  tr('channels.no_owned_channels', {
                    'fallback': 'You have not created any channels yet.',
                  }),
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: channels.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final ch = channels[index];
          return Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (ch.groupId.isNotEmpty) {
                  context.push('/groups/${ch.groupId}');
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: ch.avatarUrl != null
                          ? CachedNetworkImageProvider(ch.avatarUrl!)
                          : null,
                      child: ch.avatarUrl == null
                          ? Text(
                              ch.name.isNotEmpty ? ch.name[0].toUpperCase() : 'C',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  ch.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (ch.isVerified) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ch.isOwner ? 'Owner' : 'Admin',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ch.handle.startsWith('@') ? ch.handle : '@${ch.handle}',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ch.subscribersCount} subscribers · ${ch.videosCount} videos',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        if (ch.groupId.isNotEmpty) {
                          context.push('/groups/${ch.groupId}');
                        }
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('View'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FollowList extends ConsumerWidget {
  final ProviderBase<AsyncValue<PaginatedResponse<FollowerDto>>> provider;
  final String emptyMessageKey;
  final String? emptyFallback;

  const _FollowList({
    required this.provider,
    required this.emptyMessageKey,
    this.emptyFallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(provider);
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(provider),
      child: asyncList.when(
        data: (response) {
          final users = response.data;
          if (users.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr(
                          emptyMessageKey,
                          {'fallback': emptyFallback ?? 'No users found.'},
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                onTap: () {
                  if (user.username != null && user.username!.isNotEmpty) {
                    context.push('/@${user.username}');
                  } else {
                    context.push('/profile/user/${user.id}');
                  }
                },
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage: user.avatarUrl != null
                      ? CachedNetworkImageProvider(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          user.displayName?[0].toUpperCase() ??
                              user.username?[0].toUpperCase() ??
                              '?',
                        )
                      : null,
                ),
                title: Text(
                  user.displayName ?? user.username ?? tr('common.user'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: user.username != null
                    ? Text('@${user.username}')
                    : null,
                trailing: _FollowButton(user: user),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(tr('social.error', {'error': e.toString()})),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(provider),
                icon: const Icon(Icons.refresh),
                label: Text(tr('common.retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowButton extends ConsumerWidget {
  final FollowerDto user;
  const _FollowButton({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followStateAsync = ref.watch(followProvider(user.id));
    final tr = ref.watch(trProvider);
    final theme = Theme.of(context);

    final isFollowing =
        followStateAsync.valueOrNull?.isFollowing ?? user.isFollowing;
    final isLoading = followStateAsync.valueOrNull?.isLoading ?? false;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isFollowing
          ? OutlinedButton(
              key: const ValueKey('following'),
              onPressed: isLoading
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      ref.read(followProvider(user.id).notifier).unfollow();
                    },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      tr('follow.following'),
                      style: const TextStyle(fontSize: 13),
                    ),
            )
          : FilledButton(
              key: const ValueKey('follow'),
              onPressed: isLoading
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      ref.read(followProvider(user.id).notifier).follow();
                    },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      tr('follow.follow'),
                      style: const TextStyle(fontSize: 13),
                    ),
            ),
    );
  }
}
