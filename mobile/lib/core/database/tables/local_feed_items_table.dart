// lib/core/database/tables/local_feed_items_table.dart
import 'package:drift/drift.dart';

@DataClassName('LocalFeedItemData')
class LocalFeedItems extends Table {
  TextColumn get id => text()(); // Post or Video server ID
  TextColumn get feedType => text().withDefault(const Constant('HOME'))(); // HOME, TRENDING, LATEST
  TextColumn get title => text()();
  TextColumn get caption => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  TextColumn get videoUrl => text().nullable()();
  TextColumn get hlsUrl => text().nullable()();
  IntColumn get duration => integer().withDefault(const Constant(0))();

  // Author details
  TextColumn get authorId => text().nullable()();
  TextColumn get authorUsername => text().nullable()();
  TextColumn get authorDisplayName => text().nullable()();
  TextColumn get authorAvatarUrl => text().nullable()();

  // Stats
  IntColumn get viewsCount => integer().withDefault(const Constant(0))();
  IntColumn get likesCount => integer().withDefault(const Constant(0))();
  IntColumn get commentsCount => integer().withDefault(const Constant(0))();
  BoolColumn get isLiked => boolean().withDefault(const Constant(false))();
  BoolColumn get isSaved => boolean().withDefault(const Constant(false))();

  DateTimeColumn get publishedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
