// lib/features/stories/presentation/widgets/story_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/stories/data/models/story_feed_group_model.dart';
import 'package:mobile/features/stories/presentation/providers/story_feed_provider.dart';
import 'package:mobile/features/stories/presentation/screens/story_viewer_screen.dart';
import 'package:mobile/features/stories/presentation/widgets/my_story_item.dart';
import 'package:mobile/features/stories/presentation/widgets/story_empty_state.dart';
import 'package:mobile/features/stories/presentation/widgets/story_item.dart';

class StorySection extends ConsumerWidget {
  const StorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState.status == AuthStatus.authenticated;
    final feedAsync = ref.watch(storyFeedProvider);
    final theme = Theme.of(context);

    return feedAsync.when(
      data: (groups) {
        final myGroup = groups.isNotEmpty ? groups[0] : null;
        final otherGroups = groups.length > 1
            ? groups.sublist(1)
            : <StoryFeedGroupModel>[];

        return Container(
          height: 104,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: 1 + (otherGroups.isEmpty ? 1 : otherGroups.length),
            itemBuilder: (context, index) {
              if (index == 0) {
                return MyStoryItem(
                  myGroup: myGroup,
                  onViewStory: () {
                    if (myGroup != null && myGroup.stories.isNotEmpty) {
                      context.push(
                        '/story-viewer',
                        extra: StoryViewerArgs(
                          groups: groups,
                          initialGroupIndex: 0,
                        ),
                      );
                    } else {
                      if (isAuthenticated) {
                        context.push('/story/create');
                      } else {
                        context.push('/login');
                      }
                    }
                  },
                  onCreateStory: () {
                    if (isAuthenticated) {
                      context.push('/story/create');
                    } else {
                      context.push('/login');
                    }
                  },
                );
              }

              if (otherGroups.isEmpty) {
                return Center(
                  child: StoryEmptyState(
                    onAddStory: () {
                      if (isAuthenticated) {
                        context.push('/story/create');
                      } else {
                        context.push('/login');
                      }
                    },
                  ),
                );
              }

              final groupIndex = index; // index in full groups list is 1-based
              final otherGroup = otherGroups[index - 1];

              return StoryItem(
                group: otherGroup,
                onTap: () {
                  context.push(
                    '/story-viewer',
                    extra: StoryViewerArgs(
                      groups: groups,
                      initialGroupIndex: groupIndex,
                    ),
                  );
                },
              );
            },
          ),
        );
      },
      loading: () => _buildSkeleton(theme),
      error: (error, stack) => _buildFallback(context, isAuthenticated),
    );
  }

  Widget _buildFallback(BuildContext context, bool isAuthenticated) {
    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          MyStoryItem(
            myGroup: null,
            onViewStory: () {
              if (isAuthenticated) {
                context.push('/story/create');
              } else {
                context.push('/login');
              }
            },
            onCreateStory: () {
              if (isAuthenticated) {
                context.push('/story/create');
              } else {
                context.push('/login');
              }
            },
          ),
          Center(
            child: StoryEmptyState(
              onAddStory: () {
                if (isAuthenticated) {
                  context.push('/story/create');
                } else {
                  context.push('/login');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 48,
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
