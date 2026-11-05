// lib/features/books/data/datasources/dictionary_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:mobile/core/network/api_client.dart';
import '../models/book_model.dart';
import '../models/dictionary_model.dart';

class DictionaryRemoteDatasource {
  final Dio _dio;

  DictionaryRemoteDatasource(this._dio);

  // ── Admin APIs ──────────────────────────────────────────────────────────

  Future<List<BookModel>> fetchDictionariesAdmin() async {
    final res = await _dio.get('/books/dictionaries/admin');
    final list = parseEnvelopeList(res.data);
    return list
        .map((b) => BookModel.fromJson(b as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> triggerProcess(String bookId) async {
    final res = await _dio.post('/books/dictionaries/$bookId/process');
    return parseEnvelope(res.data);
  }

  Future<Map<String, dynamic>> fetchStatus(String bookId) async {
    final res = await _dio.get('/books/dictionaries/$bookId/status');
    return parseEnvelope(res.data);
  }

  Future<DictionaryConfigModel> updateConfig(
      String bookId, Map<String, dynamic> data) async {
    final res = await _dio.patch('/books/dictionaries/$bookId/config', data: data);
    return DictionaryConfigModel.fromJson(parseEnvelope(res.data));
  }

  Future<Map<String, dynamic>> publishDictionary(String bookId) async {
    final res = await _dio.post('/books/dictionaries/$bookId/publish');
    return parseEnvelope(res.data);
  }

  Future<Map<String, dynamic>> unpublishDictionary(String bookId) async {
    final res = await _dio.post('/books/dictionaries/$bookId/unpublish');
    return parseEnvelope(res.data);
  }

  Future<List<DictionaryLanguageModel>> fetchLanguagesAdmin(
      {bool includeDisabled = true}) async {
    final res = await _dio.get('/books/dictionaries/languages/all',
        queryParameters: {'includeDisabled': includeDisabled});
    final list = parseEnvelopeList(res.data);
    return list
        .map((l) => DictionaryLanguageModel.fromJson(l as Map<String, dynamic>))
        .toList();
  }

  Future<DictionaryLanguageModel> createLanguage(
      Map<String, dynamic> data) async {
    final res = await _dio.post('/books/dictionaries/languages', data: data);
    return DictionaryLanguageModel.fromJson(parseEnvelope(res.data));
  }

  Future<DictionaryLanguageModel> updateLanguage(
      String id, Map<String, dynamic> data) async {
    final res =
        await _dio.patch('/books/dictionaries/languages/$id', data: data);
    return DictionaryLanguageModel.fromJson(parseEnvelope(res.data));
  }

  Future<void> deleteLanguage(String id) async {
    await _dio.delete('/books/dictionaries/languages/$id');
  }

  // ── User APIs ───────────────────────────────────────────────────────────

  Future<List<BookModel>> fetchAvailableDictionaries() async {
    final res = await _dio.get('/books/dictionaries/available');
    final list = parseEnvelopeList(res.data);
    return list
        .map((b) => BookModel.fromJson(b as Map<String, dynamic>))
        .toList();
  }

  Future<List<DictionaryLanguageModel>> fetchAvailableLanguages() async {
    final res = await _dio.get('/books/dictionaries/languages/available');
    final list = parseEnvelopeList(res.data);
    return list
        .map((l) => DictionaryLanguageModel.fromJson(l as Map<String, dynamic>))
        .toList();
  }

  Future<DictionaryTranslationResult> searchDictionary(
      String bookId, String word) async {
    final res = await _dio.get(
      '/books/dictionaries/$bookId/search',
      queryParameters: {'word': word},
    );
    return DictionaryTranslationResult.fromJson(parseEnvelope(res.data));
  }

  Future<DictionaryTranslationResult> translateWord({
    required String word,
    String? bookId,
    String? sourceLanguage,
    String? targetLanguage,
  }) async {
    final res = await _dio.post('/books/dictionaries/translate', data: {
      'word': word,
      'bookId': ?bookId,
      'sourceLanguage': ?sourceLanguage,
      'targetLanguage': ?targetLanguage,
    });
    return DictionaryTranslationResult.fromJson(parseEnvelope(res.data));
  }

  // ── Translation History APIs ────────────────────────────────────────────

  Future<TranslationHistoryItemModel> saveHistory(
      Map<String, dynamic> data) async {
    final res = await _dio.post('/books/dictionaries/history', data: data);
    return TranslationHistoryItemModel.fromJson(parseEnvelope(res.data));
  }

  Future<PaginatedTranslationHistory> fetchHistory({
    String? search,
    String? sourceLanguage,
    String? targetLanguage,
    String? dictionaryBookId,
    int page = 1,
    int limit = 20,
    String sort = 'newest',
  }) async {
    final res = await _dio.get('/books/dictionaries/history', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'sourceLanguage': ?sourceLanguage,
      'targetLanguage': ?targetLanguage,
      'dictionaryBookId': ?dictionaryBookId,
      'page': page,
      'limit': limit,
      'sort': sort,
    });
    return PaginatedTranslationHistory.fromJson(parseEnvelope(res.data));
  }

  Future<void> deleteHistoryItem(String id) async {
    await _dio.delete('/books/dictionaries/history/$id');
  }

  Future<void> clearHistory() async {
    await _dio.delete('/books/dictionaries/history');
  }
}

class PaginatedTranslationHistory {
  final List<TranslationHistoryItemModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginatedTranslationHistory({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginatedTranslationHistory.fromJson(Map<String, dynamic> json) {
    final rawList = json['items'] as List? ?? [];
    return PaginatedTranslationHistory(
      items: rawList
          .map((i) =>
              TranslationHistoryItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
