// lib/features/calendar/data/calendar_offline_repository.dart
// Offline-first repository that uses local database and syncs with server

import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/daos/calendar_notes_dao.dart';
import 'package:mobile/core/database/daos/sync_queue_dao.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';
import 'package:mobile/features/calendar/data/calendar_repository.dart';
import 'package:uuid/uuid.dart';

final calendarOfflineRepositoryProvider = Provider<CalendarOfflineRepository>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  final remoteRepo = ref.watch(calendarRepositoryProvider);
  return CalendarOfflineRepository(
    db.calendarNotesDao,
    db.syncQueueDao,
    remoteRepo,
  );
});

class CalendarOfflineRepository {
  final CalendarNotesDao _dao;
  final SyncQueueDao _syncQueue;
  final CalendarRepository _remoteRepo;
  final _uuid = const Uuid();

  CalendarOfflineRepository(this._dao, this._syncQueue, this._remoteRepo);

  // ═══════════════════════════════════════════════════════════════
  // READ OPERATIONS (Local First)
  // ═══════════════════════════════════════════════════════════════

  /// Get notes for a specific date (local first with online sync)
  Future<List<CalendarNoteModel>> getNotesForDate({
    required int year,
    required int month,
    required int day,
  }) async {
    try {
      final remoteNotes = await _remoteRepo.getNotes(
        year: year,
        month: month,
        day: day,
      );
      final companions = remoteNotes.map((note) {
        return LocalCalendarNotesCompanion.insert(
          id: note.id,
          userId: note.userId,
          ethiopianYear: note.ethiopianYear,
          ethiopianMonth: note.ethiopianMonth,
          ethiopianDay: note.ethiopianDay,
          gregorianDate: note.gregorianDate,
          title: Value(note.title),
          content: Value(note.content),
          hasReminder: Value(note.hasReminder),
          reminderDateTime: Value(note.reminderDateTime),
          reminderRepeat: Value(note.reminderRepeat.name.toUpperCase()),
          reminderEthiopianMonth: Value(note.reminderEthiopianMonth),
          reminderEthiopianDay: Value(note.reminderEthiopianDay),
          reminderHour: Value(note.reminderHour),
          reminderMinute: Value(note.reminderMinute),
          reminderTimezone: Value(note.reminderTimezone),
          reminderNextOccurrence: Value(note.reminderNextOccurrence),
          createdAt: note.createdAt,
          updatedAt: note.updatedAt,
          deletedAt: Value(note.deletedAt),
          isSynced: const Value(true),
          lastSyncedAt: Value(DateTime.now()),
        );
      }).toList();

      if (companions.isNotEmpty) {
        await _dao.batchUpsertNotes(companions);
      }
      if (remoteNotes.isNotEmpty) {
        return remoteNotes;
      }
    } catch (e) {
      developer.log(
        'Remote getNotesForDate fallback: $e',
        name: 'CalendarOfflineRepository',
      );
    }

    final localNotes = await _dao.getNotesForDate(
      year: year,
      month: month,
      day: day,
    );

    final results = <CalendarNoteModel>[];
    for (final n in localNotes) {
      final media = await _dao.getMediaForNote(n.id);
      results.add(_mapToModel(n, media: media));
    }
    return results;
  }

  /// Get notes for a specific month (local first with online sync)
  Future<List<CalendarNoteModel>> getNotesForMonth({
    required int year,
    required int month,
  }) async {
    try {
      final remoteNotes = await _remoteRepo.getNotes(
        year: year,
        month: month,
      );
      final companions = remoteNotes.map((note) {
        return LocalCalendarNotesCompanion.insert(
          id: note.id,
          userId: note.userId,
          ethiopianYear: note.ethiopianYear,
          ethiopianMonth: note.ethiopianMonth,
          ethiopianDay: note.ethiopianDay,
          gregorianDate: note.gregorianDate,
          title: Value(note.title),
          content: Value(note.content),
          hasReminder: Value(note.hasReminder),
          reminderDateTime: Value(note.reminderDateTime),
          reminderRepeat: Value(note.reminderRepeat.name.toUpperCase()),
          reminderEthiopianMonth: Value(note.reminderEthiopianMonth),
          reminderEthiopianDay: Value(note.reminderEthiopianDay),
          reminderHour: Value(note.reminderHour),
          reminderMinute: Value(note.reminderMinute),
          reminderTimezone: Value(note.reminderTimezone),
          reminderNextOccurrence: Value(note.reminderNextOccurrence),
          createdAt: note.createdAt,
          updatedAt: note.updatedAt,
          deletedAt: Value(note.deletedAt),
          isSynced: const Value(true),
          lastSyncedAt: Value(DateTime.now()),
        );
      }).toList();

      if (companions.isNotEmpty) {
        await _dao.batchUpsertNotes(companions);
      }
      if (remoteNotes.isNotEmpty) {
        return remoteNotes;
      }
    } catch (e) {
      developer.log(
        'Remote getNotesForMonth fallback: $e',
        name: 'CalendarOfflineRepository',
      );
    }

    final localNotes = await _dao.getNotesForMonth(year: year, month: month);

    final results = <CalendarNoteModel>[];
    for (final n in localNotes) {
      final media = await _dao.getMediaForNote(n.id);
      results.add(_mapToModel(n, media: media));
    }
    return results;
  }

  /// Get note by ID (local first)
  Future<CalendarNoteModel?> getNoteById(String id) async {
    final localNote = await _dao.getNoteById(id);
    if (localNote == null) return null;

    final media = await _dao.getMediaForNote(id);

    return _mapToModel(localNote, media: media);
  }

  // ═══════════════════════════════════════════════════════════════
  // WRITE OPERATIONS (Online First + Offline Fallback)
  // ═══════════════════════════════════════════════════════════════

  /// Create a note
  Future<CalendarNoteModel> createNote({
    required String userId,
    required int ethiopianYear,
    required int ethiopianMonth,
    required int ethiopianDay,
    required DateTime gregorianDate,
    String? title,
    String? content,
    bool hasReminder = false,
    DateTime? reminderDateTime,
    ReminderRepeat reminderRepeat = ReminderRepeat.none,
    int? reminderEthiopianMonth,
    int? reminderEthiopianDay,
    int? reminderHour,
    int? reminderMinute,
    String reminderTimezone = 'Africa/Addis_Ababa',
    DateTime? reminderNextOccurrence,
  }) async {
    // 1. Try remote creation first
    try {
      final dto = CreateCalendarNoteDto(
        ethiopianYear: ethiopianYear,
        ethiopianMonth: ethiopianMonth,
        ethiopianDay: ethiopianDay,
        gregorianDate: gregorianDate.toIso8601String(),
        title: title,
        content: content,
        hasReminder: hasReminder,
        reminderDateTime: reminderDateTime?.toIso8601String(),
        reminderRepeat: reminderRepeat,
        reminderEthiopianMonth: reminderEthiopianMonth,
        reminderEthiopianDay: reminderEthiopianDay,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
        reminderTimezone: reminderTimezone,
      );

      final serverNote = await _remoteRepo.createNote(dto);

      // Save to local database with official server ID
      await _dao.upsertNote(
        LocalCalendarNotesCompanion.insert(
          id: serverNote.id,
          userId: serverNote.userId,
          ethiopianYear: serverNote.ethiopianYear,
          ethiopianMonth: serverNote.ethiopianMonth,
          ethiopianDay: serverNote.ethiopianDay,
          gregorianDate: serverNote.gregorianDate,
          title: Value(serverNote.title),
          content: Value(serverNote.content),
          hasReminder: Value(serverNote.hasReminder),
          reminderDateTime: Value(serverNote.reminderDateTime),
          reminderRepeat: Value(serverNote.reminderRepeat.name.toUpperCase()),
          reminderEthiopianMonth: Value(serverNote.reminderEthiopianMonth),
          reminderEthiopianDay: Value(serverNote.reminderEthiopianDay),
          reminderHour: Value(serverNote.reminderHour),
          reminderMinute: Value(serverNote.reminderMinute),
          reminderTimezone: Value(serverNote.reminderTimezone),
          reminderNextOccurrence: Value(serverNote.reminderNextOccurrence),
          createdAt: serverNote.createdAt,
          updatedAt: serverNote.updatedAt,
          deletedAt: Value(serverNote.deletedAt),
          isSynced: const Value(true),
          lastSyncedAt: Value(DateTime.now()),
        ),
      );

      return serverNote;
    } catch (e) {
      developer.log(
        'Server note creation failed, falling back to local: $e',
        name: 'CalendarOfflineRepository',
        error: e,
      );

      final noteId = await _dao.createNote(
        userId: userId,
        ethiopianYear: ethiopianYear,
        ethiopianMonth: ethiopianMonth,
        ethiopianDay: ethiopianDay,
        gregorianDate: gregorianDate,
        title: title,
        content: content,
        hasReminder: hasReminder,
        reminderDateTime: reminderDateTime,
        reminderRepeat: reminderRepeat.name.toUpperCase(),
        reminderEthiopianMonth: reminderEthiopianMonth,
        reminderEthiopianDay: reminderEthiopianDay,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
        reminderTimezone: reminderTimezone,
        reminderNextOccurrence: reminderNextOccurrence,
      );

      // Enqueue sync operation
      await _enqueueSyncOperation(
        operationType: 'CREATE_CALENDAR_NOTE',
        entityType: 'CALENDAR_NOTE',
        entityId: noteId,
        payload: {
          'userId': userId,
          'ethiopianYear': ethiopianYear,
          'ethiopianMonth': ethiopianMonth,
          'ethiopianDay': ethiopianDay,
          'gregorianDate': gregorianDate.toIso8601String(),
          'title': ?title,
          'content': ?content,
          'hasReminder': hasReminder,
          'reminderDateTime': ?reminderDateTime?.toIso8601String(),
          'reminderRepeat': reminderRepeat.name.toUpperCase(),
          'reminderEthiopianMonth': ?reminderEthiopianMonth,
          'reminderEthiopianDay': ?reminderEthiopianDay,
          'reminderHour': ?reminderHour,
          'reminderMinute': ?reminderMinute,
          'reminderTimezone': reminderTimezone,
        },
      );

      final note = await getNoteById(noteId);
      return note ??
          CalendarNoteModel(
            id: noteId,
            userId: userId,
            ethiopianYear: ethiopianYear,
            ethiopianMonth: ethiopianMonth,
            ethiopianDay: ethiopianDay,
            gregorianDate: gregorianDate,
            title: title,
            content: content,
            hasReminder: hasReminder,
            reminderDateTime: reminderDateTime,
            reminderNotified: false,
            reminderRepeat: reminderRepeat,
            reminderEthiopianMonth: reminderEthiopianMonth,
            reminderEthiopianDay: reminderEthiopianDay,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute,
            reminderTimezone: reminderTimezone,
            reminderNextOccurrence: reminderNextOccurrence,
            media: const [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
    }
  }

  /// Update a note (online-first with offline fallback)
  Future<CalendarNoteModel> updateNote(
    String id, {
    String? title,
    String? content,
    bool? hasReminder,
    DateTime? reminderDateTime,
    ReminderRepeat? reminderRepeat,
    int? reminderEthiopianMonth,
    int? reminderEthiopianDay,
    int? reminderHour,
    int? reminderMinute,
    String? reminderTimezone,
    DateTime? reminderNextOccurrence,
  }) async {
    try {
      final dto = UpdateCalendarNoteDto(
        title: title,
        content: content,
        hasReminder: hasReminder,
        reminderDateTime: reminderDateTime?.toIso8601String(),
        reminderRepeat: reminderRepeat,
        reminderEthiopianMonth: reminderEthiopianMonth,
        reminderEthiopianDay: reminderEthiopianDay,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
        reminderTimezone: reminderTimezone,
      );

      final serverNote = await _remoteRepo.updateNote(id, dto);

      await _dao.updateNote(
        id,
        title: title,
        content: content,
        hasReminder: hasReminder,
        reminderDateTime: reminderDateTime,
        reminderRepeat: reminderRepeat?.name.toUpperCase(),
        reminderEthiopianMonth: reminderEthiopianMonth,
        reminderEthiopianDay: reminderEthiopianDay,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
        reminderTimezone: reminderTimezone,
        reminderNextOccurrence: reminderNextOccurrence,
      );
      await _dao.markNoteSynced(id);

      return serverNote;
    } catch (e) {
      developer.log(
        'Server note update failed, saving offline: $e',
        name: 'CalendarOfflineRepository',
        error: e,
      );

      await _dao.updateNote(
        id,
        title: title,
        content: content,
        hasReminder: hasReminder,
        reminderDateTime: reminderDateTime,
        reminderRepeat: reminderRepeat?.name.toUpperCase(),
        reminderEthiopianMonth: reminderEthiopianMonth,
        reminderEthiopianDay: reminderEthiopianDay,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
        reminderTimezone: reminderTimezone,
        reminderNextOccurrence: reminderNextOccurrence,
      );

      // Enqueue sync operation
      await _enqueueSyncOperation(
        operationType: 'UPDATE_CALENDAR_NOTE',
        entityType: 'CALENDAR_NOTE',
        entityId: id,
        payload: {
          'title': ?title,
          'content': ?content,
          'hasReminder': ?hasReminder,
          'reminderDateTime': ?reminderDateTime?.toIso8601String(),
          'reminderRepeat': ?reminderRepeat?.name.toUpperCase(),
          'reminderEthiopianMonth': ?reminderEthiopianMonth,
          'reminderEthiopianDay': ?reminderEthiopianDay,
          'reminderHour': ?reminderHour,
          'reminderMinute': ?reminderMinute,
          'reminderTimezone': ?reminderTimezone,
        },
      );

      final note = await getNoteById(id);
      return note ??
          CalendarNoteModel(
            id: id,
            userId: '',
            ethiopianYear: 0,
            ethiopianMonth: 0,
            ethiopianDay: 0,
            gregorianDate: DateTime.now(),
            title: title,
            content: content,
            hasReminder: hasReminder ?? false,
            reminderDateTime: reminderDateTime,
            reminderNotified: false,
            reminderRepeat: reminderRepeat ?? ReminderRepeat.none,
            reminderEthiopianMonth: reminderEthiopianMonth,
            reminderEthiopianDay: reminderEthiopianDay,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute,
            reminderTimezone: reminderTimezone ?? 'Africa/Addis_Ababa',
            reminderNextOccurrence: reminderNextOccurrence,
            media: const [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
    }
  }

  /// Delete a note (online-first with offline fallback)
  Future<void> deleteNote(String id) async {
    try {
      await _remoteRepo.deleteNote(id);
      await _dao.hardDeleteNote(id);
    } catch (e) {
      developer.log(
        'Server note deletion failed, marking offline: $e',
        name: 'CalendarOfflineRepository',
        error: e,
      );
      await _dao.deleteNote(id);

      // Enqueue sync operation
      await _enqueueSyncOperation(
        operationType: 'DELETE_CALENDAR_NOTE',
        entityType: 'CALENDAR_NOTE',
        entityId: id,
        payload: {},
      );
    }
  }

  /// Add media to note (offline-first)
  Future<void> addMedia({
    required String noteId,
    required String fileId,
    required int order,
    String? caption,
    String? fileUrl,
    String? fileName,
    String? mimeType,
    int? fileSize,
  }) async {
    final mediaId = await _dao.addMedia(
      noteId: noteId,
      fileId: fileId,
      order: order,
      caption: caption,
      fileUrl: fileUrl,
      fileName: fileName,
      mimeType: mimeType,
      fileSize: fileSize,
    );

    // Enqueue sync operation
    await _enqueueSyncOperation(
      operationType: 'ADD_CALENDAR_NOTE_MEDIA',
      entityType: 'CALENDAR_NOTE_MEDIA',
      entityId: mediaId,
      payload: {
        'noteId': noteId,
        'fileId': fileId,
        'order': order,
        'caption': ?caption,
      },
    );
  }

  /// Remove media from note
  Future<void> removeMedia(String mediaId) async {
    await _dao.deleteMedia(mediaId);

    // Enqueue sync operation
    await _enqueueSyncOperation(
      operationType: 'DELETE_CALENDAR_NOTE_MEDIA',
      entityType: 'CALENDAR_NOTE_MEDIA',
      entityId: mediaId,
      payload: {},
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SYNC OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Sync notes from server to local database
  Future<void> syncNotesFromServer({int? year, int? month}) async {
    try {
      final remoteNotes = await _remoteRepo.getNotes(year: year, month: month);

      // Batch upsert to local database
      final companions = remoteNotes.map((note) {
        return LocalCalendarNotesCompanion.insert(
          id: note.id,
          userId: note.userId,
          ethiopianYear: note.ethiopianYear,
          ethiopianMonth: note.ethiopianMonth,
          ethiopianDay: note.ethiopianDay,
          gregorianDate: note.gregorianDate,
          title: Value(note.title),
          content: Value(note.content),
          hasReminder: Value(note.hasReminder),
          reminderDateTime: Value(note.reminderDateTime),
          reminderRepeat: Value(note.reminderRepeat.name.toUpperCase()),
          reminderEthiopianMonth: Value(note.reminderEthiopianMonth),
          reminderEthiopianDay: Value(note.reminderEthiopianDay),
          reminderHour: Value(note.reminderHour),
          reminderMinute: Value(note.reminderMinute),
          reminderTimezone: Value(note.reminderTimezone),
          reminderNextOccurrence: Value(note.reminderNextOccurrence),
          createdAt: note.createdAt,
          updatedAt: note.updatedAt,
          deletedAt: Value(note.deletedAt),
          isSynced: const Value(true),
          lastSyncedAt: Value(DateTime.now()),
        );
      }).toList();

      if (companions.isNotEmpty) {
        await _dao.batchUpsertNotes(companions);
      }
    } catch (e) {
      // Silently fail - offline mode
      developer.log(
        'Sync from server failed: $e',
        name: 'CalendarOfflineRepository',
        error: e,
      );
    }
  }

  /// Push unsynced notes to server
  Future<void> pushUnsyncedNotes() async {
    final unsyncedNotes = await _dao.getUnsyncedNotes();

    for (final note in unsyncedNotes) {
      try {
        if (note.isPendingDelete) {
          // Delete on server
          await _remoteRepo.deleteNote(note.id);
          await _dao.hardDeleteNote(note.id);
        } else {
          // Create or update on server
          final dto = CreateCalendarNoteDto(
            ethiopianYear: note.ethiopianYear,
            ethiopianMonth: note.ethiopianMonth,
            ethiopianDay: note.ethiopianDay,
            gregorianDate: note.gregorianDate.toIso8601String(),
            title: note.title,
            content: note.content,
            hasReminder: note.hasReminder,
            reminderDateTime: note.reminderDateTime?.toIso8601String(),
            reminderRepeat: ReminderRepeat.values.firstWhere(
              (value) => value.name.toUpperCase() == note.reminderRepeat,
              orElse: () => ReminderRepeat.none,
            ),
            reminderEthiopianMonth: note.reminderEthiopianMonth,
            reminderEthiopianDay: note.reminderEthiopianDay,
            reminderHour: note.reminderHour,
            reminderMinute: note.reminderMinute,
            reminderTimezone: note.reminderTimezone,
          );

          await _remoteRepo.createNote(dto);
          await _dao.markNoteSynced(note.id);
        }
      } catch (e) {
        // Continue with next note
        developer.log(
          'Failed to sync note ${note.id}: $e',
          name: 'CalendarOfflineRepository',
          error: e,
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _enqueueSyncOperation({
    required String operationType,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    final now = DateTime.now();
    await _syncQueue.enqueue(
      SyncQueueCompanion.insert(
        id: _uuid.v4(),
        operationType: operationType,
        entityType: entityType,
        entityId: entityId,
        payload: _encodePayload(payload),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  String _encodePayload(Map<String, dynamic> payload) {
    // Simple JSON encoding - in production, use json.encode
    return payload.toString();
  }

  CalendarNoteModel _mapToModel(
    LocalCalendarNoteData data, {
    List<LocalCalendarNoteMediaData>? media,
  }) {
    return CalendarNoteModel(
      id: data.id,
      userId: data.userId,
      ethiopianYear: data.ethiopianYear,
      ethiopianMonth: data.ethiopianMonth,
      ethiopianDay: data.ethiopianDay,
      gregorianDate: data.gregorianDate,
      title: data.title,
      content: data.content,
      hasReminder: data.hasReminder,
      reminderDateTime: data.reminderDateTime,
      reminderNotified: data.reminderNotified,
      reminderRepeat: ReminderRepeat.values.firstWhere(
        (value) => value.name.toUpperCase() == data.reminderRepeat,
        orElse: () => ReminderRepeat.none,
      ),
      reminderEthiopianMonth: data.reminderEthiopianMonth,
      reminderEthiopianDay: data.reminderEthiopianDay,
      reminderHour: data.reminderHour,
      reminderMinute: data.reminderMinute,
      reminderTimezone: data.reminderTimezone,
      reminderNextOccurrence: data.reminderNextOccurrence,
      media:
          media
              ?.map(
                (m) => CalendarNoteMedia(
                  id: m.id,
                  noteId: m.noteId,
                  fileId: m.fileId,
                  order: m.order,
                  caption: m.caption,
                  file: m.fileUrl != null
                      ? {
                          'id': m.fileId,
                          'url': m.fileUrl,
                          'fileName': m.fileName,
                          'mimeType': m.mimeType,
                          'size': m.fileSize,
                        }
                      : null,
                  createdAt: m.createdAt,
                ),
              )
              .toList() ??
          [],
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      deletedAt: data.deletedAt,
    );
  }
}
