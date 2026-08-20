// lib/features/stories/presentation/widgets/story_item.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/stories/data/models/story_feed_group_model.dart';

class StoryItem extends StatelessWidget {
  final StoryFeedGroupModel group;
  final VoidCallback onTap;

  const StoryItem({super.key, required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnseen = group.hasUnseen;

    return Semantics(
      button: true,
      label:
          '${group.owner.effectiveName} story, ${hasUnseen ? "unseen" : "seen"}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 76,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar with ring
              Container(
                width: 68,
                height: 68,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasUnseen
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.tertiary.withValues(alpha: 0.9),
                            theme.colorScheme.primaryContainer,
                          ],
                        )
                      : null,
                  border: hasUnseen
                      ? null
                      : Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.6,
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
                    child:
                        group.owner.avatarUrl != null &&
                            group.owner.avatarUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: group.owner.avatarUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                            errorWidget: (context, url, error) =>
                                _buildInitials(theme),
                          )
                        : _buildInitials(theme),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Owner name
              Text(
                group.owner.effectiveName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: hasUnseen ? FontWeight.w600 : FontWeight.normal,
                  color: hasUnseen
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitials(ThemeData theme) {
    final initials = group.owner.effectiveName.isNotEmpty
        ? group.owner.effectiveName[0].toUpperCase()
        : '?';

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
