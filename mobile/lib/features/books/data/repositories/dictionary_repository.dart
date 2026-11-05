// lib/features/books/data/repositories/dictionary_repository.dart
import 'package:flutter/foundation.dart';
import '../datasources/dictionary_remote_datasource.dart';
import '../datasources/translation_history_local_datasource.dart';
import '../models/book_model.dart';
import '../models/dictionary_model.dart';

class DictionaryRepository {
  final DictionaryRemoteDatasource _remote;
  final TranslationHistoryLocalDatasource _local;

  DictionaryRepository({
    required DictionaryRemoteDatasource remote,
    required TranslationHistoryLocalDatasource local,
  })  : _remote = remote,
        _local = local;

  // ── Public User Operations ───────────────────────────────────────────────

  Future<List<BookModel>> getAvailableDictionaries() async {
    return _remote.fetchAvailableDictionaries();
  }

  Future<List<DictionaryLanguageModel>> getAvailableLanguages() async {
    return _remote.fetchAvailableLanguages();
  }

  Future<DictionaryTranslationResult> searchDictionary(
      String bookId, String word) async {
    return _remote.searchDictionary(bookId, word);
  }

  Future<DictionaryTranslationResult> translateWord({
    required String word,
    String? bookId,
    String? sourceLanguage,
    String? targetLanguage,
  }) async {
    return _remote.translateWord(
      word: word,
      bookId: bookId,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
  }

  // ── Translation History with Offline Fallback ────────────────────────────

  Future<TranslationHistoryItemModel> saveTranslationHistory(
    String userId, {
    required String word,
    required String sourceLanguage,
    required String targetLanguage,
    required String definition,
    String? dictionaryBookId,
    String? dictionaryEntryId,
    required String dictionaryNameSnapshot,
    int? pageNumber,
    String? chapter,
    String? surroundingSentence,
  }) async {
    final payload = {
      'word': word,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'definition': definition,
      'dictionaryBookId': ?dictionaryBookId,
      'dictionaryEntryId': ?dictionaryEntryId,
      'dictionaryNameSnapshot': dictionaryNameSnapshot,
      'pageNumber': ?pageNumber,
      'chapter': ?chapter,
      'surroundingSentence': ?surroundingSentence,
    };

    try {
      final remoteItem = await _remote.saveHistory(payload);
      await _local.saveLocalItem(userId, remoteItem);
      return remoteItem;
    } catch (e) {
      debugPrint('[DictionaryRepo] Failed to save history online, saving locally: $e');
      final localItem = TranslationHistoryItemModel(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        word: word,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        definition: definition,
        dictionaryBookId: dictionaryBookId,
        dictionaryEntryId: dictionaryEntryId,
        dictionaryNameSnapshot: dictionaryNameSnapshot,
        pageNumber: pageNumber,
        chapter: chapter,
        surroundingSentence: surroundingSentence,
        createdAt: DateTime.now(),
      );
      await _local.saveLocalItem(userId, localItem);
      return localItem;
    }
  }

  Future<PaginatedTranslationHistory> getTranslationHistory(
    String userId, {
    String? search,
    String? sourceLanguage,
    String? targetLanguage,
    String? dictionaryBookId,
    int page = 1,
    int limit = 20,
    String sort = 'newest',
  }) async {
    try {
      final remoteResult = await _remote.fetchHistory(
        search: search,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        dictionaryBookId: dictionaryBookId,
        page: page,
        limit: limit,
        sort: sort,
      );

      // Cache first page to local storage for offline use
      if (page == 1 && (search == null || search.isEmpty)) {
        await _local.cacheHistory(userId, remoteResult.items);
      }
      return remoteResult;
    } catch (e) {
      debugPrint('[DictionaryRepo] Network error loading history, using local cache: $e');
      final cached = await _local.getCachedHistory(userId);
      var filtered = cached;

      if (search != null && search.isNotEmpty) {
        final query = search.toLowerCase();
        filtered = filtered
            .where((i) =>
                i.word.toLowerCase().contains(query) ||
                i.definition.toLowerCase().contains(query))
            .toList();
      }

      if (sourceLanguage != null && sourceLanguage.isNotEmpty) {
        filtered = filtered
            .where((i) =>
                i.sourceLanguage.toLowerCase() == sourceLanguage.toLowerCase())
            .toList();
      }

      if (targetLanguage != null && targetLanguage.isNotEmpty) {
        filtered = filtered
            .where((i) =>
                i.targetLanguage.toLowerCase() == targetLanguage.toLowerCase())
            .toList();
      }

      if (dictionaryBookId != null && dictionaryBookId.isNotEmpty) {
        filtered = filtered
            .where((i) => i.dictionaryBookId == dictionaryBookId)
            .toList();
      }

      if (sort == 'oldest') {
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      } else {
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      final total = filtered.length;
      final start = (page - 1) * limit;
      final paged = start >= total ? <TranslationHistoryItemModel>[] : filtered.skip(start).take(limit).toList();

      return PaginatedTranslationHistory(
        items: paged,
        total: total,
        page: page,
        limit: limit,
        totalPages: (total / limit).ceil().clamp(1, 999999),
      );
    }
  }

  Future<void> deleteTranslationHistoryItem(String userId, String id) async {
    try {
      if (!id.startsWith('local_')) {
        await _remote.deleteHistoryItem(id);
      }
    } catch (e) {
      debugPrint('[DictionaryRepo] Failed to delete online history item: $e');
    }
    await _local.deleteLocalItem(userId, id);
  }

  Future<void> clearTranslationHistory(String userId) async {
    try {
      await _remote.clearHistory();
    } catch (e) {
      debugPrint('[DictionaryRepo] Failed to clear online history: $e');
    }
    await _local.clearLocalHistory(userId);
  }

  // ── Administrator Operations ─────────────────────────────────────────────

  Future<List<BookModel>> getDictionariesAdmin() async {
    return _remote.fetchDictionariesAdmin();
  }

  Future<Map<String, dynamic>> triggerProcess(String bookId) async {
    return _remote.triggerProcess(bookId);
  }

  Future<Map<String, dynamic>> getStatus(String bookId) async {
    return _remote.fetchStatus(bookId);
  }

  Future<DictionaryConfigModel> updateConfig(
      String bookId, Map<String, dynamic> data) async {
    return _remote.updateConfig(bookId, data);
  }

  Future<Map<String, dynamic>> publishDictionary(String bookId) async {
    return _remote.publishDictionary(bookId);
  }

  Future<Map<String, dynamic>> unpublishDictionary(String bookId) async {
    return _remote.unpublishDictionary(bookId);
  }

  Future<List<DictionaryLanguageModel>> getLanguagesAdmin(
      {bool includeDisabled = true}) async {
    return _remote.fetchLanguagesAdmin(includeDisabled: includeDisabled);
  }

  Future<DictionaryLanguageModel> createLanguage(
      Map<String, dynamic> data) async {
    return _remote.createLanguage(data);
  }

  Future<DictionaryLanguageModel> updateLanguage(
      String id, Map<String, dynamic> data) async {
    return _remote.updateLanguage(id, data);
  }

  Future<void> deleteLanguage(String id) async {
    return _remote.deleteLanguage(id);
  }
}
