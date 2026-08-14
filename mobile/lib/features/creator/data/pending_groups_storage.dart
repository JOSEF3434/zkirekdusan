// lib/features/creator/data/pending_groups_storage.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/features/creator/domain/creator_group_dto.dart';

final pendingGroupsStorageProvider = Provider<PendingGroupsStorage>((ref) {
  return PendingGroupsStorage(ref.watch(storageServiceProvider));
});

class PendingGroupsStorage {
  static const String _key = 'pending_creator_groups';
  final StorageService _storageService;

  PendingGroupsStorage(this._storageService);

  Future<List<CreatorGroupDto>> getPendingGroups() async {
    final raw = await _storageService.getToken(key: _key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((e) => CreatorGroupDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addPendingGroup(CreatorGroupDto group) async {
    final current = await getPendingGroups();
    // Remove if already exists (by ID) to avoid duplicates, then add to front
    current.removeWhere((g) => g.id == group.id);
    current.insert(0, group);

    final raw = jsonEncode(current.map((e) => e.toJson()).toList());
    await _storageService.saveToken(raw, key: _key);
  }

  Future<void> removePendingGroup(String groupId) async {
    final current = await getPendingGroups();
    current.removeWhere((g) => g.id == groupId);
    final raw = jsonEncode(current.map((e) => e.toJson()).toList());
    await _storageService.saveToken(raw, key: _key);
  }

  Future<void> clearAll() async {
    await _storageService.deleteToken(key: _key);
  }
}
