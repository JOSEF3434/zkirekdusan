// lib/features/chats/presentation/widgets/compact_story_cluster.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/stories/data/models/story_feed_group_model.dart';

/// Compact overlapping story avatar cluster displayed on the right edge of the search bar,
/// matching Telegram Desktop (Screenshot 1).
class CompactStoryCluster extends StatelessWidget {
  final List<StoryFeedGroupModel> groups;
  final bool isExpanded;
  final VoidCallback onToggle;

  const CompactStoryCluster({
    super.key,
    required this.groups,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Only groups with active stories (or up to 3 total active contacts)
    final activeGroups = groups.where((g) => g.stories.isNotEmpty).toList();

    if (activeGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayCount = activeGroups.length.clamp(1, 3);
    final ringColors = [
      const Color(0xFF00C6FF),
      const Color(0xFF10B981),
      const Color(0xFFFFB300),
    ];

    // Total width for overlapping circles: first is 26px, each next adds 14px
    final totalWidth = 26.0 + (displayCount - 1) * 14.0;

    return Tooltip(
      message: isExpanded ? 'Hide stories' : 'View stories',
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: totalWidth,
                height: 26,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (int i = 0; i < displayCount; i++)
                      Positioned(
                        left: i * 14.0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ringColors[i % ringColors.length],
                              width: 1.8,
                            ),
                            color: Colors.black,
                          ),
                          padding: const EdgeInsets.all(1.5),
                          child: ClipOval(child: _buildAvatar(activeGroups[i])),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: isExpanded ? const Color(0xFF00C6FF) : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(StoryFeedGroupModel group) {
    final avatarUrl = group.owner.avatarUrl;
    final resolved = MediaUrlResolver.resolve(avatarUrl);
    final name = group.owner.displayName ?? group.owner.username ?? 'U';

    if (resolved != null && resolved.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: resolved,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => _buildFallbackText(name),
        placeholder: (_, _) => Container(color: Colors.grey[800]),
      );
    }
    return _buildFallbackText(name);
  }

  Widget _buildFallbackText(String name) {
    return Container(
      color: const Color(0xFF1E2638),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Color(0xFF00C6FF),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
