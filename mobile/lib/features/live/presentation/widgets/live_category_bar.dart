// lib/features/live/presentation/widgets/live_category_bar.dart
// Modern horizontal category bar with dynamic addition of new categories.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/live/presentation/providers/live_discovery_provider.dart';

class LiveCategoryBar extends ConsumerWidget {
  const LiveCategoryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(liveCategoriesProvider);
    final selectedCategory = ref.watch(selectedLiveCategoryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1, // +1 for "+ Add Category" button
        separatorBuilder: (ctx, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == categories.length) {
            return _buildAddCategoryButton(context, ref, theme, isDark);
          }

          final category = categories[index];
          final isSelected = selectedCategory == category;

          return _buildCategoryChip(
            category: category,
            isSelected: isSelected,
            theme: theme,
            isDark: isDark,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(selectedLiveCategoryProvider.notifier).state = category;
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip({
    required String category,
    required bool isSelected,
    required ThemeData theme,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: isSelected
              ? LinearGradient(
                  colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (isDark
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
                  : theme.colorScheme.surfaceContainerHighest),
          border: Border.all(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.4)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category == 'All') ...[
              Icon(
                Icons.grid_view_rounded,
                size: 14,
                color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ] else ...[
              _getCategoryIcon(category, isSelected, theme),
              const SizedBox(width: 6),
            ],
            Text(
              category,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCategoryButton(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => showAddCategoryDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
            style: BorderStyle.solid,
            width: 1.2,
          ),
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Add Category',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String category, bool isSelected, ThemeData theme) {
    final color = isSelected ? Colors.white : theme.colorScheme.primary;
    final lower = category.toLowerCase();

    IconData iconData = Icons.label_outline;
    if (lower.contains('church') || lower.contains('spirit') || lower.contains('gospel')) {
      iconData = Icons.church_outlined;
    } else if (lower.contains('teach') || lower.contains('educat')) {
      iconData = Icons.school_outlined;
    } else if (lower.contains('music') || lower.contains('chant')) {
      iconData = Icons.music_note_outlined;
    } else if (lower.contains('tech')) {
      iconData = Icons.laptop_chromebook;
    } else if (lower.contains('youth')) {
      iconData = Icons.groups_outlined;
    } else if (lower.contains('discuss') || lower.contains('q&a')) {
      iconData = Icons.forum_outlined;
    } else if (lower.contains('news')) {
      iconData = Icons.newspaper_outlined;
    }

    return Icon(iconData, size: 14, color: color);
  }

  static Future<void> showAddCategoryDialog(BuildContext context, WidgetRef ref) async {
    final tr = ref.read(trProvider);
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4)),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.category_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Category',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Create a custom category for live streams',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: ctrl,
                    autofocus: true,
                    maxLength: 40,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'e.g. Biblical Studies, Youth Fellowship',
                      prefixIcon: const Icon(Icons.tag),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a category name';
                      }
                      if (val.trim().length < 2) {
                        return 'Category name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(tr('common.cancel')),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Add & Select'),
                        onPressed: () {
                          if (formKey.currentState?.validate() ?? false) {
                            final newCategory = ctrl.text.trim();
                            ref.read(liveCategoriesProvider.notifier).addCategory(newCategory);
                            ref.read(selectedLiveCategoryProvider.notifier).state = newCategory;
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Category "$newCategory" added!'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
