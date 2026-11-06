// lib/core/database/daos/downloaded_books_dao.dart
import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../app_database.dart';
import '../tables/local_downloaded_books_table.dart';

part 'downloaded_books_dao.g.dart';

@DriftAccessor(tables: [LocalDownloadedBooks])
class DownloadedBooksDao extends DatabaseAccessor<AppDatabase>
    with _$DownloadedBooksDaoMixin {
  DownloadedBooksDao(super.db);

  /// All completed downloads for a user
  Stream<List<LocalDownloadedBookData>> watchDownloaded(String userId) {
    if (kIsWeb) {
      return _WebDownloadedBooksManager.watchDownloaded(userId);
    }
    return (select(localDownloadedBooks)
          ..where((t) =>
              t.userId.equals(userId) & t.status.equals('completed')))
        .watch();
  }

  /// All downloads (any status) for a user
  Stream<List<LocalDownloadedBookData>> watchAll(String userId) {
    if (kIsWeb) {
      return _WebDownloadedBooksManager.watchAll(userId);
    }
    return (select(localDownloadedBooks)
          ..where((t) => t.userId.equals(userId)))
        .watch();
  }

  /// Active downloads (queued or downloading) for a user
  Stream<List<LocalDownloadedBookData>> watchActive(String userId) {
    if (kIsWeb) {
      return _WebDownloadedBooksManager.watchActive(userId);
    }
    return (select(localDownloadedBooks)
          ..where((t) =>
              t.userId.equals(userId) &
              (t.status.equals('queued') | t.status.equals('downloading'))))
        .watch();
  }

  Future<LocalDownloadedBookData?> getRecord(
      String bookId, String userId) async {
    if (kIsWeb) {
      return _WebDownloadedBooksManager.getRecord(bookId, userId);
    }
    final exact = await (select(localDownloadedBooks)
          ..where((t) =>
              t.bookId.equals(bookId) & t.userId.equals(userId)))
        .getSingleOrNull();
    if (exact != null) return exact;

    final guest = await (select(localDownloadedBooks)
          ..where((t) =>
              t.bookId.equals(bookId) & t.userId.equals('guest')))
        .getSingleOrNull();
    if (guest != null) return guest;

    return (select(localDownloadedBooks)
          ..where((t) => t.bookId.equals(bookId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<bool> isDownloaded(String bookId, String userId) async {
    if (kIsWeb) {
      return _WebDownloadedBooksManager.isDownloaded(bookId, userId);
    }
    final record = await getRecord(bookId, userId);
    return record != null &&
        record.status == 'completed' &&
        record.localContentPath != null;
  }

  Future<void> upsertRecord(LocalDownloadedBooksCompanion record) async {
    if (kIsWeb) {
      await _WebDownloadedBooksManager.upsert(record);
      return;
    }
    await into(localDownloadedBooks).insertOnConflictUpdate(record);
  }

  Future<void> updateProgress(
      String bookId, String userId, double progress, int downloadedBytes) {
    if (kIsWeb) {
      return _WebDownloadedBooksManager.updateProgress(
          bookId, userId, progress, downloadedBytes);
    }
    return (update(localDownloadedBooks)
          ..where((t) =>
              t.bookId.equals(bookId) & t.userId.equals(userId)))
        .write(LocalDownloadedBooksCompanion(
          progress: Value(progress),
          downloadedBytes: Value(downloadedBytes),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> markCompleted(
      String bookId, String userId, String localPath, String? checksum,
      {String? localCoverPath}) {
    if (kIsWeb) {
      return _WebDownloadedBooksManager.markCompleted(
          bookId, userId, localPath, checksum,
          localCoverPath: localCoverPath);
    }
    return (update(localDownloadedBooks)
          ..where((t) =>
              t.bookId.equals(bookId) & t.userId.equals(userId)))
        .write(LocalDownloadedBooksCompanion(
          status: const Value('completed'),
          progress: const Value(1.0),
          localContentPath: Value(localPath),
          localCoverPath: localCoverPath != null
              ? Value(localCoverPath)
              : const Value.absent(),
          contentChecksum: Value(checksum),
          downloadedAt: Value(DateTime.now()),
          lastVerifiedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> updateCoverUrl(String bookId, String coverUrl) {
    if (kIsWeb) {
      return _WebDownloadedBooksManager.updateCoverUrl(bookId, coverUrl);
    }
    return (update(localDownloadedBooks)
          ..where((t) => t.bookId.equals(bookId)))
        .write(LocalDownloadedBooksCompanion(
          coverUrl: Value(coverUrl),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> markFailed(String bookId, String userId, String error) {
    if (kIsWeb) {
      return _WebDownloadedBooksManager.markFailed(bookId, userId, error);
    }
    return (update(localDownloadedBooks)
          ..where((t) =>
              t.bookId.equals(bookId) & t.userId.equals(userId)))
        .write(LocalDownloadedBooksCompanion(
          status: const Value('failed'),
          lastError: Value(error),
          retryCount: Value(0),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> markCancelled(String bookId, String userId) {
    if (kIsWeb) {
      return _WebDownloadedBooksManager.markCancelled(bookId, userId);
    }
    return (update(localDownloadedBooks)
          ..where((t) =>
              t.bookId.equals(bookId) & t.userId.equals(userId)))
        .write(LocalDownloadedBooksCompanion(
          status: const Value('cancelled'),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> updateLastOpened(String bookId, String userId) {
    if (kIsWeb) {
      return _WebDownloadedBooksManager.updateLastOpened(bookId, userId);
    }
    return (update(localDownloadedBooks)
          ..where((t) =>
              t.bookId.equals(bookId) & t.userId.equals(userId)))
        .write(LocalDownloadedBooksCompanion(
          lastOpenedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<int> deleteRecord(String bookId, String userId) {
    if (kIsWeb) {
      return _WebDownloadedBooksManager.deleteRecord(bookId, userId);
    }
    return (delete(localDownloadedBooks)
          ..where((t) =>
              t.bookId.equals(bookId) &
              (t.userId.equals(userId) | t.userId.equals('guest'))))
        .go();
  }

  Future<List<LocalDownloadedBookData>> getAllCompleted(String userId) {
    if (kIsWeb) {
      return _WebDownloadedBooksManager.getAllCompleted(userId);
    }
    return (select(localDownloadedBooks)
          ..where((t) =>
              t.userId.equals(userId) & t.status.equals('completed'))
          ..orderBy([(t) => OrderingTerm.desc(t.downloadedAt)]))
        .get();
  }
}

/// Web-compatible persistence manager for downloaded books.
/// Stores download records in HTML5 LocalStorage via SharedPreferences,
/// bypassing the no-op SQLite Web executor on Flutter Web.
class _WebDownloadedBooksManager {
  static const String _kWebStoreKey = 'zikre_downloaded_books_web_v1';
  static final StreamController<List<LocalDownloadedBookData>> _streamController =
      StreamController<List<LocalDownloadedBookData>>.broadcast();

  static Map<String, LocalDownloadedBookData>? _cache;
  static bool _isLoading = false;

  static Future<Map<String, LocalDownloadedBookData>> _ensureLoaded() async {
    if (_cache != null) return _cache!;
    if (_isLoading) {
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
      return _cache ?? {};
    }
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kWebStoreKey);
      final map = <String, LocalDownloadedBookData>{};
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            if (entry.value is Map) {
              try {
                final item = LocalDownloadedBookData.fromJson(
                  Map<String, dynamic>.from(entry.value as Map),
                );
                map[entry.key] = item;
              } catch (_) {}
            }
          }
        }
      }
      _cache = map;
    } catch (_) {
      _cache = {};
    } finally {
      _isLoading = false;
    }
    return _cache!;
  }

  static Future<void> _persist() async {
    if (_cache == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, dynamic>{};
      for (final entry in _cache!.entries) {
        map[entry.key] = entry.value.toJson();
      }
      await prefs.setString(_kWebStoreKey, jsonEncode(map));
      _streamController.add(_cache!.values.toList());
    } catch (_) {}
  }

  static String _key(String userId, String bookId) => '${userId}_$bookId';

  static Stream<List<LocalDownloadedBookData>> watchDownloaded(String userId) async* {
    final cache = await _ensureLoaded();
    yield _filter(cache.values, userId, completedOnly: true);
    yield* _streamController.stream.map((list) => _filter(list, userId, completedOnly: true));
  }

  static Stream<List<LocalDownloadedBookData>> watchAll(String userId) async* {
    final cache = await _ensureLoaded();
    yield _filter(cache.values, userId, completedOnly: false);
    yield* _streamController.stream.map((list) => _filter(list, userId, completedOnly: false));
  }

  static Stream<List<LocalDownloadedBookData>> watchActive(String userId) async* {
    final cache = await _ensureLoaded();
    yield _filterActive(cache.values, userId);
    yield* _streamController.stream.map((list) => _filterActive(list, userId));
  }

  static List<LocalDownloadedBookData> _filter(
    Iterable<LocalDownloadedBookData> items,
    String userId, {
    required bool completedOnly,
  }) {
    return items.where((it) {
      final userMatch = userId.isEmpty ||
          userId == 'guest' ||
          it.userId == userId ||
          it.userId == 'guest';
      if (!userMatch) return false;
      if (completedOnly) return it.status == 'completed';
      return true;
    }).toList();
  }

  static List<LocalDownloadedBookData> _filterActive(
    Iterable<LocalDownloadedBookData> items,
    String userId,
  ) {
    return items.where((it) {
      final userMatch = userId.isEmpty ||
          userId == 'guest' ||
          it.userId == userId ||
          it.userId == 'guest';
      return userMatch && (it.status == 'queued' || it.status == 'downloading');
    }).toList();
  }

  static Future<LocalDownloadedBookData?> getRecord(String bookId, String userId) async {
    final cache = await _ensureLoaded();
    return cache[_key(userId, bookId)] ??
        cache[_key('guest', bookId)] ??
        cache.values.cast<LocalDownloadedBookData?>().firstWhere(
              (it) => it?.bookId == bookId,
              orElse: () => null,
            );
  }

  static Future<bool> isDownloaded(String bookId, String userId) async {
    final rec = await getRecord(bookId, userId);
    return rec != null && rec.status == 'completed' && rec.localContentPath != null;
  }

  static Future<void> upsert(LocalDownloadedBooksCompanion record) async {
    final cache = await _ensureLoaded();
    final bookId = record.bookId.value;
    final userId = record.userId.value;
    final key = _key(userId, bookId);

    final existing = cache[key] ?? cache[_key('guest', bookId)];
    final LocalDownloadedBookData data;
    if (existing != null) {
      data = existing.copyWithCompanion(record);
    } else {
      data = LocalDownloadedBookData(
        bookId: bookId,
        userId: userId,
        title: record.title.value,
        titleAm: record.titleAm.present ? record.titleAm.value : null,
        coverUrl: record.coverUrl.present ? record.coverUrl.value : null,
        author: record.author.present ? record.author.value : null,
        categoryName: record.categoryName.present ? record.categoryName.value : null,
        format: record.format.present ? record.format.value : 'PDF',
        pageCount: record.pageCount.present ? record.pageCount.value : null,
        status: record.status.present ? record.status.value : 'completed',
        progress: record.progress.present ? record.progress.value : 1.0,
        expectedBytes: record.expectedBytes.present ? record.expectedBytes.value : null,
        downloadedBytes: record.downloadedBytes.present ? record.downloadedBytes.value : null,
        localContentPath: record.localContentPath.present ? record.localContentPath.value : null,
        localCoverPath: record.localCoverPath.present ? record.localCoverPath.value : null,
        contentChecksum: record.contentChecksum.present ? record.contentChecksum.value : null,
        contentVersion: record.contentVersion.present ? record.contentVersion.value : null,
        lastError: record.lastError.present ? record.lastError.value : null,
        retryCount: record.retryCount.present ? record.retryCount.value : 0,
        downloadedAt: record.downloadedAt.present ? record.downloadedAt.value : DateTime.now(),
        lastVerifiedAt: record.lastVerifiedAt.present ? record.lastVerifiedAt.value : null,
        lastOpenedAt: record.lastOpenedAt.present ? record.lastOpenedAt.value : null,
        createdAt: record.createdAt.present ? record.createdAt.value : DateTime.now(),
        updatedAt: record.updatedAt.present ? record.updatedAt.value : DateTime.now(),
      );
    }
    cache[key] = data;
    await _persist();
  }

  static Future<void> updateProgress(
    String bookId,
    String userId,
    double progress,
    int downloadedBytes,
  ) async {
    final cache = await _ensureLoaded();
    final key = _key(userId, bookId);
    final existing = cache[key] ?? cache[_key('guest', bookId)];
    if (existing != null) {
      cache[key] = existing.copyWith(
        progress: progress,
        downloadedBytes: Value(downloadedBytes),
        updatedAt: DateTime.now(),
      );
      await _persist();
    }
  }

  static Future<void> markCompleted(
    String bookId,
    String userId,
    String localPath,
    String? checksum, {
    String? localCoverPath,
  }) async {
    final cache = await _ensureLoaded();
    final key = _key(userId, bookId);
    final existing = cache[key] ?? cache[_key('guest', bookId)];
    if (existing != null) {
      cache[key] = existing.copyWith(
        status: 'completed',
        progress: 1.0,
        localContentPath: Value(localPath),
        localCoverPath: localCoverPath != null
            ? Value(localCoverPath)
            : existing.localCoverPath != null
                ? Value(existing.localCoverPath)
                : const Value.absent(),
        contentChecksum: Value(checksum),
        downloadedAt: Value(DateTime.now()),
        lastVerifiedAt: Value(DateTime.now()),
        updatedAt: DateTime.now(),
      );
      await _persist();
    }
  }

  static Future<void> updateCoverUrl(String bookId, String coverUrl) async {
    final cache = await _ensureLoaded();
    bool changed = false;
    for (final key in cache.keys.toList()) {
      if (cache[key]?.bookId == bookId) {
        cache[key] = cache[key]!.copyWith(
          coverUrl: Value(coverUrl),
          updatedAt: DateTime.now(),
        );
        changed = true;
      }
    }
    if (changed) await _persist();
  }

  static Future<void> markFailed(String bookId, String userId, String error) async {
    final cache = await _ensureLoaded();
    final key = _key(userId, bookId);
    final existing = cache[key] ?? cache[_key('guest', bookId)];
    if (existing != null) {
      cache[key] = existing.copyWith(
        status: 'failed',
        lastError: Value(error),
        updatedAt: DateTime.now(),
      );
      await _persist();
    }
  }

  static Future<void> markCancelled(String bookId, String userId) async {
    final cache = await _ensureLoaded();
    final key = _key(userId, bookId);
    final existing = cache[key] ?? cache[_key('guest', bookId)];
    if (existing != null) {
      cache[key] = existing.copyWith(
        status: 'cancelled',
        updatedAt: DateTime.now(),
      );
      await _persist();
    }
  }

  static Future<void> updateLastOpened(String bookId, String userId) async {
    final cache = await _ensureLoaded();
    final key = _key(userId, bookId);
    final existing = cache[key] ?? cache[_key('guest', bookId)];
    if (existing != null) {
      cache[key] = existing.copyWith(
        lastOpenedAt: Value(DateTime.now()),
        updatedAt: DateTime.now(),
      );
      await _persist();
    }
  }

  static Future<int> deleteRecord(String bookId, String userId) async {
    final cache = await _ensureLoaded();
    final key = _key(userId, bookId);
    bool removed = cache.remove(key) != null;
    removed = cache.remove(_key('guest', bookId)) != null || removed;
    final otherKeys = cache.keys
        .where((k) => k.endsWith('_$bookId') || k == bookId)
        .toList();
    for (final k in otherKeys) {
      cache.remove(k);
      removed = true;
    }
    if (removed) {
      await _persist();
      return 1;
    }
    return 0;
  }

  static Future<List<LocalDownloadedBookData>> getAllCompleted(String userId) async {
    final cache = await _ensureLoaded();
    return _filter(cache.values, userId, completedOnly: true);
  }
}

