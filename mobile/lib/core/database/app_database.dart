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
import 'tables/local_calendar_notes_table.dart';
import 'tables/sync_queue_table.dart';

import 'daos/users_dao.dart';
import 'daos/videos_dao.dart';
import 'daos/conversations_dao.dart';
import 'daos/messages_dao.dart';
import 'daos/watch_history_dao.dart';
import 'daos/sync_queue_dao.dart';
import 'daos/feed_dao.dart';
import 'daos/search_history_dao.dart';
import 'daos/calendar_notes_dao.dart';

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
    LocalCalendarNotes,
    LocalCalendarNoteMedia,
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
    CalendarNotesDao,
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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Version 2: Add calendar notes tables
      if (from < 2) {
        await m.createTable(localCalendarNotes);
        await m.createTable(localCalendarNoteMedia);
      }

      // Version 3: Add reminder fields to calendar notes
      if (from < 3) {
        final columns = await m.database
            .customSelect('PRAGMA table_info(local_calendar_notes)')
            .get();
        final existingColumns = columns
            .map((row) => row.read<String>('name'))
            .toSet();

        if (!existingColumns.contains('has_reminder')) {
          await m.addColumn(localCalendarNotes, localCalendarNotes.hasReminder);
        }
        if (!existingColumns.contains('reminder_date_time')) {
          await m.addColumn(
            localCalendarNotes,
            localCalendarNotes.reminderDateTime,
          );
        }
        if (!existingColumns.contains('reminder_notified')) {
          await m.addColumn(
            localCalendarNotes,
            localCalendarNotes.reminderNotified,
          );
        }
      }
    },
    beforeOpen: (OpeningDetails details) async {
      // Enable WAL mode and foreign keys for SQLite
      await customStatement('PRAGMA foreign_keys = ON;');
      await customStatement('PRAGMA journal_mode = WAL;');
    },
  );
}
