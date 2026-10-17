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
}
