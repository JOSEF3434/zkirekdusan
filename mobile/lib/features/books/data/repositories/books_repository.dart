// lib/features/books/data/repositories/books_repository.dart
import 'dart:async';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/daos/downloaded_books_dao.dart';
import '../datasources/books_remote_datasource.dart';
import '../models/book_model.dart';
import '../models/book_category_model.dart';
import '../models/book_download_setting_model.dart';
import 'package:open_filex/open_filex.dart';
import 'book_download_service.dart';

class BooksRepository {
  final BooksRemoteDatasource _remote;
  final BookDownloadService _downloader;
  final AppDatabase _db;

  BooksRepository({
    required BooksRemoteDatasource remote,
    required BookDownloadService downloader,
    required AppDatabase db,
  })  : _remote = remote,
        _downloader = downloader,
        _db = db;

  DownloadedBooksDao get _downloadDao => _db.downloadedBooksDao;

  // ── Categories ─────────────────────────────────────────────────────────

  Future<List<BookCategoryModel>> getCategories() =>
      _remote.fetchCategories();

  // ── Books ───────────────────────────────────────────────────────────────

  Future<PaginatedBooks> getBooks({
    String? search,
    String? categoryId,
    String? format,
    String? language,
    String? tag,
    int page = 1,
    int limit = 20,
    String sortBy = 'sortOrder',
    String sortDir = 'asc',
  }) =>
      _remote.fetchBooks(
        search: search,
        categoryId: categoryId,
        format: format,
        language: language,
        tag: tag,
        page: page,
        limit: limit,
        sortBy: sortBy,
        sortDir: sortDir,
      );

  Future<BookModel> getBook(String id, {bool authenticated = false}) =>
      _remote.fetchBook(id, authenticated: authenticated);

  Future<List<BookChapterModel>> getChapters(String bookId) =>
      _remote.fetchChapters(bookId);

  Future<BookChapterModel> getChapterContent(String bookId, int order) =>
      _remote.fetchChapterContent(bookId, order);

  // ── Progress ────────────────────────────────────────────────────────────

  Future<ReadingProgressModel> getProgress(String bookId) =>
      _remote.fetchProgress(bookId);

  Future<ReadingProgressModel> saveProgress(
      String bookId, Map<String, dynamic> data) =>
      _remote.saveProgress(bookId, data);

  Future<List<BookModel>> getRecentlyRead({int limit = 10}) =>
      _remote.fetchRecentlyRead(limit: limit);

  // ── Bookmarks ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getBookmarks({String? bookId}) =>
      _remote.fetchBookmarks(bookId: bookId);

  Future<Map<String, dynamic>> createBookmark(
      String bookId, Map<String, dynamic> data) =>
      _remote.createBookmark(bookId, data);

  Future<void> deleteBookmark(String bookmarkId) =>
      _remote.deleteBookmark(bookmarkId);

  // ── Reading Preferences ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> getReadingPrefs() =>
      _remote.fetchReadingPrefs();

  Future<Map<String, dynamic>> saveReadingPrefs(Map<String, dynamic> data) =>
      _remote.saveReadingPrefs(data);

  // ── Downloads ──────────────────────────────────────────────────────────

  /// Gets download info (content URLs, file sizes) from backend
  Future<Map<String, dynamic>> getDownloadInfo(String bookId) =>
      _remote.fetchDownloadInfo(bookId);

  /// Starts a download. Returns a `Future<DownloadResult>`.
  Future<DownloadResult> startDownload({
    required BookModel book,
    required String userId,
    required String contentUrl,
    BookDownloadDestination destination = BookDownloadDestination.inApp,
    String? mimeType,
    int? expectedBytes,
    void Function(double progress, int downloaded)? onProgress,
  }) =>
      _downloader.downloadBook(
        book: book,
        userId: userId,
        contentUrl: contentUrl,
        destination: destination,
        mimeType: mimeType,
        expectedBytes: expectedBytes,
        onProgress: onProgress,
      );

  Future<DownloadResult> exportInAppToDevice({
    required BookModel book,
    required String userId,
  }) =>
      _downloader.exportInAppToDevice(book, userId);

  Future<bool> openDownloadedFile({
    required BookModel book,
    required String userId,
    String? preferredPath,
  }) async {
    String? path = preferredPath;
    if (path == null) {
      final rec = await _downloadDao.getRecord(book.id, userId);
      path = rec?.localContentPath;
    }
    if (path != null) {
      final res = await BookDownloadService.openDownloadedFile(path);
      return res.type == ResultType.done;
    }
    return false;
  }

  Future<void> shareDownloadedFile({
    required BookModel book,
    required String userId,
    String? preferredPath,
  }) async {
    String? path = preferredPath;
    if (path == null) {
      final rec = await _downloadDao.getRecord(book.id, userId);
      path = rec?.localContentPath;
    }
    if (path != null) {
      await BookDownloadService.shareDownloadedFile(path, subject: book.title);
    }
  }

  Future<void> cancelDownload(String bookId, String userId) =>
      _downloader.cancelDownload(bookId, userId);

  Future<void> removeDownload(String bookId, String userId) =>
      _downloader.removeDownload(bookId, userId);

  Future<bool> verifyDownload(String bookId, String userId) =>
      _downloader.verifyDownload(bookId, userId);

  bool isActiveDownload(String bookId) => _downloader.isActiveDownload(bookId);

  // ── Local DB queries ────────────────────────────────────────────────────

  Stream<List<LocalDownloadedBookData>> watchDownloads(String userId) =>
      _downloadDao.watchDownloaded(userId);

  Stream<List<LocalDownloadedBookData>> watchAllDownloads(String userId) =>
      _downloadDao.watchAll(userId);

  Stream<List<LocalDownloadedBookData>> watchActiveDownloads(String userId) =>
      _downloadDao.watchActive(userId);

  Future<LocalDownloadedBookData?> getDownloadRecord(
          String bookId, String userId) =>
      _downloadDao.getRecord(bookId, userId);

  Future<bool> isDownloaded(String bookId, String userId) =>
      _downloadDao.isDownloaded(bookId, userId);

  Future<void> updateLastOpened(String bookId, String userId) =>
      _downloadDao.updateLastOpened(bookId, userId);

  // ── Admin Book Management ───────────────────────────────────────────────

  Future<PaginatedBooks> getAdminBooks({
    String? search,
    String? categoryId,
    String? format,
    String? language,
    String? status,
    int page = 1,
    int limit = 20,
    String sortBy = 'updatedAt',
    String sortDir = 'desc',
  }) =>
      _remote.fetchAdminBooks(
        search: search,
        categoryId: categoryId,
        format: format,
        language: language,
        status: status,
        page: page,
        limit: limit,
        sortBy: sortBy,
        sortDir: sortDir,
      );

  Future<BookModel> createBook(Map<String, dynamic> data) =>
      _remote.createBook(data);

  Future<BookModel> updateBook(String id, Map<String, dynamic> data) =>
      _remote.updateBook(id, data);

  Future<void> deleteBook(String id, {bool permanent = false}) =>
      _remote.deleteBook(id, permanent: permanent);

  Future<BookModel> publishBook(String id) => _remote.publishBook(id);

  Future<BookModel> unpublishBook(String id) => _remote.unpublishBook(id);

  Future<BookModel> archiveBook(String id) => _remote.archiveBook(id);

  Future<BookModel> restoreBook(String id) => _remote.restoreBook(id);

  Future<Map<String, dynamic>> uploadBookCover({
    required List<int> bytes,
    required String filename,
  }) =>
      _remote.uploadBookCover(bytes: bytes, filename: filename);

  Future<Map<String, dynamic>> uploadBookContent({
    required List<int> bytes,
    required String filename,
    void Function(int count, int total)? onProgress,
  }) =>
      _remote.uploadBookContent(
        bytes: bytes,
        filename: filename,
        onProgress: onProgress,
      );

  // ── Admin Category Management ───────────────────────────────────────────

  Future<List<BookCategoryModel>> getAdminCategories({
    bool includeArchived = true,
  }) =>
      _remote.fetchAdminCategories(includeArchived: includeArchived);

  Future<BookCategoryModel> createCategory(Map<String, dynamic> data) =>
      _remote.createCategory(data);

  Future<BookCategoryModel> updateCategory(
          String id, Map<String, dynamic> data) =>
      _remote.updateCategory(id, data);

  Future<void> deleteCategory(String id, {String? reassignCategoryId}) async =>
      _remote.deleteCategory(id, reassignCategoryId: reassignCategoryId);

  // ── Download Destination Settings ───────────────────────────────────────

  Future<BookDownloadSettingModel> getDownloadDestinationSetting() =>
      _remote.fetchDownloadDestination();

  Future<BookDownloadSettingModel> updateDownloadDestinationSetting(
    String destination, {
    String? description,
  }) =>
      _remote.updateDownloadDestination(destination, description: description);

  // ── Multi-Media Attachments ─────────────────────────────────────────────

  Future<Map<String, dynamic>> uploadBookAttachment({
    required List<int> bytes,
    required String filename,
    void Function(int count, int total)? onProgress,
  }) =>
      _remote.uploadBookAttachment(
        bytes: bytes,
        filename: filename,
        onProgress: onProgress,
      );
}
