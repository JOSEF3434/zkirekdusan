// lib/features/calendar/alephat/presentation/widgets/alephat_22_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/connectivity_service.dart';
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
    final isOffline = ref.watch(connectivityProvider).isOffline;

    return Column(
      children: [
        // Offline status banner if device is offline
        if (isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            color:
                theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.offline_bolt_outlined,
                    size: 14, color: theme.colorScheme.onSecondaryContainer),
                const SizedBox(width: 6),
                Text(
                  tr('alephat.22_offline_cached_banner',
                      {'fallback': 'ከመስመር ውጭ — የተቀመጡ የ22 አሌፋት መረጃዎች እየታዩ ነው'}),
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

        // Search & Filter header
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
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
                        theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
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
          ),
        ),

        // List / Grid
        Expanded(
          child: listAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 64,
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('alephat.initial_sync_22_title',
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
                      tr('alephat.initial_sync_22_desc', {
                        'fallback':
                            'የ22 አሌፋት ምስጢራትን ለመጀመሪያ ጊዜ ለማውረድ የበይነመረብ ግንኙነት ያስፈልጋል። አንዴ ከወረደ በኋላ ያለ ምንም ኢንተርኔት ከመስመር ውጭ መጠቀም ይችላሉ።',
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
                      onPressed: () => ref.invalidate(alephat22ListProvider),
                      icon: const Icon(Icons.refresh),
                      label: Text(
                          tr('common.retry', {'fallback': 'እንደገና ሞክር'})),
                    ),
                  ],
                ),
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

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(alephat22ListProvider);
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 650;
                    return GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 2 : 1,
                        mainAxisExtent: 130,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final item = entries[index];
                        return _buildEntryCard(
                            context, ref, theme, item, perms);
                      },
                    );
                  },
                ),
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
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.8),
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
                title: Text(item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  title:
                      const Text('ሰርዝ', style: TextStyle(color: Colors.red)),
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
