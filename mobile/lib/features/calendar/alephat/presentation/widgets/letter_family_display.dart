// lib/features/calendar/alephat/presentation/widgets/letter_family_display.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_letter_model.dart';
import 'package:mobile/features/calendar/alephat/presentation/providers/alephat_providers.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/letter_selection_bar.dart';

class LetterFamilyDisplay extends ConsumerStatefulWidget {
  final AlephatLetterModel letter;

  const LetterFamilyDisplay({
    super.key,
    required this.letter,
  });

  @override
  ConsumerState<LetterFamilyDisplay> createState() =>
      _LetterFamilyDisplayState();
}

class _LetterFamilyDisplayState extends ConsumerState<LetterFamilyDisplay> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedOrder = ref.watch(selectedFamilyMemberOrderProvider);
    final tr = ref.watch(trProvider);

    final isLargeScreen = MediaQuery.sizeOf(context).width >= 720;
    final members = widget.letter.familyMembers;

    if (members.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? 0 : 16,
          vertical: 12,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            tr('alephat.no_family_members', {
              'fallback': 'ለዚህ ፊደል የተመዘገቡ የቤተሰብ አባላት የሉም።',
            }),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 4 : 20,
            vertical: 6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'የ"${widget.letter.letter}" ቤተሰብ (${members.length} ድምጾች)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodySmall?.color,
                  fontFamilyFallback: const [
                    'Noto Serif Ethiopic',
                    'Noto Sans Ethiopic',
                  ],
                ),
              ),
              Text(
                'ድምጹን ለመምረጥ ይንኩ',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontFamilyFallback: const [
                    'Noto Serif Ethiopic',
                    'Noto Sans Ethiopic',
                  ],
                ),
              ),
            ],
          ),
        ),

        // Horizontally scrollable capsule row with mouse & touch drag support
        Container(
          height: 96,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ScrollConfiguration(
            behavior: const AlephatHorizontalScrollBehavior(),
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent &&
                    _scrollController.hasClients) {
                  final delta = pointerSignal.scrollDelta.dy != 0
                      ? pointerSignal.scrollDelta.dy
                      : pointerSignal.scrollDelta.dx;
                  final newOffset = (_scrollController.offset + delta).clamp(
                      0.0, _scrollController.position.maxScrollExtent);
                  _scrollController.jumpTo(newOffset);
                }
              },
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 0 : 14,
                ),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isSelected = selectedOrder == member.orderIndex;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                      elevation: isSelected ? 3 : 0,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          if (selectedOrder == member.orderIndex) {
                            // Toggle off to show base letter default note
                            ref
                                .read(
                                    selectedFamilyMemberOrderProvider.notifier)
                                .state = null;
                          } else {
                            ref
                                .read(
                                    selectedFamilyMemberOrderProvider.notifier)
                                .state = member.orderIndex;
                          }
                        },
                        child: Container(
                          width: 68,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                member.glyph,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.textTheme.bodyLarge?.color,
                                  fontFamilyFallback: const [
                                    'Noto Serif Ethiopic',
                                    'Noto Sans Ethiopic',
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                member.orderName ?? '${member.orderIndex}ኛ',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
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
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
