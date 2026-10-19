// lib/features/calendar/alephat/presentation/widgets/alephat_22_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/calendar/alephat/data/alephat_repository.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_22_model.dart';
import 'package:mobile/features/calendar/alephat/presentation/providers/alephat_providers.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/alephat_22_detail_sheet.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/manage_22_dialog.dart';

class Alephat22View extends ConsumerWidget {
  const Alephat22View({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final perms = ref.watch(adminPermissionsProvider);
    final tr = ref.watch(trProvider);
    final listAsync = ref.watch(alephat22ListProvider);

    return Column(
      children: [
        // Search & Filter header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SearchBar(
                  hintText: 'በፊደል፣ በርዕስ ወይም በማብራሪያ ፈልግ...',
                  leading: const Icon(Icons.search, size: 20),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 14),
                  ),
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  onChanged: (val) {
                    ref.read(alephat22SearchProvider.notifier).state = val;
                  },
                ),
              ),
              if (perms.canManageAlephat) ...[
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  tooltip: tr('alephat.add_22', {'fallback': 'አዲስ መዝግብ'}),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const Manage22Dialog(),
                    );
                  },
                ),
              ],
            ],
          ),
        ),

        // List / Grid
        Expanded(
          child: listAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('መረጃውን መጫን አልተቻለም፡ $err'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.invalidate(alephat22ListProvider),
                    child: const Text('እንደገና ሞክር'),
                  ),
                ],
              ),
            ),
            data: (entries) {
              if (entries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 56,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ምንም የ22 አሌፋት መረጃ አልተገኘም',
                        style: theme.textTheme.titleMedium,
                      ),
                      if (perms.canManageAlephat) ...[
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const Manage22Dialog(),
                            );
                          },
                          child: const Text('የመጀመሪያውን መዝግብ'),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 650;
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 2 : 1,
                      mainAxisExtent: 130,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final item = entries[index];
                      return _buildEntryCard(context, ref, theme, item, perms);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEntryCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Alephat22Model item,
    AdminPermissions perms,
  ) {
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => Alephat22DetailSheet(entry: item),
          );
        },
        onLongPress: perms.canManageAlephat
            ? () => _showContextMenu(context, ref, item, perms)
            : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Letter Badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    item.letter,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      fontFamilyFallback: const [
                        'Noto Serif Ethiopic',
                        'Noto Sans Ethiopic',
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Title, Meaning, Note
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamilyFallback: const [
                                'Noto Serif Ethiopic',
                                'Noto Sans Ethiopic',
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${item.order}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.meaning != null && item.meaning!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'ትርጓሜ፡ ${item.meaning}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontFamilyFallback: const [
                              'Noto Serif Ethiopic',
                              'Noto Sans Ethiopic',
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        item.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                          fontFamilyFallback: const [
                            'Noto Serif Ethiopic',
                            'Noto Sans Ethiopic',
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (perms.canManageAlephat)
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () => _showContextMenu(context, ref, item, perms),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(
    BuildContext context,
    WidgetRef ref,
    Alephat22Model item,
    AdminPermissions perms,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(child: Text(item.letter)),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('ተራ ቁጥር፡ #${item.order}'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('ሙሉ መረጃ ተመልከት'),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => Alephat22DetailSheet(entry: item),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('አርትዕ'),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder: (_) => Manage22Dialog(entry: item),
                  );
                },
              ),
              if (perms.canDeleteAlephat) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('ሰርዝ', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete(context, ref, item);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Alephat22Model item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('"${item.title}" ይሰረዝ?'),
        content: const Text('ይህ እርምጃ መረጃውን በቋሚነት ያጠፋል። እርግጠኛ ነዎት?'),
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
                await repo.delete22(item.id);
                ref.invalidate(alephat22ListProvider);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"${item.title}" ተሰርዟል')),
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
