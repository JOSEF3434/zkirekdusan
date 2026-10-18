// lib/features/books/data/datasources/books_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:mobile/core/network/api_client.dart';
import '../models/book_model.dart';
import '../models/book_category_model.dart';

class BooksRemoteDatasource {
  final Dio _dio;

  BooksRemoteDatasource(this._dio);

  // ── Categories ─────────────────────────────────────────────────────────

  Future<List<BookCategoryModel>> fetchCategories() async {
    final res = await _dio.get('/books/categories');
    final list = parseEnvelopeList(res.data);
    return list
        .map((c) => BookCategoryModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // ── Books ───────────────────────────────────────────────────────────────

  Future<PaginatedBooks> fetchBooks({
    String? search,
    String? categoryId,
    String? format,
    String? language,
    String? tag,
    int page = 1,
    int limit = 20,
    String sortBy = 'sortOrder',
    String sortDir = 'asc',
  }) async {
    final res = await _dio.get('/books', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'categoryId': ?categoryId,
      'format': ?format,
      'language': ?language,
      'tag': ?tag,
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortDir': sortDir,
    });
    return PaginatedBooks.fromJson(parseEnvelope(res.data));
  }

  Future<BookModel> fetchBook(String id, {bool authenticated = false}) async {
    final endpoint = authenticated ? '/books/$id/with-auth' : '/books/$id';
    final res = await _dio.get(endpoint);
    return BookModel.fromJson(parseEnvelope(res.data));
  }

  Future<List<BookChapterModel>> fetchChapters(String bookId) async {
    final res = await _dio.get('/books/$bookId/chapters');
    final list = parseEnvelopeList(res.data);
    return list
        .map((c) => BookChapterModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<BookChapterModel> fetchChapterContent(
      String bookId, int order) async {
    final res = await _dio.get('/books/$bookId/chapters/$order');
    return BookChapterModel.fromJson(parseEnvelope(res.data));
  }

  // ── Reading Progress ────────────────────────────────────────────────────

  Future<ReadingProgressModel> fetchProgress(String bookId) async {
    final res = await _dio.get('/books/$bookId/progress');
    return ReadingProgressModel.fromJson(parseEnvelope(res.data));
  }

  Future<ReadingProgressModel> saveProgress(
      String bookId, Map<String, dynamic> data) async {
    final res = await _dio.post('/books/$bookId/progress', data: data);
    return ReadingProgressModel.fromJson(parseEnvelope(res.data));
  }

  Future<List<BookModel>> fetchRecentlyRead({int limit = 10}) async {
    final res = await _dio.get('/books/me/recently-read',
        queryParameters: {'limit': limit});
    final list = parseEnvelopeList(res.data);
    // Response is {book: {...}, percentComplete, ...}
    return list.map((item) {
      final m = item as Map<String, dynamic>;
      final bookData = m['book'] as Map<String, dynamic>? ?? m;
      return BookModel.fromJson(bookData);
    }).toList();
  }

  // ── Bookmarks ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchBookmarks({String? bookId}) async {
    final res = await _dio.get('/books/me/bookmarks',
        queryParameters: {'bookId': ?bookId});
    return parseEnvelopeList(res.data).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createBookmark(
      String bookId, Map<String, dynamic> data) async {
    final res = await _dio.post('/books/$bookId/bookmarks', data: data);
    return parseEnvelope(res.data);
  }

  Future<void> deleteBookmark(String bookmarkId) async {
    await _dio.delete('/books/bookmarks/$bookmarkId');
  }

  // ── Reading Preferences ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchReadingPrefs() async {
    final res = await _dio.get('/books/me/preferences');
    return parseEnvelope(res.data);
  }

  Future<Map<String, dynamic>> saveReadingPrefs(
      Map<String, dynamic> data) async {
    final res = await _dio.post('/books/me/preferences', data: data);
    return parseEnvelope(res.data);
  }

  // ── Download info ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchDownloadInfo(String bookId) async {
    final res = await _dio.get('/books/$bookId/download-info');
    return parseEnvelope(res.data);
  }

  // ── Admin Book Management ───────────────────────────────────────────────

  Future<PaginatedBooks> fetchAdminBooks({
    String? search,
    String? categoryId,
    String? format,
    String? language,
    String? status,
    int page = 1,
    int limit = 20,
    String sortBy = 'updatedAt',
    String sortDir = 'desc',
  }) async {
    final res = await _dio.get('/books/admin/list', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'categoryId': ?categoryId,
      'format': ?format,
      'language': ?language,
      'status': ?status,
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortDir': sortDir,
    });
    return PaginatedBooks.fromJson(parseEnvelope(res.data));
  }

  Future<BookModel> createBook(Map<String, dynamic> data) async {
    final res = await _dio.post('/books/admin', data: data);
    return BookModel.fromJson(parseEnvelope(res.data));
  }

  Future<BookModel> updateBook(String id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/books/admin/$id', data: data);
    return BookModel.fromJson(parseEnvelope(res.data));
  }

  Future<void> deleteBook(String id, {bool permanent = false}) async {
    await _dio.delete('/books/admin/$id', queryParameters: {
      'permanent': permanent,
    });
  }

  Future<BookModel> publishBook(String id) async {
    final res = await _dio.post('/books/admin/$id/publish');
    return BookModel.fromJson(parseEnvelope(res.data));
  }

  Future<BookModel> unpublishBook(String id) async {
    final res = await _dio.post('/books/admin/$id/unpublish');
    return BookModel.fromJson(parseEnvelope(res.data));
  }

  Future<BookModel> archiveBook(String id) async {
    final res = await _dio.post('/books/admin/$id/archive');
    return BookModel.fromJson(parseEnvelope(res.data));
  }

  Future<BookModel> restoreBook(String id) async {
    final res = await _dio.post('/books/admin/$id/restore');
    return BookModel.fromJson(parseEnvelope(res.data));
  }

  Future<Map<String, dynamic>> uploadBookCover({
    required List<int> bytes,
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _dio.post('/books/admin/upload-cover', data: formData);
    return parseEnvelope(res.data);
  }

  Future<Map<String, dynamic>> uploadBookContent({
    required List<int> bytes,
    required String filename,
    void Function(int count, int total)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _dio.post(
      '/books/admin/upload-content',
      data: formData,
      onSendProgress: onProgress,
    );
    return parseEnvelope(res.data);
  }

  // ── Admin Category Management ───────────────────────────────────────────

  Future<List<BookCategoryModel>> fetchAdminCategories({
    bool includeArchived = true,
  }) async {
    final res = await _dio.get('/books/admin/categories', queryParameters: {
      'includeArchived': includeArchived,
    });
    final list = parseEnvelopeList(res.data);
    return list
        .map((c) => BookCategoryModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<BookCategoryModel> createCategory(Map<String, dynamic> data) async {
    final res = await _dio.post('/books/admin/categories', data: data);
    return BookCategoryModel.fromJson(parseEnvelope(res.data));
  }

  Future<BookCategoryModel> updateCategory(
      String id, Map<String, dynamic> data) async {
    final res = await _dio.patch('/books/admin/categories/$id', data: data);
    return BookCategoryModel.fromJson(parseEnvelope(res.data));
  }

  Future<void> deleteCategory(String id, {String? reassignCategoryId}) async {
    await _dio.delete(
      '/books/admin/categories/$id',
      queryParameters: {'reassignCategoryId': ?reassignCategoryId},
    );
  }
}
