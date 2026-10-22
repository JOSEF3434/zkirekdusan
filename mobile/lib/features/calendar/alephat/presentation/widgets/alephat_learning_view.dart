// lib/features/calendar/alephat/presentation/widgets/alephat_learning_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_letter_model.dart';
import 'package:mobile/features/calendar/alephat/presentation/providers/alephat_providers.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/letter_selection_bar.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/letter_keyboard_grid.dart';
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
        // 2. Nested Two Tabs selector (Letter Families vs 22 Alephats)
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Container(
              margin: const EdgeInsets.only(
                top: 8,
                bottom: 8,
                left: 20,
                right: 20,
              ),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildNestedTabButton(
                      context: context,
                      title: tr('alephat.tab_letters', {'fallback': 'ፊደላት'}),
                      subtitle: tr('alephat.tab_letters_sub',
                          {'fallback': 'የፊደል ቤተሰቦች'}),
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
                      subtitle:
                          tr('alephat.tab_22_sub', {'fallback': 'ምስጢረ አሌፋት'}),
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
    final layoutMode = ref.watch(alephatLayoutModeProvider);
    final isOffline = ref.watch(connectivityProvider).isOffline;
    final tr = ref.watch(trProvider);

    return lettersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) {
        // First-launch offline fallback message explaining connection requirement
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 64,
                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 16),
                Text(
                  tr('alephat.initial_sync_title',
                      {'fallback': 'የመጀመሪያ ማመሳሰል ያስፈልጋል'}),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamilyFallback: const [
                      'Noto Serif Ethiopic',
                      'Noto Sans Ethiopic',
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tr('alephat.initial_sync_desc', {
                    'fallback':
                        'የትምህርተ አሌፋት ይዘቶችን ለመጀመሪያ ጊዜ ለማውረድ የበይነመረብ ግንኙነት ያስፈልጋል። አንዴ ከወረደ በኋላ ያለ ምንም ኢንተርኔት ከመስመር ውጭ መጠቀም ይችላሉ።',
                  }),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                    fontFamilyFallback: const [
                      'Noto Serif Ethiopic',
                      'Noto Sans Ethiopic',
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(alephatLettersProvider),
                  icon: const Icon(Icons.refresh),
                  label: Text(tr('common.retry', {'fallback': 'እንደገና ሞክር'})),
                ),
              ],
            ),
          ),
        );
      },
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

        final isLargeScreen = MediaQuery.sizeOf(context).width >= 720;

        return Column(
          children: [
            // Subtle offline sync indicator banner
            if (isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.offline_bolt_outlined,
                        size: 14, color: theme.colorScheme.onSecondaryContainer),
                    const SizedBox(width: 6),
                    Text(
                      tr('alephat.offline_cached_banner',
                          {'fallback': 'ከመስመር ውጭ — የተቀመጡ የፊደላት መረጃዎች እየታዩ ነው'}),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                        fontFamilyFallback: const [
                          'Noto Serif Ethiopic',
                          'Noto Sans Ethiopic',
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // 3 & 4. Learning content (Information Card + Family Display)
            // Stays comfortably scrollable so long notes or family lists never block learning
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(alephatLettersProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Container(
                        margin: isLargeScreen
                            ? const EdgeInsets.only(
                                left: 24,
                                right: 24,
                                top: 6,
                              )
                            : EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 3. Information Card (Amharic character, transliteration, meaning/note)
                            LetterInfoPanel(letter: selectedLetter),

                            // 4. Configured Letter Family Display
                            LetterFamilyDisplay(letter: selectedLetter),

                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 5. Letter selector dock at the bottom of the learning content
            SafeArea(
              top: false,
              bottom: !isLargeScreen,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Container(
                    margin: isLargeScreen
                        ? const EdgeInsets.only(
                            left: 24,
                            right: 24,
                            bottom: 20,
                            top: 6,
                          )
                        : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius:
                          isLargeScreen ? BorderRadius.circular(16) : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                              alpha: isLargeScreen ? 0.2 : 0.12),
                          offset: const Offset(0, -2),
                          blurRadius: isLargeScreen ? 10 : 6,
                        ),
                      ],
                      border: isLargeScreen
                          ? Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.35),
                            )
                          : Border(
                              top: BorderSide(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                    ),
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dock Header: Title & Layout Toggle Controls
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                tr('alephat.select_letter',
                                    {'fallback': 'ፊደል ይምረጡ'}),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyMedium?.color,
                                  fontFamilyFallback: const [
                                    'Noto Serif Ethiopic',
                                    'Noto Sans Ethiopic',
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${letters.length}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Layout Mode Selector (Horizontal Scroll vs Keyboard Grid)
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildLayoutModeButton(
                                  context: context,
                                  icon: Icons.view_carousel_outlined,
                                  tooltip: tr('alephat.mode_horizontal', {
                                    'fallback': 'አግድም ዝርዝር (Horizontal Scroll)'
                                  }),
                                  semanticLabel:
                                      'Horizontal scrolling alphabet selector',
                                  isSelected: layoutMode ==
                                      AlephatLayoutMode.horizontal,
                                  onTap: () {
                                    ref
                                        .read(
                                            alephatLayoutModeProvider.notifier)
                                        .setLayoutMode(
                                            AlephatLayoutMode.horizontal);
                                  },
                                ),
                                const SizedBox(width: 2),
                                _buildLayoutModeButton(
                                  context: context,
                                  icon: Icons.keyboard_outlined,
                                  tooltip: tr('alephat.mode_grid', {
                                    'fallback':
                                        'የሰንጠረዥ (ኪቦርድ) ዕይታ (Keyboard Grid)'
                                  }),
                                  semanticLabel:
                                      'Keyboard grid alphabet selector',
                                  isSelected:
                                      layoutMode == AlephatLayoutMode.grid,
                                  onTap: () {
                                    ref
                                        .read(
                                            alephatLayoutModeProvider.notifier)
                                        .setLayoutMode(AlephatLayoutMode.grid);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active Letter Selector Mode (Bottom placement)
                    layoutMode == AlephatLayoutMode.horizontal
                        ? LetterSelectionBar(letters: letters)
                        : LetterKeyboardGrid(letters: letters),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
      },
    );
  }

  Widget _buildLayoutModeButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required String semanticLabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: semanticLabel,
      selected: isSelected,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          elevation: isSelected ? 1 : 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Icon(
                icon,
                size: 18,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
