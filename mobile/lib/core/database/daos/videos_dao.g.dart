// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'videos_dao.dart';

// ignore_for_file: type=lint
mixin _$VideosDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalVideosTable get localVideos => attachedDatabase.localVideos;
  VideosDaoManager get managers => VideosDaoManager(this);
}

class VideosDaoManager {
  final _$VideosDaoMixin _db;
  VideosDaoManager(this._db);
  $$LocalVideosTableTableManager get localVideos =>
      $$LocalVideosTableTableManager(_db.attachedDatabase, _db.localVideos);
}
