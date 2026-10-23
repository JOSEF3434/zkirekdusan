// test/core/database/drift_database_test.dart
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

  group('Drift Database - VideosDao', () {
    test('upsert and retrieve downloaded video', () async {
      final now = DateTime.now();
      await db.videosDao.upsertVideo(
        LocalVideosCompanion(
          id: const drift.Value('vid_123'),
          title: const drift.Value('Saint Yared Hymn'),
          isDownloaded: const drift.Value(true),
          downloadStatus: const drift.Value('completed'),
          localFilePath: const drift.Value('/storage/videos/vid_123/720p.mp4'),
          fileSizeBytes: const drift.Value(45000000),
          createdAt: drift.Value(now),
        ),
      );

      final video = await db.videosDao.getVideoById('vid_123');
      expect(video, isNotNull);
      expect(video!.title, 'Saint Yared Hymn');
      expect(video.downloadStatus, 'completed');
      expect(video.fileSizeBytes, 45000000);

      final downloaded = await db.videosDao.getDownloadedVideos();
      expect(downloaded.length, 1);
      expect(downloaded.first.id, 'vid_123');
    });

    test('update last played position', () async {
      await db.videosDao.upsertVideo(
        const LocalVideosCompanion(
          id: drift.Value('vid_456'),
          title: drift.Value('History of Debre Damo'),
        ),
      );

      await db.videosDao.updateLastPlayed('vid_456', 142);
      final video = await db.videosDao.getVideoById('vid_456');
      expect(video!.lastPlayedPosition, 142);
    });
  });

  group('Drift Database - MessagesDao & SyncQueueDao', () {
    test('insert and stream messages for conversation', () async {
      final now = DateTime.now();
      await db.conversationsDao.upsertConversation(
        LocalConversationsCompanion(
          id: const drift.Value('conv_abc'),
          type: const drift.Value('DIRECT'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      await db.messagesDao.insertMessage(
        LocalMessagesCompanion(
          localId: const drift.Value('msg_client_1'),
          clientId: const drift.Value('msg_client_1'),
          conversationId: const drift.Value('conv_abc'),
          senderId: const drift.Value('user_me'),
          content: const drift.Value('Selam!'),
          messageType: const drift.Value('TEXT'),
          status: const drift.Value('pending'),
          isPendingSync: const drift.Value(true),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      final messages = await db.messagesDao.getMessagesForConversation(
        'conv_abc',
      );
      expect(messages.length, 1);
      expect(messages.first.content, 'Selam!');
      expect(messages.first.status, 'pending');
      expect(messages.first.isPendingSync, true);

      // Reconcile server id when online
      await db.messagesDao.reconcileServerMessage(
        clientId: 'msg_client_1',
        serverId: 'srv_msg_999',
      );

      final updated = await db.messagesDao.getMessageByLocalId('msg_client_1');
      expect(updated!.serverId, 'srv_msg_999');
      expect(updated.status, 'sent');
      expect(updated.isPendingSync, false);
    });

    test('sync queue FIFO enqueue and status transitions', () async {
      final now = DateTime.now();
      await db.syncQueueDao.enqueue(
        SyncQueueCompanion(
          id: const drift.Value('sync_1'),
          operationType: const drift.Value('SEND_MESSAGE'),
          entityType: const drift.Value('MESSAGE'),
          entityId: const drift.Value('msg_1'),
          payload: const drift.Value('{"content":"test"}'),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );

      final pending = await db.syncQueueDao.getPendingEntries();
      expect(pending.length, 1);
      expect(pending.first.id, 'sync_1');
      expect(pending.first.status, 'pending');

      await db.syncQueueDao.updateEntryStatus('sync_1', 'syncing');
      final all = await db.select(db.syncQueue).get();
      expect(all.first.status, 'syncing');

      await db.syncQueueDao.removeEntry('sync_1');
      final remaining = await db.select(db.syncQueue).get();
      expect(remaining.isEmpty, true);
    });
  });

  group('Drift Database - WatchHistoryDao', () {
    test('upsert watch history and query last position', () async {
      final now = DateTime.now();
      await db.watchHistoryDao.upsertWatchHistory(
        LocalWatchHistoryCompanion(
          id: const drift.Value('usr1_vid1'),
          userId: const drift.Value('usr1'),
          videoId: const drift.Value('vid1'),
          positionSeconds: const drift.Value(320),
          durationSeconds: const drift.Value(600),
          progress: const drift.Value(0.53),
          watchedAt: drift.Value(now),
        ),
      );

      final history = await db.watchHistoryDao.getVideoHistory('usr1', 'vid1');
      expect(history, isNotNull);
      expect(history!.positionSeconds, 320);
      expect(history.progress, closeTo(0.53, 0.01));
    });
  });
}
