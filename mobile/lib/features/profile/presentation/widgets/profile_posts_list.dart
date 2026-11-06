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
import 'package:mobile/features/stories/presentation/screens/story_viewer_screen.dart';

final profileStoryHistoryProvider =
    FutureProvider.family<List<StoryModel>, String>((ref, userId) async {
      final remote = ref.read(storiesRemoteDatasourceProvider);
      return remote.getStoryHistory(userId);
    });

/// ProfileStoriesList displays the user's stories history (active and archived)
/// and allows creating new stories.
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

  @override
  Widget build(BuildContext context) {
    final storiesAsync = ref.watch(profileStoryHistoryProvider(widget.userId));
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(profileStoryHistoryProvider(widget.userId));
      },
      child: storiesAsync.when(
        data: (stories) {
          if (stories.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_stories_outlined,
                        size: 64,
                        color: theme.colorScheme.primary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.isMyProfile
                            ? tr(
                                'stories.no_stories_yet',
                                {'fallback': 'No stories yet'},
                              )
                            : tr(
                                'stories.no_stories_user',
                                {'fallback': 'No stories shared yet'},
                              ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isMyProfile
                            ? tr(
                                'stories.share_moment',
                                {
                                  'fallback':
                                      'Share a 24-hour story, reflection, or moment with your community.',
                                },
                              )
                            : 'Check back later for new stories from this user.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (widget.isMyProfile) ...[
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () {
                            context.push('/story/create').then((_) {
                              ref.invalidate(
                                profileStoryHistoryProvider(widget.userId),
                              );
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 18),
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
            );
          }

          final isDesktop = ResponsiveLayout.isDesktop(context);
          final isTablet = ResponsiveLayout.isTablet(context);
          final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);

          return ResponsiveLayout.maxReadingWidth(
            maxWidth: 1200,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header row with count & create action
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                                color: theme.colorScheme.surfaceContainerHighest,
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
                        if (widget.isMyProfile)
                          FilledButton.tonalIcon(
                            onPressed: () {
                              context.push('/story/create').then((_) {
                                ref.invalidate(
                                  profileStoryHistoryProvider(widget.userId),
                                );
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

                // Stories Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final story = stories[index];
                        final isActive = story.expiresAt.isAfter(DateTime.now());
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
                                ref.invalidate(
                                  profileStoryHistoryProvider(widget.userId),
                                );
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
                                        child: Icon(Icons.image_outlined, size: 36),
                                      ),
                                    ),

                                  // Video Play indicator
                                  if (story.type == 'VIDEO')
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
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
                                  Positioned.fill(
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
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Top Badges (Active vs Archived)
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.green.withValues(alpha: 0.9)
                                            : Colors.black54,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isActive) ...[
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
                                              size: 10,
                                              color: Colors.white70,
                                            ),
                                            const SizedBox(width: 3),
                                            const Text(
                                              'Archived',
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
                      },
                      childCount: stories.length,
                    ),
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
                  onPressed: () => ref.invalidate(
                    profileStoryHistoryProvider(widget.userId),
                  ),
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
