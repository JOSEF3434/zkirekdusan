// lib/features/social/presentation/user_follow_list_screen.dart
// Standalone screen showing either the followers OR following list for a user.
// Navigated to from the profile stats row (Followers / Following chips).

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/social/domain/follow_model.dart';
import 'package:mobile/features/social/presentation/followers_screen.dart'
    show followersProvider, followingProvider;
import 'package:mobile/features/social/presentation/providers/follow_provider.dart';

enum FollowListMode { followers, following }

// ── Screen ────────────────────────────────────────────────────────────────────

class UserFollowListScreen extends ConsumerWidget {
  final String userId;
  final FollowListMode mode;

  const UserFollowListScreen({
    super.key,
    required this.userId,
    this.mode = FollowListMode.followers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final title = mode == FollowListMode.followers
        ? tr('social.followers', {'fallback': 'Followers'})
        : tr('social.following', {'fallback': 'Following'});

    final asyncList = mode == FollowListMode.followers
        ? ref.watch(followersProvider(userId))
        : ref.watch(followingProvider(userId));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1621) : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0E1621) : Colors.grey[100],
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00C6FF),
        onRefresh: () async {
          if (mode == FollowListMode.followers) {
            ref.invalidate(followersProvider(userId));
          } else {
            ref.invalidate(followingProvider(userId));
          }
        },
        child: asyncList.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF00C6FF)),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(
                  tr('common.error_loading',
                      {'fallback': 'Error loading users'}),
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    if (mode == FollowListMode.followers) {
                      ref.invalidate(followersProvider(userId));
                    } else {
                      ref.invalidate(followingProvider(userId));
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(tr('common.retry')),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00C6FF),
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          data: (response) {
            final users = response.data;
            if (users.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 72,
                          color: isDark ? Colors.grey[700] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          mode == FollowListMode.followers
                              ? tr('social.no_followers',
                                  {'fallback': 'No followers yet'})
                              : tr('social.not_following',
                                  {'fallback': 'Not following anyone yet'}),
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: users.length,
              separatorBuilder: (_, i) => Divider(
                height: 1,
                indent: 60,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              itemBuilder: (context, index) {
                final user = users[index];
                return _UserFollowTile(user: user, isDark: isDark);
              },
            );
          },
        ),
      ),
    );
  }
}

// ── User Tile ─────────────────────────────────────────────────────────────────

class _UserFollowTile extends ConsumerWidget {
  final FollowerDto user;
  final bool isDark;

  const _UserFollowTile({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = user.displayName ?? user.username ?? 'User';

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      onTap: () {
        if (user.username != null && user.username!.isNotEmpty) {
          context.push('/@${user.username}');
        } else {
          context.push('/profile/user/${user.id}');
        }
      },
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF00C6FF).withValues(alpha: 0.2),
        backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
            ? CachedNetworkImageProvider(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null || user.avatarUrl!.isEmpty
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00C6FF),
                  fontSize: 18,
                ),
              )
            : null,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: user.username != null
          ? Text(
              '@${user.username}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            )
          : null,
      trailing: _FollowTileButton(user: user),
    );
  }
}

// ── Follow Button ─────────────────────────────────────────────────────────────

class _FollowTileButton extends ConsumerWidget {
  final FollowerDto user;
  const _FollowTileButton({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followAsync = ref.watch(followProvider(user.id));
    final isFollowing =
        followAsync.valueOrNull?.isFollowing ?? user.isFollowing;
    final isLoading = followAsync.valueOrNull?.isLoading ?? false;

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                side: const BorderSide(color: Color(0xFF10B981)),
                foregroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF10B981)),
                    )
                  : const Text('Following',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                backgroundColor: const Color(0xFF00C6FF),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Follow',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
    );
  }
}

