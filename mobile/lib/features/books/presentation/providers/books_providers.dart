// lib/features/books/presentation/providers/books_providers.dart
// All Riverpod providers for the Books feature.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
export 'package:mobile/core/database/app_database.dart' show LocalDownloadedBookData;
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/books_remote_datasource.dart';
import '../../data/repositories/book_download_service.dart';
import '../../data/repositories/books_repository.dart';
import '../../data/models/book_model.dart';
import '../../data/models/book_category_model.dart';
import 'book_download_settings_provider.dart';

// ── Infrastructure ────────────────────────────────────────────────────────

final booksRemoteDatasourceProvider = Provider<BooksRemoteDatasource>((ref) {
  return BooksRemoteDatasource(ref.watch(apiClientProvider));
});

final bookDownloadServiceProvider = Provider<BookDownloadService>((ref) {
  return BookDownloadService(
    ref.watch(apiClientProvider),
    ref.watch(appDatabaseProvider),
  );
});

final booksRepositoryProvider = Provider<BooksRepository>((ref) {
  return BooksRepository(
    remote: ref.watch(booksRemoteDatasourceProvider),
    downloader: ref.watch(bookDownloadServiceProvider),
    db: ref.watch(appDatabaseProvider),
  );
});

// ── Categories ─────────────────────────────────────────────────────────────

final bookCategoriesProvider =
    FutureProvider<List<BookCategoryModel>>((ref) async {
  return ref.watch(booksRepositoryProvider).getCategories();
});

// ── Library state ──────────────────────────────────────────────────────────

class LibraryFilter {
  final String? categoryId;
  final String? search;
  final String? format;
  final String? language;
  final String sortBy;
  final String sortDir;
  final String downloadFilter; // 'all' | 'downloaded' | 'notDownloaded'

  const LibraryFilter({
    this.categoryId,
    this.search,
    this.format,
    this.language,
    this.sortBy = 'sortOrder',
    this.sortDir = 'asc',
    this.downloadFilter = 'all',
  });

  LibraryFilter copyWith({
    String? categoryId,
    bool clearCategory = false,
    String? search,
    String? format,
    bool clearFormat = false,
    String? language,
    bool clearLanguage = false,
    String? sortBy,
    String? sortDir,
    String? downloadFilter,
  }) {
    return LibraryFilter(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      search: search ?? this.search,
      format: clearFormat ? null : (format ?? this.format),
      language: clearLanguage ? null : (language ?? this.language),
      sortBy: sortBy ?? this.sortBy,
      sortDir: sortDir ?? this.sortDir,
      downloadFilter: downloadFilter ?? this.downloadFilter,
    );
  }

  LibraryFilter clearSearch() => LibraryFilter(
        categoryId: categoryId,
        format: format,
        language: language,
        sortBy: sortBy,
        sortDir: sortDir,
        downloadFilter: downloadFilter,
      );
}

class LibraryState {
  final List<BookModel> books;
  final int total;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final LibraryFilter filter;

  const LibraryState({
    this.books = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.filter = const LibraryFilter(),
  });

  LibraryState copyWith({
    List<BookModel>? books,
    int? total,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    LibraryFilter? filter,
    bool clearError = false,
  }) {
    return LibraryState(
      books: books ?? this.books,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      filter: filter ?? this.filter,
    );
  }
}

class LibraryNotifier extends StateNotifier<LibraryState> {
  final BooksRepository _repo;

  LibraryNotifier(this._repo) : super(const LibraryState()) {
    load();
  }

  Future<void> load({bool reset = true}) async {
    if (state.isLoading) return;
    if (reset) {
      state = state.copyWith(isLoading: true, clearError: true, page: 1);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final page = reset ? 1 : state.page + 1;
      final result = await _repo.getBooks(
        search: state.filter.search,
        categoryId: state.filter.categoryId,
        format: state.filter.format,
        language: state.filter.language,
        page: page,
        sortBy: state.filter.sortBy,
        sortDir: state.filter.sortDir,
      );

      state = state.copyWith(
        books: reset ? result.items : [...state.books, ...result.items],
        total: result.total,
        page: page,
        hasMore: result.hasNext,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    await load(reset: false);
  }

  Future<void> applyFilter(LibraryFilter filter) async {
    state = state.copyWith(filter: filter);
    await load();
  }

  Future<void> search(String query) async {
    final newFilter = query.isEmpty
        ? state.filter.clearSearch()
        : state.filter.copyWith(search: query);
    state = state.copyWith(filter: newFilter);
    await load();
  }

  void refresh() => load();
}

final libraryProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier(ref.watch(booksRepositoryProvider));
});

// ── Book detail ─────────────────────────────────────────────────────────────

final bookDetailProvider =
    FutureProvider.family<BookModel, String>((ref, id) async {
  final auth = ref.watch(authProvider);
  final isAuth = auth.status == AuthStatus.authenticated;
  final userId = auth.user?.id;
  return ref
      .watch(booksRepositoryProvider)
      .getBook(id, authenticated: isAuth, userId: userId);
});

// ── Reading progress ─────────────────────────────────────────────────────────

class ProgressNotifier extends StateNotifier<AsyncValue<ReadingProgressModel?>> {
  final BooksRepository _repo;
  final String _bookId;

  ProgressNotifier(this._repo, this._bookId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _repo.getProgress(_bookId);
      state = AsyncValue.data(p);
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> save({
    int? currentPage,
    int? currentChapter,
    double? scrollOffset,
    double? percentComplete,
    bool? isCompleted,
  }) async {
    try {
      final updated = await _repo.saveProgress(_bookId, {
        'currentPage': ?currentPage,
        'currentChapter': ?currentChapter,
        'scrollOffset': ?scrollOffset,
        'percentComplete': ?percentComplete,
        'isCompleted': ?isCompleted,
      });
      state = AsyncValue.data(updated);
    } catch (_) {
      // Don't surface progress-save errors to the user — they're non-critical
    }
  }
}

final progressProvider = StateNotifierProvider.family<ProgressNotifier,
    AsyncValue<ReadingProgressModel?>, String>((ref, bookId) {
  return ProgressNotifier(ref.watch(booksRepositoryProvider), bookId);
});

// ── Downloads ─────────────────────────────────────────────────────────────────

class DownloadState {
  final Map<String, double> activeProgress; // bookId → 0.0–1.0
  final Map<String, String> errors; // bookId → message
  final Map<String, DownloadResult> lastResults; // bookId → DownloadResult

  const DownloadState({
    this.activeProgress = const {},
    this.errors = const {},
    this.lastResults = const {},
  });

  DownloadState copyWith({
    Map<String, double>? activeProgress,
    Map<String, String>? errors,
    Map<String, DownloadResult>? lastResults,
  }) {
    return DownloadState(
      activeProgress: activeProgress ?? this.activeProgress,
      errors: errors ?? this.errors,
      lastResults: lastResults ?? this.lastResults,
    );
  }
}

class DownloadsNotifier extends StateNotifier<DownloadState> {
  final BooksRepository _repo;
  final Ref? _ref;

  DownloadsNotifier(this._repo, [this._ref]) : super(const DownloadState());

  Future<DownloadResult?> startDownload(
    BookModel book,
    String userId, {
    BookDownloadDestination? overrideDestination,
  }) async {
    if (_repo.isActiveDownload(book.id)) return null;

    // First get download info from backend
    Map<String, dynamic> info;
    try {
      info = await _repo.getDownloadInfo(book.id);
    } catch (e) {
      state = DownloadState(
        activeProgress: state.activeProgress,
        errors: {
          ...state.errors,
          book.id: 'Cannot start download: ${e.toString()}',
        },
        lastResults: state.lastResults,
      );
      return null;
    }

    final contentUrl = info['contentFile']?['url'] as String?;
    if (contentUrl == null) {
      state = DownloadState(
        activeProgress: state.activeProgress,
        errors: {
          ...state.errors,
          book.id: 'No downloadable content available for this book',
        },
        lastResults: state.lastResults,
      );
      return null;
    }

    final mimeType = info['contentFile']?['mimeType'] as String?;
    final fileSize = (info['contentFile']?['fileSize'] as num?)?.toInt();

    final destination = overrideDestination ??
        _ref?.read(bookDownloadSettingsProvider).setting.destination ??
        BookDownloadDestination.inApp;

    // Set initial progress
    state = DownloadState(
      activeProgress: {...state.activeProgress, book.id: 0.0},
      errors: Map.from(state.errors)..remove(book.id),
      lastResults: Map.from(state.lastResults)..remove(book.id),
    );

    final result = await _repo.startDownload(
      book: book,
      userId: userId,
      contentUrl: contentUrl,
      destination: destination,
      mimeType: mimeType,
      expectedBytes: fileSize,
      onProgress: (progress, _) {
        if (mounted) {
          state = DownloadState(
            activeProgress: {...state.activeProgress, book.id: progress},
            errors: state.errors,
            lastResults: state.lastResults,
          );
        }
      },
    );

    if (!mounted) return result;

    // Remove from active
    final newActive = Map<String, double>.from(state.activeProgress)
      ..remove(book.id);
    final newResults = Map<String, DownloadResult>.from(state.lastResults)
      ..[book.id] = result;

    if (result.success) {
      state = DownloadState(
        activeProgress: newActive,
        errors: state.errors,
        lastResults: newResults,
      );
      _ref?.invalidate(isBookDownloadedProvider(book.id));
      _ref?.invalidate(downloadedBooksStreamProvider);
      _ref?.invalidate(allDownloadsStreamProvider);
    } else {
      state = DownloadState(
        activeProgress: newActive,
        errors: {...state.errors, book.id: result.error ?? 'Download failed'},
        lastResults: newResults,
      );
    }

    return result;
  }

  /// Retries exporting in-app download to user device Downloads directory without re-downloading
  Future<DownloadResult> exportInAppToDevice(BookModel book, String userId) async {
    final result = await _repo.exportInAppToDevice(book: book, userId: userId);
    if (mounted) {
      final newResults = Map<String, DownloadResult>.from(state.lastResults)
        ..[book.id] = result;
      if (result.success) {
        final errs = Map<String, String>.from(state.errors)..remove(book.id);
        state = DownloadState(
          activeProgress: state.activeProgress,
          errors: errs,
          lastResults: newResults,
        );
        _ref?.invalidate(isBookDownloadedProvider(book.id));
        _ref?.invalidate(downloadedBooksStreamProvider);
        _ref?.invalidate(allDownloadsStreamProvider);
      } else {
        state = DownloadState(
          activeProgress: state.activeProgress,
          errors: {
            ...state.errors,
            book.id: result.error ?? 'Export to device failed',
          },
          lastResults: newResults,
        );
      }
    }
    return result;
  }

  Future<void> cancelDownload(String bookId, String userId) async {
    await _repo.cancelDownload(bookId, userId);
    final newActive = Map<String, double>.from(state.activeProgress)
      ..remove(bookId);
    state = DownloadState(
      activeProgress: newActive,
      errors: state.errors,
      lastResults: state.lastResults,
    );
  }

  Future<void> removeDownload(String bookId, String userId) async {
    await _repo.removeDownload(bookId, userId);
    final newResults = Map<String, DownloadResult>.from(state.lastResults)
      ..remove(bookId);
    state = DownloadState(
      activeProgress: state.activeProgress,
      errors: state.errors,
      lastResults: newResults,
    );
    _ref?.invalidate(isBookDownloadedProvider(bookId));
    _ref?.invalidate(downloadedBooksStreamProvider);
    _ref?.invalidate(allDownloadsStreamProvider);
  }

  void clearError(String bookId) {
    final errs = Map<String, String>.from(state.errors)..remove(bookId);
    state = DownloadState(
      activeProgress: state.activeProgress,
      errors: errs,
      lastResults: state.lastResults,
    );
  }
}

final downloadsNotifierProvider =
    StateNotifierProvider<DownloadsNotifier, DownloadState>((ref) {
  return DownloadsNotifier(ref.watch(booksRepositoryProvider), ref);
});

/// Stream of all completed downloads for current user
final downloadedBooksStreamProvider =
    StreamProvider<List<LocalDownloadedBookData>>((ref) {
  final userId = ref.watch(authProvider).user?.id ?? 'guest';
  return ref.watch(booksRepositoryProvider).watchDownloads(userId);
});

/// Stream of ALL download records (any status) for current user
final allDownloadsStreamProvider =
    StreamProvider<List<LocalDownloadedBookData>>((ref) {
  final userId = ref.watch(authProvider).user?.id ?? 'guest';
  return ref.watch(booksRepositoryProvider).watchAllDownloads(userId);
});

/// Quick lookup: is a specific book downloaded for the current user?
final isBookDownloadedProvider =
    FutureProvider.family<bool, String>((ref, bookId) async {
  final userId = ref.watch(authProvider).user?.id ?? 'guest';
  return ref.watch(booksRepositoryProvider).isDownloaded(bookId, userId);
});

// ── Bookmarks ─────────────────────────────────────────────────────────────

final bookBookmarksProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, bookId) {
  return ref.watch(booksRepositoryProvider).getBookmarks(bookId: bookId);
});

// ── Reading preferences ────────────────────────────────────────────────────

class ReadingPrefsState {
  final double fontSize;
  final double lineSpacing;
  final String fontFamily;
  final String textAlign;
  final String themeMode;
  final double pageMargin;
  final String scrollMode;
  final bool gridView;
  final String sortBy;
  final bool sortAsc;

  const ReadingPrefsState({
    this.fontSize = 16,
    this.lineSpacing = 1.5,
    this.fontFamily = 'default',
    this.textAlign = 'left',
    this.themeMode = 'system',
    this.pageMargin = 16,
    this.scrollMode = 'continuous',
    this.gridView = true,
    this.sortBy = 'title',
    this.sortAsc = true,
  });

  ReadingPrefsState copyWith({
    double? fontSize,
    double? lineSpacing,
    String? fontFamily,
    String? textAlign,
    String? themeMode,
    double? pageMargin,
    String? scrollMode,
    bool? gridView,
    String? sortBy,
    bool? sortAsc,
  }) {
    return ReadingPrefsState(
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      fontFamily: fontFamily ?? this.fontFamily,
      textAlign: textAlign ?? this.textAlign,
      themeMode: themeMode ?? this.themeMode,
      pageMargin: pageMargin ?? this.pageMargin,
      scrollMode: scrollMode ?? this.scrollMode,
      gridView: gridView ?? this.gridView,
      sortBy: sortBy ?? this.sortBy,
      sortAsc: sortAsc ?? this.sortAsc,
    );
  }

  factory ReadingPrefsState.fromMap(Map<String, dynamic> m) {
    return ReadingPrefsState(
      fontSize: (m['fontSize'] as num?)?.toDouble() ?? 16,
      lineSpacing: (m['lineSpacing'] as num?)?.toDouble() ?? 1.5,
      fontFamily: m['fontFamily'] as String? ?? 'default',
      textAlign: m['textAlign'] as String? ?? 'left',
      themeMode: m['themeMode'] as String? ?? 'system',
      pageMargin: (m['pageMargin'] as num?)?.toDouble() ?? 16,
      scrollMode: m['scrollMode'] as String? ?? 'continuous',
      gridView: m['gridView'] as bool? ?? true,
      sortBy: m['sortBy'] as String? ?? 'title',
      sortAsc: m['sortAsc'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'fontSize': fontSize,
        'lineSpacing': lineSpacing,
        'fontFamily': fontFamily,
        'textAlign': textAlign,
        'themeMode': themeMode,
        'pageMargin': pageMargin,
        'scrollMode': scrollMode,
        'gridView': gridView,
        'sortBy': sortBy,
        'sortAsc': sortAsc,
      };
}

class ReadingPrefsNotifier extends StateNotifier<ReadingPrefsState> {
  final BooksRepository _repo;

  ReadingPrefsNotifier(this._repo) : super(const ReadingPrefsState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repo.getReadingPrefs();
      state = ReadingPrefsState.fromMap(data);
    } catch (_) {}
  }

  Future<void> update(ReadingPrefsState newPrefs) async {
    state = newPrefs;
    try {
      await _repo.saveReadingPrefs(newPrefs.toMap());
    } catch (_) {
      // Best-effort — local state already updated
    }
  }
}

final readingPrefsProvider =
    StateNotifierProvider<ReadingPrefsNotifier, ReadingPrefsState>((ref) {
  return ReadingPrefsNotifier(ref.watch(booksRepositoryProvider));
});
