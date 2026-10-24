// lib/core/database/tables/local_live_recordings_table.dart
//
// Local SQLite table tracking live-stream recordings captured on this device.
//
// Recording types and honest capability notes:
//   AUDIO_ONLY — M4A/AAC recorded via the `record` package alongside an RTMP
//                broadcast.  This is the only format available without a native
//                platform plugin, because `apivideo_live_stream` does not expose
//                a local video-file output.  The broadcaster's video is NOT
//                captured in this file — it goes exclusively to the RTMP ingest.
//   AV_NATIVE   — Future: requires a platform channel / native MediaRecorder.
//                 Currently unsupported; reserved for a future native plugin.

import 'package:drift/drift.dart';

/// Status values for a recording file on this device.
enum LocalRecordingStatus {
  /// Actively recording right now.
  recording,
  /// Recording stopped; file is finalized and playable.
  complete,
  /// Recording stopped before finalization (app kill, OOM, etc.).
  incomplete,
  /// Recording failed before any data was written.
  failed,
  /// File is being uploaded to the server.
  uploading,
  /// File was successfully uploaded.
  uploaded,
  /// Upload failed; local copy retained.
  uploadFailed,
}

/// What media is in the recording file.
enum LocalRecordingType {
  /// Audio track only (M4A/AAC, microphone input).
  audioOnly,
  /// Audio + video (not yet implemented; reserved).
  audioVideo,
}

@DataClassName('LocalLiveRecordingData')
class LocalLiveRecordings extends Table {
  /// Unique local UUID for this recording row.
  TextColumn get id => text()();

  /// Server-side stream ID this recording belongs to.
  TextColumn get streamId => text()();

  /// Stream title at the time of recording (denormalized for display).
  TextColumn get streamTitle => text().withDefault(const Constant(''))();

  // ── File information ─────────────────────────────────────────────────────

  /// Absolute path of the recording file on this device.
  /// Null until recording starts successfully.
  TextColumn get localFilePath => text().nullable()();

  /// MIME type: 'audio/mp4' for M4A or 'video/mp4' for future AV files.
  TextColumn get mimeType => text().withDefault(const Constant('audio/mp4'))();

  /// What media the file contains (see [LocalRecordingType]).
  TextColumn get recordingType =>
      text().withDefault(const Constant('audioOnly'))();

  /// File size in bytes — filled after finalization.
  IntColumn get fileSizeBytes =>
      integer().withDefault(const Constant(0))();

  /// Recorded duration in seconds — filled after finalization.
  IntColumn get durationSeconds =>
      integer().withDefault(const Constant(0))();

  // ── Status ───────────────────────────────────────────────────────────────

  /// Current status (see [LocalRecordingStatus]).
  TextColumn get status =>
      text().withDefault(const Constant('recording'))();

  /// Human-readable error if status == 'failed' or 'uploadFailed'.
  TextColumn get errorMessage => text().nullable()();

  // ── Upload tracking ──────────────────────────────────────────────────────

  /// URL of the uploaded file on the server (filled after successful upload).
  TextColumn get uploadedUrl => text().nullable()();

  /// Upload progress 0.0–1.0 (transient, may be 0 after app restart).
  RealColumn get uploadProgress =>
      real().withDefault(const Constant(0.0))();

  /// Number of upload attempts made so far.
  IntColumn get uploadAttempts =>
      integer().withDefault(const Constant(0))();

  // ── Timestamps ───────────────────────────────────────────────────────────

  /// When the recording started (UTC).
  DateTimeColumn get startedAt => dateTime()();

  /// When recording stopped / finalized (UTC). Null while still recording.
  DateTimeColumn get finishedAt => dateTime().nullable()();

  /// When the row was last updated.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
