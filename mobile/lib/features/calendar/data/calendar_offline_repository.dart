// lib/features/calendar/data/calendar_offline_repository.dart
// Offline-first repository that uses local database and syncs with server

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/database/daos/calendar_notes_dao.dart';
import 'package:mobile/core/database/daos/sync_queue_dao.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/core/sync/retry_strategy.dart';
import 'package:mobile/core/utils/ethiopian_calendar_util.dart';
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

/// Structured result of pushing pending local notes to the server
class CalendarPushResult {
  final int pushedCount;
  final int failedCount;
  final int permanentFailures;
  final bool isThrottled;
  final String? lastError;

  const CalendarPushResult({
    this.pushedCount = 0,
    this.failedCount = 0,
    this.permanentFailures = 0,
    this.isThrottled = false,
    this.lastError,
  });

  bool get hasErrors => failedCount > 0 || permanentFailures > 0 || isThrottled;
  bool get isSuccess => !hasErrors && failedCount == 0;
}

/// Structured result of rolling one-Ethiopian-year synchronization
class CalendarRollingSyncResult {
  final int localRecordsLoaded;
  final int newRecords;
  final int updatedRecords;
  final int deletedRecords;
  final int unchangedRecordsSkipped;
  final bool isSuccess;
  final String? errorMessage;
  final bool isThrottled;

  const CalendarRollingSyncResult({
    this.localRecordsLoaded = 0,
    this.newRecords = 0,
    this.updatedRecords = 0,
    this.deletedRecords = 0,
    this.unchangedRecordsSkipped = 0,
    this.isSuccess = true,
    this.errorMessage,
    this.isThrottled = false,
  });

  bool get hasErrors => !isSuccess || isThrottled || errorMessage != null;
}

class CalendarOfflineRepository {
  final CalendarNotesDao _dao;
  final SyncQueueDao _syncQueue;
  final CalendarRepository _remoteRepo;
  final _uuid = const Uuid();
  Future<CalendarPushResult>? _inFlightPush;

  /// In-memory cache for Web where Drift uses no-op safe executor
  final Map<String, CalendarNoteModel> _webCache = {};

  CalendarOfflineRepository(this._dao, this._syncQueue, this._remoteRepo);

  // ═══════════════════════════════════════════════════════════════
  // READ OPERATIONS (Local First - Instantaneous & Offline-Safe)
  // ═══════════════════════════════════════════════════════════════

  /// Get notes for a specific date (authoritative local database or Web cache)
  Future<List<CalendarNoteModel>> getNotesForDate({
    required int year,
    required int month,
    required int day,
  }) async {
    if (kIsWeb) {
      final cached = _webCache.values
          .where(
            (n) =>
                n.ethiopianYear == year &&
                n.ethiopianMonth == month &&
                n.ethiopianDay == day &&
                n.deletedAt == null,
          )
          .toList();
      if (cached.isNotEmpty) {
        return cached;
      }
      try {
        final remote = await _remoteRepo.getNotes(
          year: year,
          month: month,
          day: day,
        );
        for (final n in remote) {
          _webCache[n.id] = n;
        }
        return remote.where((n) => n.deletedAt == null).toList();
      } catch (e) {
        developer.log(
          'Web getNotesForDate fallback error: $e',
          name: 'CalendarOfflineRepository',
        );
        return cached;
      }
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

  /// Get notes for a specific month (authoritative local database or Web cache)
  Future<List<CalendarNoteModel>> getNotesForMonth({
    required int year,
    required int month,
  }) async {
    if (kIsWeb) {
      var cached = _webCache.values
          .where(
            (n) =>
                n.ethiopianYear == year &&
                n.ethiopianMonth == month &&
                n.deletedAt == null,
          )
          .toList();
      if (cached.isNotEmpty) {
        cached.sort((a, b) {
          final dayCmp = a.ethiopianDay.compareTo(b.ethiopianDay);
          if (dayCmp != 0) return dayCmp;
          return b.createdAt.compareTo(a.createdAt);
        });
        return cached;
      }
      try {
        final remote = await _remoteRepo.getNotes(year: year, month: month);
        for (final n in remote) {
          _webCache[n.id] = n;
        }
        cached = remote.where((n) => n.deletedAt == null).toList();
        cached.sort((a, b) {
          final dayCmp = a.ethiopianDay.compareTo(b.ethiopianDay);
          if (dayCmp != 0) return dayCmp;
          return b.createdAt.compareTo(a.createdAt);
        });
        return cached;
      } catch (e) {
        developer.log(
          'Web getNotesForMonth fallback error: $e',
          name: 'CalendarOfflineRepository',
        );
        return cached;
      }
    }

    final localNotes = await _dao.getNotesForMonth(year: year, month: month);

    final results = <CalendarNoteModel>[];
    for (final n in localNotes) {
      final media = await _dao.getMediaForNote(n.id);
      results.add(_mapToModel(n, media: media));
    }
    return results;
  }

  /// Get note by ID (local first, remote fallback)
  Future<CalendarNoteModel?> getNoteById(String id) async {
    if (kIsWeb) {
      final cached = _webCache[id];
      if (cached != null) return cached;
      try {
        final serverNote = await _remoteRepo.getNote(id);
        _webCache[serverNote.id] = serverNote;
        return serverNote;
      } catch (e) {
        developer.log(
          'Web remote getNoteById failed: $e',
          name: 'CalendarOfflineRepository',
          error: e,
        );
        return null;
      }
    }

    // 1. Try local cache first
    final localNote = await _dao.getNoteById(id);
    if (localNote != null) {
      final media = await _dao.getMediaForNote(id);
      return _mapToModel(localNote, media: media);
    }

    // 2. Fallback: fetch from remote API and cache locally
    try {
      final serverNote = await _remoteRepo.getNote(id);
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
          category: Value(serverNote.category),
          recurrenceType:
              Value(serverNote.recurrenceType?.name.toUpperCase() ?? 'NONE'),
          isAutoPublishEnabled: Value(serverNote.isAutoPublishEnabled),
          autoPublishTime: Value(serverNote.autoPublishTime),
          publicationStatus: Value(serverNote.publicationStatus),
          nextPublicationDate: Value(serverNote.nextPublicationDate),
          generatedPostId: Value(serverNote.generatedPostId),
          createdAt: serverNote.createdAt,
          updatedAt: serverNote.updatedAt,
          deletedAt: Value(serverNote.deletedAt),
          isSynced: const Value(true),
          lastSyncedAt: Value(DateTime.now()),
        ),
      );
      if (serverNote.media.isNotEmpty) {
        final mediaCompanions = serverNote.media.map((m) {
          return LocalCalendarNoteMediaCompanion.insert(
            id: m.id,
            noteId: serverNote.id,
            fileId: m.fileId,
            order: m.order,
            caption: Value(m.caption),
            fileUrl: Value(m.url),
            fileName: Value(m.fileName),
            mimeType: Value(m.mimeType),
            fileSize: Value(m.fileSize),
            createdAt: m.createdAt,
            isSynced: const Value(true),
          );
        }).toList();
        await _dao.batchUpsertMedia(mediaCompanions);
      }
      return serverNote;
    } catch (e) {
      developer.log(
        'Remote getNoteById fallback failed: $e',
        name: 'CalendarOfflineRepository',
        error: e,
      );
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // WRITE OPERATIONS (Genuinely Offline-First)
  // ═══════════════════════════════════════════════════════════════

  /// Create a note (persists locally immediately, enqueues sync)
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
    bool allowDownload = false,
    String? category,
    ReminderRepeat? recurrenceType,
    bool isAutoPublishEnabled = false,
    String? autoPublishTime,
  }) async {
    final noteId = _uuid.v4();
    final now = DateTime.now();

    if (kIsWeb) {
      final dto = CreateCalendarNoteDto(
        id: noteId,
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
        allowDownload: allowDownload,
        recurrenceType: recurrenceType ?? reminderRepeat,
        isAutoPublishEnabled: isAutoPublishEnabled,
        autoPublishTime: autoPublishTime,
      );
      try {
        final serverNote = await _remoteRepo.createNote(dto);
        _webCache[serverNote.id] = serverNote;
        return serverNote;
      } catch (e) {
        developer.log(
          'Web createNote remote error: $e',
          name: 'CalendarOfflineRepository',
          error: e,
        );
        final localModel = CalendarNoteModel(
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
          allowDownload: allowDownload,
          category: category,
          recurrenceType: recurrenceType ?? reminderRepeat,
          isAutoPublishEnabled: isAutoPublishEnabled,
          autoPublishTime: autoPublishTime,
          createdAt: now,
          updatedAt: now,
        );
        _webCache[noteId] = localModel;
        rethrow;
      }
    }

    // 1. Immediately persist to local database with isSynced = false
    await _dao.createNote(
      id: noteId,
      userId: userId,
      ethiopianYear: ethiopianYear,
      ethiopianMonth: ethiopianMonth,
      ethiopianDay: ethiopianDay,
      gregorianDate: gregorianDate,
      title: title,
      content: content,
      category: category,
      recurrenceType: (recurrenceType ?? reminderRepeat).name.toUpperCase(),
      isAutoPublishEnabled: isAutoPublishEnabled,
      autoPublishTime: autoPublishTime,
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

    // 2. Persist to durable sync queue with full JSON payload
    await _enqueueSyncOperation(
      operationType: 'CREATE_CALENDAR_NOTE',
      entityType: 'CALENDAR_NOTE',
      entityId: noteId,
      payload: {
        'id': noteId,
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
        'allowDownload': allowDownload,
        'category': ?category,
        'recurrenceType': (recurrenceType ?? reminderRepeat).name.toUpperCase(),
        'isAutoPublishEnabled': isAutoPublishEnabled,
        'autoPublishTime': ?autoPublishTime,
      },
    );

    // 3. Construct model and return immediately to UI
    final localModel = CalendarNoteModel(
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
      allowDownload: allowDownload,
      category: category,
      recurrenceType: recurrenceType ?? reminderRepeat,
      isAutoPublishEnabled: isAutoPublishEnabled,
      autoPublishTime: autoPublishTime,
      createdAt: now,
      updatedAt: now,
    );

    // 4. Non-blocking asynchronous sync attempt
    unawaited(pushUnsyncedNotes());

    return localModel;
  }

  /// Update a note (persists locally immediately, enqueues sync)
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
    bool? allowDownload,
    String? category,
    ReminderRepeat? recurrenceType,
    bool? isAutoPublishEnabled,
    String? autoPublishTime,
  }) async {
    if (kIsWeb) {
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
        allowDownload: allowDownload,
        recurrenceType: recurrenceType ?? reminderRepeat,
        isAutoPublishEnabled: isAutoPublishEnabled,
        autoPublishTime: autoPublishTime,
      );
      try {
        final serverNote = await _remoteRepo.updateNote(id, dto);
        _webCache[serverNote.id] = serverNote;
        return serverNote;
      } catch (e) {
        developer.log(
          'Web updateNote remote error: $e',
          name: 'CalendarOfflineRepository',
          error: e,
        );
        rethrow;
      }
    }

    // 1. Immediately persist to local database with isSynced = false
    await _dao.updateNote(
      id,
      title: title,
      content: content,
      category: category,
      recurrenceType: (recurrenceType ?? reminderRepeat)?.name.toUpperCase(),
      isAutoPublishEnabled: isAutoPublishEnabled,
      autoPublishTime: autoPublishTime,
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

    // 2. Persist update to sync queue
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
        'allowDownload': ?allowDownload,
        'category': ?category,
        'recurrenceType': ?(recurrenceType ?? reminderRepeat)?.name.toUpperCase(),
        'isAutoPublishEnabled': ?isAutoPublishEnabled,
        'autoPublishTime': ?autoPublishTime,
      },
    );

    // 3. Return updated model from local database immediately
    final updatedNote = await getNoteById(id);

    // 4. Non-blocking asynchronous sync attempt
    unawaited(pushUnsyncedNotes());

    return updatedNote ??
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
          allowDownload: allowDownload ?? false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
  }

  /// Delete a note (marks deleted locally immediately, enqueues sync)
  Future<void> deleteNote(String id) async {
    if (kIsWeb) {
      _webCache.remove(id);
      try {
        await _remoteRepo.deleteNote(id);
      } catch (e) {
        developer.log(
          'Web deleteNote remote error: $e',
          name: 'CalendarOfflineRepository',
          error: e,
        );
        rethrow;
      }
      return;
    }

    // 1. Mark deleted in local database immediately
    await _dao.deleteNote(id);

    // 2. Persist delete to sync queue
    await _enqueueSyncOperation(
      operationType: 'DELETE_CALENDAR_NOTE',
      entityType: 'CALENDAR_NOTE',
      entityId: id,
      payload: {'id': id},
    );

    // 3. Non-blocking asynchronous sync attempt
    unawaited(pushUnsyncedNotes());
  }

  /// Add media to note (offline-first, with Web cache support)
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
    final mediaId = _uuid.v4();
    final now = DateTime.now();

    if (kIsWeb) {
      final note = _webCache[noteId];
      if (note != null) {
        final newMedia = CalendarNoteMedia(
          id: mediaId,
          noteId: noteId,
          fileId: fileId,
          order: order,
          caption: caption,
          file: fileUrl != null
              ? {
                  'id': fileId,
                  'url': fileUrl,
                  'fileName': fileName,
                  'mimeType': mimeType,
                  'size': fileSize,
                }
              : null,
          createdAt: now,
        );
        _webCache[noteId] = note.copyWith(
          media: [...note.media, newMedia],
        );
      }
      return;
    }

    await _dao.addMedia(
      noteId: noteId,
      fileId: fileId,
      order: order,
      caption: caption,
      fileUrl: fileUrl,
      fileName: fileName,
      mimeType: mimeType,
      fileSize: fileSize,
    );

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

  /// Remove media from note (local-only by mediaId)
  Future<void> removeMedia(String mediaId) async {
    if (kIsWeb) {
      for (final entry in _webCache.entries) {
        if (entry.value.media.any((m) => m.id == mediaId)) {
          _webCache[entry.key] = entry.value.copyWith(
            media: entry.value.media.where((m) => m.id != mediaId).toList(),
          );
          break;
        }
      }
      return;
    }

    await _dao.deleteMedia(mediaId);

    await _enqueueSyncOperation(
      operationType: 'DELETE_CALENDAR_NOTE_MEDIA',
      entityType: 'CALENDAR_NOTE_MEDIA',
      entityId: mediaId,
      payload: {'mediaId': mediaId},
    );
  }

  /// Remove a specific media item from a note by (noteId, mediaId).
  Future<void> removeNoteMedia({
    required String noteId,
    required String mediaId,
  }) async {
    await _remoteRepo.removeNoteMedia(noteId: noteId, mediaId: mediaId);
    if (kIsWeb) {
      final note = _webCache[noteId];
      if (note != null) {
        _webCache[noteId] = note.copyWith(
          media: note.media.where((m) => m.id != mediaId).toList(),
        );
      }
    } else {
      await _dao.deleteMedia(mediaId);
    }
  }

  /// Update caption/order of a specific media item on a note.
  Future<void> updateNoteMedia({
    required String noteId,
    required String mediaId,
    String? caption,
    int? order,
  }) async {
    await _remoteRepo.updateNoteMedia(
      noteId: noteId,
      mediaId: mediaId,
      caption: caption,
      order: order,
    );
    if (kIsWeb) {
      final note = _webCache[noteId];
      if (note != null) {
        _webCache[noteId] = note.copyWith(
          media: note.media.map((m) {
            if (m.id == mediaId) {
              return m.copyWith(
                caption: caption ?? m.caption,
                order: order ?? m.order,
              );
            }
            return m;
          }).toList(),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SYNC OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Synchronize the active rolling one-Ethiopian-year calendar window covering all 13 months.
  /// Dynamically computes window from today's Ethiopian date, loads local records immediately,
  /// checks for incremental changes, skips unchanged records, and outputs structured logs.
  Future<CalendarRollingSyncResult> syncRollingWindow({
    DateTime? since,
    bool forceFull = false,
  }) async {
    final etNow = EthiopianCalendarUtil.now();
    final window = EthiopianCalendarUtil.getRollingOneYearWindow(etNow);
    final curDateStr = EthiopianCalendarUtil.formatIsoDate(
      etNow.year,
      etNow.month,
      etNow.day,
    );
    final startStr = EthiopianCalendarUtil.formatIsoDate(
      window.start.year,
      window.start.month,
      window.start.day,
    );
    final endStr = EthiopianCalendarUtil.formatIsoDate(
      window.end.year,
      window.end.month,
      window.end.day,
    );

    developer.log(
      '[CalendarSync] Current Ethiopian date: $curDateStr',
      name: 'CalendarSync',
    );
    developer.log(
      '[CalendarSync] Active window: $startStr → $endStr',
      name: 'CalendarSync',
    );

    int localLoaded = 0;
    Map<String, LocalCalendarNoteData> localMap = {};
    if (!kIsWeb) {
      final localNotes = await _dao.getNotesInRollingWindow(
        startYear: window.start.year,
        startMonth: window.start.month,
        startDay: window.start.day,
        endYear: window.end.year,
        endMonth: window.end.month,
        endDay: window.end.day,
      );
      localLoaded = localNotes.length;
      localMap = {for (final l in localNotes) l.id: l};
    } else {
      localLoaded = _webCache.values
          .where(
            (n) =>
                EthiopianCalendarUtil.isDateInRollingWindow(
                  year: n.ethiopianYear,
                  month: n.ethiopianMonth,
                  day: n.ethiopianDay,
                  start: window.start,
                  end: window.end,
                ) &&
                n.deletedAt == null,
          )
          .length;
    }

    developer.log(
      '[CalendarSync] Local records loaded: $localLoaded',
      name: 'CalendarSync',
    );

    // Determine effective incremental since timestamp
    DateTime? effectiveSince = since;
    if (effectiveSince == null && !forceFull && !kIsWeb) {
      final meta = await _dao.getSyncMetadata();
      effectiveSince = meta?.lastSuccessfulSyncAt;
    }

    int newRecords = 0;
    int updatedRecords = 0;
    int deletedRecords = 0;
    int unchangedSkipped = 0;

    try {
      final syncResult = await _remoteRepo.syncRollingWindow(
        from: startStr,
        to: endStr,
        since: effectiveSince,
      );

      final remoteNotes = syncResult.notes;
      final deletedIds = syncResult.deletedIds;

      if (kIsWeb) {
        for (final note in remoteNotes) {
          final cached = _webCache[note.id];
          if (cached == null) {
            newRecords++;
          } else if (cached.updatedAt.isBefore(note.updatedAt)) {
            updatedRecords++;
          } else {
            unchangedSkipped++;
          }
          _webCache[note.id] = note;
        }
        for (final delId in deletedIds) {
          _webCache.remove(delId);
          deletedRecords++;
        }
      } else {
        // Soft delete remote-reported deleted notes
        for (final delId in deletedIds) {
          await _dao.softDeleteNote(delId);
          deletedRecords++;
        }

        final companions = <LocalCalendarNotesCompanion>[];
        final mediaCompanions = <LocalCalendarNoteMediaCompanion>[];

        for (final note in remoteNotes) {
          final local = localMap[note.id];
          if (local != null) {
            if (!local.isSynced) {
              unchangedSkipped++;
              continue;
            }
            if (local.updatedAt.isAfter(note.updatedAt) ||
                local.updatedAt.isAtSameMomentAs(note.updatedAt)) {
              unchangedSkipped++;
              continue;
            }
            updatedRecords++;
          } else {
            newRecords++;
          }

          final effectiveContent = note.content ?? local?.content;
          final effectiveTitle = note.title ?? local?.title;

          companions.add(
            LocalCalendarNotesCompanion.insert(
              id: note.id,
              userId: note.userId,
              ethiopianYear: note.ethiopianYear,
              ethiopianMonth: note.ethiopianMonth,
              ethiopianDay: note.ethiopianDay,
              gregorianDate: note.gregorianDate,
              title: Value(effectiveTitle),
              content: Value(effectiveContent),
              hasReminder: Value(note.hasReminder),
              reminderDateTime: Value(note.reminderDateTime),
              reminderRepeat: Value(note.reminderRepeat.name.toUpperCase()),
              reminderEthiopianMonth: Value(note.reminderEthiopianMonth),
              reminderEthiopianDay: Value(note.reminderEthiopianDay),
              reminderHour: Value(note.reminderHour),
              reminderMinute: Value(note.reminderMinute),
              reminderTimezone: Value(note.reminderTimezone),
              reminderNextOccurrence: Value(note.reminderNextOccurrence),
              category: Value(note.category),
              recurrenceType: Value(
                (note.recurrenceType ?? note.reminderRepeat).name.toUpperCase(),
              ),
              isAutoPublishEnabled: Value(note.isAutoPublishEnabled),
              publicationStatus: Value(note.publicationStatus),
              nextPublicationDate: Value(note.nextPublicationDate),
              generatedPostId: Value(note.generatedPostId),
              remoteId: Value(note.id),
              createdAt: note.createdAt,
              updatedAt: note.updatedAt,
              deletedAt: Value(note.deletedAt),
              isSynced: const Value(true),
              lastSyncedAt: Value(DateTime.now()),
            ),
          );

          for (final m in note.media) {
            mediaCompanions.add(
              LocalCalendarNoteMediaCompanion.insert(
                id: m.id,
                noteId: note.id,
                fileId: m.fileId,
                order: m.order,
                caption: Value(m.caption),
                fileUrl: Value(m.url),
                fileName: Value(m.fileName),
                mimeType: Value(m.mimeType),
                fileSize: Value(m.fileSize),
                createdAt: m.createdAt,
                isSynced: const Value(true),
                isPendingDelete: const Value(false),
              ),
            );
          }
        }

        if (companions.isNotEmpty) {
          await _dao.batchUpsertNotesPreservingPending(companions);
        }
        if (mediaCompanions.isNotEmpty) {
          await _dao.batchUpsertMedia(mediaCompanions);
        }

        // Save sync metadata
        await _dao.setSyncMetadata(
          LocalCalendarSyncMetadataCompanion.insert(
            id: 'calendar_sync_metadata',
            activeWindowStart: startStr,
            activeWindowEnd: endStr,
            lastSuccessfulSyncAt: Value(DateTime.now()),
            lastSyncCursor: Value(
              syncResult.serverTime ?? DateTime.now().toIso8601String(),
            ),
            schemaVersion: const Value(1),
          ),
        );
      }

      developer.log(
        '[CalendarSync] New records: $newRecords',
        name: 'CalendarSync',
      );
      developer.log(
        '[CalendarSync] Updated records: $updatedRecords',
        name: 'CalendarSync',
      );
      developer.log(
        '[CalendarSync] Deleted records: $deletedRecords',
        name: 'CalendarSync',
      );
      developer.log(
        '[CalendarSync] Unchanged records skipped: $unchangedSkipped',
        name: 'CalendarSync',
      );
      developer.log(
        '[CalendarSync] Offline cache ready',
        name: 'CalendarSync',
      );
      developer.log(
        '[CalendarSync] Incremental synchronization completed',
        name: 'CalendarSync',
      );

      return CalendarRollingSyncResult(
        localRecordsLoaded: localLoaded,
        newRecords: newRecords,
        updatedRecords: updatedRecords,
        deletedRecords: deletedRecords,
        unchangedRecordsSkipped: unchangedSkipped,
        isSuccess: true,
      );
    } on DioException catch (dioErr) {
      final isThrottled = dioErr.response?.statusCode == 429;
      developer.log(
        '[CalendarSync] Offline cache ready',
        name: 'CalendarSync',
      );
      return CalendarRollingSyncResult(
        localRecordsLoaded: localLoaded,
        isSuccess: false,
        isThrottled: isThrottled,
        errorMessage: isThrottled ? 'Rate limited (HTTP 429)' : dioErr.toString(),
      );
    } catch (e) {
      developer.log(
        '[CalendarSync] Offline cache ready',
        name: 'CalendarSync',
      );
      return CalendarRollingSyncResult(
        localRecordsLoaded: localLoaded,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sync notes from server to local database while preserving local pending edits
  /// and reconciling note content and media attachments
  Future<int> syncNotesFromServer({int? year, int? month}) async {
    try {
      final remoteNotes = await _remoteRepo.getNotes(year: year, month: month);

      if (kIsWeb) {
        for (final note in remoteNotes) {
          _webCache[note.id] = note;
        }
        return remoteNotes.length;
      }

      // Query existing local notes for intelligent reconciliation
      final remoteIds = remoteNotes.map((n) => n.id).toList();
      final existingLocalNotes = await _dao.getNotesByIds(remoteIds);
      final localMap = {for (final l in existingLocalNotes) l.id: l};

      final companions = <LocalCalendarNotesCompanion>[];
      final mediaCompanions = <LocalCalendarNoteMediaCompanion>[];

      for (final note in remoteNotes) {
        final local = localMap[note.id];
        if (local != null) {
          // Strictly preserve locally pending edits from being overwritten
          if (!local.isSynced) continue;
          // Skip if local note has more recent edits than server timestamp
          if (local.updatedAt.isAfter(note.updatedAt)) continue;
        }

        // Reconcile content & title: NEVER overwrite non-null local content with null from server
        final effectiveContent = note.content ?? local?.content;
        final effectiveTitle = note.title ?? local?.title;

        companions.add(
          LocalCalendarNotesCompanion.insert(
            id: note.id,
            userId: note.userId,
            ethiopianYear: note.ethiopianYear,
            ethiopianMonth: note.ethiopianMonth,
            ethiopianDay: note.ethiopianDay,
            gregorianDate: note.gregorianDate,
            title: Value(effectiveTitle),
            content: Value(effectiveContent),
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
          ),
        );

        // Reconcile media attachments from server
        for (final m in note.media) {
          mediaCompanions.add(
            LocalCalendarNoteMediaCompanion.insert(
              id: m.id,
              noteId: note.id,
              fileId: m.fileId,
              order: m.order,
              caption: Value(m.caption),
              fileUrl: Value(m.url),
              fileName: Value(m.fileName),
              mimeType: Value(m.mimeType),
              fileSize: Value(m.fileSize),
              createdAt: m.createdAt,
              isSynced: const Value(true),
              isPendingDelete: const Value(false),
            ),
          );
        }
      }

      if (companions.isNotEmpty) {
        await _dao.batchUpsertNotesPreservingPending(companions);
      }
      if (mediaCompanions.isNotEmpty) {
        await _dao.batchUpsertMedia(mediaCompanions);
      }
      return remoteNotes.length;
    } catch (e) {
      developer.log(
        'Sync from server failed: $e',
        name: 'CalendarOfflineRepository',
        error: e,
      );
      rethrow;
    }
  }

  /// Push unsynced notes to server with structured result and retry handling
  Future<CalendarPushResult> pushUnsyncedNotes() {
    if (_inFlightPush != null) {
      developer.log(
        'Push unsynced notes already in progress, returning existing task',
        name: 'CalendarOfflineRepository',
      );
      return _inFlightPush!;
    }
    _inFlightPush = _executePushUnsyncedNotes().whenComplete(() {
      _inFlightPush = null;
    });
    return _inFlightPush!;
  }

  Future<CalendarPushResult> _executePushUnsyncedNotes() async {
    final unsyncedNotes = await _dao.getUnsyncedNotes();
    if (unsyncedNotes.isEmpty) {
      return const CalendarPushResult();
    }

    int pushedCount = 0;
    int failedCount = 0;
    int permanentFailures = 0;
    bool isThrottled = false;
    String? lastError;

    final queueEntries = await _syncQueue.getPendingEntries(limit: 100);

    for (final note in unsyncedNotes) {
      if (isThrottled) {
        failedCount++;
        continue;
      }

      final matchingQueue =
          queueEntries.where((e) => e.entityId == note.id).firstOrNull;

      try {
        if (note.isPendingDelete) {
          try {
            await _remoteRepo.deleteNote(note.id);
          } on DioException catch (dioErr) {
            if (dioErr.response?.statusCode != 404) rethrow;
          }
          await _dao.hardDeleteNote(note.id);
          await _syncQueue.removeEntriesForEntity(note.id);
          pushedCount++;
        } else {
          bool allowDownload = false;
          if (matchingQueue != null) {
            try {
              final payload =
                  jsonDecode(matchingQueue.payload) as Map<String, dynamic>;
              allowDownload = payload['allowDownload'] as bool? ?? false;
            } catch (_) {}
          }

          final dto = CreateCalendarNoteDto(
            id: note.id,
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
            allowDownload: allowDownload,
            recurrenceType: note.recurrenceType.isNotEmpty &&
                    note.recurrenceType != 'NONE'
                ? ReminderRepeat.values.firstWhere(
                    (v) =>
                        v.name.toUpperCase() ==
                        note.recurrenceType.toUpperCase(),
                    orElse: () => ReminderRepeat.none,
                  )
                : null,
            isAutoPublishEnabled: note.isAutoPublishEnabled,
            autoPublishTime: note.autoPublishTime,
          );

          await _remoteRepo.createNote(dto);
          await _dao.markNoteSynced(note.id);
          await _syncQueue.removeEntriesForEntity(note.id);
          pushedCount++;
        }
      } catch (e) {
        lastError = e.toString();
        developer.log(
          'Failed to sync note ${note.id}: $e',
          name: 'CalendarOfflineRepository',
          error: e,
        );

        if (e is DioException) {
          final statusCode = e.response?.statusCode;
          if (statusCode == 429) {
            isThrottled = true;
            failedCount++;
            if (matchingQueue != null) {
              await _syncQueue.updateEntryStatus(
                matchingQueue.id,
                'failed',
                retryCount: matchingQueue.retryCount + 1,
                nextRetryAt: DateTime.now().add(const Duration(seconds: 30)),
                error: 'HTTP 429: Rate limited by server',
              );
            }
          } else if (statusCode != null &&
              statusCode >= 400 &&
              statusCode < 500) {
            permanentFailures++;
            if (matchingQueue != null) {
              await _syncQueue.updateEntryStatus(
                matchingQueue.id,
                'failed',
                retryCount: matchingQueue.retryCount + 1,
                nextRetryAt: null, // Do not loop retry on permanent 4xx validation errors
                error: 'HTTP $statusCode: ${e.response?.data}',
              );
            }
          } else {
            failedCount++;
            if (matchingQueue != null) {
              final nextRetry =
                  RetryStrategy.getNextRetryTime(matchingQueue.retryCount);
              await _syncQueue.updateEntryStatus(
                matchingQueue.id,
                'failed',
                retryCount: matchingQueue.retryCount + 1,
                nextRetryAt: nextRetry,
                error: e.toString(),
              );
            }
          }
        } else {
          failedCount++;
        }
      }
    }

    return CalendarPushResult(
      pushedCount: pushedCount,
      failedCount: failedCount,
      permanentFailures: permanentFailures,
      isThrottled: isThrottled,
      lastError: lastError,
    );
  }

  /// Get unsynced local notes
  Future<List<LocalCalendarNoteData>> getUnsyncedNotes() =>
      _dao.getUnsyncedNotes();

  /// Watch unsynced notes count reactively
  Stream<int> watchUnsyncedCount() => _dao.watchUnsyncedCount();

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
        payload: jsonEncode(payload),
        createdAt: now,
        updatedAt: now,
      ),
    );
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
      category: data.category,
      recurrenceType: ReminderRepeat.values.firstWhere(
        (value) =>
            value.name.toUpperCase() ==
            (data.recurrenceType.isNotEmpty
                ? data.recurrenceType
                : data.reminderRepeat),
        orElse: () => ReminderRepeat.none,
      ),
      isAutoPublishEnabled: data.isAutoPublishEnabled,
      autoPublishTime: data.autoPublishTime,
      publicationStatus: data.publicationStatus,
      nextPublicationDate: data.nextPublicationDate,
      generatedPostId: data.generatedPostId,
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
