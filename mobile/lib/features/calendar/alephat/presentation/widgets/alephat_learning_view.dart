// lib/features/calendar/alephat/presentation/widgets/alephat_learning_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_letter_model.dart';
import 'package:mobile/features/calendar/alephat/presentation/providers/alephat_providers.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/letter_selection_bar.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/letter_info_panel.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/letter_family_display.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/alephat_22_view.dart';

class AlephatLearningView extends ConsumerWidget {
  const AlephatLearningView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeTab = ref.watch(alephatNestedTabProvider);
    final tr = ref.watch(trProvider);

    return Column(
      children: [
        // Nested Two Tabs selector
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildNestedTabButton(
                  context: context,
                  title: tr('alephat.tab_letters', {'fallback': 'ፊደላት'}),
                  subtitle: tr('alephat.tab_letters_sub', {'fallback': 'የፊደል ቤተሰቦች'}),
                  icon: Icons.font_download_outlined,
                  isActive: activeTab == 0,
                  onTap: () {
                    ref.read(alephatNestedTabProvider.notifier).state = 0;
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildNestedTabButton(
                  context: context,
                  title: tr('alephat.tab_22', {'fallback': '22 አሌፋት'}),
                  subtitle: tr('alephat.tab_22_sub', {'fallback': 'ምስጢረ አሌፋት'}),
                  icon: Icons.menu_book_outlined,
                  isActive: activeTab == 1,
                  onTap: () {
                    ref.read(alephatNestedTabProvider.notifier).state = 1;
                  },
                ),
              ),
            ],
          ),
        ),

        // Nested Tab Content
        Expanded(
          child: activeTab == 0
              ? const _LetterFamiliesContent()
              : const Alephat22View(),
        ),
      ],
    );
  }

  Widget _buildNestedTabButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: isActive ? theme.colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      elevation: isActive ? 1 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyLarge?.color,
                      fontFamilyFallback: const [
                        'Noto Serif Ethiopic',
                        'Noto Sans Ethiopic',
                      ],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: isActive
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.textTheme.bodySmall?.color,
                      fontFamilyFallback: const [
                        'Noto Serif Ethiopic',
                        'Noto Sans Ethiopic',
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LetterFamiliesContent extends ConsumerWidget {
  const _LetterFamiliesContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lettersAsync = ref.watch(alephatLettersProvider);
    final selectedId = ref.watch(selectedBaseLetterIdProvider);

    return lettersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('ፊደላትን መጫን አልተቻለም፡ $err'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.invalidate(alephatLettersProvider),
              child: const Text('እንደገና ሞክር'),
            ),
          ],
        ),
      ),
      data: (letters) {
        if (letters.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.text_fields_outlined,
                  size: 56,
                  color: theme.textTheme.bodySmall?.color,
                ),
                const SizedBox(height: 12),
                Text(
                  'ምንም ፊደል አልተገኘም',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        // Determine currently selected base letter (default to first letter if none selected)
        AlephatLetterModel selectedLetter = letters.first;
        if (selectedId != null) {
          final found = letters.where((l) => l.id == selectedId);
          if (found.isNotEmpty) {
            selectedLetter = found.first;
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(alephatLettersProvider);
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // 1. Horizontal Letter Selection Bar
              LetterSelectionBar(letters: letters),

              // 2. Explanatory Note Panel (Above the family display)
              LetterInfoPanel(letter: selectedLetter),

              // 3. Complete Configured Letter Family Display
              LetterFamilyDisplay(letter: selectedLetter),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
