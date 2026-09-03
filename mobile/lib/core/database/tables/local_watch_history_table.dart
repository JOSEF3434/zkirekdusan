// lib/core/database/tables/local_watch_history_table.dart
import 'package:drift/drift.dart';

@DataClassName('LocalWatchHistoryData')
class LocalWatchHistory extends Table {
  TextColumn get id => text()(); // Composite or UUID
  TextColumn get videoId => text()();
  TextColumn get userId => text()();
  IntColumn get positionSeconds => integer().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  RealColumn get progress => real().withDefault(const Constant(0.0))();
  DateTimeColumn get watchedAt => dateTime()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  BoolColumn get synced => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastSyncAttemptAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
