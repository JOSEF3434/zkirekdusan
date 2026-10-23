// lib/features/calendar/alephat/presentation/widgets/letter_selection_bar.dart
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/core/utils/web_context_menu_manager.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_letter_model.dart';
import 'package:mobile/features/calendar/alephat/presentation/providers/alephat_providers.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/letter_action_helper.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/manage_letter_dialog.dart';

/// Custom ScrollBehavior enabling mouse and trackpad dragging on Web & Desktop
class AlephatHorizontalScrollBehavior extends MaterialScrollBehavior {
  const AlephatHorizontalScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class LetterSelectionBar extends ConsumerStatefulWidget {
  final List<AlephatLetterModel> letters;

  const LetterSelectionBar({
    super.key,
    required this.letters,
  });

  @override
  ConsumerState<LetterSelectionBar> createState() => _LetterSelectionBarState();
}

class _LetterSelectionBarState extends ConsumerState<LetterSelectionBar> {
  late final ScrollController _scrollController;
  static const double _itemWidth = 72.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Auto-scroll to selected letter after the first layout frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedLetter(animate: false);
    });
  }

  @override
  void didUpdateWidget(covariant LetterSelectionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.letters != widget.letters) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedLetter(animate: true);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedLetter({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    final selectedId = ref.read(selectedBaseLetterIdProvider);
    if (selectedId == null) return;

    final index = widget.letters.indexWhere((l) => l.id == selectedId);
    if (index < 0) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset =
        (index * _itemWidth - (screenWidth / 2) + (_itemWidth / 2))
            .clamp(0.0, _scrollController.position.maxScrollExtent);

    if (animate) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedId = ref.watch(selectedBaseLetterIdProvider);
    final perms = ref.watch(adminPermissionsProvider);
    final tr = ref.watch(trProvider);

    // Listen for external selection changes to bring the active letter into view
    ref.listen(selectedBaseLetterIdProvider, (prev, next) {
      if (prev != next && next != null) {
        _scrollToSelectedLetter(animate: true);
      }
    });

    final totalCount = widget.letters.length + (perms.canManageAlephat ? 1 : 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktopOrWeb = kIsWeb || constraints.maxWidth > 700;

        return Row(
          children: [
            // Left scroll chevron button (Web / Desktop discoverability)
            if (isDesktopOrWeb)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: tr('alephat.scroll_left',
                      {'fallback': 'ወደ ግራ ሸብልል (Scroll Left)'}),
                  onPressed: () => _scrollDelta(-220),
                ),
              ),

            // Horizontal Scroll Area with custom pointer behavior and scrollbar
            Expanded(
              child: SizedBox(
                height: 84,
                child: ScrollConfiguration(
                  behavior: const AlephatHorizontalScrollBehavior(),
                  child: Listener(
                    // Translate vertical mouse wheel scrolling into horizontal scrolling on Web/Desktop
                    onPointerSignal: (pointerSignal) {
                      if (pointerSignal is PointerScrollEvent &&
                          _scrollController.hasClients) {
                        final delta = pointerSignal.scrollDelta.dy != 0
                            ? pointerSignal.scrollDelta.dy
                            : pointerSignal.scrollDelta.dx;
                        final newOffset = (_scrollController.offset + delta)
                            .clamp(0.0,
                                _scrollController.position.maxScrollExtent);
                        _scrollController.jumpTo(newOffset);
                      }
                    },
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: kIsWeb,
                      interactive: true,
                      child: ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        itemCount: totalCount,
                        itemBuilder: (context, index) {
                          if (index == widget.letters.length) {
                            // Admin "+" button
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 4, right: 12),
                                child: IconButton.filledTonal(
                                  icon: const Icon(Icons.add),
                                  tooltip: tr('alephat.add_letter',
                                      {'fallback': 'አዲስ ፊደል ጨምር'}),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) =>
                                          const ManageLetterDialog(),
                                    );
                                  },
                                ),
                              ),
                            );
                          }

                          final item = widget.letters[index];
                          final isSelected = item.id == selectedId;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: Material(
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.55),
                              elevation: isSelected ? 2 : 0,
                              borderRadius: BorderRadius.circular(12),
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
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    ref
                                        .read(selectedBaseLetterIdProvider.notifier)
                                        .state = item.id;
                                    ref
                                        .read(selectedFamilyMemberOrderProvider
                                            .notifier)
                                        .state = null;
                                  },
                                  onLongPress: perms.canManageAlephat
                                      ? () => LetterActionHelper
                                          .showLetterContextMenu(
                                              context, ref, item)
                                      : null,
                                  onSecondaryTapDown: perms.canManageAlephat
                                      ? (_) => WebContextMenuManager
                                          .onSecondaryPointerDown()
                                      : null,
                                  onSecondaryTap: perms.canManageAlephat
                                      ? () => LetterActionHelper
                                          .showLetterContextMenu(
                                              context, ref, item)
                                      : null,
                                  child: Container(
                                  constraints:
                                      const BoxConstraints(minWidth: 56),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outlineVariant
                                              .withValues(alpha: 0.2),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        item.letter,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme
                                                  .textTheme.bodyLarge?.color,
                                          fontFamilyFallback: const [
                                            'Noto Serif Ethiopic',
                                            'Noto Sans Ethiopic',
                                          ],
                                        ),
                                      ),
                                      if (item.name != null &&
                                          item.name!.isNotEmpty)
                                        Text(
                                          item.name!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            fontSize: 10,
                                            color: isSelected
                                                ? theme.colorScheme
                                                    .onPrimaryContainer
                                                : theme.textTheme.bodySmall
                                                    ?.color,
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
            ),

            // Right scroll chevron button (Web / Desktop discoverability)
            if (isDesktopOrWeb)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: tr('alephat.scroll_right',
                      {'fallback': 'ወደ ቀኝ ሸብልል (Scroll Right)'}),
                  onPressed: () => _scrollDelta(220),
                ),
              ),
          ],
        );
      },
    );
  }
}
