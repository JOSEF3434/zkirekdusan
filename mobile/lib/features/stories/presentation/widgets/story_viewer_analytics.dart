// lib/features/stories/presentation/widgets/story_viewer_analytics.dart
import 'package:flutter/material.dart';
import 'package:mobile/features/stories/data/models/story_model.dart';

class StoryViewerAnalytics extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onViewersTap;
  final VoidCallback onDeleteTap;

  const StoryViewerAnalytics({
    super.key,
    required this.story,
    required this.onViewersTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.85),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Views Counter
            InkWell(
              onTap: onViewersTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${story.viewsCount} ${story.viewsCount == 1 ? "view" : "views"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Reactions Counter
            if (story.reactionsCount > 0) ...[
              InkWell(
                onTap: onViewersTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${story.reactionsCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const Spacer(),

            // Delete Action
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
                size: 22,
              ),
              tooltip: 'Delete story',
              onPressed: onDeleteTap,
            ),
          ],
        ),
      ),
    );
  }
}
