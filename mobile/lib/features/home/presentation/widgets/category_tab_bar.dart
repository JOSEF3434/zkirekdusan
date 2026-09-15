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

          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final textColor = isSelected
              ? (isDark ? Colors.black87 : Colors.white)
              : (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87);

          return ChoiceChip(
            label: Text(
              category.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: textColor,
              ),
            ),
            selected: isSelected,
            showCheckmark: false,
            backgroundColor: isDark ? const Color(0xFF242424) : Colors.grey.shade200,
            selectedColor: theme.colorScheme.primary,
            side: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.1)),
            ),
            onSelected: (selected) {
              if (selected) {
                onCategorySelected(category);
              }
            },
          );
        },
      ),
    );
  }
}
