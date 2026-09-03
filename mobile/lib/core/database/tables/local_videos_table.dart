// lib/core/database/tables/local_videos_table.dart
import 'package:drift/drift.dart';

@DataClassName('LocalVideoData')
class LocalVideos extends Table {
  TextColumn get id => text()(); // Video ID (serverId or local UUID)
  TextColumn get serverId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  TextColumn get videoUrl => text().nullable()();
  TextColumn get hlsUrl => text().nullable()();
  TextColumn get dashUrl => text().nullable()();
  IntColumn get duration => integer().withDefault(const Constant(0))();
  TextColumn get creatorId => text().nullable()();
  TextColumn get creatorName => text().nullable()();
  TextColumn get creatorAvatar => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  // Offline and download state
  BoolColumn get isDownloaded => boolean().withDefault(const Constant(false))();
  TextColumn get downloadStatus =>
      text().withDefault(const Constant('none'))(); // none, queued, downloading, paused, completed, failed, cancelled
  TextColumn get localFilePath => text().nullable()();
  RealColumn get downloadProgress => real().withDefault(const Constant(0.0))();
  TextColumn get selectedQuality => text().nullable()(); // 360p, 480p, 720p, 1080p, original
  IntColumn get fileSizeBytes => integer().withDefault(const Constant(0))();
  TextColumn get downloadError => text().nullable()();

  // Playback tracking & favorites
  IntColumn get lastPlayedPosition => integer().withDefault(const Constant(0))(); // seconds
  DateTimeColumn get lastAccessedAt => dateTime().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get renditionsJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
