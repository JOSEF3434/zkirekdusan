// lib/features/home/presentation/widgets/category_tab_bar.dart
import 'package:flutter/material.dart';
import 'package:mobile/features/home/domain/video_model.dart';

class CategoryTabBar extends StatelessWidget {
  final VideoFeedCategory selectedCategory;
  final ValueChanged<VideoFeedCategory> onCategorySelected;

  const CategoryTabBar({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: VideoFeedCategory.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = VideoFeedCategory.values[index];
          final isSelected = category == selectedCategory;
          
          return ChoiceChip(
            label: Text(category.label),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                onCategorySelected(category);
              }
            },
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
