// test/features/books/dictionary_system_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/features/books/data/datasources/translation_history_local_datasource.dart';
import 'package:mobile/features/books/data/models/book_model.dart';
import 'package:mobile/features/books/data/models/dictionary_model.dart';

void main() {
  group('Dictionary Models Test', () {
    test('DictionaryLanguageModel fromJson and toJson preserves Amharic / Ge\'ez Unicode', () {
      final json = {
        'id': 'lang-1',
        'code': 'am',
        'name': 'Amharic',
        'nativeName': 'አማርኛ',
        'direction': 'ltr',
        'isEnabled': true,
        'sortOrder': 2,
      };

      final lang = DictionaryLanguageModel.fromJson(json);
      expect(lang.id, 'lang-1');
      expect(lang.code, 'am');
      expect(lang.nativeName, 'አማርኛ');
      expect(lang.isEnabled, true);
      expect(lang.direction, 'ltr');

      final outJson = lang.toJson();
      expect(outJson['nativeName'], 'አማርኛ');
      expect(outJson['code'], 'am');
    });

    test('DictionaryConfigModel status predicates work correctly', () {
      final readyConfig = DictionaryConfigModel.fromJson({
        'id': 'cfg-1',
        'bookId': 'book-1',
        'dictionaryName': 'መዝገበ ቃላት',
        'processingStatus': 'READY',
        'totalEntries': 1450,
      });

      expect(readyConfig.isReady, isTrue);
      expect(readyConfig.isProcessing, isFalse);
      expect(readyConfig.isFailed, isFalse);
      expect(readyConfig.totalEntries, 1450);

      final failedConfig = DictionaryConfigModel.fromJson({
        'id': 'cfg-2',
        'bookId': 'book-2',
        'dictionaryName': 'Greek Lexicon',
        'processingStatus': 'FAILED',
        'errorMessage': 'No extractable text',
        'totalEntries': 0,
      });

      expect(failedConfig.isReady, isFalse);
      expect(failedConfig.isProcessing, isFalse);
      expect(failedConfig.isFailed, isTrue);
      expect(failedConfig.errorMessage, 'No extractable text');

      final parsingConfig = DictionaryConfigModel.fromJson({
        'id': 'cfg-3',
        'bookId': 'book-3',
        'dictionaryName': 'Latin-English',
        'processingStatus': 'PARSING',
        'totalEntries': 0,
      });

      expect(parsingConfig.isProcessing, isTrue);
    });

    test('DictionaryTranslationResult deserializes definitions correctly', () {
      final json = {
        'word': 'Love',
        'sourceLanguage': 'en',
        'targetLanguage': 'am',
        'dictionaryBookId': 'book-dict-1',
        'dictionaryName': 'መዝገበ ቃላት',
        'totalMatches': 1,
        'definitions': [
          {
            'text': 'ፍቅር፤ ጥልቅ ፍቅርና አድናቆት።',
            'entryId': 'entry-1',
            'headword': 'love',
            'pageNumber': 42,
          }
        ],
      };

      final result = DictionaryTranslationResult.fromJson(json);
      expect(result.hasDefinitions, isTrue);
      expect(result.word, 'Love');
      expect(result.dictionaryName, 'መዝገበ ቃላት');
      expect(result.definitions.length, 1);
      expect(result.definitions.first.text, 'ፍቅር፤ ጥልቅ ፍቅርና አድናቆት።');
      expect(result.definitions.first.pageNumber, 42);
    });

    test('BookModel binds isDictionary and dictionaryConfig seamlessly', () {
      final bookJson = {
        'id': 'book-100',
        'title': 'English-Amharic Theological Dictionary',
        'language': 'ENGLISH',
        'format': 'PDF',
        'status': 'PUBLISHED',
        'isDictionary': true,
        'dictionaryConfig': {
          'id': 'cfg-100',
          'bookId': 'book-100',
          'dictionaryName': 'መዝገበ ቃላት',
          'processingStatus': 'READY',
          'totalEntries': 5200,
        },
        'tags': ['theology', 'dictionary'],
        'viewsCount': 10,
        'bookmarksCount': 2,
        'createdAt': '2026-11-05T00:00:00.000Z',
        'updatedAt': '2026-11-05T00:00:00.000Z',
      };

      final book = BookModel.fromJson(bookJson);
      expect(book.isDictionary, isTrue);
      expect(book.dictionaryConfig, isNotNull);
      expect(book.dictionaryConfig!.dictionaryName, 'መዝገበ ቃላት');
      expect(book.dictionaryConfig!.totalEntries, 5200);
      expect(book.dictionaryConfig!.isReady, isTrue);
    });
  });

  group('TranslationHistoryLocalDatasource Offline Cache', () {
    late SharedPreferences prefs;
    late TranslationHistoryLocalDatasource localDatasource;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      localDatasource = TranslationHistoryLocalDatasource(prefs);
    });

    test('Saves and retrieves translation history isolated per user', () async {
      const user1 = 'user-alpha';
      const user2 = 'user-beta';

      final itemUser1 = TranslationHistoryItemModel(
        id: 'hist-1',
        userId: user1,
        word: 'grace',
        sourceLanguage: 'en',
        targetLanguage: 'am',
        definition: 'ጸጋ',
        dictionaryNameSnapshot: 'መዝገበ ቃላት',
        createdAt: DateTime.now(),
      );

      final itemUser2 = TranslationHistoryItemModel(
        id: 'hist-2',
        userId: user2,
        word: 'peace',
        sourceLanguage: 'en',
        targetLanguage: 'am',
        definition: 'ሰላም',
        dictionaryNameSnapshot: 'መዝገበ ቃላት',
        createdAt: DateTime.now(),
      );

      await localDatasource.saveLocalItem(user1, itemUser1);
      await localDatasource.saveLocalItem(user2, itemUser2);

      // Verify user 1 only sees user 1 history
      final u1Items = await localDatasource.getCachedHistory(user1);
      expect(u1Items.length, 1);
      expect(u1Items.first.word, 'grace');
      expect(u1Items.first.definition, 'ጸጋ');

      // Verify user 2 only sees user 2 history
      final u2Items = await localDatasource.getCachedHistory(user2);
      expect(u2Items.length, 1);
      expect(u2Items.first.word, 'peace');
      expect(u2Items.first.definition, 'ሰላም');

      // Test delete item
      await localDatasource.deleteLocalItem(user1, 'hist-1');
      final u1AfterDelete = await localDatasource.getCachedHistory(user1);
      expect(u1AfterDelete.isEmpty, isTrue);

      final u2AfterDelete = await localDatasource.getCachedHistory(user2);
      expect(u2AfterDelete.length, 1);

      // Test clear history
      await localDatasource.clearLocalHistory(user2);
      final u2AfterClear = await localDatasource.getCachedHistory(user2);
      expect(u2AfterClear.isEmpty, isTrue);
    });
  });
}
