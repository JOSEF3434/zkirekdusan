// lib/core/database/daos/feed_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/local_feed_items_table.dart';

part 'feed_dao.g.dart';

@DriftAccessor(tables: [LocalFeedItems])
class FeedDao extends DatabaseAccessor<AppDatabase> with _$FeedDaoMixin {
  FeedDao(super.db);

  Future<void> upsertFeedItems(List<LocalFeedItemsCompanion> items) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(localFeedItems, items);
    });
  }

  Future<List<LocalFeedItemData>> getFeedItems({
    String feedType = 'HOME',
    int limit = 50,
  }) {
    return (select(localFeedItems)
          ..where((tbl) => tbl.feedType.equals(feedType))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.publishedAt, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(
                expression: tbl.cachedAt, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .get();
  }

  Stream<List<LocalFeedItemData>> watchFeedItems({String feedType = 'HOME'}) {
    return (select(localFeedItems)
          ..where((tbl) => tbl.feedType.equals(feedType))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.publishedAt, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(
                expression: tbl.cachedAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<int> clearFeed({String? feedType}) {
    if (feedType != null) {
      return (delete(localFeedItems)
            ..where((tbl) => tbl.feedType.equals(feedType)))
          .go();
    }
    return delete(localFeedItems).go();
  }
}
