// lib/core/database/tables/local_search_history_table.dart
import 'package:drift/drift.dart';

@DataClassName('LocalSearchHistoryData')
class LocalSearchHistory extends Table {
  TextColumn get id => text()();
  TextColumn get query => text()();
  TextColumn get category => text().nullable()();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
