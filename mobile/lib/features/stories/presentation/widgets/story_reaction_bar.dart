// lib/features/stories/presentation/widgets/story_reaction_bar.dart
import 'package:flutter/material.dart';

class StoryReactionBar extends StatelessWidget {
  final String? myReaction;
  final void Function(String reaction) onReactionSelected;

  const StoryReactionBar({
    super.key,
    this.myReaction,
    required this.onReactionSelected,
  });

  static const List<Map<String, String>> _reactions = [
    {'type': 'LIKE', 'emoji': '❤️'},
    {'type': 'LOVE', 'emoji': '😍'},
    {'type': 'HAHA', 'emoji': '😂'},
    {'type': 'WOW', 'emoji': '😮'},
    {'type': 'SAD', 'emoji': '😢'},
    {'type': 'ANGRY', 'emoji': '🔥'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _reactions.map((r) {
          final isSelected = myReaction == r['type'];
          return GestureDetector(
            onTap: () => onReactionSelected(r['type']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                r['emoji']!,
                style: TextStyle(fontSize: isSelected ? 24 : 20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
