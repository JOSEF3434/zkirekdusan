// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_history_dao.dart';

// ignore_for_file: type=lint
mixin _$WatchHistoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalWatchHistoryTable get localWatchHistory =>
      attachedDatabase.localWatchHistory;
  WatchHistoryDaoManager get managers => WatchHistoryDaoManager(this);
}

class WatchHistoryDaoManager {
  final _$WatchHistoryDaoMixin _db;
  WatchHistoryDaoManager(this._db);
  $$LocalWatchHistoryTableTableManager get localWatchHistory =>
      $$LocalWatchHistoryTableTableManager(
        _db.attachedDatabase,
        _db.localWatchHistory,
      );
}
