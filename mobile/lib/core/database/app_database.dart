import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

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
import 'tables/local_downloaded_books_table.dart';
import 'tables/local_live_recordings_table.dart';


import 'daos/users_dao.dart';
import 'daos/videos_dao.dart';
import 'daos/conversations_dao.dart';
import 'daos/messages_dao.dart';
import 'daos/watch_history_dao.dart';
import 'daos/sync_queue_dao.dart';
import 'daos/feed_dao.dart';
import 'daos/search_history_dao.dart';
import 'daos/calendar_notes_dao.dart';
import 'daos/downloaded_books_dao.dart';
import 'daos/live_recordings_dao.dart';


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
    LocalCalendarSyncMetadata,
    SyncQueue,
    LocalDownloadedBooks,
    LocalLiveRecordings,
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
    DownloadedBooksDao,
    LiveRecordingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  static QueryExecutor _openConnection() {
    if (kIsWeb) {
      return _SafeWebQueryExecutor();
    }
    return driftDatabase(
      name: 'zikre_kidusan_local_v1.db',
    );
  }

  @override
  int get schemaVersion => 7;

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

      if (from < 4) {
        final columns = await m.database
            .customSelect('PRAGMA table_info(local_calendar_notes)')
            .get();
        final existingColumns = columns
            .map((row) => row.read<String>('name'))
            .toSet();
        final additions = <String, GeneratedColumn Function()>{
          'reminder_repeat': () => localCalendarNotes.reminderRepeat,
          'reminder_ethiopian_month': () =>
              localCalendarNotes.reminderEthiopianMonth,
          'reminder_ethiopian_day': () =>
              localCalendarNotes.reminderEthiopianDay,
          'reminder_hour': () => localCalendarNotes.reminderHour,
          'reminder_minute': () => localCalendarNotes.reminderMinute,
          'reminder_timezone': () => localCalendarNotes.reminderTimezone,
          'reminder_next_occurrence': () =>
              localCalendarNotes.reminderNextOccurrence,
        };
        for (final entry in additions.entries) {
          if (!existingColumns.contains(entry.key)) {
            await m.addColumn(localCalendarNotes, entry.value());
          }
        }
      }

      // Version 5: Add downloaded books table for offline reading
      if (from < 5) {
        await m.createTable(localDownloadedBooks);
      }

      // Version 6: Add local live recordings table
      if (from < 6) {
        await m.createTable(localLiveRecordings);
      }

      // Version 7: Add recurrence, category, publication fields and sync metadata
      if (from < 7) {
        final columns = await m.database
            .customSelect('PRAGMA table_info(local_calendar_notes)')
            .get();
        final existingColumns = columns
            .map((row) => row.read<String>('name'))
            .toSet();
        final additions = <String, GeneratedColumn Function()>{
          'category': () => localCalendarNotes.category,
          'recurrence_type': () => localCalendarNotes.recurrenceType,
          'is_auto_publish_enabled': () =>
              localCalendarNotes.isAutoPublishEnabled,
          'auto_publish_time': () => localCalendarNotes.autoPublishTime,
          'publication_status': () => localCalendarNotes.publicationStatus,
          'next_publication_date': () => localCalendarNotes.nextPublicationDate,
          'generated_post_id': () => localCalendarNotes.generatedPostId,
          'remote_id': () => localCalendarNotes.remoteId,
        };
        for (final entry in additions.entries) {
          if (!existingColumns.contains(entry.key)) {
            await m.addColumn(localCalendarNotes, entry.value());
          }
        }
        await m.createTable(localCalendarSyncMetadata);
      }
    },
    beforeOpen: (OpeningDetails details) async {
      // Enable WAL mode and foreign keys for SQLite
      await customStatement('PRAGMA foreign_keys = ON;');
      await customStatement('PRAGMA journal_mode = WAL;');
    },
  );
}

/// Fallback QueryExecutor for Flutter Web when SQLite WebAssembly is unavailable.
/// Returns safe empty collections and no-op writes, preventing unhandled WebAssembly
/// runtime errors and debugger pauses while the app runs in browser mode.
class _SafeWebQueryExecutor extends QueryExecutor {
  @override
  SqlDialect get dialect => SqlDialect.sqlite;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async => true;

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) async {}

  @override
  Future<int> runInsert(String statement, List<Object?> args) async => 0;

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async => 0;

  @override
  Future<int> runDelete(String statement, List<Object?> args) async => 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) async => [];

  @override
  Future<void> runBatched(BatchedStatements statements) async {}

  @override
  TransactionExecutor beginTransaction() => _SafeWebTransactionExecutor();

  @override
  TransactionExecutor beginExclusive() => _SafeWebTransactionExecutor();

  @override
  Future<void> close() async {}
}

class _SafeWebTransactionExecutor extends _SafeWebQueryExecutor
    implements TransactionExecutor {
  @override
  bool get supportsNestedTransactions => false;

  bool get completesWithCommit => true;

  @override
  Future<void> send() async {}

  @override
  Future<void> rollback() async {}
}

