// lib/core/database/daos/sync_queue_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Future<void> enqueue(SyncQueueCompanion entry) {
    return into(syncQueue).insertOnConflictUpdate(entry);
  }

  Future<List<SyncQueueData>> getPendingEntries({int limit = 50}) {
    final now = DateTime.now();
    return (select(syncQueue)
          ..where((tbl) =>
              (tbl.status.equals('pending') &
                  (tbl.nextRetryAt.isNull() |
                      tbl.nextRetryAt.isSmallerOrEqualValue(now))) |
              (tbl.status.equals('failed') &
                  tbl.nextRetryAt.isNotNull() &
                  tbl.nextRetryAt.isSmallerOrEqualValue(now)))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.createdAt, mode: OrderingMode.asc)
          ])
          ..limit(limit))
        .get();
  }

  Stream<int> watchPendingCount() {
    return (select(syncQueue)
          ..where((tbl) =>
              tbl.status.equals('pending') |
              (tbl.status.equals('failed') & tbl.nextRetryAt.isNotNull())))
        .watch()
        .map((list) => list.length);
  }

  Future<void> updateEntryStatus(
    String id,
    String status, {
    int? retryCount,
    DateTime? nextRetryAt,
    String? error,
  }) {
    final now = DateTime.now();
    return (update(syncQueue)..where((tbl) => tbl.id.equals(id))).write(
      SyncQueueCompanion(
        status: Value(status),
        updatedAt: Value(now),
        lastAttemptAt: Value(now),
        retryCount: retryCount != null ? Value(retryCount) : const Value.absent(),
        nextRetryAt: Value(nextRetryAt),
        errorMessage: Value(error),
      ),
    );
  }

  Future<int> removeEntry(String id) {
    return (delete(syncQueue)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> removeEntriesForEntity(String entityId) {
    return (delete(syncQueue)..where((tbl) => tbl.entityId.equals(entityId)))
        .go();
  }

  Future<int> clearCompleted() {
    return (delete(syncQueue)..where((tbl) => tbl.status.equals('completed')))
        .go();
  }

  Future<int> getPendingCount() async {
    final list = await (select(syncQueue)
          ..where((tbl) =>
              tbl.status.equals('pending') |
              (tbl.status.equals('failed') & tbl.nextRetryAt.isNotNull())))
        .get();
    return list.length;
  }
}
