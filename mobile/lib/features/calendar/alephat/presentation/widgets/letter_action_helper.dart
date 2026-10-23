// lib/features/calendar/alephat/presentation/widgets/letter_action_helper.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/core/utils/web_context_menu_manager.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/calendar/alephat/data/alephat_repository.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_letter_model.dart';
import 'package:mobile/features/calendar/alephat/presentation/providers/alephat_providers.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/manage_letter_dialog.dart';

class LetterActionHelper {
  static void showLetterContextMenu(
    BuildContext context,
    WidgetRef ref,
    AlephatLetterModel letter, {
    int initialTab = 0,
  }) {
    final perms = ref.read(adminPermissionsProvider);
    final tr = ref.read(trProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLargeScreenOrWeb =
        kIsWeb || MediaQuery.sizeOf(context).width > 600;

    Widget buildMenuContent(BuildContext ctx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                letter.letter,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                  fontFamilyFallback: const [
                    'Noto Serif Ethiopic',
                    'Noto Sans Ethiopic',
                  ],
                ),
              ),
            ),
            title: Text(
              '${letter.letter} (${letter.name ?? ''})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamilyFallback: [
                  'Noto Serif Ethiopic',
                  'Noto Sans Ethiopic',
                ],
              ),
            ),
            subtitle: Text(
              'ተራ ቁጥር፡ ${letter.order} • ቤተሰብ፡ ${letter.familyMembers.length}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(tr('alephat.edit_letter', {'fallback': 'ፊደሉን አርትዕ'})),
            onTap: () {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                builder: (_) => ManageLetterDialog(letter: letter, initialTab: 0),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.family_restroom_outlined),
            title: Text(
              tr('alephat.manage_family', {'fallback': 'የፊደል ቤተሰብ አስተዳድር'}),
            ),
            onTap: () {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                builder: (_) =>
                    ManageLetterDialog(letter: letter, initialTab: 1),
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
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                tr('alephat.delete_letter', {'fallback': 'ፊደሉን ሰርዝ'}),
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                confirmDeleteLetter(context, ref, letter);
              },
            ),
          ],
        ],
      );
    }

    WebContextMenuManager.onCustomMenuOpened();

    if (isLargeScreenOrWeb) {
      showDialog(
        context: context,
        builder: (dialogCtx) => Dialog(
          backgroundColor: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          elevation: 20,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: buildMenuContent(dialogCtx),
                ),
              ),
            ),
          ),
        ),
      ).then((_) {
        WebContextMenuManager.onCustomMenuClosed();
      });
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetCtx) => SafeArea(
          child: buildMenuContent(sheetCtx),
        ),
      ).then((_) {
        WebContextMenuManager.onCustomMenuClosed();
      });
    }
  }

  static void confirmDeleteLetter(
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
