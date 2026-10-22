// lib/features/calendar/alephat/presentation/widgets/letter_keyboard_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_letter_model.dart';
import 'package:mobile/features/calendar/alephat/presentation/providers/alephat_providers.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/letter_action_helper.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/manage_letter_dialog.dart';

class LetterKeyboardGrid extends ConsumerWidget {
  final List<AlephatLetterModel> letters;

  const LetterKeyboardGrid({
    super.key,
    required this.letters,
  });

  int _calculateColumnCount(double width) {
    if (width < 360) return 6;
    if (width < 540) return 7;
    if (width < 720) return 9;
    return 11; // 11 columns on large screens/web displays 33 letters in exactly 3 rows (11 x 3 = 33)
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedId = ref.watch(selectedBaseLetterIdProvider);
    final perms = ref.watch(adminPermissionsProvider);
    final tr = ref.watch(trProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = _calculateColumnCount(width);
        final isMobileWidth = width < 720;
        final totalItemCount = letters.length + (perms.canManageAlephat ? 1 : 0);
        final rowCount = (totalItemCount / crossAxisCount).ceil();
        final double itemHeight = isMobileWidth ? 46.0 : 48.0;
        final double spacing = 5.0;
        final double totalGridHeight =
            (rowCount * itemHeight) + ((rowCount - 1) * spacing) + 12.0;

        Widget gridContent = GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: itemHeight,
          ),
          itemCount: totalItemCount,
          itemBuilder: (context, index) {
            if (index == letters.length) {
              // Admin "+" key
              return Tooltip(
                message: tr('alephat.add_letter', {'fallback': 'አዲስ ፊደል ጨምር'}),
                child: Material(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const ManageLetterDialog(),
                      );
                    },
                    child: Center(
                      child: Icon(
                        Icons.add,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              );
            }

            final item = letters[index];
            final isSelected = item.id == selectedId;

            return Semantics(
              button: true,
              selected: isSelected,
              label: '${item.letter}, ${item.name ?? ''}',
              child: Tooltip(
                message: '${item.letter} — ${item.name ?? ''}',
                child: Material(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.55),
                  elevation: isSelected ? 2 : 0,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      ref.read(selectedBaseLetterIdProvider.notifier).state =
                          item.id;
                      ref
                          .read(selectedFamilyMemberOrderProvider.notifier)
                          .state = null;
                    },
                    onLongPress: perms.canManageAlephat
                        ? () => LetterActionHelper.showLetterContextMenu(
                            context, ref, item)
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.25),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 2),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.letter,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: isMobileWidth ? 18 : 20,
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
                              if (item.name != null &&
                                  item.name!.isNotEmpty &&
                                  !isMobileWidth)
                                Text(
                                  item.name!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 9,
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
                ),
              ),
            );
          },
        );

        return SizedBox(
          height: totalGridHeight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: gridContent,
          ),
        );
      },
    );
  }
}
