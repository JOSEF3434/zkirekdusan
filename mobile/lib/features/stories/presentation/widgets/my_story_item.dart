// lib/features/stories/presentation/widgets/my_story_item.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/stories/data/models/story_feed_group_model.dart';

class MyStoryItem extends StatelessWidget {
  final StoryFeedGroupModel? myGroup;
  final VoidCallback onViewStory;
  final VoidCallback onCreateStory;

  const MyStoryItem({
    super.key,
    required this.myGroup,
    required this.onViewStory,
    required this.onCreateStory,
  });

  bool get hasActiveStories => myGroup != null && myGroup!.stories.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = myGroup?.owner.avatarUrl;
    final displayName = myGroup?.owner.displayName ?? 'You';

    return Container(
      width: 76,
      margin: const EdgeInsets.only(left: 12, right: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Avatar with active story ring or subtle border
              GestureDetector(
                onTap: hasActiveStories ? onViewStory : onCreateStory,
                child: Container(
                  width: 68,
                  height: 68,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasActiveStories
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.tertiary,
                            ],
                          )
                        : null,
                    border: hasActiveStories
                        ? null
                        : Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                            width: 1.5,
                          ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: avatarUrl != null && avatarUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: avatarUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                              errorWidget: (context, url, error) =>
                                  _buildInitials(displayName, theme),
                            )
                          : _buildInitials(displayName, theme),
                    ),
                  ),
                ),
              ),

              // Plus button badge
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onCreateStory,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Label
          Text(
            'Your Story',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitials(String name, ThemeData theme) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'Y';
    return Container(
      color: theme.colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
