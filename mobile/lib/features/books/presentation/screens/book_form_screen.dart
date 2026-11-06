// lib/features/books/presentation/screens/book_form_screen.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/book_attachment_model.dart';
import '../../data/models/book_category_model.dart';
import '../../data/models/book_model.dart';
import '../../data/models/dictionary_model.dart';
import '../providers/dictionary_providers.dart';
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

  final List<_AttachmentFormItem> _attachments = [];

  // Dictionary Mode states
  bool _isDictionary = false;
  late final TextEditingController _dictionaryNameController;
  late final TextEditingController _dictionaryDescController;
  String? _sourceLanguageId;
  String? _targetLanguageId;
  DictionaryConfigModel? _existingDictConfig;

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
    _isDictionary = b?.isDictionary ?? false;
    _dictionaryNameController = TextEditingController(
      text: b?.dictionaryConfig?.dictionaryName ?? (b?.isDictionary == true ? b?.title ?? '' : ''),
    );
    _dictionaryDescController = TextEditingController(
      text: b?.dictionaryConfig?.description ?? '',
    );
    _sourceLanguageId = b?.dictionaryConfig?.sourceLanguageId;
    _targetLanguageId = b?.dictionaryConfig?.targetLanguageId;
    _existingDictConfig = b?.dictionaryConfig;

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

      if (b.attachments.isNotEmpty) {
        for (final att in b.attachments) {
          _attachments.add(_AttachmentFormItem.fromExisting(att));
        }
      } else {
        _attachments.add(_AttachmentFormItem.empty());
      }
    } else {
      _attachments.add(_AttachmentFormItem.empty());
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
            _isDictionary = b.isDictionary;
            _dictionaryNameController.text = b.dictionaryConfig?.dictionaryName ?? (b.isDictionary ? b.title : '');
            _dictionaryDescController.text = b.dictionaryConfig?.description ?? '';
            _sourceLanguageId = b.dictionaryConfig?.sourceLanguageId;
            _targetLanguageId = b.dictionaryConfig?.targetLanguageId;
            _existingDictConfig = b.dictionaryConfig;
            _selectedCategoryId = b.categoryId;
            _language = _langToString(b.language);
            _format = _formatToString(b.format);
            _status = _statusToString(b.status);
            _existingCoverUrl = b.coverUrl;
            _coverFileId = b.coverFileId;
            _existingContentUrl = b.contentUrl;
            _contentFileId = b.contentFileId;
            _contentFileName = b.contentUrl?.split('/').last;

            if (b.attachments.isNotEmpty) {
              for (final a in _attachments) {
                a.dispose();
              }
              _attachments.clear();
              for (final att in b.attachments) {
                _attachments.add(_AttachmentFormItem.fromExisting(att));
              }
            }
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
    _dictionaryNameController.dispose();
    _dictionaryDescController.dispose();
    for (final a in _attachments) {
      a.dispose();
    }
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

  // ── Media Attachment Pickers & Helpers ──────────────────────────────────

  AttachmentMediaType _detectMediaType(String ext) {
    if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
      return AttachmentMediaType.image;
    }
    if (['mp3', 'wav', 'm4a', 'aac', 'ogg'].contains(ext)) {
      return AttachmentMediaType.audio;
    }
    if (['mp4', 'webm', 'mov', 'mkv'].contains(ext)) {
      return AttachmentMediaType.video;
    }
    if (['pdf', 'epub', 'doc', 'docx', 'txt', 'md'].contains(ext)) {
      return AttachmentMediaType.document;
    }
    return AttachmentMediaType.other;
  }

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickAttachmentFile(_AttachmentFormItem item) async {
    try {
      final extensions = [
        'pdf', 'doc', 'docx', 'epub', 'txt', 'md',
        'jpg', 'jpeg', 'png', 'webp',
        'mp3', 'wav', 'm4a', 'aac', 'ogg',
        'mp4', 'webm', 'mov',
      ];
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
          final ext = f.name.contains('.')
              ? f.name.split('.').last.toLowerCase()
              : '';
          setState(() {
            item.newBytes = bytes;
            item.newFileName = f.name;
            item.newFileSize = f.size;
            item.uploadedFileId = null;
            item.uploadError = null;
            item.mediaType = _detectMediaType(ext);
            if (item.titleController.text.trim().isEmpty) {
              final nameWithoutExt = f.name.contains('.')
                  ? f.name.substring(0, f.name.lastIndexOf('.'))
                  : f.name;
              item.titleController.text = nameWithoutExt;
            }
          });
          _uploadAttachmentItem(item);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select media attachment: $e');
    }
  }

  Future<void> _uploadAttachmentItem(_AttachmentFormItem item) async {
    if (item.newBytes == null || item.newFileName == null) return;
    setState(() {
      item.isUploading = true;
      item.uploadProgress = 0.0;
      item.uploadError = null;
    });

    try {
      final repo = ref.read(booksRepositoryProvider);
      final res = await repo.uploadBookAttachment(
        bytes: item.newBytes!,
        filename: item.newFileName!,
        onProgress: (count, total) {
          if (total > 0 && mounted) {
            setState(() {
              item.uploadProgress = count / total;
            });
          }
        },
      );
      final fileId = res['id'] as String?;
      if (mounted) {
        setState(() {
          item.isUploading = false;
          item.uploadedFileId = fileId;
          item.uploadProgress = 1.0;
          item.uploadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          item.isUploading = false;
          item.uploadError = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _removeAttachmentItem(int index) async {
    final item = _attachments[index];
    if (item.existingId != null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove Attachment'),
          content: Text(
            'Are you sure you want to remove "${item.titleController.text.isNotEmpty ? item.titleController.text : (item.newFileName ?? item.existingOriginalName ?? 'this attachment')}"?\n\nThis attachment will be unlinked when you save changes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() {
      item.dispose();
      _attachments.removeAt(index);
    });
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

      // 3. Upload any pending attachment files
      for (final att in _attachments) {
        if (att.newBytes != null &&
            att.uploadedFileId == null &&
            !att.isUploading) {
          await _uploadAttachmentItem(att);
        }
      }

      // Check if any attachment is still uploading
      final stillUploading = _attachments.any((a) => a.isUploading);
      if (stillUploading) {
        _showErrorSnackBar(
          'Please wait for media attachment uploads to complete',
        );
        setState(() => _isSaving = false);
        return;
      }

      final attachmentsData = <Map<String, dynamic>>[];
      for (int i = 0; i < _attachments.length; i++) {
        final item = _attachments[i];
        final fileId = item.uploadedFileId ?? item.existingFileId;
        if (fileId != null) {
          attachmentsData.add({
            if (item.existingId != null) 'id': item.existingId,
            'fileId': fileId,
            'title': item.titleController.text.trim().isNotEmpty
                ? item.titleController.text.trim()
                : (item.newFileName ??
                    item.existingOriginalName ??
                    'Attachment ${i + 1}'),
            'sortOrder': i,
          });
        }
      }

      if (_isDictionary) {
        if (_sourceLanguageId == null || _targetLanguageId == null) {
          _showErrorSnackBar(
            'Please select both Source and Target languages for the dictionary',
          );
          setState(() => _isSaving = false);
          return;
        }
        if (_sourceLanguageId == _targetLanguageId) {
          _showErrorSnackBar(
            'Source and Target languages cannot be identical',
          );
          setState(() => _isSaving = false);
          return;
        }
      }

      // 4. Build data map
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
        'attachments': attachmentsData,
        'isDictionary': _isDictionary,
        if (_isDictionary) ...{
          'dictionaryName': _dictionaryNameController.text.trim().isNotEmpty
              ? _dictionaryNameController.text.trim()
              : _titleController.text.trim(),
          if (_dictionaryDescController.text.trim().isNotEmpty)
            'dictionaryDescription': _dictionaryDescController.text.trim(),
          if (_sourceLanguageId != null) 'sourceLanguageId': _sourceLanguageId,
          if (_targetLanguageId != null) 'targetLanguageId': _targetLanguageId,
        },
      };

      final savedBook = isEditing
          ? await repo.updateBook(widget.bookId!, data)
          : await repo.createBook(data);

      if (_isDictionary) {
        try {
          await ref.read(dictionaryRepositoryProvider).triggerProcess(savedBook.id);
        } catch (_) {}
      }

      // Refresh providers
      ref.read(bookAdminListProvider.notifier).refresh();
      ref.read(libraryProvider.notifier).refresh();
      ref.invalidate(bookCategoriesProvider);
      ref.invalidate(availableDictionariesProvider);
      ref.invalidate(adminDictionariesProvider);
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

  InputDecoration _inputDeco({
    required ThemeData theme,
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: theme.colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.error,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildSectionCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 18),
          ...children,
        ],
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
            padding: const EdgeInsets.only(right: 16),
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
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save Book'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Responsive horizontal padding for large screens / media
          final double horizontalPadding;
          if (width >= 1400) {
            horizontalPadding = (width - 960) / 2;
          } else if (width >= 1000) {
            horizontalPadding = (width - 860) / 2;
          } else if (width >= 700) {
            horizontalPadding = (width - 640) / 2;
          } else {
            horizontalPadding = 16.0;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              children: [
                // ── Section 1: Basic Information ──────────────────────────
                _buildSectionCard(
                  theme: theme,
                  title: 'Basic Information',
                  subtitle: 'Primary book titles, subtitle, and content overview',
                  icon: Icons.menu_book_rounded,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDeco(
                        theme: theme,
                        labelText: 'Book Title *',
                        hintText: 'Enter title (English / Primary)',
                        prefixIcon: const Icon(Icons.title),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Title is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _titleAmController,
                            decoration: _inputDeco(
                              theme: theme,
                              labelText: 'Title (Amharic)',
                              hintText: 'ርዕስ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: _titleGezController,
                            decoration: _inputDeco(
                              theme: theme,
                              labelText: 'Title (Ge\'ez)',
                              hintText: 'አርዕስት',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _subtitleController,
                      decoration: _inputDeco(
                        theme: theme,
                        labelText: 'Subtitle',
                        hintText: 'Optional subtitle or alternative title',
                        prefixIcon: const Icon(Icons.subtitles_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: _inputDeco(
                        theme: theme,
                        labelText: 'Description',
                        hintText: 'Overview, synopsis, or content summary',
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.notes_rounded),
                      ),
                    ),
                  ],
                ),

                // ── Section 2: Authorship & Publication ──────────────────
                _buildSectionCard(
                  theme: theme,
                  title: 'Authorship & Publication',
                  subtitle: 'Church Fathers, authors, translator, publisher & dates',
                  icon: Icons.person_outline_rounded,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _authorController,
                            decoration: _inputDeco(
                              theme: theme,
                              labelText: 'Author *',
                              hintText: 'Author or Church Father',
                              prefixIcon: const Icon(Icons.person),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Author is required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: _translatorController,
                            decoration: _inputDeco(
                              theme: theme,
                              labelText: 'Translator',
                              hintText: 'Translator if applicable',
                              prefixIcon: const Icon(Icons.translate_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _publisherController,
                            decoration: _inputDeco(
                              theme: theme,
                              labelText: 'Publisher',
                              hintText: 'Publishing house / Church / Diocese',
                              prefixIcon: const Icon(Icons.business_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: _publishedYearController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDeco(
                              theme: theme,
                              labelText: 'Year',
                              hintText: 'e.g. 2015',
                              prefixIcon: const Icon(Icons.calendar_today_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _editionController,
                            decoration: _inputDeco(
                              theme: theme,
                              labelText: 'Edition',
                              hintText: 'e.g. 1st, Revised, Jubilee',
                              prefixIcon: const Icon(Icons.bookmark_border_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: _pageCountController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDeco(
                              theme: theme,
                              labelText: 'Pages',
                              hintText: 'e.g. 240',
                              prefixIcon: const Icon(Icons.auto_stories_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // ── Section 3: Classification & Language ─────────────────
                _buildSectionCard(
                  theme: theme,
                  title: 'Classification & Language',
                  subtitle: 'Language selection, categorization, and searchable tags',
                  icon: Icons.category_outlined,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _language,
                            decoration: _inputDeco(
                              theme: theme,
                              labelText: 'Language',
                              prefixIcon: const Icon(Icons.language_rounded),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'AMHARIC',
                                child: Text('Amharic (አማርኛ)', overflow: TextOverflow.ellipsis),
                              ),
                              DropdownMenuItem(
                                value: 'GEEZ',
                                child: Text('Ge\'ez (ግዕዝ)', overflow: TextOverflow.ellipsis),
                              ),
                              DropdownMenuItem(
                                value: 'ENGLISH',
                                child: Text('English', overflow: TextOverflow.ellipsis),
                              ),
                              DropdownMenuItem(
                                value: 'OTHER',
                                child: Text('Other', overflow: TextOverflow.ellipsis),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _language = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: categoriesAsync.when(
                            data: (cats) {
                              final items = _flattenCategories(cats);
                              return DropdownButtonFormField<String?>(
                                isExpanded: true,
                                initialValue: _selectedCategoryId,
                                decoration: _inputDeco(
                                  theme: theme,
                                  labelText: 'Category',
                                  prefixIcon: const Icon(Icons.folder_outlined),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('No Category', overflow: TextOverflow.ellipsis),
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
                                onChanged: (v) => setState(() => _selectedCategoryId = v),
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (_, _) => const Text('Error loading categories'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _tagsController,
                      decoration: _inputDeco(
                        theme: theme,
                        labelText: 'Tags (comma-separated)',
                        hintText: 'e.g. Theology, Liturgy, History, Saints',
                        prefixIcon: const Icon(Icons.tag_rounded),
                      ),
                    ),
                  ],
                ),

                // ── Section 4: Format & Book Files ───────────────────────
                _buildSectionCard(
                  theme: theme,
                  title: 'Format & Book Files',
                  subtitle: 'Format specification, book cover artwork, and document file',
                  icon: Icons.attach_file_rounded,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _format,
                      decoration: _inputDeco(
                        theme: theme,
                        labelText: 'Book Format',
                        prefixIcon: const Icon(Icons.file_present_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'PDF',
                          child: Text('PDF Document', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'EPUB',
                          child: Text('EPUB eBook', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'TEXT',
                          child: Text('Structured Text / Chapters', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'AUDIO',
                          child: Text('Audiobook / Recitation', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 'EXTERNAL_LINK',
                          child: Text('External Resource URL', overflow: TextOverflow.ellipsis),
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
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _externalUrlController,
                        decoration: _inputDeco(
                          theme: theme,
                          labelText: 'External URL',
                          hintText: 'https://...',
                          prefixIcon: const Icon(Icons.link_rounded),
                        ),
                      ),
                    ],
                  ],
                ),

                // ── Section 5: Media Attachments ─────────────────────────
                _buildSectionCard(
                  theme: theme,
                  title: 'Media Attachments',
                  subtitle: 'Supplementary audio guides, video lectures, document notes, or illustrations',
                  icon: Icons.perm_media_outlined,
                  children: [
                    ..._attachments.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _buildAttachmentCard(theme, item, index);
                    }),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _attachments.add(_AttachmentFormItem.empty());
                        });
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('+ Add Media Attachment'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Section 5.5: Dictionary Mode Configuration (Admin Only) ──
                if (perms.canManageDictionaries) ...[
                  _buildDictionarySection(theme),
                ],

                // ── Section 6: Publication Status & Ordering ─────────────
                _buildSectionCard(
                  theme: theme,
                  title: 'Publication Status & Order',
                  subtitle: 'Manage availability to readers and catalog sequence order',
                  icon: Icons.tune_rounded,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _status,
                            decoration: _inputDeco(
                              theme: theme,
                              labelText: 'Status',
                              prefixIcon: const Icon(Icons.flag_outlined),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'DRAFT',
                                child: Text('Draft (Unpublished)', overflow: TextOverflow.ellipsis),
                              ),
                              if (perms.canPublish)
                                const DropdownMenuItem(
                                  value: 'PUBLISHED',
                                  child: Text('Published (Live)', overflow: TextOverflow.ellipsis),
                                ),
                              const DropdownMenuItem(
                                value: 'ARCHIVED',
                                child: Text('Archived', overflow: TextOverflow.ellipsis),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _status = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _sortOrderController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDeco(
                              theme: theme,
                              labelText: 'Sort Order',
                              hintText: '0',
                              prefixIcon: const Icon(Icons.sort_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Save & Cancel Actions ────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _save,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 20),
                        label: Text(
                          _isSaving
                              ? 'Saving...'
                              : (isEditing ? 'Save Changes' : 'Create Book'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDictionarySection(ThemeData theme) {
    final languagesAsync = ref.watch(availableDictionaryLanguagesProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _isDictionary
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDictionary
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: _isDictionary ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isDictionary
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.translate_rounded,
                  color: _isDictionary
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable Dictionary Mode (መዝገበ ቃላት)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _isDictionary
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Index entries for in-book word lookup & translation',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isDictionary,
                activeThumbColor: theme.colorScheme.primary,
                onChanged: (val) {
                  setState(() {
                    _isDictionary = val;
                    if (val && _dictionaryNameController.text.trim().isEmpty) {
                      _dictionaryNameController.text = _titleController.text.trim();
                    }
                  });
                },
              ),
            ],
          ),
          if (_isDictionary) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 18),

            // Processing Status Card (if editing)
            if (_existingDictConfig != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _existingDictConfig!.isReady
                          ? Icons.check_circle_rounded
                          : _existingDictConfig!.isFailed
                              ? Icons.error_rounded
                              : Icons.hourglass_top_rounded,
                      size: 20,
                      color: _existingDictConfig!.isReady
                          ? Colors.green
                          : _existingDictConfig!.isFailed
                              ? theme.colorScheme.error
                              : Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: ${_existingDictConfig!.processingStatus}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_existingDictConfig!.totalEntries} entries indexed',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isEditing)
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          try {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Triggering dictionary indexing...'),
                              ),
                            );
                            await ref
                                .read(dictionaryRepositoryProvider)
                                .triggerProcess(widget.bookId!);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Processing started in background!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadDetailsIfNeeded();
                            }
                          } catch (e) {
                            if (mounted) {
                              _showErrorSnackBar('Failed to trigger indexing: $e');
                            }
                          }
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Re-index'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                      ),
                  ],
                ),
              ),
              if (_existingDictConfig!.errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 18, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _existingDictConfig!.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _dictionaryNameController,
              decoration: _inputDeco(
                theme: theme,
                labelText: 'Dictionary Name *',
                hintText: 'e.g. መዝገበ ቃላት / English-Amharic Dictionary',
                prefixIcon: const Icon(Icons.menu_book_rounded),
              ),
              validator: (v) => _isDictionary && (v == null || v.trim().isEmpty)
                  ? 'Dictionary name is required'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _dictionaryDescController,
              maxLines: 2,
              decoration: _inputDeco(
                theme: theme,
                labelText: 'Dictionary Description (optional)',
                hintText: 'Scope, target vocabulary, or usage notes',
                prefixIcon: const Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),

            // Language Pair Dropdowns
            languagesAsync.when(
              data: (langs) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Source Language
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _sourceLanguageId,
                            decoration: _inputDeco(
                              theme: theme,
                              labelText: 'Translate From *',
                              hintText: 'Source',
                              prefixIcon: const Icon(Icons.input_rounded),
                            ),
                            items: langs
                                .map(
                                  (l) => DropdownMenuItem(
                                    value: l.id,
                                    child: Text(
                                      l.nativeName.isNotEmpty
                                          ? '${l.name} (${l.nativeName})'
                                          : l.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _sourceLanguageId = v),
                            validator: (v) =>
                                _isDictionary && (v == null || v.isEmpty)
                                    ? 'Select source language'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Target Language
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _targetLanguageId,
                            decoration: _inputDeco(
                              theme: theme,
                              labelText: 'Translate To *',
                              hintText: 'Target',
                              prefixIcon: const Icon(Icons.output_rounded),
                            ),
                            items: langs
                                .map(
                                  (l) => DropdownMenuItem(
                                    value: l.id,
                                    child: Text(
                                      l.nativeName.isNotEmpty
                                          ? '${l.name} (${l.nativeName})'
                                          : l.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _targetLanguageId = v),
                            validator: (v) =>
                                _isDictionary && (v == null || v.isEmpty)
                                    ? 'Select target language'
                                    : null,
                          ),
                        ),
                      ],
                    ),
                    if (_sourceLanguageId != null &&
                        _targetLanguageId != null &&
                        _sourceLanguageId == _targetLanguageId) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Source and target languages cannot be identical',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text(
                'Failed to load languages: $err',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Supported formats for dictionary indexing: PDF and EPUB.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
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


  Widget _buildAttachmentCard(
    ThemeData theme,
    _AttachmentFormItem item,
    int index,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final (IconData mediaIcon, Color mediaColor, String mediaLabel) =
        switch (item.mediaType) {
      AttachmentMediaType.document => (
          Icons.description_outlined,
          Colors.blue,
          'Document',
        ),
      AttachmentMediaType.image => (
          Icons.image_outlined,
          Colors.teal,
          'Image',
        ),
      AttachmentMediaType.audio => (
          Icons.audiotrack_outlined,
          Colors.purple,
          'Audio',
        ),
      AttachmentMediaType.video => (
          Icons.videocam_outlined,
          Colors.orange,
          'Video',
        ),
      AttachmentMediaType.other => (
          Icons.attach_file,
          Colors.blueGrey,
          'Media',
        ),
    };

    final fileName = item.newFileName ??
        item.existingOriginalName ??
        (item.existingUrl?.split('/').last) ??
        'No file chosen';
    final fileSize = item.newFileSize ?? item.existingSize;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.uploadError != null
              ? theme.colorScheme.error.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${index + 1}',
                  style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: mediaColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: mediaColor.withAlpha(100)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(mediaIcon, size: 14, color: mediaColor),
                    const SizedBox(width: 4),
                    Text(
                      mediaLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: mediaColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: theme.colorScheme.error,
                tooltip: 'Remove Attachment',
                onPressed: () => _removeAttachmentItem(index),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: item.titleController,
            decoration: InputDecoration(
              labelText: 'Attachment Title',
              hintText: 'e.g. Full Audio Narration, Manuscript Map, Notes...',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: item.hasFile
                ? Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: mediaColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(mediaIcon,
                                color: mediaColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (fileSize != null && fileSize > 0)
                                  Text(
                                    _formatBytes(fileSize),
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => _pickAttachmentFile(item),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Replace',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      if (item.isUploading) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                            value: item.uploadProgress > 0
                                ? item.uploadProgress
                                : null),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Uploading attachment...',
                                style: TextStyle(fontSize: 11)),
                            Text('${(item.uploadProgress * 100).toInt()}%',
                                style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                      ],
                      if (item.uploadError != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.error_outline,
                                size: 16, color: theme.colorScheme.error),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.uploadError!,
                                style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontSize: 11),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _uploadAttachmentItem(item),
                              child: const Text('Retry',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                      if (item.uploadedFileId != null &&
                          !item.isUploading &&
                          item.uploadError == null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'Ready / Uploaded',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          size: 24, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No file selected (Optional)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'PDF, DOC, EPUB, TXT, JPG, PNG, MP3, MP4 (Max 150MB)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () => _pickAttachmentFile(item),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Choose File',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentFormItem {
  final String key;
  final String? existingId;
  final String? existingFileId;
  final String? existingUrl;
  final String? existingOriginalName;
  final String? existingMimeType;
  final int? existingSize;
  AttachmentMediaType mediaType;

  final TextEditingController titleController;

  Uint8List? newBytes;
  String? newFileName;
  int? newFileSize;

  String? uploadedFileId;
  bool isUploading;
  double uploadProgress;
  String? uploadError;

  _AttachmentFormItem({
    required this.key,
    this.existingId,
    this.existingFileId,
    this.existingUrl,
    this.existingOriginalName,
    this.existingMimeType,
    this.existingSize,
    this.mediaType = AttachmentMediaType.other,
    String? title,
    this.uploadedFileId,
  })  : titleController = TextEditingController(text: title ?? ''),
        isUploading = false,
        uploadProgress = 0.0;

  factory _AttachmentFormItem.empty() {
    return _AttachmentFormItem(
      key: UniqueKey().toString(),
    );
  }

  factory _AttachmentFormItem.fromExisting(BookAttachmentModel model) {
    return _AttachmentFormItem(
      key: model.id,
      existingId: model.id,
      existingFileId: model.fileId,
      existingUrl: model.url,
      existingOriginalName: model.originalName,
      existingMimeType: model.mimeType,
      existingSize: model.fileSizeBytes,
      mediaType: model.mediaType,
      title: model.title ?? model.originalName ?? '',
      uploadedFileId: model.fileId,
    );
  }

  bool get hasFile =>
      uploadedFileId != null ||
      existingFileId != null ||
      (newBytes != null && newFileName != null);

  void dispose() {
    titleController.dispose();
  }
}

class _FlatCategoryItem {
  final BookCategoryModel category;
  final String prefix;
  final String id;

  _FlatCategoryItem({required this.category, required this.prefix})
      : id = category.id;
}
