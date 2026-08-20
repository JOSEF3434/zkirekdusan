// lib/features/stories/presentation/widgets/story_progress_bar.dart
import 'package:flutter/material.dart';

class StoryProgressBar extends StatelessWidget {
  final int totalStories;
  final int currentIndex;
  final double currentProgress; // 0.0 to 1.0

  const StoryProgressBar({
    super.key,
    required this.totalStories,
    required this.currentIndex,
    required this.currentProgress,
  });

  @override
  Widget build(BuildContext context) {
    if (totalStories <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: List.generate(totalStories, (index) {
          double fill = 0.0;
          if (index < currentIndex) {
            fill = 1.0;
          } else if (index == currentIndex) {
            fill = currentProgress.clamp(0.0, 1.0);
          } else {
            fill = 0.0;
          }

          return Expanded(
            child: Container(
              height: 2.5,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fill,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
