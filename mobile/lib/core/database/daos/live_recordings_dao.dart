// lib/core/database/daos/live_recordings_dao.dart
//
// Data Access Object for local live-stream recordings.

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/local_live_recordings_table.dart';

part 'live_recordings_dao.g.dart';

@DriftAccessor(tables: [LocalLiveRecordings])
class LiveRecordingsDao extends DatabaseAccessor<AppDatabase>
    with _$LiveRecordingsDaoMixin {
  LiveRecordingsDao(super.db);

  /// Insert a new recording row when recording starts.
  Future<void> insertRecording(LocalLiveRecordingsCompanion row) =>
      into(localLiveRecordings).insert(row);

  /// Update any fields on an existing recording row.
  Future<bool> updateRecording(LocalLiveRecordingsCompanion row) =>
      update(localLiveRecordings).replace(row);

  /// Update individual fields without replacing the whole row.
  Future<int> updateRecordingFields({
    required String id,
    String? status,
    String? errorMessage,
    String? localFilePath,
    int? fileSizeBytes,
    int? durationSeconds,
    String? uploadedUrl,
    double? uploadProgress,
    int? uploadAttempts,
    DateTime? finishedAt,
  }) {
    return (update(localLiveRecordings)..where((r) => r.id.equals(id))).write(
      LocalLiveRecordingsCompanion(
        status: status != null ? Value(status) : const Value.absent(),
        errorMessage: errorMessage != null
            ? Value(errorMessage)
            : const Value.absent(),
        localFilePath: localFilePath != null
            ? Value(localFilePath)
            : const Value.absent(),
        fileSizeBytes: fileSizeBytes != null
            ? Value(fileSizeBytes)
            : const Value.absent(),
        durationSeconds: durationSeconds != null
            ? Value(durationSeconds)
            : const Value.absent(),
        uploadedUrl: uploadedUrl != null
            ? Value(uploadedUrl)
            : const Value.absent(),
        uploadProgress: uploadProgress != null
            ? Value(uploadProgress)
            : const Value.absent(),
        uploadAttempts: uploadAttempts != null
            ? Value(uploadAttempts)
            : const Value.absent(),
        finishedAt:
            finishedAt != null ? Value(finishedAt) : const Value.absent(),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Load all recordings, newest first.
  Future<List<LocalLiveRecordingData>> getAllRecordings() =>
      (select(localLiveRecordings)
            ..orderBy([(r) => OrderingTerm.desc(r.startedAt)]))
          .get();

  /// Load recordings for a specific stream.
  Future<List<LocalLiveRecordingData>> getRecordingsForStream(
    String streamId,
  ) =>
      (select(localLiveRecordings)
            ..where((r) => r.streamId.equals(streamId))
            ..orderBy([(r) => OrderingTerm.desc(r.startedAt)]))
          .get();

  /// Watch all recordings as a live stream (auto-updates on change).
  Stream<List<LocalLiveRecordingData>> watchAllRecordings() =>
      (select(localLiveRecordings)
            ..orderBy([(r) => OrderingTerm.desc(r.startedAt)]))
          .watch();

  /// Get a single recording by ID.
  Future<LocalLiveRecordingData?> getRecordingById(String id) =>
      (select(localLiveRecordings)..where((r) => r.id.equals(id)))
          .getSingleOrNull();

  /// Delete a recording row. Caller is responsible for deleting the file.
  Future<int> deleteRecording(String id) =>
      (delete(localLiveRecordings)..where((r) => r.id.equals(id))).go();

  /// Find recordings still in 'recording' state at startup
  /// (likely left orphaned after a previous app crash).
  Future<List<LocalLiveRecordingData>> getOrphanedRecordings() =>
      (select(localLiveRecordings)
            ..where((r) => r.status.equals('recording')))
          .get();

  /// Count how many recordings are pending upload.
  Future<int> countPendingUploads() async {
    final rows = await (select(localLiveRecordings)
          ..where(
            (r) =>
                r.status.equals('complete') |
                r.status.equals('uploadFailed'),
          ))
        .get();
    return rows.length;
  }
}
