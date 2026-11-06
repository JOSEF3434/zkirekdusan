// lib/features/books/presentation/screens/translation_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
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
  final TextEditingController _translateInputCtrl = TextEditingController();

  // Quick translation state
  String _sourceLang = 'en';
  String _targetLang = 'am';
  bool _isTranslating = false;
  DictionaryTranslationResult? _translateResult;
  String? _translateError;
  bool _isSaved = false;
  bool _isSavingTranslation = false;

  // Fallback language list for quick selector
  static const List<({String code, String name, String nativeName})> _defaultLanguages = [
    (code: 'en', name: 'English', nativeName: 'English'),
    (code: 'am', name: 'Amharic', nativeName: 'አማርኛ'),
    (code: 'gez', name: "Ge'ez", nativeName: 'ግዕዝ'),
    (code: 'ti', name: 'Tigrinya', nativeName: 'ትግርኛ'),
    (code: 'om', name: 'Oromo', nativeName: 'Afaan Oromoo'),
    (code: 'ar', name: 'Arabic', nativeName: 'العربية'),
    (code: 'fr', name: 'French', nativeName: 'Français'),
  ];

  @override
  void initState() {
    super.initState();
    _translateInputCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _translateInputCtrl.dispose();
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

  void _swapLanguages() {
    setState(() {
      final tmp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = tmp;
      _translateResult = null;
      _translateError = null;
      _isSaved = false;
    });
  }

  Future<void> _performTranslation() async {
    final query = _translateInputCtrl.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isTranslating = true;
      _translateError = null;
      _translateResult = null;
      _isSaved = false;
    });

    try {
      final result = await ref.read(dictionaryRepositoryProvider).translateWord(
            word: query,
            sourceLanguage: _sourceLang,
            targetLanguage: _targetLang,
          );
      if (mounted) {
        setState(() {
          _translateResult = result;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _translateError = e.toString().replaceAll('Exception: ', '');
          _isTranslating = false;
        });
      }
    }
  }

  Future<void> _saveQuickTranslation() async {
    if (_translateResult == null || !_translateResult!.hasDefinitions) return;
    final auth = ref.read(authProvider);
    final userId = auth.user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save translations')),
      );
      return;
    }

    setState(() => _isSavingTranslation = true);
    try {
      final firstDef = _translateResult!.definitions.first;
      final allDefsText =
          _translateResult!.definitions.map((d) => d.text).join('; ');

      await ref.read(dictionaryRepositoryProvider).saveTranslationHistory(
            userId,
            word: _translateResult!.word,
            sourceLanguage: _translateResult!.sourceLanguage,
            targetLanguage: _translateResult!.targetLanguage,
            definition: allDefsText.isNotEmpty ? allDefsText : firstDef.text,
            dictionaryBookId: _translateResult!.dictionaryBookId,
            dictionaryEntryId: firstDef.entryId,
            dictionaryNameSnapshot:
                _translateResult!.dictionaryName ?? 'መዝገበ ቃላት',
            pageNumber: firstDef.pageNumber,
            chapter: firstDef.chapterTitle,
          );

      if (mounted) {
        setState(() {
          _isSaved = true;
          _isSavingTranslation = false;
        });
        ref.read(translationHistoryProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(trProvider)('books.translation_saved')),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingTranslation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save translation: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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

  List<(String code, String label)> _getLanguageOptions(
      List<DictionaryLanguageModel>? dynamicLangs) {
    if (dynamicLangs != null && dynamicLangs.isNotEmpty) {
      return dynamicLangs
          .map((l) => (
                l.code.toLowerCase(),
                l.nativeName.isNotEmpty
                    ? '${l.name} (${l.nativeName})'
                    : l.name,
              ))
          .toList();
    }
    return _defaultLanguages
        .map((l) => (
              l.code,
              l.nativeName.isNotEmpty && l.nativeName != l.name
                  ? '${l.name} (${l.nativeName})'
                  : l.name,
            ))
        .toList();
  }

  Widget _buildQuickTranslateCard(
    ThemeData theme,
    dynamic tr,
    AsyncValue<List<DictionaryLanguageModel>> languagesAsync,
  ) {
    final langOptions = _getLanguageOptions(languagesAsync.valueOrNull);

    // Ensure selected source and target exist in options
    final availableCodes = langOptions.map((e) => e.$1).toSet();
    final effectiveSource =
        availableCodes.contains(_sourceLang) ? _sourceLang : (langOptions.firstOrNull?.$1 ?? 'en');
    final effectiveTarget =
        availableCodes.contains(_targetLang) ? _targetLang : (langOptions.length > 1 ? langOptions[1].$1 : 'am');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.translate_rounded,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Translate / መዝገበ ቃላት',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (_translateResult != null || _translateError != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _translateResult = null;
                      _translateError = null;
                      _translateInputCtrl.clear();
                      _isSaved = false;
                    });
                  },
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Clear', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Language Dropdowns & Swap Button
          Row(
            children: [
              // From Language Dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: effectiveSource,
                  decoration: InputDecoration(
                    labelText: tr('books.source_language'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  items: langOptions
                      .map(
                        (l) => DropdownMenuItem(
                          value: l.$1,
                          child: Text(
                            l.$2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _sourceLang = val;
                        _translateResult = null;
                        _translateError = null;
                      });
                    }
                  },
                ),
              ),
              // Swap Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: IconButton(
                  icon: const Icon(Icons.swap_horiz_rounded),
                  tooltip: 'Swap Languages',
                  color: theme.colorScheme.primary,
                  onPressed: _swapLanguages,
                ),
              ),
              // To Language Dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: effectiveTarget,
                  decoration: InputDecoration(
                    labelText: tr('books.target_language'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  items: langOptions
                      .map(
                        (l) => DropdownMenuItem(
                          value: l.$1,
                          child: Text(
                            l.$2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _targetLang = val;
                        _translateResult = null;
                        _translateError = null;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Word Input Field & Translate Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _translateInputCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _performTranslation(),
                  decoration: InputDecoration(
                    hintText: 'Enter word to translate (e.g. Love, ሰላም)...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _translateInputCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _translateInputCtrl.clear();
                              setState(() {
                                _translateResult = null;
                                _translateError = null;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isTranslating ? null : _performTranslation,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isTranslating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.translate_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text(tr('books.translate')),
                        ],
                      ),
              ),
            ],
          ),

          // Meaning Display / Result / Error
          if (_isTranslating) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Searching in published dictionaries...',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ] else if (_translateError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 20, color: theme.colorScheme.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _translateError!,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _performTranslation,
                    child: Text(tr('common.retry')),
                  ),
                ],
              ),
            ),
          ] else if (_translateResult != null) ...[
            const SizedBox(height: 12),
            _buildTranslationResultCard(theme, tr),
          ],
        ],
      ),
    );
  }

  Widget _buildTranslationResultCard(ThemeData theme, dynamic tr) {
    final result = _translateResult!;

    if (!result.hasDefinitions) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.search_off_rounded, color: Colors.amber, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('books.no_definitions_found'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No published dictionary match for "${result.word}" in ${_sourceLang.toUpperCase()} → ${_targetLang.toUpperCase()}. Check the spelling or choose another language pair.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word & Badges
          Row(
            children: [
              Expanded(
                child: Text(
                  result.word,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${result.sourceLanguage.toUpperCase()} → ${result.targetLanguage.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              if (result.dictionaryName != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.menu_book_rounded,
                          size: 11, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        result.dictionaryName!,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Meaning(s)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < result.definitions.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (result.definitions.length > 1)
                            Text(
                              '${i + 1}. ',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          Expanded(
                            child: SelectableText(
                              result.definitions[i].text,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Action buttons: Copy Word, Copy Meaning, Save to History
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _copy(result.word, tr('books.word_copied')),
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: Text(tr('books.copy_word'), style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  final allText =
                      result.definitions.map((d) => d.text).join('\n\n');
                  _copy(allText, tr('books.meaning_copied'));
                },
                icon: const Icon(Icons.text_snippet_outlined, size: 14),
                label: Text(tr('books.copy_meaning'), style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: (_isSaved || _isSavingTranslation)
                    ? null
                    : _saveQuickTranslation,
                icon: _isSavingTranslation
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isSaved
                            ? Icons.check_circle_rounded
                            : Icons.bookmark_add_rounded,
                        size: 14,
                      ),
                label: Text(
                  _isSaved ? 'Saved' : tr('books.save_translation'),
                  style: const TextStyle(fontSize: 12),
                ),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);
    final filter = ref.watch(translationHistoryFilterProvider);
    final historyAsync = ref.watch(translationHistoryProvider);
    final languagesAsync = ref.watch(availableDictionaryLanguagesProvider);

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
          // ── Quick Translation Card (Translate word directly) ─────────────
          _buildQuickTranslateCard(theme, tr, languagesAsync),

          // ── Saved History Section Header ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Saved History',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                historyAsync.when(
                  data: (data) => data.items.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${data.total} saved',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // ── Search & Filter bar for Saved Words ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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

          // ── Items List ───────────────────────────────────────────────────
          Expanded(
            child: historyAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
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
                                : 'No translations saved yet.\nTranslate a word above or while reading to save them.',
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
