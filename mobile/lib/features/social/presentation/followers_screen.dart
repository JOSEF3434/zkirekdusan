import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/social/data/follow_repository.dart';
import 'package:mobile/features/social/data/social_repository.dart';
import 'package:mobile/features/social/domain/follow_model.dart';
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
    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('social.followers_title')),
          bottom: TabBar(
            tabs: [
              Tab(text: tr('social.tab_followers')),
              Tab(text: tr('social.tab_following')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FollowList(
              provider: followersProvider(profileId),
              emptyMessageKey: 'social.no_followers',
            ),
            _FollowList(
              provider: followingProvider(profileId),
              emptyMessageKey: 'social.not_following',
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowList extends ConsumerWidget {
  final ProviderBase<AsyncValue<PaginatedResponse<FollowerDto>>> provider;
  final String emptyMessageKey;

  const _FollowList({required this.provider, required this.emptyMessageKey});

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
                        tr(emptyMessageKey),
                        style: TextStyle(
                          fontSize: 15,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
