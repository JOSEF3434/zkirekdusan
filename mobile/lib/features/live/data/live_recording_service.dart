// lib/features/live/data/live_recording_service.dart
//
// Service that records live-stream audio alongside an active RTMP broadcast
// using the `record` package (AudioRecorder).
//
// ─── PLATFORM CAPABILITY STATEMENT ────────────────────────────────────────────
//
// On ANDROID and iOS this service records the device MICROPHONE audio to an
// M4A/AAC file.  This produces an audio-only recording (no video) because
// the `apivideo_live_stream` broadcaster does not expose a local video-file
// output — the encoded video bitstream goes exclusively to the RTMP ingest
// endpoint and is not accessible to this process.
//
// AUDIO-ONLY LIMITATION: The resulting file captures the broadcaster's
// microphone, not the final broadcast stream.  It is labeled clearly in the
// UI as "Audio Recording" and is NOT presented as a full AV capture.
//
// FULL AV RECORDING REQUIREMENT: A full audio+video local recording would
// require one of:
//   a) A native Android MediaRecorder pipeline that muxes the Camera2 surface
//      output and AudioRecord into an MP4 container (not available in the
//      apivideo_live_stream ^1.2.0 plugin).
//   b) A custom platform channel invoking the Android MediaProjection API.
//   c) A Flutter plugin that supports concurrent RTMP + local file mux.
// This is tracked as a future enhancement.
//
// ON WEB (Flutter Web / WHIP broadcaster): AudioRecorder from the `record`
// package uses the WebAudio API, which in most browsers only works when the
// user explicitly grants permission for a separate getUserMedia call.  Since
// the WHIP broadcaster already holds the microphone track (via flutter_webrtc),
// a concurrent AudioRecorder call WILL conflict and throw 'cameraNotReadable' /
// 'DOMException: NotReadableError'.  Recording is therefore DISABLED on web.
//
// ──────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/tables/local_live_recordings_table.dart';
import 'package:mobile/core/providers/database_provider.dart';

/// Provides the singleton [LiveRecordingService].
final liveRecordingServiceProvider = Provider<LiveRecordingService>((ref) {
  final db = ref.read(appDatabaseProvider);
  final service = LiveRecordingService(db);
  ref.onDispose(service.dispose);
  return service;
});

// ─── Model ───────────────────────────────────────────────────────────────────

/// Current state of the recording service, exposed to the UI.
class LiveRecordingState {
  /// The active (or most recently completed) recording row.
  final LocalLiveRecordingData? recording;

  /// True while [AudioRecorder] is actively capturing audio.
  final bool isRecording;

  /// True when recording was requested but is not supported on this platform.
  final bool platformUnsupported;

  /// Human-readable reason for [platformUnsupported].
  final String? unsupportedReason;

  /// Error message if recording start/stop failed.
  final String? error;

  const LiveRecordingState({
    this.recording,
    this.isRecording = false,
    this.platformUnsupported = false,
    this.unsupportedReason,
    this.error,
  });

  LiveRecordingState copyWith({
    LocalLiveRecordingData? recording,
    bool? isRecording,
    bool? platformUnsupported,
    String? unsupportedReason,
    bool clearError = false,
    String? error,
  }) => LiveRecordingState(
    recording: recording ?? this.recording,
    isRecording: isRecording ?? this.isRecording,
    platformUnsupported: platformUnsupported ?? this.platformUnsupported,
    unsupportedReason: unsupportedReason ?? this.unsupportedReason,
    error: clearError ? null : (error ?? this.error),
  );
}

// ─── Service ─────────────────────────────────────────────────────────────────

class LiveRecordingService extends ChangeNotifier {
  LiveRecordingService(this._db);

  final AppDatabase _db;
  final AudioRecorder _recorder = AudioRecorder();
  final _uuid = const Uuid();

  // Current session state.
  String? _activeRecordingId;
  DateTime? _recordingStartTime;
  Timer? _durationTracker;
  int _elapsedSeconds = 0;

  LiveRecordingState _state = const LiveRecordingState();
  LiveRecordingState get state => _state;

  void _setState(LiveRecordingState s) {
    _state = s;
    notifyListeners();
  }

  // ─── Platform check ─────────────────────────────────────────────────────

  /// Returns `null` if recording is supported, or an explanation string if not.
  String? _checkPlatformSupport() {
    if (kIsWeb) {
      return 'Audio recording during a live stream is not supported on '
          'Flutter Web because the WHIP broadcaster already holds the '
          'microphone track (WebRTC MediaStream). Requesting a second '
          'getUserMedia() call would throw NotReadableError in most browsers.';
    }
    // Android and iOS are supported via the `record` package.
    return null;
  }

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Start recording microphone audio for a given [streamId].
  ///
  /// - On web: returns immediately with [LiveRecordingState.platformUnsupported].
  /// - On mobile: opens an AudioRecorder to an M4A file in the app's documents
  ///   directory and persists a row in [LocalLiveRecordings].
  ///
  /// Returns the recording row ID (UUID) on success, or null if unsupported.
  Future<String?> startRecording({
    required String streamId,
    required String streamTitle,
  }) async {
    // 1. Platform check — fail gracefully, never throw to caller.
    final unsupported = _checkPlatformSupport();
    if (unsupported != null) {
      debugPrint('[LiveRecording] Unsupported: $unsupported');
      _setState(_state.copyWith(
        platformUnsupported: true,
        unsupportedReason: unsupported,
      ));
      return null;
    }

    // 2. Stop any previous session first.
    if (_state.isRecording) {
      await stopRecording();
    }

    // 3. Check microphone permission.
    final hasMic = await _recorder.hasPermission();
    if (!hasMic) {
      const reason = 'Microphone permission is required for local recording.';
      debugPrint('[LiveRecording] $reason');
      _setState(_state.copyWith(error: reason));
      return null;
    }

    final id = _uuid.v4();
    final startTime = DateTime.now().toUtc();

    try {
      // 4. Build file path in the app documents directory so it persists across
      //    app restarts and is excluded from media-scanner auto-deletion.
      final docsDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory(p.join(docsDir.path, 'live_recordings'));
      if (!recordingsDir.existsSync()) {
        recordingsDir.createSync(recursive: true);
      }
      final fileName =
          'live_${streamId.substring(0, streamId.length.clamp(0, 8))}_'
          '${startTime.millisecondsSinceEpoch}.m4a';
      final filePath = p.join(recordingsDir.path, fileName);

      // 5. Insert DB row BEFORE starting the recorder so we always have a row
      //    to mark 'failed' even if the recorder crashes immediately.
      await _db.liveRecordingsDao.insertRecording(
        LocalLiveRecordingsCompanion(
          id: Value(id),
          streamId: Value(streamId),
          streamTitle: Value(streamTitle),
          localFilePath: Value(filePath),
          mimeType: const Value('audio/mp4'),
          recordingType: const Value('audioOnly'),
          status: const Value('recording'),
          startedAt: Value(startTime),
          updatedAt: Value(startTime),
        ),
      );

      // 6. Start the AudioRecorder.
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
          numChannels: 2, // Stereo — matches most mobile mics.
        ),
        path: filePath,
      );

      _activeRecordingId = id;
      _recordingStartTime = startTime;
      _elapsedSeconds = 0;

      // 7. Start a ticker to track elapsed time.
      _durationTracker?.cancel();
      _durationTracker = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsedSeconds++;
      });

      final row = await _db.liveRecordingsDao.getRecordingById(id);
      _setState(LiveRecordingState(recording: row, isRecording: true));

      debugPrint(
        '[LiveRecording] Started audio-only recording → $filePath',
      );
      return id;
    } catch (e, st) {
      debugPrint('[LiveRecording] Failed to start: $e\n$st');
      // Mark row as failed in DB (it may or may not exist depending on where
      // the error occurred — best-effort).
      await _db.liveRecordingsDao.updateRecordingFields(
        id: id,
        status: 'failed',
        errorMessage: e.toString(),
        finishedAt: DateTime.now().toUtc(),
      );
      _setState(_state.copyWith(
        isRecording: false,
        error: 'Recording failed to start: $e',
      ));
      return null;
    }
  }

  /// Stop the active recording, finalize the file, and update the DB row.
  ///
  /// Returns the [LocalLiveRecordingData] for the finished recording, or null
  /// if no active session exists.
  Future<LocalLiveRecordingData?> stopRecording() async {
    if (!_state.isRecording || _activeRecordingId == null) return null;

    _durationTracker?.cancel();
    _durationTracker = null;

    final id = _activeRecordingId!;
    _activeRecordingId = null;
    final finishedAt = DateTime.now().toUtc();
    final durationSecs = _recordingStartTime != null
        ? finishedAt.difference(_recordingStartTime!).inSeconds
        : _elapsedSeconds;
    _recordingStartTime = null;
    _elapsedSeconds = 0;

    try {
      // Stop the recorder — this finalizes and flushes the file.
      final filePath = await _recorder.stop();

      if (filePath == null || filePath.isEmpty) {
        debugPrint('[LiveRecording] Recorder returned null path — file lost.');
        await _db.liveRecordingsDao.updateRecordingFields(
          id: id,
          status: 'incomplete',
          errorMessage: 'Recorder returned no file path after stop().',
          durationSeconds: durationSecs,
          finishedAt: finishedAt,
        );
        _setState(_state.copyWith(isRecording: false));
        return null;
      }

      // Measure the actual file size.
      int fileSizeBytes = 0;
      try {
        fileSizeBytes = File(filePath).lengthSync();
      } catch (_) {}

      // Update DB row to 'complete'.
      await _db.liveRecordingsDao.updateRecordingFields(
        id: id,
        status: fileSizeBytes > 0 ? 'complete' : 'incomplete',
        localFilePath: filePath,
        fileSizeBytes: fileSizeBytes,
        durationSeconds: durationSecs,
        finishedAt: finishedAt,
      );

      final row = await _db.liveRecordingsDao.getRecordingById(id);
      _setState(LiveRecordingState(recording: row, isRecording: false));

      debugPrint(
        '[LiveRecording] Stopped. File: $filePath  '
        'size=${fileSizeBytes}B  duration=${durationSecs}s',
      );
      return row;
    } catch (e, st) {
      debugPrint('[LiveRecording] Error stopping recording: $e\n$st');
      await _db.liveRecordingsDao.updateRecordingFields(
        id: id,
        status: 'incomplete',
        errorMessage: e.toString(),
        durationSeconds: durationSecs,
        finishedAt: DateTime.now().toUtc(),
      );
      _setState(_state.copyWith(
        isRecording: false,
        error: 'Recording stop failed: $e',
      ));
      return null;
    }
  }

  /// Called at app startup to mark any 'recording' rows left by a previous
  /// crash as 'incomplete'.  Does not delete files.
  Future<void> reconcileOrphanedRecordings() async {
    if (kIsWeb) return;
    try {
      final orphans = await _db.liveRecordingsDao.getOrphanedRecordings();
      for (final row in orphans) {
        // Check whether the file was actually written at all.
        int size = 0;
        if (row.localFilePath != null) {
          try {
            size = File(row.localFilePath!).lengthSync();
          } catch (_) {}
        }
        await _db.liveRecordingsDao.updateRecordingFields(
          id: row.id,
          status: size > 0 ? 'incomplete' : 'failed',
          errorMessage: 'App was closed during recording.',
          finishedAt: DateTime.now().toUtc(),
        );
        debugPrint(
          '[LiveRecording] Reconciled orphan ${row.id}: '
          'size=$size → ${size > 0 ? 'incomplete' : 'failed'}',
        );
      }
    } catch (e) {
      debugPrint('[LiveRecording] reconcileOrphanedRecordings error: $e');
    }
  }

  @override
  void dispose() {
    _durationTracker?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}
