import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/features/social/data/follow_repository.dart';
import 'package:mobile/features/social/data/social_repository.dart';
import 'package:mobile/features/social/domain/follow_model.dart';

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
  final int initialTabIndex; // 0 for followers, 1 for following

  const FollowersScreen({
    super.key,
    required this.profileId,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Follows'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Followers'),
              Tab(text: 'Following'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FollowList(
              provider: followersProvider(profileId),
              emptyMessage: 'No followers yet.',
            ),
            _FollowList(
              provider: followingProvider(profileId),
              emptyMessage: 'Not following anyone yet.',
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowList extends ConsumerWidget {
  final ProviderBase<AsyncValue<PaginatedResponse<FollowerDto>>> provider;
  final String emptyMessage;

  const _FollowList({required this.provider, required this.emptyMessage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(provider);
    final theme = Theme.of(context);

    return asyncList.when(
      data: (response) {
        final users = response.data;
        if (users.isEmpty) {
          return Center(child: Text(emptyMessage));
        }
        return ListView.builder(
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
              title: Text(user.displayName ?? user.username ?? 'User'),
              subtitle: user.username != null
                  ? Text('@${user.username}')
                  : null,
              trailing: ElevatedButton(
                onPressed: () {
                  // TODO: Follow/Unfollow user
                },
                child: const Text('Follow'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
