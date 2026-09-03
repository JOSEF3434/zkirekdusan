// lib/core/database/tables/sync_queue_table.dart
import 'package:drift/drift.dart';

@DataClassName('SyncQueueData')
class SyncQueue extends Table {
  TextColumn get id => text()(); // UUID
  // CREATE_MESSAGE, EDIT_MESSAGE, DELETE_MESSAGE, SEND_REACTION, REMOVE_REACTION, UPDATE_READ_STATE, UPDATE_WATCH_HISTORY, CREATE_LIKE, REMOVE_LIKE
  TextColumn get operationType => text()();
  // MESSAGE, REACTION, READ_STATE, WATCH_HISTORY, LIKE
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get payload => text()(); // JSON payload

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();

  // pending, in_progress, failed, completed
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
