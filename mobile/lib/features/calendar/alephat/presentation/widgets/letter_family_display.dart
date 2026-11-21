// lib/features/calendar/alephat/presentation/widgets/letter_family_display.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/core/utils/web_context_menu_manager.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_letter_model.dart';
import 'package:mobile/features/calendar/alephat/presentation/providers/alephat_providers.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/letter_action_helper.dart';
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
  void didUpdateWidget(covariant LetterFamilyDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.letter.id != widget.letter.id) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollDelta(double delta) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + delta)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToSelectedMember(int orderIndex) {
    if (!_scrollController.hasClients) return;
    final index = widget.letter.familyMembers
        .indexWhere((m) => m.orderIndex == orderIndex);
    if (index < 0) return;
    const itemWidth = 80.0;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final targetOffset =
        (index * itemWidth - (screenWidth / 2) + (itemWidth / 2))
            .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedOrder = ref.watch(selectedFamilyMemberOrderProvider);
    final tr = ref.watch(trProvider);
    final perms = ref.watch(adminPermissionsProvider);

    final isLargeScreen = MediaQuery.sizeOf(context).width >= 720;
    final members = widget.letter.familyMembers;

    ref.listen(selectedFamilyMemberOrderProvider, (prev, next) {
      if (next != null) {
        _scrollToSelectedMember(next);
      }
    });

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

        // Horizontally scrollable capsule row with mouse & touch drag and chevron navigation
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              if (isLargeScreen && members.length > 8)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, size: 22),
                    tooltip: tr('alephat.scroll_left',
                        {'fallback': 'ወደ ግራ ሸብልል'}),
                    onPressed: () => _scrollDelta(-240),
                  ),
                ),
              Expanded(
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
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: members.length > 8,
                      interactive: true,
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
                              child: MouseRegion(
                                onEnter: perms.canManageAlephat
                                    ? (_) => WebContextMenuManager
                                        .onMessagePointerEnter()
                                    : null,
                                onExit: perms.canManageAlephat
                                    ? (_) => WebContextMenuManager
                                        .onMessagePointerExit()
                                    : null,
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
                                  onLongPress: perms.canManageAlephat
                                      ? () => LetterActionHelper.showLetterContextMenu(
                                          context, ref, widget.letter,
                                          initialTab: 1)
                                      : null,
                                  onSecondaryTapDown: perms.canManageAlephat
                                      ? (_) => WebContextMenuManager
                                          .onSecondaryPointerDown()
                                      : null,
                                  onSecondaryTap: perms.canManageAlephat
                                      ? () => LetterActionHelper.showLetterContextMenu(
                                          context, ref, widget.letter,
                                          initialTab: 1)
                                      : null,
                                  child: Container(
                                    width: 72,
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
                                        horizontal: 2, vertical: 8),
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
                                            fontSize: 9.5,
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
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              if (isLargeScreen && members.length > 8)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, size: 22),
                    tooltip: tr('alephat.scroll_right',
                        {'fallback': 'ወደ ቀኝ ሸብልል'}),
                    onPressed: () => _scrollDelta(240),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
