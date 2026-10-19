// lib/features/books/presentation/screens/book_form_screen.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/book_category_model.dart';
import '../../data/models/book_model.dart';
import '../providers/book_admin_providers.dart';
import '../providers/book_permissions_provider.dart';
import '../providers/books_providers.dart';

class BookFormScreen extends ConsumerStatefulWidget {
  final String? bookId;
  final BookModel? initialBook;

  const BookFormScreen({super.key, this.bookId, this.initialBook});

  @override
  ConsumerState<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends ConsumerState<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  late final TextEditingController _titleController;
  late final TextEditingController _titleAmController;
  late final TextEditingController _titleGezController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _authorController;
  late final TextEditingController _translatorController;
  late final TextEditingController _publisherController;
  late final TextEditingController _publishedYearController;
  late final TextEditingController _editionController;
  late final TextEditingController _isbnController;
  late final TextEditingController _pageCountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;
  late final TextEditingController _externalUrlController;
  late final TextEditingController _sortOrderController;

  // Selected values
  String _language = 'AMHARIC';
  String _format = 'PDF';
  String _status = 'DRAFT';
  String? _selectedCategoryId;

  // File states
  String? _existingCoverUrl;
  String? _coverFileId;
  Uint8List? _newCoverBytes;
  String? _newCoverName;

  String? _existingContentUrl;
  String? _contentFileId;
  String? _contentFileName;
  Uint8List? _newContentBytes;
  String? _newContentName;
  int? _newContentSize;

  bool _isSaving = false;
  double? _contentUploadProgress;

  bool get isEditing => widget.bookId != null;

  @override
  void initState() {
    super.initState();
    final b = widget.initialBook;

    _titleController = TextEditingController(text: b?.title ?? '');
    _titleAmController = TextEditingController(text: b?.titleAm ?? '');
    _titleGezController = TextEditingController(text: b?.titleGez ?? '');
    _subtitleController = TextEditingController(text: b?.subtitle ?? '');
    _authorController = TextEditingController(text: b?.author ?? '');
    _translatorController = TextEditingController(text: b?.translator ?? '');
    _publisherController = TextEditingController(text: b?.publisher ?? '');
    _publishedYearController = TextEditingController(
      text: b?.publishedYear != null ? b!.publishedYear.toString() : '',
    );
    _editionController = TextEditingController(text: b?.edition ?? '');
    _isbnController = TextEditingController(text: b?.isbn ?? '');
    _pageCountController = TextEditingController(
      text: b?.pageCount != null ? b!.pageCount.toString() : '',
    );
    _descriptionController = TextEditingController(text: b?.description ?? '');
    _tagsController = TextEditingController(text: b?.tags.join(', ') ?? '');
    _externalUrlController = TextEditingController(text: b?.externalUrl ?? '');
    _sortOrderController =
        TextEditingController(text: (b?.sortOrder ?? 0).toString());

    if (b != null) {
      _selectedCategoryId = b.categoryId;
      _language = _langToString(b.language);
      _format = _formatToString(b.format);
      _status = _statusToString(b.status);
      _existingCoverUrl = b.coverUrl;
      _coverFileId = b.coverFileId;
      _existingContentUrl = b.contentUrl;
      _contentFileId = b.contentFileId;
      _contentFileName = b.contentUrl?.split('/').last;
    } else {
      _loadDetailsIfNeeded();
    }
  }

  Future<void> _loadDetailsIfNeeded() async {
    if (widget.bookId != null && widget.initialBook == null) {
      try {
        final b = await ref
            .read(booksRepositoryProvider)
            .getBook(widget.bookId!, authenticated: true);
        if (mounted) {
          setState(() {
            _titleController.text = b.title;
            _titleAmController.text = b.titleAm ?? '';
            _titleGezController.text = b.titleGez ?? '';
            _subtitleController.text = b.subtitle ?? '';
            _authorController.text = b.author ?? '';
            _translatorController.text = b.translator ?? '';
            _publisherController.text = b.publisher ?? '';
            _publishedYearController.text =
                b.publishedYear != null ? b.publishedYear.toString() : '';
            _editionController.text = b.edition ?? '';
            _isbnController.text = b.isbn ?? '';
            _pageCountController.text =
                b.pageCount != null ? b.pageCount.toString() : '';
            _descriptionController.text = b.description ?? '';
            _tagsController.text = b.tags.join(', ');
            _externalUrlController.text = b.externalUrl ?? '';
            _sortOrderController.text = b.sortOrder.toString();
            _selectedCategoryId = b.categoryId;
            _language = _langToString(b.language);
            _format = _formatToString(b.format);
            _status = _statusToString(b.status);
            _existingCoverUrl = b.coverUrl;
            _coverFileId = b.coverFileId;
            _existingContentUrl = b.contentUrl;
            _contentFileId = b.contentFileId;
            _contentFileName = b.contentUrl?.split('/').last;
          });
        }
      } catch (_) {}
    }
  }

  String _langToString(BookLanguage l) {
    switch (l) {
      case BookLanguage.amharic:
        return 'AMHARIC';
      case BookLanguage.geez:
        return 'GEEZ';
      case BookLanguage.english:
        return 'ENGLISH';
      default:
        return 'OTHER';
    }
  }

  String _formatToString(BookFormat f) {
    switch (f) {
      case BookFormat.pdf:
        return 'PDF';
      case BookFormat.epub:
        return 'EPUB';
      case BookFormat.text:
        return 'TEXT';
      case BookFormat.audio:
        return 'AUDIO';
      case BookFormat.externalLink:
        return 'EXTERNAL_LINK';
    }
  }

  String _statusToString(BookStatus s) {
    switch (s) {
      case BookStatus.published:
        return 'PUBLISHED';
      case BookStatus.archived:
        return 'ARCHIVED';
      case BookStatus.deleted:
        return 'DELETED';
      default:
        return 'DRAFT';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleAmController.dispose();
    _titleGezController.dispose();
    _subtitleController.dispose();
    _authorController.dispose();
    _translatorController.dispose();
    _publisherController.dispose();
    _publishedYearController.dispose();
    _editionController.dispose();
    _isbnController.dispose();
    _pageCountController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _externalUrlController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  // ── Cover picker ────────────────────────────────────────────────────────

  Future<void> _pickCover() async {
    try {
      final res = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (res != null && res.files.isNotEmpty) {
        final f = res.files.first;
        Uint8List? bytes = f.bytes;
        if (bytes == null && f.path != null) {
          bytes = await File(f.path!).readAsBytes();
        }
        if (bytes != null) {
          setState(() {
            _newCoverBytes = bytes;
            _newCoverName = f.name;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select cover image: $e');
    }
  }

  // ── Content picker ──────────────────────────────────────────────────────

  Future<void> _pickContent() async {
    try {
      final extensions = ['pdf', 'epub', 'txt', 'mp3', 'm4a', 'aac', 'wav'];
      final res = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
        withData: true,
      );
      if (res != null && res.files.isNotEmpty) {
        final f = res.files.first;
        Uint8List? bytes = f.bytes;
        if (bytes == null && f.path != null) {
          bytes = await File(f.path!).readAsBytes();
        }
        if (bytes != null) {
          setState(() {
            _newContentBytes = bytes;
            _newContentName = f.name;
            _newContentSize = f.size;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select content file: $e');
    }
  }

  // ── Save action ─────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(booksRepositoryProvider);

      // 1. Upload cover if new one selected
      String? coverId = _coverFileId;
      if (_newCoverBytes != null && _newCoverName != null) {
        final coverRes = await repo.uploadBookCover(
          bytes: _newCoverBytes!,
          filename: _newCoverName!,
        );
        coverId = coverRes['id'] as String?;
      }

      // 2. Upload content file if new one selected
      String? contentId = _contentFileId;
      if (_newContentBytes != null && _newContentName != null) {
        final contentRes = await repo.uploadBookContent(
          bytes: _newContentBytes!,
          filename: _newContentName!,
          onProgress: (count, total) {
            if (total > 0 && mounted) {
              setState(() {
                _contentUploadProgress = count / total;
              });
            }
          },
        );
        contentId = contentRes['id'] as String?;
      }

      // 3. Build data map
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final data = <String, dynamic>{
        'title': _titleController.text.trim(),
        if (_titleAmController.text.trim().isNotEmpty)
          'titleAm': _titleAmController.text.trim(),
        if (_titleGezController.text.trim().isNotEmpty)
          'titleGez': _titleGezController.text.trim(),
        if (_subtitleController.text.trim().isNotEmpty)
          'subtitle': _subtitleController.text.trim(),
        if (_authorController.text.trim().isNotEmpty)
          'author': _authorController.text.trim(),
        if (_translatorController.text.trim().isNotEmpty)
          'translator': _translatorController.text.trim(),
        if (_publisherController.text.trim().isNotEmpty)
          'publisher': _publisherController.text.trim(),
        if (_publishedYearController.text.trim().isNotEmpty)
          'publishedYear': int.tryParse(_publishedYearController.text.trim()),
        if (_editionController.text.trim().isNotEmpty)
          'edition': _editionController.text.trim(),
        if (_isbnController.text.trim().isNotEmpty)
          'isbn': _isbnController.text.trim(),
        if (_pageCountController.text.trim().isNotEmpty)
          'pageCount': int.tryParse(_pageCountController.text.trim()),
        if (_descriptionController.text.trim().isNotEmpty)
          'description': _descriptionController.text.trim(),
        'language': _language,
        'format': _format,
        'status': _status,
        'categoryId': ?_selectedCategoryId,
        'tags': tags,
        'sortOrder': int.tryParse(_sortOrderController.text.trim()) ?? 0,
        if (_externalUrlController.text.trim().isNotEmpty)
          'externalUrl': _externalUrlController.text.trim(),
        'coverFileId': ?coverId,
        'contentFileId': ?contentId,
      };

      if (isEditing) {
        await repo.updateBook(widget.bookId!, data);
      } else {
        await repo.createBook(data);
      }

      // Refresh providers
      ref.read(bookAdminListProvider.notifier).refresh();
      ref.read(libraryProvider.notifier).refresh();
      ref.invalidate(bookCategoriesProvider);
      if (widget.bookId != null) {
        ref.invalidate(bookDetailProvider(widget.bookId!));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Book updated successfully'
                  : 'Book created successfully',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        String errorMessage = 'Failed to save book';
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map) {
            if (data['details'] != null) {
              if (data['details'] is List && (data['details'] as List).isNotEmpty) {
                errorMessage = (data['details'] as List).join('\n');
              } else if (data['details'] is String) {
                errorMessage = data['details'] as String;
              }
            } else if (data['error'] != null) {
              errorMessage = data['error'].toString();
            } else if (data['message'] != null) {
              errorMessage = data['message'].toString();
            }
          } else if (e.message != null && e.message!.isNotEmpty) {
            errorMessage = e.message!;
          }
        } else {
          errorMessage = 'Failed to save book: ${e.toString().replaceAll('Exception: ', '')}';
        }
        _showErrorSnackBar(errorMessage);
      }
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final perms = ref.watch(bookPermissionsProvider);
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Book' : 'Add Book',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // ── Section 1: Basic Information ──────────────────────────────
            _buildSectionHeader(theme, 'Basic Information', Icons.info_outline),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Book Title *',
                hintText: 'Enter title (English / Primary)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _titleAmController,
                    decoration: const InputDecoration(
                      labelText: 'Title (Amharic)',
                      hintText: 'ርዕስ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _titleGezController,
                    decoration: const InputDecoration(
                      labelText: 'Title (Ge\'ez)',
                      hintText: 'አርዕስት',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subtitleController,
              decoration: const InputDecoration(
                labelText: 'Subtitle',
                hintText: 'Optional subtitle',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Overview, synopsis, or content summary',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            // ── Section 2: Authorship & Publishing ────────────────────────
            _buildSectionHeader(
              theme,
              'Authorship & Publication',
              Icons.person_outline,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _authorController,
                    decoration: const InputDecoration(
                      labelText: 'Author *',
                      hintText: 'Author or Church Father',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Author is required'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _translatorController,
                    decoration: const InputDecoration(
                      labelText: 'Translator',
                      hintText: 'Translator if applicable',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _publisherController,
                    decoration: const InputDecoration(
                      labelText: 'Publisher',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _publishedYearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      hintText: 'e.g. 2015',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _editionController,
                    decoration: const InputDecoration(
                      labelText: 'Edition',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _pageCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pages',
                      hintText: 'e.g. 240',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Section 3: Category, Language & Tags ───────────────────────
            _buildSectionHeader(
              theme,
              'Classification & Language',
              Icons.category_outlined,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _language,
                    decoration: const InputDecoration(
                      labelText: 'Language',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'AMHARIC',
                        child: Text('Amharic (አማርኛ)'),
                      ),
                      DropdownMenuItem(
                        value: 'GEEZ',
                        child: Text('Ge\'ez (ግዕዝ)'),
                      ),
                      DropdownMenuItem(
                        value: 'ENGLISH',
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: 'OTHER',
                        child: Text('Other'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _language = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: categoriesAsync.when(
                    data: (cats) {
                      final items = _flattenCategories(cats);
                      return DropdownButtonFormField<String?>(
                        initialValue: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No Category'),
                          ),
                          ...items.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.prefix + c.category.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedCategoryId = v),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const Text('Error loading categories'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma-separated)',
                hintText: 'e.g. Theology, Liturgy, History, Saints',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
            ),

            const SizedBox(height: 24),

            // ── Section 4: Format & Uploads ───────────────────────────────
            _buildSectionHeader(
              theme,
              'Format & Book Files',
              Icons.attach_file,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _format,
              decoration: const InputDecoration(
                labelText: 'Book Format',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'PDF', child: Text('PDF Document')),
                DropdownMenuItem(value: 'EPUB', child: Text('EPUB eBook')),
                DropdownMenuItem(
                  value: 'TEXT',
                  child: Text('Structured Text / Chapters'),
                ),
                DropdownMenuItem(
                  value: 'AUDIO',
                  child: Text('Audiobook / Recitation'),
                ),
                DropdownMenuItem(
                  value: 'EXTERNAL_LINK',
                  child: Text('External Resource URL'),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _format = v);
              },
            ),
            const SizedBox(height: 16),

            // Cover Image picker card
            _buildCoverCard(theme),
            const SizedBox(height: 16),

            // Content File picker card
            if (_format != 'EXTERNAL_LINK') _buildContentCard(theme),

            if (_format == 'EXTERNAL_LINK') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _externalUrlController,
                decoration: const InputDecoration(
                  labelText: 'External URL',
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Section 5: Status & Sorting ───────────────────────────────
            _buildSectionHeader(
              theme,
              'Publication Status & Order',
              Icons.tune,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'DRAFT',
                        child: Text('Draft (Unpublished)'),
                      ),
                      if (perms.canPublish)
                        const DropdownMenuItem(
                          value: 'PUBLISHED',
                          child: Text('Published (Live)'),
                        ),
                      const DropdownMenuItem(
                        value: 'ARCHIVED',
                        child: Text('Archived'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sortOrderController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sort Order',
                      hintText: '0',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Save & Cancel buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isEditing ? 'Save Changes' : 'Create Book'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildCoverCard(ThemeData theme) {
    final hasNew = _newCoverBytes != null;
    final hasExisting = _existingCoverUrl != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Preview box
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 80,
              child: hasNew
                  ? Image.memory(_newCoverBytes!, fit: BoxFit.cover)
                  : (hasExisting
                      ? Image.network(
                          _existingCoverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.image),
                        )
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.menu_book, size: 30),
                        )),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasNew
                      ? (_newCoverName ?? 'Selected Cover Image')
                      : (hasExisting
                          ? 'Current Cover Image'
                          : 'No Cover Selected'),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Format: JPG, PNG, WebP (Max 10MB)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickCover,
                      icon: const Icon(Icons.upload, size: 16),
                      label: Text(
                        hasNew || hasExisting ? 'Change Cover' : 'Pick Cover',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    ),
                    if (hasNew) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _newCoverBytes = null;
                            _newCoverName = null;
                          });
                        },
                        tooltip: 'Clear new cover',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(ThemeData theme) {
    final hasNew = _newContentBytes != null;
    final hasExisting = _existingContentUrl != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _format == 'AUDIO'
                      ? Icons.audiotrack
                      : Icons.picture_as_pdf,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasNew
                          ? (_newContentName ?? 'Selected Content File')
                          : (hasExisting
                              ? (_contentFileName ?? 'Existing Content File')
                              : 'No File Selected'),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasNew && _newContentSize != null
                          ? '${(_newContentSize! / (1024 * 1024)).toStringAsFixed(1)} MB'
                          : 'Supported: PDF, EPUB, TXT, Audio (Max 150MB)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _pickContent,
                icon: const Icon(Icons.attach_file, size: 16),
                label: Text(hasNew || hasExisting ? 'Replace' : 'Upload'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
          if (_contentUploadProgress != null && _isSaving) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _contentUploadProgress),
            const SizedBox(height: 4),
            Text(
              'Uploading content: ${((_contentUploadProgress ?? 0) * 100).toInt()}%',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  List<_FlatCategoryItem> _flattenCategories(List<BookCategoryModel> cats) {
    final list = <_FlatCategoryItem>[];
    void addRec(BookCategoryModel c, String prefix) {
      list.add(_FlatCategoryItem(category: c, prefix: prefix));
      for (final child in c.children) {
        addRec(child, '$prefix— ');
      }
    }

    for (final c in cats) {
      addRec(c, '');
    }
    return list;
  }
}

class _FlatCategoryItem {
  final BookCategoryModel category;
  final String prefix;
  final String id;

  _FlatCategoryItem({required this.category, required this.prefix})
      : id = category.id;
}
