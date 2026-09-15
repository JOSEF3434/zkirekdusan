// lib/features/profile/presentation/widgets/profile_posts_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/presentation/widgets/responsive_layout.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/home/presentation/widgets/post_card.dart';
import 'package:mobile/features/profile/presentation/providers/profile_posts_provider.dart';

class ProfilePostsList extends ConsumerStatefulWidget {
  final String userId;
  final bool isMyProfile;

  const ProfilePostsList({
    super.key,
    required this.userId,
    this.isMyProfile = false,
  });

  @override
  ConsumerState<ProfilePostsList> createState() => _ProfilePostsListState();
}

class _ProfilePostsListState extends ConsumerState<ProfilePostsList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(profilePostsProvider(widget.userId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profilePostsProvider(widget.userId));
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                state.error!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref
                    .read(profilePostsProvider(widget.userId).notifier)
                    .refresh(),
                icon: const Icon(Icons.refresh),
                label: Text(tr('common.retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (state.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.article_outlined,
                size: 56,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                widget.isMyProfile
                    ? tr('profile.posts.my_empty_title')
                    : tr('profile.posts.empty_title'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isMyProfile
                    ? tr('profile.posts.my_empty_desc')
                    : tr('profile.posts.empty_desc'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (widget.isMyProfile) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => context.push('/upload'),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Create Post'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(profilePostsProvider(widget.userId).notifier).refresh(),
      child: ResponsiveLayout.maxReadingWidth(
        maxWidth: 700,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: state.posts.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < state.posts.length) {
              return PostCard(
                post: state.posts[index],
                onPostDeleted: () => ref
                    .read(profilePostsProvider(widget.userId).notifier)
                    .refresh(),
                onPostUpdated: () => ref
                    .read(profilePostsProvider(widget.userId).notifier)
                    .refresh(),
              );
            } else {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
          },
        ),
      ),
    );
  }
}
