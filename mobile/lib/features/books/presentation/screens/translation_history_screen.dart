// lib/features/books/presentation/screens/translation_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/utils/localization_service.dart';
import '../../data/models/dictionary_model.dart';
import '../providers/dictionary_providers.dart';

class TranslationHistoryScreen extends ConsumerStatefulWidget {
  const TranslationHistoryScreen({super.key});

  @override
  ConsumerState<TranslationHistoryScreen> createState() =>
      _TranslationHistoryScreenState();
}

class _TranslationHistoryScreenState
    extends ConsumerState<TranslationHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _copy(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmClearAll() async {
    final tr = ref.read(trProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('books.clear_history')),
        content: Text(tr('books.clear_history_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(tr('common.remove')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(translationHistoryProvider.notifier).clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Translation history cleared'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showItemDetails(TranslationHistoryItemModel item) {
    final theme = Theme.of(context);
    final tr = ref.read(trProvider);
    final dateStr = DateFormat.yMMMMd().add_jm().format(item.createdAt);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.word,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.sourceLanguage.toUpperCase()} → ${item.targetLanguage.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.menu_book_rounded,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        item.dictionaryNameSnapshot,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Meaning / ፍቺ:',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              item.definition,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (item.surroundingSentence != null &&
                item.surroundingSentence!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original Context / ዐውድ:',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.surroundingSentence!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Saved: $dateStr',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _copy(item.word, tr('books.word_copied')),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(tr('books.copy_word')),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () =>
                      _copy(item.definition, tr('books.meaning_copied')),
                  icon: const Icon(Icons.text_snippet_outlined, size: 16),
                  label: Text(tr('books.copy_meaning')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);
    final filter = ref.watch(translationHistoryFilterProvider);
    final historyAsync = ref.watch(translationHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('books.translation_history')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: tr('books.clear_history'),
            onPressed: () => _confirmClearAll(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(translationHistoryProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: tr('books.search_history'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: filter.search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                ref
                                    .read(translationHistoryFilterProvider.notifier)
                                    .state = filter.copyWith(search: '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (v) {
                      ref
                          .read(translationHistoryFilterProvider.notifier)
                          .state = filter.copyWith(search: v.trim(), page: 1);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort_rounded),
                  tooltip: 'Sort Order',
                  onSelected: (val) {
                    ref
                        .read(translationHistoryFilterProvider.notifier)
                        .state = filter.copyWith(sort: val, page: 1);
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'newest',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward,
                              size: 18,
                              color: filter.sort == 'newest'
                                  ? theme.colorScheme.primary
                                  : null),
                          const SizedBox(width: 8),
                          const Text('Newest First'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'oldest',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward,
                              size: 18,
                              color: filter.sort == 'oldest'
                                  ? theme.colorScheme.primary
                                  : null),
                          const SizedBox(width: 8),
                          const Text('Oldest First'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: historyAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(err.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref
                          .read(translationHistoryProvider.notifier)
                          .refresh(),
                      child: Text(tr('common.retry')),
                    ),
                  ],
                ),
              ),
              data: (data) {
                if (data.items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 64,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            filter.search.isNotEmpty
                                ? 'No matching saved words found.'
                                : 'No translations saved yet.\nSelect words while reading to translate and save them.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: data.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final item = data.items[idx];
                    final dateStr =
                        DateFormat.yMMMd().format(item.createdAt);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showItemDetails(item),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.word,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.definition,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    onSelected: (val) {
                                      if (val == 'copy_word') {
                                        _copy(item.word,
                                            tr('books.word_copied'));
                                      } else if (val == 'copy_def') {
                                        _copy(item.definition,
                                            tr('books.meaning_copied'));
                                      } else if (val == 'delete') {
                                        ref
                                            .read(translationHistoryProvider
                                                .notifier)
                                            .deleteItem(item.id);
                                      }
                                    },
                                    itemBuilder: (c) => [
                                      PopupMenuItem(
                                        value: 'copy_word',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.copy_rounded,
                                                size: 18),
                                            const SizedBox(width: 8),
                                            Text(tr('books.copy_word')),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'copy_def',
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons.text_snippet_outlined,
                                                size: 18),
                                            const SizedBox(width: 8),
                                            Text(tr('books.copy_meaning')),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuDivider(),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.delete_outline,
                                                color: Colors.red, size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              tr('common.remove'),
                                              style: const TextStyle(
                                                  color: Colors.red),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${item.sourceLanguage} → ${item.targetLanguage}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: theme
                                            .colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.dictionaryNameSnapshot,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
