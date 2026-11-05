// lib/features/books/presentation/providers/dictionary_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/dictionary_remote_datasource.dart';
import '../../data/datasources/translation_history_local_datasource.dart';
import '../../data/models/book_model.dart';
import '../../data/models/dictionary_model.dart';
import '../../data/repositories/dictionary_repository.dart';

// ── Datasources & Repository Providers ─────────────────────────────────────

final dictionaryRemoteDatasourceProvider =
    Provider<DictionaryRemoteDatasource>((ref) {
  final dio = ref.watch(apiClientProvider);
  return DictionaryRemoteDatasource(dio);
});

final translationHistoryLocalDatasourceProvider =
    Provider<TranslationHistoryLocalDatasource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TranslationHistoryLocalDatasource(prefs);
});

final dictionaryRepositoryProvider = Provider<DictionaryRepository>((ref) {
  final remote = ref.watch(dictionaryRemoteDatasourceProvider);
  final local = ref.watch(translationHistoryLocalDatasourceProvider);
  return DictionaryRepository(remote: remote, local: local);
});

// ── Public User Providers ──────────────────────────────────────────────────

final availableDictionariesProvider =
    FutureProvider.autoDispose<List<BookModel>>((ref) async {
  final repo = ref.watch(dictionaryRepositoryProvider);
  return repo.getAvailableDictionaries();
});

final availableDictionaryLanguagesProvider =
    FutureProvider.autoDispose<List<DictionaryLanguageModel>>((ref) async {
  final repo = ref.watch(dictionaryRepositoryProvider);
  return repo.getAvailableLanguages();
});

// ── Admin Providers ────────────────────────────────────────────────────────

class AdminLanguagesNotifier
    extends AsyncNotifier<List<DictionaryLanguageModel>> {
  @override
  Future<List<DictionaryLanguageModel>> build() async {
    final repo = ref.watch(dictionaryRepositoryProvider);
    return repo.getLanguagesAdmin(includeDisabled: true);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      final repo = ref.read(dictionaryRepositoryProvider);
      return repo.getLanguagesAdmin(includeDisabled: true);
    });
  }

  Future<DictionaryLanguageModel> createLanguage(Map<String, dynamic> data) async {
    final repo = ref.read(dictionaryRepositoryProvider);
    final created = await repo.createLanguage(data);
    await refresh();
    return created;
  }

  Future<DictionaryLanguageModel> updateLanguage(
      String id, Map<String, dynamic> data) async {
    final repo = ref.read(dictionaryRepositoryProvider);
    final updated = await repo.updateLanguage(id, data);
    await refresh();
    return updated;
  }

  Future<void> deleteLanguage(String id) async {
    final repo = ref.read(dictionaryRepositoryProvider);
    await repo.deleteLanguage(id);
    await refresh();
  }
}

final adminLanguagesProvider =
    AsyncNotifierProvider<AdminLanguagesNotifier, List<DictionaryLanguageModel>>(
  () => AdminLanguagesNotifier(),
);

class AdminDictionariesNotifier extends AsyncNotifier<List<BookModel>> {
  @override
  Future<List<BookModel>> build() async {
    final repo = ref.watch(dictionaryRepositoryProvider);
    return repo.getDictionariesAdmin();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      final repo = ref.read(dictionaryRepositoryProvider);
      return repo.getDictionariesAdmin();
    });
  }

  Future<void> triggerProcessing(String bookId) async {
    final repo = ref.read(dictionaryRepositoryProvider);
    await repo.triggerProcess(bookId);
    await refresh();
  }

  Future<void> publishDictionary(String bookId) async {
    final repo = ref.read(dictionaryRepositoryProvider);
    await repo.publishDictionary(bookId);
    await refresh();
  }

  Future<void> unpublishDictionary(String bookId) async {
    final repo = ref.read(dictionaryRepositoryProvider);
    await repo.unpublishDictionary(bookId);
    await refresh();
  }

  Future<void> updateConfig(String bookId, Map<String, dynamic> data) async {
    final repo = ref.read(dictionaryRepositoryProvider);
    await repo.updateConfig(bookId, data);
    await refresh();
  }
}

final adminDictionariesProvider =
    AsyncNotifierProvider<AdminDictionariesNotifier, List<BookModel>>(
  () => AdminDictionariesNotifier(),
);

// ── Translation History Providers ──────────────────────────────────────────

class TranslationHistoryFilter {
  final String search;
  final String? sourceLanguage;
  final String? targetLanguage;
  final String? dictionaryBookId;
  final int page;
  final int limit;
  final String sort;

  const TranslationHistoryFilter({
    this.search = '',
    this.sourceLanguage,
    this.targetLanguage,
    this.dictionaryBookId,
    this.page = 1,
    this.limit = 20,
    this.sort = 'newest',
  });

  TranslationHistoryFilter copyWith({
    String? search,
    String? sourceLanguage,
    String? targetLanguage,
    String? dictionaryBookId,
    int? page,
    int? limit,
    String? sort,
  }) {
    return TranslationHistoryFilter(
      search: search ?? this.search,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      dictionaryBookId: dictionaryBookId ?? this.dictionaryBookId,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      sort: sort ?? this.sort,
    );
  }
}

final translationHistoryFilterProvider =
    StateProvider<TranslationHistoryFilter>((ref) {
  return const TranslationHistoryFilter();
});

class TranslationHistoryNotifier
    extends AsyncNotifier<PaginatedTranslationHistory> {
  @override
  Future<PaginatedTranslationHistory> build() async {
    final auth = ref.watch(authProvider);
    final userId = auth.user?.id ?? 'guest';
    final filter = ref.watch(translationHistoryFilterProvider);
    final repo = ref.watch(dictionaryRepositoryProvider);

    return repo.getTranslationHistory(
      userId,
      search: filter.search,
      sourceLanguage: filter.sourceLanguage,
      targetLanguage: filter.targetLanguage,
      dictionaryBookId: filter.dictionaryBookId,
      page: filter.page,
      limit: filter.limit,
      sort: filter.sort,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final auth = ref.read(authProvider);
      final userId = auth.user?.id ?? 'guest';
      final filter = ref.read(translationHistoryFilterProvider);
      final repo = ref.read(dictionaryRepositoryProvider);

      return repo.getTranslationHistory(
        userId,
        search: filter.search,
        sourceLanguage: filter.sourceLanguage,
        targetLanguage: filter.targetLanguage,
        dictionaryBookId: filter.dictionaryBookId,
        page: filter.page,
        limit: filter.limit,
        sort: filter.sort,
      );
    });
  }

  Future<void> deleteItem(String id) async {
    final auth = ref.read(authProvider);
    final userId = auth.user?.id ?? 'guest';
    final repo = ref.read(dictionaryRepositoryProvider);
    await repo.deleteTranslationHistoryItem(userId, id);
    await refresh();
  }

  Future<void> clearAll() async {
    final auth = ref.read(authProvider);
    final userId = auth.user?.id ?? 'guest';
    final repo = ref.read(dictionaryRepositoryProvider);
    await repo.clearTranslationHistory(userId);
    await refresh();
  }

  Future<void> saveItem({
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
    final auth = ref.read(authProvider);
    final userId = auth.user?.id ?? 'guest';
    final repo = ref.read(dictionaryRepositoryProvider);

    await repo.saveTranslationHistory(
      userId,
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
    );
    await refresh();
  }
}

final translationHistoryProvider = AsyncNotifierProvider<
    TranslationHistoryNotifier, PaginatedTranslationHistory>(
  () => TranslationHistoryNotifier(),
);
