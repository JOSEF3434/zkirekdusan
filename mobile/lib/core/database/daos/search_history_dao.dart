// lib/core/database/daos/search_history_dao.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../app_database.dart';
import '../tables/local_search_history_table.dart';

part 'search_history_dao.g.dart';

@DriftAccessor(tables: [LocalSearchHistory])
class SearchHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$SearchHistoryDaoMixin {
  SearchHistoryDao(super.db);

  Future<void> addSearchQuery(
    String query, {
    String? category,
    String? userId,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    // Delete any previous identical query for this user/category to avoid clutter
    final deleteQuery = delete(localSearchHistory)
      ..where((tbl) => tbl.query.equals(trimmed));
    if (userId != null) {
      deleteQuery.where((tbl) => tbl.userId.equals(userId));
    }
    await deleteQuery.go();

    await into(localSearchHistory).insert(
      LocalSearchHistoryCompanion(
        id: Value(const Uuid().v4()),
        query: Value(trimmed),
        category: Value(category),
        userId: Value(userId),
        createdAt: Value(DateTime.now()),
      ),
    );

    // Limit to 30 most recent searches
    final all = await getSearchHistory(userId: userId, limit: 100);
    if (all.length > 30) {
      final excess = all.sublist(30);
      for (final item in excess) {
        await removeSearchQuery(item.id);
      }
    }
  }

  Future<List<LocalSearchHistoryData>> getSearchHistory({
    String? userId,
    int limit = 20,
  }) {
    final query = select(localSearchHistory);
    if (userId != null) {
      query.where((tbl) => tbl.userId.equals(userId) | tbl.userId.isNull());
    }
    query
      ..orderBy([
        (tbl) => OrderingTerm(
            expression: tbl.createdAt, mode: OrderingMode.desc)
      ])
      ..limit(limit);
    return query.get();
  }

  Future<int> removeSearchQuery(String id) {
    return (delete(localSearchHistory)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> clearSearchHistory({String? userId}) {
    if (userId != null) {
      return (delete(localSearchHistory)
            ..where((tbl) => tbl.userId.equals(userId)))
          .go();
    }
    return delete(localSearchHistory).go();
  }
}
