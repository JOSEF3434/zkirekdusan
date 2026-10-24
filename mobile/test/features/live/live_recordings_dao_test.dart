// test/features/live/live_recordings_dao_test.dart
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('LiveRecordingsDao SQLite & Drift Operations', () {
    test('insertRecording and getRecordingById', () async {
      final now = DateTime.now().toUtc();
      const recId = 'rec-test-uuid-1';
      const streamId = 'stream-abc-123';

      await db.liveRecordingsDao.insertRecording(
        LocalLiveRecordingsCompanion(
          id: const drift.Value(recId),
          streamId: const drift.Value(streamId),
          streamTitle: const drift.Value('Holy Liturgy Live Broadcast'),
          status: const drift.Value('recording'),
          mimeType: const drift.Value('audio/mp4'),
          recordingType: const drift.Value('audioOnly'),
          startedAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      final row = await db.liveRecordingsDao.getRecordingById(recId);
      expect(row, isNotNull);
      expect(row!.id, recId);
      expect(row.streamId, streamId);
      expect(row.streamTitle, 'Holy Liturgy Live Broadcast');
      expect(row.status, 'recording');
      expect(row.mimeType, 'audio/mp4');
      expect(row.recordingType, 'audioOnly');
      expect(row.durationSeconds, 0);
      expect(row.fileSizeBytes, 0);
    });

    test('updateRecordingFields on completion with file path and size', () async {
      final started = DateTime.now().toUtc().subtract(const Duration(minutes: 45));
      final finished = DateTime.now().toUtc();
      const recId = 'rec-test-uuid-2';
      const streamId = 'stream-xyz-456';

      await db.liveRecordingsDao.insertRecording(
        LocalLiveRecordingsCompanion(
          id: const drift.Value(recId),
          streamId: const drift.Value(streamId),
          streamTitle: const drift.Value('Evening Prayer & Teachings'),
          status: const drift.Value('recording'),
          mimeType: const drift.Value('audio/mp4'),
          recordingType: const drift.Value('audioOnly'),
          startedAt: drift.Value(started),
          updatedAt: drift.Value(started),
        ),
      );

      // Finalize the recording
      await db.liveRecordingsDao.updateRecordingFields(
        id: recId,
        status: 'completed',
        localFilePath: '/data/user/0/org.zikrekidusan.app/app_flutter/rec_2.m4a',
        durationSeconds: 2700,
        fileSizeBytes: 32450000,
        finishedAt: finished,
      );

      final updated = await db.liveRecordingsDao.getRecordingById(recId);
      expect(updated, isNotNull);
      expect(updated!.status, 'completed');
      expect(updated.durationSeconds, 2700);
      expect(updated.fileSizeBytes, 32450000);
      expect(updated.localFilePath, contains('rec_2.m4a'));
      expect(updated.finishedAt, isNotNull);
    });

    test('getRecordingsForStream and deleteRecording', () async {
      const streamId = 'stream-multi-rec';
      final now = DateTime.now().toUtc();

      await db.liveRecordingsDao.insertRecording(
        LocalLiveRecordingsCompanion.insert(
          id: 'rec-1',
          streamId: streamId,
          streamTitle: const drift.Value('Part 1'),
          status: const drift.Value('completed'),
          mimeType: const drift.Value('audio/mp4'),
          recordingType: const drift.Value('audioOnly'),
          startedAt: now,
          updatedAt: now,
        ),
      );

      await db.liveRecordingsDao.insertRecording(
        LocalLiveRecordingsCompanion.insert(
          id: 'rec-2',
          streamId: streamId,
          streamTitle: const drift.Value('Part 2'),
          status: const drift.Value('completed'),
          mimeType: const drift.Value('audio/mp4'),
          recordingType: const drift.Value('audioOnly'),
          startedAt: now,
          updatedAt: now,
        ),
      );

      final forStream = await db.liveRecordingsDao.getRecordingsForStream(streamId);
      expect(forStream.length, 2);

      final deletedCount = await db.liveRecordingsDao.deleteRecording('rec-1');
      expect(deletedCount, 1);

      final remaining = await db.liveRecordingsDao.getRecordingsForStream(streamId);
      expect(remaining.length, 1);
      expect(remaining.first.id, 'rec-2');
    });

    test('watchAllRecordings emits updates in real time', () async {
      final stream = db.liveRecordingsDao.watchAllRecordings();
      final initial = await stream.first;
      expect(initial, isEmpty);

      final now = DateTime.now().toUtc();
      await db.liveRecordingsDao.insertRecording(
        LocalLiveRecordingsCompanion.insert(
          id: 'rec-stream-test',
          streamId: 'stream-reactive',
          streamTitle: const drift.Value('Sunday Sermon'),
          status: const drift.Value('recording'),
          mimeType: const drift.Value('audio/mp4'),
          recordingType: const drift.Value('audioOnly'),
          startedAt: now,
          updatedAt: now,
        ),
      );

      final updated = await stream.first;
      expect(updated.length, 1);
      expect(updated.first.id, 'rec-stream-test');
    });
  });
}
