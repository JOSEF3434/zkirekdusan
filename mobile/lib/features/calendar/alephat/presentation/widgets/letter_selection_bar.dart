// lib/features/calendar/alephat/presentation/widgets/letter_selection_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_letter_model.dart';
import 'package:mobile/features/calendar/alephat/data/alephat_repository.dart';
import 'package:mobile/features/calendar/alephat/presentation/providers/alephat_providers.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/manage_letter_dialog.dart';

class LetterSelectionBar extends ConsumerWidget {
  final List<AlephatLetterModel> letters;

  const LetterSelectionBar({
    super.key,
    required this.letters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedId = ref.watch(selectedBaseLetterIdProvider);
    final perms = ref.watch(adminPermissionsProvider);
    final tr = ref.watch(trProvider);

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: letters.length + (perms.canManageAlephat ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == letters.length) {
            // Plus button for authorized creators
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 16),
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.add),
                  tooltip: tr('alephat.add_letter', {'fallback': 'አዲስ ፊደል ጨምር'}),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => const ManageLetterDialog(),
                    );
                  },
                ),
              ),
            );
          }

          final item = letters[index];
          final isSelected = item.id == selectedId;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Material(
              color: isSelected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              elevation: isSelected ? 2 : 0,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  ref.read(selectedBaseLetterIdProvider.notifier).state = item.id;
                  // Reset family member selection to default note when base letter changes
                  ref.read(selectedFamilyMemberOrderProvider.notifier).state = null;
                },
                onLongPress: perms.canManageAlephat
                    ? () => _showLetterContextMenu(context, ref, item)
                    : null,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 54),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.letter,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 24,
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
                      if (item.name != null && item.name!.isNotEmpty)
                        Text(
                          item.name!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
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
    );
  }

  void _showLetterContextMenu(
    BuildContext context,
    WidgetRef ref,
    AlephatLetterModel letter,
  ) {
    final perms = ref.read(adminPermissionsProvider);
    final tr = ref.read(trProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  child: Text(
                    letter.letter,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  '${letter.letter} (${letter.name ?? ''})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('ተራ ቁጥር፡ ${letter.order} • ቤተሰብ፡ ${letter.familyMembers.length}'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(tr('alephat.edit_letter', {'fallback': 'ፊደሉን አርትዕ'})),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => ManageLetterDialog(letter: letter),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.family_restroom_outlined),
                title: Text(tr('alephat.manage_family', {'fallback': 'የፊደል ቤተሰብ አስተዳድር'})),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => ManageLetterDialog(letter: letter, initialTab: 1),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: Text(tr('alephat.add_new', {'fallback': 'አዲስ ፊደል ጨምር'})),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => const ManageLetterDialog(),
                  );
                },
              ),
              if (perms.canDeleteAlephat) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    tr('alephat.delete_letter', {'fallback': 'ፊደሉን ሰርዝ'}),
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteLetter(context, ref, letter);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteLetter(
    BuildContext context,
    WidgetRef ref,
    AlephatLetterModel letter,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ፊደል "${letter.letter}" ይሰረዝ?'),
        content: Text(
          'ይህ እርምጃ ፊደሉንና ሁሉንም የተያያዙ ${letter.familyMembers.length} የፊደል ቤተሰቦች ያጠፋል። እርግጠኛ ነዎት?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ይቅር'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(alephatRepositoryProvider);
                await repo.deleteLetter(letter.id);
                ref.invalidate(alephatLettersProvider);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ፊደል "${letter.letter}" ተሰርዟል')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ስህተት፡ $e')),
                );
              }
            },
            child: const Text('ሰርዝ'),
          ),
        ],
      ),
    );
  }
}
