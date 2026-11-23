// lib/features/profile/presentation/widgets/profile_posts_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/presentation/widgets/app_network_image.dart';
import 'package:mobile/core/presentation/widgets/responsive_layout.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/stories/data/datasources/stories_remote_datasource.dart';
import 'package:mobile/features/stories/data/models/story_feed_group_model.dart';
import 'package:mobile/features/stories/data/models/story_model.dart';
import 'package:mobile/features/stories/presentation/providers/story_feed_provider.dart';
import 'package:mobile/features/stories/presentation/screens/story_viewer_screen.dart';

/// Provider for user's active/public stories history (non-archived)
final profileStoryHistoryProvider =
    FutureProvider.family<List<StoryModel>, String>((ref, userId) async {
      final remote = ref.read(storiesRemoteDatasourceProvider);
      return remote.getStoryHistory(userId, archived: false);
    });

/// Provider for user's archived stories (accessible only by the profile owner)
final profileArchivedStoriesProvider =
    FutureProvider.family<List<StoryModel>, String>((ref, userId) async {
      final remote = ref.read(storiesRemoteDatasourceProvider);
      return remote.getStoryHistory(userId, archived: true);
    });

/// ProfileStoriesList displays the user's stories (active and archived)
/// and provides archive/unarchive, delete, and repost functionalities.
class ProfileStoriesList extends ConsumerStatefulWidget {
  final String userId;
  final bool isMyProfile;

  const ProfileStoriesList({
    super.key,
    required this.userId,
    this.isMyProfile = false,
  });

  @override
  ConsumerState<ProfileStoriesList> createState() => _ProfileStoriesListState();
}

class _ProfileStoriesListState extends ConsumerState<ProfileStoriesList> {
  bool _showArchived = false;

  Color? _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return null;
    try {
      var hex = colorStr.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  void _invalidateAll() {
    ref.invalidate(profileStoryHistoryProvider(widget.userId));
    if (widget.isMyProfile) {
      ref.invalidate(profileArchivedStoriesProvider(widget.userId));
    }
    ref.invalidate(storyFeedProvider);
  }

  Future<void> _handleArchive(StoryModel story) async {
    try {
      await ref.read(storiesRemoteDatasourceProvider).archiveStory(story.id);
      _invalidateAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story added to archive'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to archive: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleUnarchive(StoryModel story) async {
    try {
      await ref.read(storiesRemoteDatasourceProvider).unarchiveStory(story.id);
      _invalidateAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story removed from archive'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unarchive: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleRepost(StoryModel story) async {
    final tr = ref.read(trProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Repost Story'),
        content: const Text(
          'Repost this story? It will be published as a new 24-hour story.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('common.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00C6FF),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Repost'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(storiesRemoteDatasourceProvider).repostStory(story.id);
        _invalidateAll();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Story reposted successfully!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to repost: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDelete(StoryModel story) async {
    final tr = ref.read(trProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('stories.delete_title')),
        content: Text(tr('stories.delete_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('common.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('common.delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(storiesRemoteDatasourceProvider).deleteStory(story.id);
        _invalidateAll();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('stories.deleted')),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete story: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Widget _buildSubTabButton({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (theme.brightness == Brightness.dark
                  ? const Color(0xFF00C6FF)
                  : const Color(0xFF0072FF))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? (theme.brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white)
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected
                    ? (theme.brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white)
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.black.withValues(alpha: 0.15)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? (theme.brightness == Brightness.dark
                          ? Colors.black87
                          : Colors.white)
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    // If viewing another user's profile, always fetch regular stories (archived is private)
    final isShowingArchived = widget.isMyProfile && _showArchived;
    final storiesAsync = isShowingArchived
        ? ref.watch(profileArchivedStoriesProvider(widget.userId))
        : ref.watch(profileStoryHistoryProvider(widget.userId));

    // Also get counts for sub-tab badges when viewing own profile
    final regularStoriesList =
        ref.watch(profileStoryHistoryProvider(widget.userId)).valueOrNull ?? [];
    final archivedStoriesList = widget.isMyProfile
        ? (ref
                .watch(profileArchivedStoriesProvider(widget.userId))
                .valueOrNull ??
            [])
        : <StoryModel>[];

    return RefreshIndicator(
      onRefresh: () async => _invalidateAll(),
      child: storiesAsync.when(
        data: (stories) {
          final isDesktop = ResponsiveLayout.isDesktop(context);
          final isTablet = ResponsiveLayout.isTablet(context);
          final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);

          return ResponsiveLayout.maxReadingWidth(
            maxWidth: 1200,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header row with tabs (Stories / Archive Stories) and Create Story button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Sub-tabs for owner, or simple title for friends
                        if (widget.isMyProfile)
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildSubTabButton(
                                  label: tr(
                                    'stories.title',
                                    {'fallback': 'Stories'},
                                  ),
                                  count: regularStoriesList.length,
                                  isSelected: !_showArchived,
                                  onTap: () =>
                                      setState(() => _showArchived = false),
                                  theme: theme,
                                ),
                                const SizedBox(width: 4),
                                _buildSubTabButton(
                                  label: 'Archive Stories',
                                  count: archivedStoriesList.length,
                                  isSelected: _showArchived,
                                  onTap: () =>
                                      setState(() => _showArchived = true),
                                  theme: theme,
                                  icon: Icons.archive_outlined,
                                ),
                              ],
                            ),
                          )
                        else
                          Row(
                            children: [
                              Text(
                                tr('stories.title', {'fallback': 'Stories'}),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${stories.length}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                        // Create Story button for owner (only shown on regular stories tab)
                        if (widget.isMyProfile && !_showArchived)
                          FilledButton.tonalIcon(
                            onPressed: () {
                              context.push('/story/create').then((_) {
                                _invalidateAll();
                              });
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(
                              tr(
                                'stories.create_story',
                                {'fallback': 'Create Story'},
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Empty state or stories grid
                if (stories.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isShowingArchived
                                  ? Icons.archive_outlined
                                  : Icons.auto_stories_outlined,
                              size: 64,
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isShowingArchived
                                  ? 'No archived stories yet'
                                  : (widget.isMyProfile
                                      ? tr(
                                          'stories.no_stories_yet',
                                          {'fallback': 'No stories yet'},
                                        )
                                      : tr(
                                          'stories.no_stories_user',
                                          {
                                            'fallback':
                                                'No stories shared yet',
                                          },
                                        )),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isShowingArchived
                                  ? 'Stories you add to archive will be saved privately here.'
                                  : (widget.isMyProfile
                                      ? tr(
                                          'stories.share_moment',
                                          {
                                            'fallback':
                                                'Share a 24-hour story, reflection, or moment with your community.',
                                          },
                                        )
                                      : 'Check back later for new stories from this user.'),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (widget.isMyProfile && !isShowingArchived) ...[
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: () {
                                  context.push('/story/create').then((_) {
                                    _invalidateAll();
                                  });
                                },
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                ),
                                label: Text(
                                  tr(
                                    'stories.create_story',
                                    {'fallback': 'Create Story'},
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  // Stories Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final story = stories[index];
                        final isActive = story.expiresAt.isAfter(
                              DateTime.now(),
                            ) &&
                            !story.isArchived;
                        final bgColor = _parseColor(story.backgroundColor) ??
                            theme.colorScheme.surfaceContainerHighest;
                        final textColor = _parseColor(story.textColor) ??
                            theme.colorScheme.onSurface;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final group = StoryFeedGroupModel(
                                owner: story.author,
                                stories: stories,
                                hasUnseen: false,
                                latestStoryAt: stories.first.createdAt,
                                totalStories: stories.length,
                              );
                              context.push(
                                '/story-viewer',
                                extra: StoryViewerArgs(
                                  groups: [group],
                                  initialStoryIndex: index,
                                ),
                              ).then((_) {
                                _invalidateAll();
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Story Background
                                  if (story.type == 'TEXT')
                                    Container(
                                      color: bgColor,
                                      padding: const EdgeInsets.all(16),
                                      alignment: Alignment.center,
                                      child: Text(
                                        story.content ?? '',
                                        maxLines: 6,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  else if (story.mediaUrl != null &&
                                      story.mediaUrl!.isNotEmpty)
                                    AppNetworkImage(
                                      imageUrl: MediaUrlResolver.resolve(
                                            story.mediaUrl!,
                                          ) ??
                                          story.mediaUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  else
                                    Container(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_outlined,
                                          size: 36,
                                        ),
                                      ),
                                    ),

                                  // Video Play indicator
                                  if (story.type == 'VIDEO')
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Colors.black45,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),

                                  // Gradient Overlay for text readability
                                  const Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black38,
                                            Colors.transparent,
                                            Colors.black87,
                                          ],
                                          stops: [0.0, 0.5, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Top-Left Badge (Active vs Expired vs Archived)
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: story.isArchived
                                            ? Colors.orange.withValues(
                                                alpha: 0.9,
                                              )
                                            : (isActive
                                                ? Colors.green.withValues(
                                                    alpha: 0.9,
                                                  )
                                                : Colors.black54),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (story.isArchived) ...[
                                            const Icon(
                                              Icons.archive_outlined,
                                              size: 11,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Archived',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ] else if (isActive) ...[
                                            const Icon(
                                              Icons.circle,
                                              size: 6,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Active',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ] else ...[
                                            const Icon(
                                              Icons.history,
                                              size: 11,
                                              color: Colors.white70,
                                            ),
                                            const SizedBox(width: 3),
                                            const Text(
                                              'Expired',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Top-Right 3-Dots Action Menu for Story Owner
                                  if (widget.isMyProfile)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black45,
                                            shape: BoxShape.circle,
                                          ),
                                          child: PopupMenuButton<String>(
                                            icon: const Icon(
                                              Icons.more_vert_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            onSelected: (action) {
                                              if (action == 'archive') {
                                                _handleArchive(story);
                                              } else if (action ==
                                                  'unarchive') {
                                                _handleUnarchive(story);
                                              } else if (action == 'repost') {
                                                _handleRepost(story);
                                              } else if (action == 'delete') {
                                                _handleDelete(story);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              if (!story.isArchived)
                                                const PopupMenuItem(
                                                  value: 'archive',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.archive_outlined,
                                                        size: 18,
                                                      ),
                                                      SizedBox(width: 10),
                                                      Text('Add to Archive'),
                                                    ],
                                                  ),
                                                ),
                                              if (story.isArchived)
                                                const PopupMenuItem(
                                                  value: 'unarchive',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .unarchive_outlined,
                                                        size: 18,
                                                      ),
                                                      SizedBox(width: 10),
                                                      Text(
                                                        'Remove from Archive',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              const PopupMenuItem(
                                                value: 'repost',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.repeat_rounded,
                                                      color: Color(0xFF00C6FF),
                                                      size: 18,
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text('Repost Story'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red,
                                                      size: 18,
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(
                                                      'Delete Story',
                                                      style: TextStyle(
                                                        color: Colors.red,
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

                                  // Bottom Metadata (Views & Date)
                                  Positioned(
                                    left: 10,
                                    right: 10,
                                    bottom: 10,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.visibility_outlined,
                                              size: 13,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${story.viewsCount}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          _formatDate(story.createdAt),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }, childCount: stories.length),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  err.toString(),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _invalidateAll(),
                  icon: const Icon(Icons.refresh),
                  label: Text(tr('common.retry')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Backwards compatible alias for ProfilePostsList
typedef ProfilePostsList = ProfileStoriesList;
