// lib/features/books/data/datasources/translation_history_local_datasource.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dictionary_model.dart';

class TranslationHistoryLocalDatasource {
  final SharedPreferences _prefs;

  TranslationHistoryLocalDatasource(this._prefs);

  String _key(String userId) => 'cached_translation_history_$userId';

  Future<List<TranslationHistoryItemModel>> getCachedHistory(String userId) async {
    final raw = _prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = json.decode(raw) as List;
      return list
          .map((item) =>
              TranslationHistoryItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> cacheHistory(
      String userId, List<TranslationHistoryItemModel> items) async {
    final encoded = json.encode(items.map((i) => i.toJson()).toList());
    await _prefs.setString(_key(userId), encoded);
  }

  Future<void> saveLocalItem(
      String userId, TranslationHistoryItemModel item) async {
    final list = await getCachedHistory(userId);
    // Remove duplicate if exists
    list.removeWhere((i) => i.id == item.id || (i.word.toLowerCase() == item.word.toLowerCase() && i.definition == item.definition));
    list.insert(0, item);
    await cacheHistory(userId, list);
  }

  Future<void> deleteLocalItem(String userId, String id) async {
    final list = await getCachedHistory(userId);
    list.removeWhere((i) => i.id == id);
    await cacheHistory(userId, list);
  }

  Future<void> clearLocalHistory(String userId) async {
    await _prefs.remove(_key(userId));
  }
}

