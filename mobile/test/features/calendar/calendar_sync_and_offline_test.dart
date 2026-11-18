// test/features/calendar/calendar_sync_and_offline_test.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
import 'package:mobile/features/calendar/data/calendar_connectivity_sync.dart';
import 'package:mobile/features/calendar/data/calendar_offline_repository.dart';
import 'package:mobile/features/calendar/data/calendar_repository.dart';
import 'package:mobile/features/calendar/data/calendar_sync_service.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';

class FakeCalendarRepository implements CalendarRepository {
  final List<CreateCalendarNoteDto> createdDtos = [];
  final List<int?> queriedYears = [];
  final List<int?> queriedMonths = [];
  final List<String> deletedIds = [];
  List<CalendarNoteModel>? customNotesToReturn;

  bool shouldThrow429OnCreate = false;
  bool shouldThrow429OnGet = false;
  bool shouldThrow400OnCreate = false;
  int notesReturnedPerQuery = 2;

  @override
  Future<CalendarNoteModel> createNote(CreateCalendarNoteDto dto) async {
    if (shouldThrow429OnCreate) {
      throw DioException(
        requestOptions: RequestOptions(path: '/calendar/notes'),
        response: Response(
          requestOptions: RequestOptions(path: '/calendar/notes'),
          statusCode: 429,
        ),
      );
    }
    if (shouldThrow400OnCreate) {
      throw DioException(
        requestOptions: RequestOptions(path: '/calendar/notes'),
        response: Response(
          requestOptions: RequestOptions(path: '/calendar/notes'),
          statusCode: 400,
          data: {'message': 'property allowDownload should not exist'},
        ),
      );
    }
    createdDtos.add(dto);
    return CalendarNoteModel(
      id: dto.id ?? 'server-assigned-id',
      userId: 'test-user',
      ethiopianYear: dto.ethiopianYear,
      ethiopianMonth: dto.ethiopianMonth,
      ethiopianDay: dto.ethiopianDay,
      gregorianDate: DateTime.parse(dto.gregorianDate),
      title: dto.title,
      content: dto.content,
      allowDownload: dto.allowDownload,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<CalendarNoteModel>> getNotes({
    int? year,
    int? month,
    int? day,
    int? startYear,
    int? startMonth,
    int? startDay,
    int? endYear,
    int? endMonth,
    int? endDay,
    String? from,
    String? to,
    DateTime? since,
  }) async {
    queriedYears.add(year);
    queriedMonths.add(month);

    if (shouldThrow429OnGet) {
      throw DioException(
        requestOptions: RequestOptions(path: '/calendar/notes'),
        response: Response(
          requestOptions: RequestOptions(path: '/calendar/notes'),
          statusCode: 429,
        ),
      );
    }

    if (customNotesToReturn != null) {
      return customNotesToReturn!;
    }

    return List.generate(
      notesReturnedPerQuery,
      (i) => CalendarNoteModel(
        id: 'remote-note-$year-$month-$i',
        userId: 'test-user',
        ethiopianYear: year ?? 2018,
        ethiopianMonth: month ?? 1,
        ethiopianDay: i + 1,
        gregorianDate: DateTime(2026, 1, 1 + i),
        title: 'Remote Note $i',
        content: 'Content $i',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<CalendarNoteModel> getNote(String id) async {
    return CalendarNoteModel(
      id: id,
      userId: 'test-user',
      ethiopianYear: 2018,
      ethiopianMonth: 1,
      ethiopianDay: 1,
      gregorianDate: DateTime(2026, 1, 1),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<CalendarNoteModel> updateNote(
    String id,
    UpdateCalendarNoteDto dto,
  ) async {
    return CalendarNoteModel(
      id: id,
      userId: 'test-user',
      ethiopianYear: 2018,
      ethiopianMonth: 1,
      ethiopianDay: 1,
      gregorianDate: DateTime(2026, 1, 1),
      title: dto.title,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteNote(String id) async {
    deletedIds.add(id);
  }

  @override
  Future<void> removeNoteMedia({
    required String noteId,
    required String mediaId,
  }) async {}

  @override
  Future<void> updateNoteMedia({
    required String noteId,
    required String mediaId,
    String? caption,
    int? order,
  }) async {}

  int rollingSyncCalls = 0;
  String? lastRollingStart;
  String? lastRollingEnd;
  String? lastRollingSince;
  bool shouldThrow429OnRollingSync = false;

  @override
  Future<({List<CalendarNoteModel> notes, List<String> deletedIds, String? serverTime})>
      syncRollingWindow({
    int? startYear,
    int? startMonth,
    int? startDay,
    int? endYear,
    int? endMonth,
    int? endDay,
    String? from,
    String? to,
    DateTime? since,
  }) async {
    rollingSyncCalls++;
    lastRollingStart = from ?? (startYear != null ? '$startYear-$startMonth-$startDay' : null);
    lastRollingEnd = to ?? (endYear != null ? '$endYear-$endMonth-$endDay' : null);
    lastRollingSince = since?.toIso8601String();

    if (shouldThrow429OnRollingSync || shouldThrow429OnGet) {
      throw DioException(
        requestOptions: RequestOptions(path: '/calendar/notes/sync'),
        response: Response(
          requestOptions: RequestOptions(path: '/calendar/notes/sync'),
          statusCode: 429,
        ),
      );
    }

    return (
      notes: customNotesToReturn ?? [],
      deletedIds: <String>[],
      serverTime: DateTime.now().toUtc().toIso8601String(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeCalendarRepository remoteRepo;
  late CalendarOfflineRepository offlineRepo;
  late CalendarSyncService syncService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    remoteRepo = FakeCalendarRepository();
    offlineRepo = CalendarOfflineRepository(
      db.calendarNotesDao,
      db.syncQueueDao,
      remoteRepo,
    );
    syncService = CalendarSyncService(offlineRepo);
  });

  tearDown(() async {
    await db.close();
  });

  group('CalendarNotesDao - Offline-First & Unsynced Count', () {
    test('createNote persists with client id and isSynced = false', () async {
      final noteId = await db.calendarNotesDao.createNote(
        id: 'client-note-1',
        userId: 'user-1',
        ethiopianYear: 2018,
        ethiopianMonth: 2,
        ethiopianDay: 12,
        gregorianDate: DateTime(2025, 10, 22),
        title: 'Feast of Saint Michael',
        content: 'Commemoration and prayer',
      );

      expect(noteId, 'client-note-1');

      final note = await db.calendarNotesDao.getNoteById('client-note-1');
      expect(note, isNotNull);
      expect(note!.isSynced, isFalse);
      expect(note.title, 'Feast of Saint Michael');

      final unsyncedCount = await db.calendarNotesDao.getUnsyncedCount();
      expect(unsyncedCount, 1);
    });

    test('watchUnsyncedCount reactively tracks pending notes count', () async {
      final emissions = <int>[];
      final sub = db.calendarNotesDao.watchUnsyncedCount().listen(
        emissions.add,
      );
      await Future.delayed(const Duration(milliseconds: 30));

      // 1. Create first note
      await db.calendarNotesDao.createNote(
        id: 'note-a',
        userId: 'user-1',
        ethiopianYear: 2018,
        ethiopianMonth: 1,
        ethiopianDay: 1,
        gregorianDate: DateTime(2025, 9, 11),
      );
      await Future.delayed(const Duration(milliseconds: 30));

      // 2. Create second note
      await db.calendarNotesDao.createNote(
        id: 'note-b',
        userId: 'user-1',
        ethiopianYear: 2018,
        ethiopianMonth: 1,
        ethiopianDay: 2,
        gregorianDate: DateTime(2025, 9, 12),
      );
      await Future.delayed(const Duration(milliseconds: 30));

      // 3. Mark note-a synced
      await db.calendarNotesDao.markNoteSynced('note-a');
      await Future.delayed(const Duration(milliseconds: 30));

      // 4. Mark note-b synced
      await db.calendarNotesDao.markNoteSynced('note-b');
      await Future.delayed(const Duration(milliseconds: 30));

      expect(emissions, [0, 1, 2, 1, 0]);
      await sub.cancel();
    });

    test(
      'batchUpsertNotesPreservingPending preserves unsynced local pending notes',
      () async {
        // 1. Locally pending note edited by user
        await db.calendarNotesDao.createNote(
          id: 'note-local-pending',
          userId: 'user-1',
          ethiopianYear: 2018,
          ethiopianMonth: 1,
          ethiopianDay: 1,
          gregorianDate: DateTime(2025, 9, 11),
          title: 'Local User Edit',
        );

        // 2. Note already synced
        await db.calendarNotesDao.createNote(
          id: 'note-already-synced',
          userId: 'user-1',
          ethiopianYear: 2018,
          ethiopianMonth: 1,
          ethiopianDay: 2,
          gregorianDate: DateTime(2025, 9, 12),
          title: 'Old Title',
        );
        await db.calendarNotesDao.markNoteSynced('note-already-synced');

        // 3. Incoming batch from server trying to overwrite both
        final companions = [
          LocalCalendarNotesCompanion.insert(
            id: 'note-local-pending',
            userId: 'user-1',
            ethiopianYear: 2018,
            ethiopianMonth: 1,
            ethiopianDay: 1,
            gregorianDate: DateTime(2025, 9, 11),
            title: const drift.Value('Server Stale Title'),
            isSynced: const drift.Value(true),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          LocalCalendarNotesCompanion.insert(
            id: 'note-already-synced',
            userId: 'user-1',
            ethiopianYear: 2018,
            ethiopianMonth: 1,
            ethiopianDay: 2,
            gregorianDate: DateTime(2025, 9, 12),
            title: const drift.Value('Server Updated Title'),
            isSynced: const drift.Value(true),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        await db.calendarNotesDao.batchUpsertNotesPreservingPending(companions);

        final pendingNote = await db.calendarNotesDao.getNoteById(
          'note-local-pending',
        );
        expect(
          pendingNote!.title,
          'Local User Edit',
          reason: 'Locally pending note must not be overwritten by server',
        );
        expect(pendingNote.isSynced, isFalse);

        final syncedNote = await db.calendarNotesDao.getNoteById(
          'note-already-synced',
        );
        expect(
          syncedNote!.title,
          'Server Updated Title',
          reason: 'Clean synced note should be updated by server data',
        );
      },
    );
  });

  group('CalendarOfflineRepository - Offline Creation, allowDownload & Push', () {
    test(
      'createNote saves locally, queues operation with allowDownload, returns immediately',
      () async {
        final note = await offlineRepo.createNote(
          userId: 'user-123',
          ethiopianYear: 2018,
          ethiopianMonth: 2,
          ethiopianDay: 5,
          gregorianDate: DateTime(2025, 10, 15),
          title: 'Meskerem Note',
          content: 'Important holiday',
          allowDownload: true,
        );

        expect(note.id, isNotEmpty);
        expect(note.title, 'Meskerem Note');
        expect(note.allowDownload, isTrue);

        // Verify stored in DB
        final local = await db.calendarNotesDao.getNoteById(note.id);
        expect(local, isNotNull);
        expect(local!.isSynced, isFalse);

        // Verify enqueued in SyncQueue
        final queue = await db.syncQueueDao.getPendingEntries();
        expect(queue.length, 1);
        expect(queue.first.operationType, 'CREATE_CALENDAR_NOTE');
        final payload = jsonDecode(queue.first.payload) as Map<String, dynamic>;
        expect(payload['id'], note.id);
        expect(payload['allowDownload'], isTrue);
      },
    );

    test(
      'pushUnsyncedNotes pushes client id and allowDownload, clears queue and marks synced',
      () async {
        final noteId = await db.calendarNotesDao.createNote(
          id: 'manual-note-1',
          userId: 'user-123',
          ethiopianYear: 2018,
          ethiopianMonth: 2,
          ethiopianDay: 5,
          gregorianDate: DateTime(2025, 10, 15),
          title: 'Push Test',
        );

        await db.syncQueueDao.enqueue(
          SyncQueueCompanion.insert(
            id: 'queue-1',
            operationType: 'CREATE_CALENDAR_NOTE',
            entityType: 'CALENDAR_NOTE',
            entityId: noteId,
            payload: jsonEncode({
              'id': noteId,
              'userId': 'user-123',
              'ethiopianYear': 2018,
              'ethiopianMonth': 2,
              'ethiopianDay': 5,
              'gregorianDate': DateTime(2025, 10, 15).toIso8601String(),
              'title': 'Push Test',
              'hasReminder': false,
              'reminderRepeat': 'NONE',
              'reminderTimezone': 'Africa/Addis_Ababa',
              'allowDownload': true,
            }),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        final result = await offlineRepo.pushUnsyncedNotes();

        expect(result.isSuccess, isTrue);
        expect(result.pushedCount, 1);
        expect(result.failedCount, 0);

        // Verify remote repository received exact payload
        expect(remoteRepo.createdDtos.length, 1);
        final dto = remoteRepo.createdDtos.first;
        expect(dto.id, noteId);
        expect(dto.allowDownload, isTrue);
        expect(dto.title, 'Push Test');

        // Verify local note is marked synced
        final updatedLocal = await db.calendarNotesDao.getNoteById(noteId);
        expect(updatedLocal!.isSynced, isTrue);

        // Verify sync queue entry was removed
        final remainingQueue = await db.syncQueueDao.getPendingEntries();
        expect(remainingQueue, isEmpty);

        // Verify authoritative count is now 0
        final unsyncedCount = await db.calendarNotesDao.getUnsyncedCount();
        expect(unsyncedCount, 0);
      },
    );

    test(
      'pushUnsyncedNotes handles HTTP 429 without looping and sets isThrottled',
      () async {
        await offlineRepo.createNote(
          userId: 'user-123',
          ethiopianYear: 2018,
          ethiopianMonth: 2,
          ethiopianDay: 5,
          gregorianDate: DateTime(2025, 10, 15),
          title: 'Rate Limit Test',
        );

        remoteRepo.shouldThrow429OnCreate = true;

        final result = await offlineRepo.pushUnsyncedNotes();

        expect(result.isThrottled, isTrue);
        expect(result.pushedCount, 0);
        expect(result.failedCount, 1);

        // Note remains unsynced for next retry
        final local = await db.calendarNotesDao.getUnsyncedNotes();
        expect(local.length, 1);
      },
    );
  });

  group(
    'CalendarSyncService - Rolling One-Ethiopian-Year Sync & Single-Flight Lock',
    () {
      test(
        'performSync syncs single rolling 1-Ethiopian-year window in 1 request instead of 3 separate full years',
        () async {
          final result = await syncService.performSync();

          expect(result.isSuccess, isTrue);
          expect(remoteRepo.rollingSyncCalls, 1);
          expect(remoteRepo.queriedYears.isEmpty, isTrue);

          final etNow = EthiopianCalendarUtil.now();
          final expectedWindow =
              EthiopianCalendarUtil.getRollingOneYearWindow(etNow);
          expect(
            remoteRepo.lastRollingStart,
            EthiopianCalendarUtil.formatIsoDate(expectedWindow.start),
          );
          expect(
            remoteRepo.lastRollingEnd,
            EthiopianCalendarUtil.formatIsoDate(expectedWindow.end),
          );
        },
      );

      test(
        'performSync single-flight lock deduplicates concurrent calls',
        () async {
          final future1 = syncService.performSync();
          final future2 = syncService.performSync();

          expect(identical(future1, future2), isTrue);

          final results = await Future.wait([future1, future2]);
          expect(results[0].isSuccess, isTrue);
          expect(results[1].isSuccess, isTrue);
          // Remote repository queried only 1 time, not duplicated
          expect(remoteRepo.rollingSyncCalls, 1);
        },
      );

      test(
        'performQuickSync syncs rolling window and pushes notes',
        () async {
          await offlineRepo.createNote(
            userId: 'user-1',
            ethiopianYear: 2018,
            ethiopianMonth: 1,
            ethiopianDay: 1,
            gregorianDate: DateTime(2025, 9, 11),
            title: 'Quick Sync Note',
          );

          final result = await syncService.performQuickSync();

          expect(result.isSuccess, isTrue);
          expect(result.notesPushed, 1);
          expect(remoteRepo.rollingSyncCalls, 1);
        },
      );

      test(
        'performSync reports throttled outcome honestly on HTTP 429',
        () async {
          remoteRepo.shouldThrow429OnRollingSync = true;

          final result = await syncService.performSync();

          expect(result.isSuccess, isFalse);
          expect(result.isThrottled, isTrue);
          expect(result.pullFailures, 1);
          expect(result.errorMessage, contains('429'));
          expect(remoteRepo.rollingSyncCalls, 1);
        },
      );
    },
  );

  group('CalendarConnectivitySync - Lifecycle & Reconnection', () {
    test('didChangeAppLifecycleState(resumed) triggers rolling-window sync', () async {
      final connectivitySync = CalendarConnectivitySync(syncService);

      // Trigger app resumed lifecycle event
      connectivitySync.didChangeAppLifecycleState(AppLifecycleState.resumed);

      await Future.delayed(const Duration(milliseconds: 200));

      expect(remoteRepo.rollingSyncCalls, 1);
      expect(remoteRepo.queriedYears.isEmpty, isTrue);
      connectivitySync.dispose();
    });

    test('debounces rapid sync attempts within 5 seconds', () async {
      final connectivitySync = CalendarConnectivitySync(syncService);

      // First trigger
      connectivitySync.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future.delayed(const Duration(milliseconds: 200));

      // Immediate second trigger
      connectivitySync.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future.delayed(const Duration(milliseconds: 50));

      // Should only have executed once (1 rolling sync query)
      expect(remoteRepo.rollingSyncCalls, 1);
      connectivitySync.dispose();
    });
  });

  group('CalendarOfflineRepository - Rolling Window & Deduplication', () {
    test('syncRollingWindow avoids downloading and re-inserting unchanged records', () async {
      final testNote = CalendarNoteModel(
        id: 'note-rolling-1',
        userId: 'admin-user',
        ethiopianYear: 2019,
        ethiopianMonth: 3,
        ethiopianDay: 9,
        gregorianDate: DateTime(2026, 11, 18),
        title: 'Feast of Qirqos',
        content: 'Commemoration content',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      remoteRepo.customNotesToReturn = [testNote];

      // 1. First sync: downloads and inserts new record
      final res1 = await offlineRepo.syncRollingWindow();
      expect(res1.isSuccess, isTrue);
      expect(res1.newRecords, 1);
      expect(res1.unchangedRecordsSkipped, 0);

      // 2. Second sync: unchanged record skipped, zero redundant inserts
      final res2 = await offlineRepo.syncRollingWindow();
      expect(res2.isSuccess, isTrue);
      expect(res2.newRecords, 0);
      expect(res2.updatedRecords, 0);
      expect(res2.unchangedRecordsSkipped, 1);

      // 3. Read offline from SQLite
      final notes = await offlineRepo.getNotesForDate(
        year: 2019,
        month: 3,
        day: 9,
      );
      expect(notes.length, 1);
      expect(notes.first.title, 'Feast of Qirqos');
    });
  });

  group('Intelligent Sync Reconciliation & Media Attachment', () {
    test(
      'Server notes with media attachments are persisted locally with file metadata',
      () async {
        final remoteMedia = CalendarNoteMedia(
          id: 'media-1',
          noteId: 'note-with-media',
          fileId: 'file-123',
          order: 0,
          caption: 'Holy Trinity Icon',
          file: {
            'id': 'file-123',
            'url': 'https://res.cloudinary.com/test/image/upload/v1/icon.jpg',
            'fileName': 'icon.jpg',
            'mimeType': 'image/jpeg',
            'size': 102400,
          },
          createdAt: DateTime.now(),
        );

        final remoteNote = CalendarNoteModel(
          id: 'note-with-media',
          userId: 'admin-user',
          ethiopianYear: 2018,
          ethiopianMonth: 2,
          ethiopianDay: 7,
          gregorianDate: DateTime(2025, 10, 18),
          title: 'Feast Day',
          content: 'Special feast commemoration',
          media: [remoteMedia],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        remoteRepo.customNotesToReturn = [remoteNote];

        // Sync from server
        final count = await offlineRepo.syncNotesFromServer(
          year: 2018,
          month: 2,
        );
        expect(count, 1);

        // Verify note and media returned by getNotesForDate
        final notes = await offlineRepo.getNotesForDate(
          year: 2018,
          month: 2,
          day: 7,
        );
        expect(notes.length, 1);
        expect(notes.first.id, 'note-with-media');
        expect(notes.first.media.length, 1);
        final media = notes.first.media.first;
        expect(media.fileId, 'file-123');
        expect(
          media.url,
          'https://res.cloudinary.com/test/image/upload/v1/icon.jpg',
        );
        expect(media.fileName, 'icon.jpg');
        expect(media.mimeType, 'image/jpeg');
        expect(media.fileSize, 102400);
        expect(media.caption, 'Holy Trinity Icon');
      },
    );

    test(
      'Server note with null content does not overwrite non-null local content',
      () async {
        // 1. Create a local note with content
        final local = await offlineRepo.createNote(
          userId: 'admin-user',
          ethiopianYear: 2018,
          ethiopianMonth: 2,
          ethiopianDay: 10,
          gregorianDate: DateTime(2025, 10, 21),
          title: 'Original Title',
          content: 'Preserve this precious local content',
        );

        // Mark synced locally so reconciliation allows merging
        await db.calendarNotesDao.markNoteSynced(local.id);

        // 2. Simulate server sending back content: null for the same note
        final serverNoteWithNullContent = CalendarNoteModel(
          id: local.id,
          userId: 'admin-user',
          ethiopianYear: 2018,
          ethiopianMonth: 2,
          ethiopianDay: 10,
          gregorianDate: DateTime(2025, 10, 21),
          title: 'Server Updated Title',
          content: null, // Null content from server!
          createdAt: local.createdAt,
          updatedAt: DateTime.now(),
        );

        remoteRepo.customNotesToReturn = [serverNoteWithNullContent];

        // Sync
        await offlineRepo.syncNotesFromServer(year: 2018, month: 2);

        // 3. Verify content was NOT wiped out
        final retrieved = await offlineRepo.getNoteById(local.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.content, 'Preserve this precious local content');
        expect(retrieved.title, 'Server Updated Title');
      },
    );

    test(
      'CalendarNoteMediaX correctly resolves properties from Cloudinary file maps',
      () {
        final media = CalendarNoteMedia(
          id: 'm1',
          noteId: 'n1',
          fileId: 'f1',
          order: 0,
          file: {
            'url': 'https://res.cloudinary.com/test/image/upload/sample.jpg',
            'originalName': 'photo.jpg',
            'mimeType': 'image/jpeg',
            'size': 54321,
          },
          createdAt: DateTime.now(),
        );

        expect(
          media.url,
          'https://res.cloudinary.com/test/image/upload/sample.jpg',
        );
        expect(media.fileName, 'photo.jpg');
        expect(media.mimeType, 'image/jpeg');
        expect(media.fileSize, 54321);
      },
    );
  });
}
