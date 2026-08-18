// lib/features/explore/presentation/widgets/search_result_widgets.dart
// Reusable search result tiles for users, groups, streams, and skeleton states.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/explore/domain/search_model.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/home/presentation/widgets/video_card.dart';

// ── Skeleton Loader ───────────────────────────────────────────────────────────

class SearchSkeleton extends StatelessWidget {
  const SearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shimmerColor = cs.onSurface.withValues(alpha: 0.08);

    Widget block({double w = double.infinity, double h = 14, double r = 8}) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: shimmerColor,
          borderRadius: BorderRadius.circular(r),
        ),
      );
    }

    return Column(
      children: List.generate(5, (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(radius: 22, backgroundColor: shimmerColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    block(w: 140),
                    const SizedBox(height: 6),
                    block(w: 90, h: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class SearchSectionHeader extends StatelessWidget {
  final String title;
  const SearchSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── User Tile ─────────────────────────────────────────────────────────────────

class SearchUserTile extends StatelessWidget {
  final SearchUserDto user;
  const SearchUserTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        backgroundImage: user.avatarUrl != null
            ? CachedNetworkImageProvider(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? Text(
                (user.displayName ?? user.username ?? '?')[0].toUpperCase(),
                style: theme.textTheme.titleSmall,
              )
            : null,
      ),
      title: Text(user.displayName ?? user.username ?? 'User'),
      subtitle: user.username != null ? Text('@${user.username}') : null,
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: () {
        if (user.username != null) {
          context.push('/profile/user/${user.username}');
        }
      },
    );
  }
}

// ── Group Tile ────────────────────────────────────────────────────────────────

class SearchGroupTile extends StatelessWidget {
  final SearchGroupDto group;
  const SearchGroupTile({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: theme.colorScheme.primaryContainer,
        backgroundImage: group.avatarUrl != null
            ? CachedNetworkImageProvider(group.avatarUrl!)
            : null,
        child: group.avatarUrl == null ? const Icon(Icons.group) : null,
      ),
      title: Text(group.name ?? 'Group'),
      subtitle: group.slug != null ? Text('@${group.slug}') : null,
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: () {
        // Navigate to group if route exists
      },
    );
  }
}

// ── Stream Tile ───────────────────────────────────────────────────────────────

class SearchStreamTile extends StatelessWidget {
  final SearchStreamDto stream;
  const SearchStreamTile({super.key, required this.stream});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.live_tv_rounded, color: theme.colorScheme.error),
      ),
      title: Text(stream.title ?? 'Live Stream'),
      subtitle: Row(
        children: [
          if (stream.isLive) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (stream.viewerCount != null) Text('${stream.viewerCount} viewers'),
          if (stream.creatorUsername != null)
            Text(' · @${stream.creatorUsername}'),
        ],
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: () {
        context.push('/live/${stream.id}');
      },
    );
  }
}

// ── Video Result Card ─────────────────────────────────────────────────────────

class SearchVideoResultCard extends StatelessWidget {
  final VideoResponseDto video;
  const SearchVideoResultCard({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: VideoCard(video: video),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class SearchEmptyState extends StatelessWidget {
  final String query;
  final VoidCallback onRetry;
  const SearchEmptyState({
    super.key,
    required this.query,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 72,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or filters',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────

class SearchErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const SearchErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: theme.colorScheme.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text('Search failed', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
