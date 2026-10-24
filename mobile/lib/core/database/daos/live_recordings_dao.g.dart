// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_recordings_dao.dart';

// ignore_for_file: type=lint
mixin _$LiveRecordingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalLiveRecordingsTable get localLiveRecordings =>
      attachedDatabase.localLiveRecordings;
  LiveRecordingsDaoManager get managers => LiveRecordingsDaoManager(this);
}

class LiveRecordingsDaoManager {
  final _$LiveRecordingsDaoMixin _db;
  LiveRecordingsDaoManager(this._db);
  $$LocalLiveRecordingsTableTableManager get localLiveRecordings =>
      $$LocalLiveRecordingsTableTableManager(
        _db.attachedDatabase,
        _db.localLiveRecordings,
      );
}
