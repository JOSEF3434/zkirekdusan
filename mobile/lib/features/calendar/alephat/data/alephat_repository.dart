// lib/features/calendar/alephat/data/alephat_repository.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_letter_model.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_22_model.dart';
import 'package:mobile/features/calendar/alephat/data/alephat_seed_data.dart';

final alephatRepositoryProvider = Provider<AlephatRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {
    // In environments where sharedPreferencesProvider is not explicitly overridden
  }
  return AlephatRepository(dio, prefs);
});

class AlephatRepository {
  final Dio _dio;
  final SharedPreferences? _injectedPrefs;

  static const String _keyCachedLetters = 'alephat_cached_letters';
  static const String _keyCached22 = 'alephat_cached_22';
  static const String _keyLastSync = 'alephat_last_synced_at';

  AlephatRepository(this._dio, [this._injectedPrefs]);

  Future<SharedPreferences> _getPrefs() async {
    if (_injectedPrefs != null) return _injectedPrefs;
    return await SharedPreferences.getInstance();
  }

  // Helper to extract data from optional response envelope
  dynamic _extractData(dynamic responseData) {
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }

  // ─────────────────────────────────────────────────────────
  // CACHE PERSISTENCE HELPERS
  // ─────────────────────────────────────────────────────────

  Future<List<AlephatLetterModel>> getCachedLetters() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_keyCachedLetters);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final letters = decoded
              .map((item) =>
                  AlephatLetterModel.fromJson(item as Map<String, dynamic>))
              .toList();
          letters.sort((a, b) => a.order.compareTo(b.order));
          return letters;
        }
      }
    } catch (e) {
      developer.log('Error reading cached letters: $e',
          name: 'AlephatRepository');
    }
    // When local storage has no cached letters yet, populate with initial seed data
    final seeds = AlephatSeedData.getInitialLetters();
    saveCachedLetters(seeds);
    return seeds;
  }

  Future<void> saveCachedLetters(List<AlephatLetterModel> letters) async {
    try {
      final prefs = await _getPrefs();
      final encoded = jsonEncode(letters.map((l) => l.toJson()).toList());
      await prefs.setString(_keyCachedLetters, encoded);
      await prefs.setString(_keyLastSync, DateTime.now().toIso8601String());
    } catch (e) {
      developer.log('Error saving cached letters: $e',
          name: 'AlephatRepository');
    }
  }

  Future<List<Alephat22Model>> getCached22List() async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(_keyCached22);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final entries = decoded
              .map((item) =>
                  Alephat22Model.fromJson(item as Map<String, dynamic>))
              .toList();
          entries.sort((a, b) => a.order.compareTo(b.order));
          return entries;
        }
      }
    } catch (e) {
      developer.log('Error reading cached 22 list: $e',
          name: 'AlephatRepository');
    }
    // When local storage has no cached 22 entries yet, populate with initial seed data
    final seeds = AlephatSeedData.getInitial22List();
    saveCached22List(seeds);
    return seeds;
  }

  Future<void> saveCached22List(List<Alephat22Model> list) async {
    try {
      final prefs = await _getPrefs();
      final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString(_keyCached22, encoded);
      await prefs.setString(_keyLastSync, DateTime.now().toIso8601String());
    } catch (e) {
      developer.log('Error saving cached 22 list: $e',
          name: 'AlephatRepository');
    }
  }

  Future<bool> hasCachedLetters() async {
    final prefs = await _getPrefs();
    return prefs.containsKey(_keyCachedLetters);
  }

  Future<bool> hasCached22() async {
    final prefs = await _getPrefs();
    return prefs.containsKey(_keyCached22);
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_keyLastSync);
    if (raw != null && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  Future<void> clearCache() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyCachedLetters);
    await prefs.remove(_keyCached22);
    await prefs.remove(_keyLastSync);
  }

  Future<void> _updateSingleLetterInCache(AlephatLetterModel letter) async {
    final cached = await getCachedLetters();
    final index = cached.indexWhere((l) => l.id == letter.id);
    if (index >= 0) {
      cached[index] = letter;
    } else {
      cached.add(letter);
    }
    cached.sort((a, b) => a.order.compareTo(b.order));
    await saveCachedLetters(cached);
  }

  Future<void> _updateSingle22InCache(Alephat22Model entry) async {
    final cached = await getCached22List();
    final index = cached.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      cached[index] = entry;
    } else {
      cached.add(entry);
    }
    cached.sort((a, b) => a.order.compareTo(b.order));
    await saveCached22List(cached);
  }

  Future<void> _mergeLettersIntoCache(
      List<AlephatLetterModel> remoteLetters) async {
    final cached = await getCachedLetters();
    final map = {for (var l in cached) l.id: l};
    for (var r in remoteLetters) {
      map[r.id] = r;
    }
    final merged = map.values.toList();
    merged.sort((a, b) => a.order.compareTo(b.order));
    await saveCachedLetters(merged);
  }

  // ─────────────────────────────────────────────────────────
  // TAB 1: Letters & Families (Offline-First with Remote Sync)
  // ─────────────────────────────────────────────────────────

  Future<List<AlephatLetterModel>> getLetters({
    String? search,
    bool? includeUnpublished,
  }) async {
    // 1. Read existing local cache first
    final cached = await getCachedLetters();

    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (includeUnpublished != null) {
        queryParams['includeUnpublished'] = includeUnpublished;
      }

      final response = await _dio.get(
        '/alephat/letters',
        queryParameters: queryParams,
      );

      final data = _extractData(response.data);
      if (data is List) {
        final remoteLetters = data
            .map((item) =>
                AlephatLetterModel.fromJson(item as Map<String, dynamic>))
            .toList();

        if (search == null || search.trim().isEmpty) {
          if (remoteLetters.isNotEmpty) {
            await saveCachedLetters(remoteLetters);
          }
        } else {
          await _mergeLettersIntoCache(remoteLetters);
        }
        return remoteLetters;
      }
    } catch (e) {
      // Remote call failed (offline, timeout, network error)
      // If we have cached letters, return them safely
      if (cached.isNotEmpty) {
        if (search != null && search.trim().isNotEmpty) {
          final query = search.trim().toLowerCase();
          return cached.where((l) {
            final matchLetter = l.letter.toLowerCase().contains(query);
            final matchName = (l.name ?? '').toLowerCase().contains(query);
            final matchNote =
                (l.defaultNote ?? '').toLowerCase().contains(query);
            final matchPron =
                (l.pronunciationGuide ?? '').toLowerCase().contains(query);
            final matchFamily = l.familyMembers.any((m) =>
                m.glyph.toLowerCase().contains(query) ||
                (m.orderName ?? '').toLowerCase().contains(query) ||
                (m.note ?? '').toLowerCase().contains(query));
            return matchLetter ||
                matchName ||
                matchNote ||
                matchPron ||
                matchFamily;
          }).toList();
        }
        return cached;
      }

      return await getCachedLetters();
    }

    return cached;
  }

  Future<AlephatLetterModel> getLetter(
    String id, {
    bool? includeUnpublished,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (includeUnpublished != null) {
        queryParams['includeUnpublished'] = includeUnpublished;
      }

      final response = await _dio.get(
        '/alephat/letters/$id',
        queryParameters: queryParams,
      );

      final data = _extractData(response.data);
      final letter =
          AlephatLetterModel.fromJson(data as Map<String, dynamic>);
      await _updateSingleLetterInCache(letter);
      return letter;
    } catch (e) {
      final cached = await getCachedLetters();
      final match = cached.where((l) => l.id == id);
      if (match.isNotEmpty) {
        return match.first;
      }
      rethrow;
    }
  }

  Future<AlephatLetterModel> createLetter(Map<String, dynamic> data) async {
    final response = await _dio.post('/alephat/letters', data: data);
    final resData = _extractData(response.data);
    final letter =
        AlephatLetterModel.fromJson(resData as Map<String, dynamic>);
    await _updateSingleLetterInCache(letter);
    return letter;
  }

  Future<AlephatLetterModel> updateLetter(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch('/alephat/letters/$id', data: data);
    final resData = _extractData(response.data);
    final letter =
        AlephatLetterModel.fromJson(resData as Map<String, dynamic>);
    await _updateSingleLetterInCache(letter);
    return letter;
  }

  Future<void> deleteLetter(String id) async {
    await _dio.delete('/alephat/letters/$id');
    final cached = await getCachedLetters();
    final updated = cached.where((l) => l.id != id).toList();
    await saveCachedLetters(updated);
  }

  Future<void> reorderLetters(List<Map<String, dynamic>> items) async {
    await _dio.post('/alephat/letters/reorder', data: {'items': items});
    // Refresh letters into cache
    try {
      final response = await _dio.get('/alephat/letters');
      final data = _extractData(response.data);
      if (data is List) {
        final letters = data
            .map((item) =>
                AlephatLetterModel.fromJson(item as Map<String, dynamic>))
            .toList();
        await saveCachedLetters(letters);
      }
    } catch (_) {}
  }

  Future<AlephatFamilyMemberModel> addFamilyMember(
    String letterId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post(
      '/alephat/letters/$letterId/family',
      data: data,
    );
    final resData = _extractData(response.data);
    final member =
        AlephatFamilyMemberModel.fromJson(resData as Map<String, dynamic>);

    final cached = await getCachedLetters();
    final updated = cached.map((l) {
      if (l.id == letterId) {
        final members =
            List<AlephatFamilyMemberModel>.from(l.familyMembers)..add(member);
        members.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        return l.copyWith(familyMembers: members);
      }
      return l;
    }).toList();
    await saveCachedLetters(updated);
    return member;
  }

  Future<AlephatFamilyMemberModel> updateFamilyMember(
    String letterId,
    String memberId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      '/alephat/letters/$letterId/family/$memberId',
      data: data,
    );
    final resData = _extractData(response.data);
    final member =
        AlephatFamilyMemberModel.fromJson(resData as Map<String, dynamic>);

    final cached = await getCachedLetters();
    final updated = cached.map((l) {
      if (l.id == letterId) {
        final members = l.familyMembers
            .map((m) => m.id == memberId ? member : m)
            .toList();
        members.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        return l.copyWith(familyMembers: members);
      }
      return l;
    }).toList();
    await saveCachedLetters(updated);
    return member;
  }

  Future<void> deleteFamilyMember(String letterId, String memberId) async {
    await _dio.delete('/alephat/letters/$letterId/family/$memberId');
    final cached = await getCachedLetters();
    final updated = cached.map((l) {
      if (l.id == letterId) {
        final members =
            l.familyMembers.where((m) => m.id != memberId).toList();
        return l.copyWith(familyMembers: members);
      }
      return l;
    }).toList();
    await saveCachedLetters(updated);
  }

  Future<void> reorderFamilyMembers(
    String letterId,
    List<Map<String, dynamic>> items,
  ) async {
    await _dio.post(
      '/alephat/letters/$letterId/family/reorder',
      data: {'items': items},
    );
  }

  // ─────────────────────────────────────────────────────────
  // TAB 2: 22 Alephats (Offline-First with Remote Sync)
  // ─────────────────────────────────────────────────────────

  Future<List<Alephat22Model>> get22List({
    String? search,
    bool? includeUnpublished,
  }) async {
    // 1. Read existing local cache first
    final cached = await getCached22List();

    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (includeUnpublished != null) {
        queryParams['includeUnpublished'] = includeUnpublished;
      }

      final response = await _dio.get(
        '/alephat/22',
        queryParameters: queryParams,
      );

      final data = _extractData(response.data);
      if (data is List) {
        final remoteEntries = data
            .map((item) =>
                Alephat22Model.fromJson(item as Map<String, dynamic>))
            .toList();

        if (search == null || search.trim().isEmpty) {
          if (remoteEntries.isNotEmpty) {
            await saveCached22List(remoteEntries);
          }
        }
        return remoteEntries;
      }
    } catch (e) {
      // Remote call failed (offline, timeout, etc.)
      if (cached.isNotEmpty) {
        if (search != null && search.trim().isNotEmpty) {
          final query = search.trim().toLowerCase();
          return cached.where((item) {
            final matchLetter = item.letter.toLowerCase().contains(query);
            final matchTitle = item.title.toLowerCase().contains(query);
            final matchMeaning =
                (item.meaning ?? '').toLowerCase().contains(query);
            final matchNote = item.note.toLowerCase().contains(query);
            final matchSupp =
                (item.supplementaryInfo ?? '').toLowerCase().contains(query);
            return matchLetter ||
                matchTitle ||
                matchMeaning ||
                matchNote ||
                matchSupp;
          }).toList();
        }
        return cached;
      }

      return await getCached22List();
    }

    return cached;
  }

  Future<Alephat22Model> get22Detail(
    String id, {
    bool? includeUnpublished,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (includeUnpublished != null) {
        queryParams['includeUnpublished'] = includeUnpublished;
      }

      final response = await _dio.get(
        '/alephat/22/$id',
        queryParameters: queryParams,
      );

      final data = _extractData(response.data);
      final item = Alephat22Model.fromJson(data as Map<String, dynamic>);
      await _updateSingle22InCache(item);
      return item;
    } catch (e) {
      final cached = await getCached22List();
      final match = cached.where((e) => e.id == id);
      if (match.isNotEmpty) {
        return match.first;
      }
      rethrow;
    }
  }

  Future<Alephat22Model> create22(Map<String, dynamic> data) async {
    final response = await _dio.post('/alephat/22', data: data);
    final resData = _extractData(response.data);
    final item = Alephat22Model.fromJson(resData as Map<String, dynamic>);
    await _updateSingle22InCache(item);
    return item;
  }

  Future<Alephat22Model> update22(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/alephat/22/$id', data: data);
    final resData = _extractData(response.data);
    final item = Alephat22Model.fromJson(resData as Map<String, dynamic>);
    await _updateSingle22InCache(item);
    return item;
  }

  Future<void> delete22(String id) async {
    await _dio.delete('/alephat/22/$id');
    final cached = await getCached22List();
    final updated = cached.where((e) => e.id != id).toList();
    await saveCached22List(updated);
  }

  Future<void> reorder22(List<Map<String, dynamic>> items) async {
    await _dio.post('/alephat/22/reorder', data: {'items': items});
    try {
      final response = await _dio.get('/alephat/22');
      final data = _extractData(response.data);
      if (data is List) {
        final entries = data
            .map((item) =>
                Alephat22Model.fromJson(item as Map<String, dynamic>))
            .toList();
        await saveCached22List(entries);
      }
    } catch (_) {}
  }
}
