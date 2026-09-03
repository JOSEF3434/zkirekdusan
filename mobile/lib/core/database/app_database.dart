// lib/core/database/app_database.dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/local_users_table.dart';
import 'tables/local_videos_table.dart';
import 'tables/local_conversations_table.dart';
import 'tables/local_messages_table.dart';
import 'tables/local_message_attachments_table.dart';
import 'tables/local_watch_history_table.dart';
import 'tables/local_search_history_table.dart';
import 'tables/local_feed_items_table.dart';
import 'tables/sync_queue_table.dart';

import 'daos/users_dao.dart';
import 'daos/videos_dao.dart';
import 'daos/conversations_dao.dart';
import 'daos/messages_dao.dart';
import 'daos/watch_history_dao.dart';
import 'daos/sync_queue_dao.dart';
import 'daos/feed_dao.dart';
import 'daos/search_history_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    LocalUsers,
    LocalVideos,
    LocalConversations,
    LocalMessages,
    LocalMessageAttachments,
    LocalWatchHistory,
    LocalSearchHistory,
    LocalFeedItems,
    SyncQueue,
  ],
  daos: [
    UsersDao,
    VideosDao,
    ConversationsDao,
    MessagesDao,
    WatchHistoryDao,
    SyncQueueDao,
    FeedDao,
    SearchHistoryDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'zikre_kidusan_local_v1.db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Future migrations will be added here step-by-step
          // Example:
          // if (from < 2) { ... }
        },
        beforeOpen: (OpeningDetails details) async {
          // Enable WAL mode and foreign keys for SQLite
          await customStatement('PRAGMA foreign_keys = ON;');
          await customStatement('PRAGMA journal_mode = WAL;');
        },
      );
}
