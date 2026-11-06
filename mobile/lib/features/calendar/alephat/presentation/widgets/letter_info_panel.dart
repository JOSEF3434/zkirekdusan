// lib/features/calendar/alephat/presentation/widgets/letter_info_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_letter_model.dart';
import 'package:mobile/features/calendar/alephat/presentation/providers/alephat_providers.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/alephat_media_popup.dart';

class LetterInfoPanel extends ConsumerWidget {
  final AlephatLetterModel letter;

  const LetterInfoPanel({
    super.key,
    required this.letter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedOrder = ref.watch(selectedFamilyMemberOrderProvider);
    final tr = ref.watch(trProvider);

    // If an individual family member is selected, look it up
    AlephatFamilyMemberModel? selectedMember;
    if (selectedOrder != null) {
      for (final m in letter.familyMembers) {
        if (m.orderIndex == selectedOrder) {
          selectedMember = m;
          break;
        }
      }
    }

    final isMemberSelected = selectedMember != null;
    final displayGlyph = isMemberSelected ? selectedMember.glyph : letter.letter;
    final displayOrderName = isMemberSelected
        ? (selectedMember.orderName ?? '${selectedMember.orderIndex}ኛ ድምጽ')
        : (letter.name ?? 'ግዕዝ');

    // Note selection: family member note if available, else letter general note
    final memberNote = selectedMember?.note;
    final generalNote = letter.defaultNote;
    final hasMemberNote = memberNote != null && memberNote.trim().isNotEmpty;
    final hasGeneralNote = generalNote != null && generalNote.trim().isNotEmpty;

    final String displayNote;
    if (isMemberSelected && hasMemberNote) {
      displayNote = memberNote;
    } else if (hasGeneralNote) {
      displayNote = generalNote;
    } else {
      displayNote = tr('alephat.no_note', {'fallback': 'ለዚህ ፊደል የተመዘገበ ማብራሪያ የለም።'});
    }

    final pronunciation = isMemberSelected
        ? (selectedMember.pronunciation ?? letter.pronunciationGuide)
        : letter.pronunciationGuide;

    final isLargeScreen = MediaQuery.sizeOf(context).width >= 720;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 0 : 16,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with Prominent Letter, Order name, and reset button if sub-member is selected
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$displayGlyph፡',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                    fontFamilyFallback: const [
                      'Noto Serif Ethiopic',
                      'Noto Sans Ethiopic',
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayOrderName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamilyFallback: const [
                          'Noto Serif Ethiopic',
                          'Noto Sans Ethiopic',
                        ],
                      ),
                    ),
                    if ((pronunciation != null && pronunciation.isNotEmpty) ||
                        letter.mediaUrls.isNotEmpty ||
                        (selectedMember?.mediaUrls.isNotEmpty ?? false))
                      Tooltip(
                        message: 'ድምጽ/ሚዲያ አጫውት (Play audio/media)',
                        child: InkWell(
                          key: const Key('alephat_speaker_button'),
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => AlephatMediaPopup.show(
                            context,
                            letter: letter,
                            selectedMember: selectedMember,
                            pronunciation: pronunciation,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.volume_up_outlined,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (pronunciation != null && pronunciation.isNotEmpty)
                                      ? pronunciation
                                      : 'ድምጽ አጫውት',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isMemberSelected)
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: Text(
                    tr('alephat.show_base', {'fallback': 'ጠቅላላ ማብራሪያ'}),
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () {
                    ref.read(selectedFamilyMemberOrderProvider.notifier).state = null;
                  },
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Explanatory note text in a scrollable/responsive area
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            child: SingleChildScrollView(
              child: SelectableText(
                displayNote,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  letterSpacing: 0.2,
                  fontFamilyFallback: const [
                    'Noto Serif Ethiopic',
                    'Noto Sans Ethiopic',
                  ],
                ),
              ),
            ),
          ),

          // Indicator distinguishing between general and member note
          if (isMemberSelected && hasMemberNote && hasGeneralNote)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '• የዚህ ድምጽ ብቻ ማብራሪያ',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontFamilyFallback: const [
                    'Noto Serif Ethiopic',
                    'Noto Sans Ethiopic',
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
