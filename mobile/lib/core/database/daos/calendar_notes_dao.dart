// lib/core/database/daos/calendar_notes_dao.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../app_database.dart';
import '../tables/local_calendar_notes_table.dart';

part 'calendar_notes_dao.g.dart';

@DriftAccessor(tables: [
  LocalCalendarNotes,
  LocalCalendarNoteMedia,
  LocalCalendarSyncMetadata,
])
class CalendarNotesDao extends DatabaseAccessor<AppDatabase>
    with _$CalendarNotesDaoMixin {
  CalendarNotesDao(super.db);

  final _uuid = const Uuid();

  // ═══════════════════════════════════════════════════════════════
  // NOTES CRUD
  // ═══════════════════════════════════════════════════════════════

  /// Get all notes for a specific date
  Future<List<LocalCalendarNoteData>> getNotesForDate({
    required int year,
    required int month,
    required int day,
  }) {
    return (select(localCalendarNotes)
          ..where(
            (tbl) =>
                tbl.ethiopianYear.equals(year) &
                tbl.ethiopianMonth.equals(month) &
                tbl.ethiopianDay.equals(day) &
                tbl.deletedAt.isNull(),
          )
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
  }

  /// Get all notes for a specific month
  Future<List<LocalCalendarNoteData>> getNotesForMonth({
    required int year,
    required int month,
  }) {
    return (select(localCalendarNotes)
          ..where(
            (tbl) =>
                tbl.ethiopianYear.equals(year) &
                tbl.ethiopianMonth.equals(month) &
                tbl.deletedAt.isNull(),
          )
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.ethiopianDay),
            (tbl) => OrderingTerm.desc(tbl.createdAt),
          ]))
        .get();
  }

  /// Get a single note by ID
  Future<LocalCalendarNoteData?> getNoteById(String id) {
    return (select(
      localCalendarNotes,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Get notes by a list of IDs
  Future<List<LocalCalendarNoteData>> getNotesByIds(List<String> ids) {
    if (ids.isEmpty) return Future.value([]);
    return (select(localCalendarNotes)..where((tbl) => tbl.id.isIn(ids))).get();
  }

  /// Insert or update a note
  Future<void> upsertNote(LocalCalendarNotesCompanion note) {
    return into(localCalendarNotes).insertOnConflictUpdate(note);
  }

  /// Create a new note (offline-first)
  Future<String> createNote({
    String? id,
    required String userId,
    required int ethiopianYear,
    required int ethiopianMonth,
    required int ethiopianDay,
    required DateTime gregorianDate,
    String? title,
    String? content,
    String? category,
    String? recurrenceType,
    bool? isAutoPublishEnabled,
    String? autoPublishTime,
    String? publicationStatus,
    String? nextPublicationDate,
    String? generatedPostId,
    bool hasReminder = false,
    DateTime? reminderDateTime,
    String reminderRepeat = 'NONE',
    int? reminderEthiopianMonth,
    int? reminderEthiopianDay,
    int? reminderHour,
    int? reminderMinute,
    String reminderTimezone = 'Africa/Addis_Ababa',
    DateTime? reminderNextOccurrence,
  }) async {
    final noteId = id ?? _uuid.v4();
    final now = DateTime.now();

    await into(localCalendarNotes).insert(
      LocalCalendarNotesCompanion.insert(
        id: noteId,
        userId: userId,
        ethiopianYear: ethiopianYear,
        ethiopianMonth: ethiopianMonth,
        ethiopianDay: ethiopianDay,
        gregorianDate: gregorianDate,
        title: Value(title),
        content: Value(content),
        category: Value(category),
        recurrenceType: Value(recurrenceType ?? 'NONE'),
        isAutoPublishEnabled: Value(isAutoPublishEnabled ?? false),
        autoPublishTime: Value(autoPublishTime),
        publicationStatus: Value(publicationStatus),
        nextPublicationDate: Value(nextPublicationDate),
        generatedPostId: Value(generatedPostId),
        hasReminder: Value(hasReminder),
        reminderDateTime: Value(reminderDateTime),
        reminderRepeat: Value(reminderRepeat),
        reminderEthiopianMonth: Value(reminderEthiopianMonth),
        reminderEthiopianDay: Value(reminderEthiopianDay),
        reminderHour: Value(reminderHour),
        reminderMinute: Value(reminderMinute),
        reminderTimezone: Value(reminderTimezone),
        reminderNextOccurrence: Value(reminderNextOccurrence),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
      ),
    );

    return noteId;
  }

  /// Update a note (offline-first)
  Future<void> updateNote(
    String id, {
    String? title,
    String? content,
    String? category,
    String? recurrenceType,
    bool? isAutoPublishEnabled,
    String? autoPublishTime,
    String? publicationStatus,
    String? nextPublicationDate,
    String? generatedPostId,
    bool? hasReminder,
    DateTime? reminderDateTime,
    String? reminderRepeat,
    int? reminderEthiopianMonth,
    int? reminderEthiopianDay,
    int? reminderHour,
    int? reminderMinute,
    String? reminderTimezone,
    DateTime? reminderNextOccurrence,
  }) async {
    final now = DateTime.now();

    await (update(localCalendarNotes)..where((tbl) => tbl.id.equals(id))).write(
      LocalCalendarNotesCompanion(
        title: Value(title),
        content: Value(content),
        category: category == null ? const Value.absent() : Value(category),
        recurrenceType:
            recurrenceType == null ? const Value.absent() : Value(recurrenceType),
        isAutoPublishEnabled: isAutoPublishEnabled == null
            ? const Value.absent()
            : Value(isAutoPublishEnabled),
        autoPublishTime: autoPublishTime == null
            ? const Value.absent()
            : Value(autoPublishTime),
        publicationStatus: publicationStatus == null
            ? const Value.absent()
            : Value(publicationStatus),
        nextPublicationDate: nextPublicationDate == null
            ? const Value.absent()
            : Value(nextPublicationDate),
        generatedPostId: generatedPostId == null
            ? const Value.absent()
            : Value(generatedPostId),
        hasReminder: hasReminder == null
            ? const Value.absent()
            : Value(hasReminder),
        reminderDateTime: Value(reminderDateTime),
        reminderRepeat: reminderRepeat == null
            ? const Value.absent()
            : Value(reminderRepeat),
        reminderEthiopianMonth: Value(reminderEthiopianMonth),
        reminderEthiopianDay: Value(reminderEthiopianDay),
        reminderHour: Value(reminderHour),
        reminderMinute: Value(reminderMinute),
        reminderTimezone: reminderTimezone == null
            ? const Value.absent()
            : Value(reminderTimezone),
        reminderNextOccurrence: Value(reminderNextOccurrence),
        updatedAt: Value(now),
        isSynced: const Value(false),
      ),
    );
  }

  /// Soft delete a note (offline-first)
  Future<void> deleteNote(String id) async {
    final now = DateTime.now();

    await (update(localCalendarNotes)..where((tbl) => tbl.id.equals(id))).write(
      LocalCalendarNotesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        isSynced: const Value(false),
        isPendingDelete: const Value(true),
      ),
    );
  }

  /// Hard delete a note (after sync confirmation)
  Future<void> hardDeleteNote(String id) {
    return (delete(localCalendarNotes)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Mark note as synced
  Future<void> markNoteSynced(String id) {
    final now = DateTime.now();
    return (update(
      localCalendarNotes,
    )..where((tbl) => tbl.id.equals(id))).write(
      LocalCalendarNotesCompanion(
        isSynced: const Value(true),
        lastSyncedAt: Value(now),
      ),
    );
  }

  /// Get unsynced notes
  Future<List<LocalCalendarNoteData>> getUnsyncedNotes() {
    return (select(localCalendarNotes)
          ..where((tbl) => tbl.isSynced.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }

  /// Get unsynced notes count
  Future<int> getUnsyncedCount() async {
    final list = await (select(localCalendarNotes)
          ..where((tbl) => tbl.isSynced.equals(false)))
        .get();
    return list.length;
  }

  /// Watch unsynced notes count reactively
  Stream<int> watchUnsyncedCount() {
    return (select(localCalendarNotes)
          ..where((tbl) => tbl.isSynced.equals(false)))
        .watch()
        .map((list) => list.length);
  }

  /// Watch unsynced notes reactively
  Stream<List<LocalCalendarNoteData>> watchUnsyncedNotes() {
    return (select(localCalendarNotes)
          ..where((tbl) => tbl.isSynced.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .watch();
  }


  // ═══════════════════════════════════════════════════════════════
  // MEDIA CRUD
  // ═══════════════════════════════════════════════════════════════

  /// Get media for a note
  Future<List<LocalCalendarNoteMediaData>> getMediaForNote(String noteId) {
    return (select(localCalendarNoteMedia)
          ..where(
            (tbl) =>
                tbl.noteId.equals(noteId) & tbl.isPendingDelete.equals(false),
          )
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.order)]))
        .get();
  }

  /// Add media to note
  Future<String> addMedia({
    required String noteId,
    required String fileId,
    required int order,
    String? caption,
    String? fileUrl,
    String? fileName,
    String? mimeType,
    int? fileSize,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await into(localCalendarNoteMedia).insert(
      LocalCalendarNoteMediaCompanion.insert(
        id: id,
        noteId: noteId,
        fileId: fileId,
        order: order,
        caption: Value(caption),
        fileUrl: Value(fileUrl),
        fileName: Value(fileName),
        mimeType: Value(mimeType),
        fileSize: Value(fileSize),
        createdAt: now,
        isSynced: const Value(false),
      ),
    );

    return id;
  }

  /// Update media
  Future<void> updateMedia(String id, {int? order, String? caption}) {
    return (update(
      localCalendarNoteMedia,
    )..where((tbl) => tbl.id.equals(id))).write(
      LocalCalendarNoteMediaCompanion(
        order: order != null ? Value(order) : const Value.absent(),
        caption: Value(caption),
        isSynced: const Value(false),
      ),
    );
  }

  /// Delete media
  Future<void> deleteMedia(String id) {
    return (update(
      localCalendarNoteMedia,
    )..where((tbl) => tbl.id.equals(id))).write(
      const LocalCalendarNoteMediaCompanion(
        isPendingDelete: Value(true),
        isSynced: Value(false),
      ),
    );
  }

  /// Hard delete media
  Future<void> hardDeleteMedia(String id) {
    return (delete(
      localCalendarNoteMedia,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Mark media as synced
  Future<void> markMediaSynced(String id) {
    return (update(localCalendarNoteMedia)..where((tbl) => tbl.id.equals(id)))
        .write(const LocalCalendarNoteMediaCompanion(isSynced: Value(true)));
  }

  /// Get unsynced media
  Future<List<LocalCalendarNoteMediaData>> getUnsyncedMedia() {
    return (select(localCalendarNoteMedia)
          ..where((tbl) => tbl.isSynced.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]))
        .get();
  }

  // ═══════════════════════════════════════════════════════════════
  // BATCH OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Batch upsert notes from server
  Future<void> batchUpsertNotes(List<LocalCalendarNotesCompanion> notes) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localCalendarNotes, notes);
    });
  }

  /// Batch upsert notes from server, strictly preserving locally pending edits
  Future<void> batchUpsertNotesPreservingPending(
    List<LocalCalendarNotesCompanion> notes,
  ) async {
    if (notes.isEmpty) return;
    await transaction(() async {
      // Find notes that are currently unsynced locally
      final unsynced = await (select(localCalendarNotes)
            ..where((tbl) => tbl.isSynced.equals(false)))
          .get();
      final unsyncedIds = unsynced.map((n) => n.id).toSet();

      // Only upsert notes that do NOT have local pending changes
      final safeToUpsert = notes
          .where((note) => !unsyncedIds.contains(note.id.value))
          .toList();

      if (safeToUpsert.isNotEmpty) {
        await batch((b) {
          b.insertAllOnConflictUpdate(localCalendarNotes, safeToUpsert);
        });
      }
    });
  }


  /// Batch upsert media from server
  Future<void> batchUpsertMedia(
    List<LocalCalendarNoteMediaCompanion> mediaList,
  ) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localCalendarNoteMedia, mediaList);
    });
  }

  /// Get all active notes within an inclusive rolling Ethiopian-year window
  Future<List<LocalCalendarNoteData>> getNotesInRollingWindow({
    required int startYear,
    required int startMonth,
    required int startDay,
    required int endYear,
    required int endMonth,
    required int endDay,
  }) async {
    final startScore = startYear * 10000 + startMonth * 100 + startDay;
    final endScore = endYear * 10000 + endMonth * 100 + endDay;

    final notes = await (select(localCalendarNotes)
          ..where(
            (tbl) =>
                tbl.ethiopianYear.isBiggerOrEqualValue(startYear) &
                tbl.ethiopianYear.isSmallerOrEqualValue(endYear) &
                tbl.deletedAt.isNull(),
          )
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.ethiopianYear),
            (tbl) => OrderingTerm.asc(tbl.ethiopianMonth),
            (tbl) => OrderingTerm.asc(tbl.ethiopianDay),
          ]))
        .get();

    return notes.where((note) {
      final score =
          note.ethiopianYear * 10000 +
          note.ethiopianMonth * 100 +
          note.ethiopianDay;
      return score >= startScore && score <= endScore;
    }).toList();
  }

  /// Get synchronization metadata
  Future<LocalCalendarSyncMetadataData?> getSyncMetadata([
    String id = 'calendar_sync_metadata',
  ]) {
    return (select(localCalendarSyncMetadata)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Save synchronization metadata
  Future<void> setSyncMetadata(LocalCalendarSyncMetadataCompanion metadata) {
    return into(localCalendarSyncMetadata).insertOnConflictUpdate(metadata);
  }

  /// Soft delete a note by marking deletedAt
  Future<void> softDeleteNote(String id) {
    return (update(localCalendarNotes)..where((tbl) => tbl.id.equals(id))).write(
      LocalCalendarNotesCompanion(
        deletedAt: Value(DateTime.now()),
        isSynced: const Value(true),
      ),
    );
  }

  /// Clear all notes (for logout/cache clear)
  Future<void> clearAllNotes() async {
    await delete(localCalendarNoteMedia).go();
    await delete(localCalendarNotes).go();
  }
}
