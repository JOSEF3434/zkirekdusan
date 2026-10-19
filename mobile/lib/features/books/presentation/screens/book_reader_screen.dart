// lib/features/books/presentation/screens/book_reader_screen.dart
// PDF reader using pdfx (cross-platform: Android, iOS, macOS, web, Windows, Linux).
// Text books use a scrollable text viewer. EPUB/AUDIO are indicated as unsupported
// in Phase 1 with clear messaging.

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:pdfx/pdfx.dart';
import '../../data/models/book_model.dart';
import '../providers/books_providers.dart';

class BookReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final int startChapter;
  final bool isDownloaded;

  const BookReaderScreen({
    super.key,
    required this.bookId,
    this.startChapter = 0,
    this.isDownloaded = false,
  });

  @override
  ConsumerState<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends ConsumerState<BookReaderScreen> {
  PdfControllerPinch? _pdfController;
  bool _uiVisible = true;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _loadError = false;
  String? _loadErrorMsg;
  bool _isLoading = true;
  BookModel? _book;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final auth = ref.read(authProvider);
    final isAuth = auth.status == AuthStatus.authenticated;

    try {
      final repo = ref.read(booksRepositoryProvider);
      _book = await repo.getBook(widget.bookId, authenticated: isAuth);
      if (!mounted) return;

      if (_book!.format == BookFormat.pdf) {
        await _initPdf(_book!);
      } else {
        setState(() => _isLoading = false);
      }

      // Restore progress
      if (isAuth && mounted) {
        final progress = await repo.getProgress(widget.bookId);
        if (mounted &&
            progress.currentPage != null &&
            progress.currentPage! > 1 &&
            _pdfController != null) {
          _pdfController!.animateToPage(
            pageNumber: progress.currentPage!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = true;
          _loadErrorMsg = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _initPdf(BookModel book) async {
    String? contentUrl;

    // Prefer local file if downloaded
    if (widget.isDownloaded && !kIsWeb) {
      final auth = ref.read(authProvider);
      final userId = auth.user?.id;
      if (userId != null) {
        final record = await ref
            .read(booksRepositoryProvider)
            .getDownloadRecord(book.id, userId);
        if (record?.localContentPath != null &&
            await File(record!.localContentPath!).exists()) {
          contentUrl = record.localContentPath!;
        }
      }
    }

    // Fall back to remote URL
    contentUrl ??= book.contentUrl;

    if (contentUrl == null) {
      setState(() {
        _isLoading = false;
        _loadError = true;
        _loadErrorMsg = 'No PDF content available for this book.';
      });
      return;
    }

    try {
      final doc = contentUrl.startsWith('http')
          ? PdfDocument.openData(
              Uri.parse(contentUrl).data?.contentAsBytes() ??
                  await _fetchBytes(contentUrl),
            )
          : PdfDocument.openFile(contentUrl);

      _pdfController = PdfControllerPinch(
        document: doc,
        initialPage: widget.startChapter > 0 ? widget.startChapter : 1,
      );

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = true;
          _loadErrorMsg = 'Could not load PDF: ${e.toString()}';
        });
      }
    }
  }

  /// Downloads bytes from a URL using Dio (fully cross-platform on web, mobile, desktop)
  Future<Uint8List> _fetchBytes(String url) async {
    final dio = Dio();
    final response = await dio.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
    if (response.data == null || response.data!.isEmpty) {
      throw Exception('Empty response received for book PDF');
    }
    return Uint8List.fromList(response.data!);
  }

  @override
  void dispose() {
    _saveProgress();
    _pdfController?.dispose();
    super.dispose();
  }

  void _saveProgress() {
    final auth = ref.read(authProvider);
    if (auth.status != AuthStatus.authenticated) return;
    if (_totalPages == 0) return;

    final percent = (_currentPage / _totalPages * 100).clamp(0.0, 100.0);
    ref.read(progressProvider(widget.bookId).notifier).save(
          currentPage: _currentPage,
          percentComplete: percent,
          isCompleted: _currentPage >= _totalPages,
        );

    // Update last opened timestamp for downloads
    final userId = auth.user?.id;
    if (userId != null) {
      ref
          .read(booksRepositoryProvider)
          .updateLastOpened(widget.bookId, userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = ref.watch(readingPrefsProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Opening book...', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    if (_loadError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reader')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _loadErrorMsg ?? 'Could not open this book',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (!widget.isDownloaded)
                  const Text(
                    'Tip: Download the book for reliable offline reading.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final book = _book;

    // Unsupported formats in Phase 1
    if (book != null &&
        (book.format == BookFormat.epub || book.format == BookFormat.audio)) {
      return _UnsupportedFormatScreen(book: book);
    }

    // Text book reader
    if (book != null && book.format == BookFormat.text) {
      return _TextReaderScreen(book: book, prefs: prefs);
    }

    // PDF reader
    if (_pdfController == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reader')),
        body: const Center(child: Text('No content available')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _uiVisible = !_uiVisible),
        child: Stack(
          children: [
            // PDF viewer
            PdfViewPinch(
              controller: _pdfController!,
              onDocumentLoaded: (doc) {
                setState(() => _totalPages = doc.pagesCount);
              },
              onPageChanged: (page) {
                setState(() => _currentPage = page);
                // Auto-save progress every 5 pages
                if (page % 5 == 0) _saveProgress();
              },
              scrollDirection: prefs.scrollMode == 'continuous'
                  ? Axis.vertical
                  : Axis.horizontal,
              builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(),
                documentLoaderBuilder: (_) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                pageLoaderBuilder: (_) => const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
                errorBuilder: (_, error) => Center(
                  child: Text(error.toString(),
                      style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),

            // Top AppBar overlay
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: _uiVisible ? 0 : -100,
              left: 0,
              right: 0,
              child: _ReaderAppBar(
                bookTitle: book?.title ?? '',
                onClose: () {
                  _saveProgress();
                  context.pop();
                },
              ),
            ),

            // Bottom page indicator
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: _uiVisible ? 0 : -80,
              left: 0,
              right: 0,
              child: _PageIndicatorBar(
                currentPage: _currentPage,
                totalPages: _totalPages,
                onJump: (p) {
                  _pdfController!.animateToPage(
                    pageNumber: p,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _ReaderAppBar extends StatelessWidget {
  final String bookTitle;
  final VoidCallback onClose;
  const _ReaderAppBar({required this.bookTitle, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          bookTitle,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onClose,
        ),
      ),
    );
  }
}

class _PageIndicatorBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onJump;
  const _PageIndicatorBar({
    required this.currentPage,
    required this.totalPages,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages == 0) return const SizedBox.shrink();
    final progress = totalPages > 0 ? currentPage / totalPages : 0.0;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Row(
        children: [
          Text(
            'Page $currentPage',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 2,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: (v) => onJump((v * totalPages).round().clamp(1, totalPages)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'of $totalPages',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TextReaderScreen extends ConsumerWidget {
  final BookModel book;
  final ReadingPrefsState prefs;
  const _TextReaderScreen({required this.book, required this.prefs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = prefs.themeMode == 'dark' ||
        (prefs.themeMode == 'system' &&
            theme.brightness == Brightness.dark);

    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFFFDE7);
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(book.title, style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.text_fields, color: textColor),
            onPressed: () => _showPrefsSheet(context, ref, prefs),
          ),
        ],
      ),
      body: book.description != null
          ? SingleChildScrollView(
              padding: EdgeInsets.all(prefs.pageMargin),
              child: Text(
                book.description!,
                style: TextStyle(
                  color: textColor,
                  fontSize: prefs.fontSize,
                  height: prefs.lineSpacing,
                  fontFamily: prefs.fontFamily == 'default'
                      ? null
                      : prefs.fontFamily,
                ),
              ),
            )
          : Center(
              child: Text(
                'No text content available for this book.',
                style: TextStyle(color: textColor.withValues(alpha: 0.5)),
              ),
            ),
    );
  }

  void _showPrefsSheet(
      BuildContext context, WidgetRef ref, ReadingPrefsState prefs) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _TextPrefsSheet(prefs: prefs),
    );
  }
}

class _TextPrefsSheet extends ConsumerWidget {
  final ReadingPrefsState prefs;
  const _TextPrefsSheet({required this.prefs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reading Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Text('Font size: ${prefs.fontSize.toInt()}pt', style: theme.textTheme.labelMedium),
          Slider(
            value: prefs.fontSize,
            min: 12,
            max: 32,
            divisions: 10,
            onChanged: (v) {
              ref.read(readingPrefsProvider.notifier).update(prefs.copyWith(fontSize: v));
            },
          ),
          Text('Line spacing: ${prefs.lineSpacing.toStringAsFixed(1)}', style: theme.textTheme.labelMedium),
          Slider(
            value: prefs.lineSpacing,
            min: 1.0,
            max: 3.0,
            divisions: 8,
            onChanged: (v) {
              ref.read(readingPrefsProvider.notifier).update(prefs.copyWith(lineSpacing: v));
            },
          ),
          Row(
            children: [
              const Text('Theme: '),
              ...['system', 'light', 'dark'].map((t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: prefs.themeMode == t,
                      onSelected: (_) {
                        ref.read(readingPrefsProvider.notifier).update(prefs.copyWith(themeMode: t));
                      },
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _UnsupportedFormatScreen extends StatelessWidget {
  final BookModel book;
  const _UnsupportedFormatScreen({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                book.format == BookFormat.audio
                    ? Icons.headphones
                    : Icons.import_contacts,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                book.format == BookFormat.audio
                    ? 'Audio Book'
                    : 'EPUB Book',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                book.format == BookFormat.audio
                    ? 'Audio playback support is coming in a future update. '
                        'Download the book now to have it ready when the feature launches.'
                    : 'EPUB reading support is coming in a future update. '
                        'The book content is available and will be accessible once EPUB support is added.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Library'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
