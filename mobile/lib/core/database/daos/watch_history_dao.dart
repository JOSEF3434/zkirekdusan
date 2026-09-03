// lib/core/database/daos/watch_history_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/local_watch_history_table.dart';

part 'watch_history_dao.g.dart';

@DriftAccessor(tables: [LocalWatchHistory])
class WatchHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$WatchHistoryDaoMixin {
  WatchHistoryDao(super.db);

  Future<void> upsertWatchHistory(LocalWatchHistoryCompanion entry) {
    return into(localWatchHistory).insertOnConflictUpdate(entry);
  }

  Future<List<LocalWatchHistoryData>> getWatchHistory(String userId,
      {int limit = 50}) {
    return (select(localWatchHistory)
          ..where((tbl) => tbl.userId.equals(userId))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.watchedAt, mode: OrderingMode.desc)
          ])
          ..limit(limit))
        .get();
  }

  Future<LocalWatchHistoryData?> getVideoHistory(
      String userId, String videoId) {
    return (select(localWatchHistory)
          ..where(
              (tbl) => tbl.userId.equals(userId) & tbl.videoId.equals(videoId)))
        .getSingleOrNull();
  }

  Future<List<LocalWatchHistoryData>> getUnsyncedHistory() {
    return (select(localWatchHistory)
          ..where((tbl) => tbl.synced.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.watchedAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Future<void> markSynced(String id) {
    return (update(localWatchHistory)..where((tbl) => tbl.id.equals(id)))
        .write(
      const LocalWatchHistoryCompanion(
        synced: Value(true),
      ),
    );
  }

  Future<int> deleteHistoryItem(String id) {
    return (delete(localWatchHistory)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> clearUserHistory(String userId) {
    return (delete(localWatchHistory)..where((tbl) => tbl.userId.equals(userId)))
        .go();
  }
}
