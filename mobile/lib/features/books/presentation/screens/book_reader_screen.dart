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
import '../../data/repositories/books_repository.dart';
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

class _BookReaderScreenState extends ConsumerState<BookReaderScreen>
    with WidgetsBindingObserver {
  PdfControllerPinch? _pdfController;
  bool _uiVisible = true;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _loadError = false;
  String? _loadErrorMsg;
  bool _isLoading = true;
  BookModel? _book;
  bool _isVertical = true;
  bool _fitToPage = true;

  // Cached dependencies & state for lifecycle-safe progress saving
  ProgressNotifier? _progressNotifier;
  BooksRepository? _booksRepository;
  String? _currentUserId;
  bool _isAuthenticated = false;
  int? _lastSavedPage;
  int? _lastSavedTotalPages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _captureDependencies();
  }

  void _captureDependencies() {
    if (!mounted) return;
    try {
      final auth = ref.read(authProvider);
      _isAuthenticated = auth.status == AuthStatus.authenticated;
      _currentUserId = auth.user?.id;
      _progressNotifier = ref.read(progressProvider(widget.bookId).notifier);
      _booksRepository = ref.read(booksRepositoryProvider);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _flushFinalProgress();
    }
  }

  Future<void> _initialize() async {
    _captureDependencies();
    final isAuth = _isAuthenticated;

    try {
      final BooksRepository repo =
          _booksRepository ?? ref.read(booksRepositoryProvider);
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
      if (!mounted) return;
      final userId = _currentUserId;
      final repo = _booksRepository;
      if (userId != null && repo != null) {
        final record = await repo.getDownloadRecord(book.id, userId);
        if (record?.localContentPath != null &&
            await File(record!.localContentPath!).exists()) {
          contentUrl = record.localContentPath!;
        }
      }
    }

    // Fall back to remote URL
    contentUrl ??= book.contentUrl;

    if (contentUrl == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = true;
          _loadErrorMsg = 'No PDF content available for this book.';
        });
      }
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
    WidgetsBinding.instance.removeObserver(this);
    // Lifecycle-safe flush: uses captured notifier/repo and does NOT access ref
    _flushFinalProgress();
    _pdfController?.dispose();
    super.dispose();
  }

  void _saveProgress() {
    _flushFinalProgress();
  }

  void _flushFinalProgress() {
    if (!_isAuthenticated) return;
    if (_totalPages == 0) return;
    if (_lastSavedPage == _currentPage && _lastSavedTotalPages == _totalPages) {
      return;
    }

    final page = _currentPage;
    final total = _totalPages;
    final percent = (page / total * 100).clamp(0.0, 100.0);
    final isCompleted = page >= total;
    final notifier = _progressNotifier;
    final repo = _booksRepository;
    final userId = _currentUserId;

    _lastSavedPage = page;
    _lastSavedTotalPages = total;

    if (notifier != null) {
      try {
        notifier.save(
          currentPage: page,
          percentComplete: percent,
          isCompleted: isCompleted,
        );
      } catch (e) {
        debugPrint('[BookReaderScreen] Failed to save progress: $e');
      }
    }

    if (repo != null && userId != null) {
      try {
        repo.updateLastOpened(widget.bookId, userId);
      } catch (e) {
        debugPrint('[BookReaderScreen] Failed to update last opened: $e');
      }
    }
  }

  void _handleDownload() {
    if (_book == null) return;
    final isDownloadedAsync = ref.read(isBookDownloadedProvider(widget.bookId));
    final isDownloaded = widget.isDownloaded || (isDownloadedAsync.valueOrNull ?? false);
    if (isDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${_book!.title}" is downloaded and available offline.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    final userId = _currentUserId ?? 'guest';
    ref.read(downloadsNotifierProvider.notifier).startDownload(_book!, userId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "${_book!.title}" for offline reading...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _captureDependencies();
    final theme = Theme.of(context);
    final prefs = ref.watch(readingPrefsProvider);
    final isDownloadedAsync = ref.watch(isBookDownloadedProvider(widget.bookId));
    final isDownloaded =
        widget.isDownloaded || (isDownloadedAsync.valueOrNull ?? false);
    final downloadState = ref.watch(downloadsNotifierProvider);
    final isDownloading = downloadState.activeProgress.containsKey(widget.bookId);
    final downloadProgress = downloadState.activeProgress[widget.bookId] ?? 0.0;

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

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _flushFinalProgress();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => setState(() => _uiVisible = !_uiVisible),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              // On desktop/web wide screens, constrain width so the full page height fits vertically on screen
              final double? maxPageWidth = (isWide && _fitToPage)
                  ? (constraints.maxHeight * 0.72).clamp(420.0, 850.0)
                  : null;

              return Stack(
                children: [
                  // PDF viewer centered and properly scaled on wide screens
                  Center(
                    child: SizedBox(
                      width: maxPageWidth ?? double.infinity,
                      height: double.infinity,
                      child: PdfViewPinch(
                        controller: _pdfController!,
                        onDocumentLoaded: (doc) {
                          setState(() => _totalPages = doc.pagesCount);
                        },
                        onPageChanged: (page) {
                          setState(() => _currentPage = page);
                          // Auto-save progress every 5 pages
                          if (page % 5 == 0) _saveProgress();
                        },
                        scrollDirection:
                            _isVertical ? Axis.vertical : Axis.horizontal,
                        backgroundDecoration:
                            const BoxDecoration(color: Colors.black),
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
                      isVertical: _isVertical,
                      isFitToPage: _fitToPage,
                      showFitToggle: isWide,
                      isDownloaded: isDownloaded,
                      isDownloading: isDownloading,
                      downloadProgress: downloadProgress,
                      onDownload: _handleDownload,
                      onToggleScroll: () =>
                          setState(() => _isVertical = !_isVertical),
                      onToggleFit: () =>
                          setState(() => _fitToPage = !_fitToPage),
                      onClose: () {
                        _flushFinalProgress();
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
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _ReaderAppBar extends StatelessWidget {
  final String bookTitle;
  final bool isVertical;
  final bool isFitToPage;
  final bool showFitToggle;
  final bool isDownloaded;
  final bool isDownloading;
  final double downloadProgress;
  final VoidCallback onDownload;
  final VoidCallback onToggleScroll;
  final VoidCallback onToggleFit;
  final VoidCallback onClose;

  const _ReaderAppBar({
    required this.bookTitle,
    required this.isVertical,
    required this.isFitToPage,
    required this.showFitToggle,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    required this.onDownload,
    required this.onToggleScroll,
    required this.onToggleFit,
    required this.onClose,
  });

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
        actions: [
          // Download / Offline action button: changes before and after download
          if (isDownloading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    value: downloadProgress > 0 ? downloadProgress : null,
                    strokeWidth: 2,
                    color: const Color(0xFF38BDF8),
                  ),
                ),
              ),
            )
          else if (isDownloaded)
            IconButton(
              icon: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF059669),
              ),
              tooltip: 'Downloaded • Available Offline',
              onPressed: onDownload,
            )
          else
            IconButton(
              icon: const Icon(
                Icons.cloud_download_outlined,
                color: Color(0xFF38BDF8),
              ),
              tooltip: 'Download for offline reading',
              onPressed: onDownload,
            ),
          IconButton(
            icon: Icon(
              isVertical ? Icons.swap_vert_rounded : Icons.swap_horiz_rounded,
              color: Colors.white,
            ),
            tooltip: isVertical
                ? 'Vertical scroll (click for horizontal)'
                : 'Horizontal swipe (click for vertical)',
            onPressed: onToggleScroll,
          ),
          if (showFitToggle)
            IconButton(
              icon: Icon(
                isFitToPage ? Icons.fit_screen_rounded : Icons.fullscreen_rounded,
                color: Colors.white,
              ),
              tooltip: isFitToPage
                  ? 'Fit page (click for full width)'
                  : 'Full width (click to fit page)',
              onPressed: onToggleFit,
            ),
          const SizedBox(width: 8),
        ],
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

    final isDownloadedAsync = ref.watch(isBookDownloadedProvider(book.id));
    final isDownloaded = isDownloadedAsync.valueOrNull ?? false;
    final downloadState = ref.watch(downloadsNotifierProvider);
    final isDownloading = downloadState.activeProgress.containsKey(book.id);
    final downloadProgress = downloadState.activeProgress[book.id] ?? 0.0;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text(book.title, style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
        actions: [
          if (isDownloading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    value: downloadProgress > 0 ? downloadProgress : null,
                    strokeWidth: 2,
                    color: const Color(0xFF38BDF8),
                  ),
                ),
              ),
            )
          else if (isDownloaded)
            IconButton(
              icon: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF059669)),
              tooltip: 'Downloaded • Available Offline',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '"${book.title}" is downloaded for offline reading.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.cloud_download_outlined,
                  color: Color(0xFF0284C7)),
              tooltip: 'Download for offline reading',
              onPressed: () {
                final userId = ref.read(authProvider).user?.id ?? 'guest';
                ref
                    .read(downloadsNotifierProvider.notifier)
                    .startDownload(book, userId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Downloading "${book.title}" for offline reading...'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
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
