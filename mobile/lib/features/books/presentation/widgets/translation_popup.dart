// lib/features/books/presentation/widgets/translation_popup.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import '../providers/dictionary_providers.dart';
import '../../data/models/dictionary_model.dart';

class TranslationPopup extends ConsumerStatefulWidget {
  final String word;
  final String? bookId;
  final String? sourceLanguage;
  final String? targetLanguage;
  final String? surroundingSentence;
  final int? pageNumber;
  final String? chapter;

  const TranslationPopup({
    super.key,
    required this.word,
    this.bookId,
    this.sourceLanguage,
    this.targetLanguage,
    this.surroundingSentence,
    this.pageNumber,
    this.chapter,
  });

  static Future<void> show(
    BuildContext context, {
    required String word,
    String? bookId,
    String? sourceLanguage,
    String? targetLanguage,
    String? surroundingSentence,
    int? pageNumber,
    String? chapter,
  }) async {
    final cleanWord = word.trim();
    if (cleanWord.isEmpty) return;

    final isWide = MediaQuery.of(context).size.width > 600;

    if (isWide) {
      await showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
            child: TranslationPopup(
              word: cleanWord,
              bookId: bookId,
              sourceLanguage: sourceLanguage,
              targetLanguage: targetLanguage,
              surroundingSentence: surroundingSentence,
              pageNumber: pageNumber,
              chapter: chapter,
            ),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.88,
          expand: false,
          builder: (ctx, scrollCtrl) => TranslationPopup(
            word: cleanWord,
            bookId: bookId,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            surroundingSentence: surroundingSentence,
            pageNumber: pageNumber,
            chapter: chapter,
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<TranslationPopup> createState() => _TranslationPopupState();
}

class _TranslationPopupState extends ConsumerState<TranslationPopup> {
  bool _isLoading = true;
  String? _errorMessage;
  DictionaryTranslationResult? _result;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _fetchTranslation();
  }

  Future<void> _fetchTranslation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(dictionaryRepositoryProvider);
      final res = await repo.translateWord(
        word: widget.word,
        bookId: widget.bookId,
        sourceLanguage: widget.sourceLanguage,
        targetLanguage: widget.targetLanguage,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _result = res;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _copyToClipboard(String text, String successMsg) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMsg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveTranslation() async {
    if (_result == null || _result!.definitions.isEmpty || _isSaved) return;

    final primaryDef = _result!.definitions.first.text;
    final dictName = _result!.dictionaryName ?? 'መዝገበ ቃላት';

    try {
      await ref.read(translationHistoryProvider.notifier).saveItem(
            word: widget.word,
            sourceLanguage: _result!.sourceLanguage,
            targetLanguage: _result!.targetLanguage,
            definition: primaryDef,
            dictionaryBookId: _result!.dictionaryBookId ?? widget.bookId,
            dictionaryEntryId: _result!.definitions.first.entryId,
            dictionaryNameSnapshot: dictName,
            pageNumber: widget.pageNumber,
            chapter: widget.chapter,
            surroundingSentence: widget.surroundingSentence,
          );

      if (mounted) {
        setState(() => _isSaved = true);
        final tr = ref.read(trProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('books.translation_saved')),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save translation: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle on mobile
          if (!kIsWeb && MediaQuery.of(context).size.width <= 600)
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

          // Header: Word + Close Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.word,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_result != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_result!.sourceLanguage} → ${_result!.targetLanguage}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            if (_result!.dictionaryName != null) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.menu_book_rounded,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        _result!.dictionaryName!,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildBody(theme, tr),
            ),
          ),

          // Actions Toolbar
          if (!_isLoading && _errorMessage == null && _result?.hasDefinitions == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(
                      widget.word,
                      tr('books.word_copied'),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text(tr('books.copy_word')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      final allDefs = _result!.definitions
                          .map((d) => d.text)
                          .join('\n\n');
                      _copyToClipboard(allDefs, tr('books.meaning_copied'));
                    },
                    icon: const Icon(Icons.text_snippet_outlined, size: 16),
                    label: Text(tr('books.copy_meaning')),
                  ),
                  FilledButton.icon(
                    onPressed: _isSaved ? null : _saveTranslation,
                    icon: Icon(
                      _isSaved ? Icons.check_circle_rounded : Icons.bookmark_add_rounded,
                      size: 16,
                    ),
                    label: Text(
                      _isSaved ? 'Saved' : tr('books.save_translation'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, String Function(String, [Map<String, dynamic>?]) tr) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Searching dictionary...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _fetchTranslation,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(tr('common.retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (_result == null || !_result!.hasDefinitions) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 56,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                tr('books.no_definitions_found'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              if (_result?.message != null) ...[
                const SizedBox(height: 8),
                Text(
                  _result!.message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meaning heading
        Row(
          children: [
            Text(
              'Meaning / ፍቺ',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const Spacer(),
            if (_result!.totalMatches > 1)
              Text(
                '${_result!.totalMatches} entries found',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // List of definitions
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _result!.definitions.length,
          separatorBuilder: (_, _) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          itemBuilder: (ctx, idx) {
            final def = _result!.definitions[idx];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_result!.definitions.length > 1)
                  Container(
                    margin: const EdgeInsets.only(top: 2, right: 10),
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${idx + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        def.text,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (def.pageNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Page ${def.pageNumber}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),

        // Surrounding sentence if available
        if (widget.surroundingSentence != null &&
            widget.surroundingSentence!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Context / ዐውድ:',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.surroundingSentence!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
