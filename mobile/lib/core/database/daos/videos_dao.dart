// lib/core/database/daos/videos_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/local_videos_table.dart';

part 'videos_dao.g.dart';

@DriftAccessor(tables: [LocalVideos])
class VideosDao extends DatabaseAccessor<AppDatabase> with _$VideosDaoMixin {
  VideosDao(super.db);

  Future<void> upsertVideo(LocalVideosCompanion video) {
    return into(localVideos).insertOnConflictUpdate(video);
  }

  Future<void> upsertVideos(List<LocalVideosCompanion> videos) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(localVideos, videos);
    });
  }

  Future<LocalVideoData?> getVideoById(String id) {
    return (select(localVideos)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<LocalVideoData?> getVideoByServerId(String serverId) {
    return (select(localVideos)
          ..where((tbl) =>
              tbl.serverId.equals(serverId) | tbl.id.equals(serverId)))
        .getSingleOrNull();
  }

  Future<List<LocalVideoData>> getDownloadedVideos() {
    return (select(localVideos)
          ..where((tbl) =>
              tbl.isDownloaded.equals(true) &
              tbl.downloadStatus.equals('completed'))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.lastAccessedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Stream<List<LocalVideoData>> watchDownloadedVideos() {
    return (select(localVideos)
          ..where((tbl) =>
              tbl.isDownloaded.equals(true) &
              tbl.downloadStatus.equals('completed'))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.lastAccessedAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Stream<LocalVideoData?> watchVideo(String id) {
    return (select(localVideos)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<void> updateDownloadProgress(String id, double progress,
      {int? fileSizeBytes}) {
    return (update(localVideos)..where((tbl) => tbl.id.equals(id))).write(
      LocalVideosCompanion(
        downloadProgress: Value(progress),
        downloadStatus: const Value('downloading'),
        fileSizeBytes: fileSizeBytes != null
            ? Value(fileSizeBytes)
            : const Value.absent(),
      ),
    );
  }

  Future<void> updateDownloadStatus(
    String id,
    String status, {
    String? localFilePath,
    String? error,
    int? fileSizeBytes,
    String? selectedQuality,
  }) {
    final companion = LocalVideosCompanion(
      downloadStatus: Value(status),
      isDownloaded: Value(status == 'completed'),
      localFilePath: Value(localFilePath),
      downloadError: Value(error),
      lastAccessedAt: Value(DateTime.now()),
      downloadProgress: status == 'completed'
          ? const Value(1.0)
          : (status == 'failed' ? const Value(0.0) : const Value.absent()),
      selectedQuality: Value(selectedQuality),
      fileSizeBytes: fileSizeBytes != null ? Value(fileSizeBytes) : const Value.absent(),
    );
    return (update(localVideos)..where((tbl) => tbl.id.equals(id)))
        .write(companion);
  }

  Future<void> updateLastPlayed(String id, int positionSeconds) {
    return (update(localVideos)..where((tbl) => tbl.id.equals(id))).write(
      LocalVideosCompanion(
        lastPlayedPosition: Value(positionSeconds),
        lastAccessedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> toggleFavorite(String id, bool isFavorite) {
    return (update(localVideos)..where((tbl) => tbl.id.equals(id))).write(
      LocalVideosCompanion(isFavorite: Value(isFavorite)),
    );
  }

  Future<int> deleteVideo(String id) {
    return (delete(localVideos)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<List<LocalVideoData>> getAllCachedVideos() {
    return select(localVideos).get();
  }
}
