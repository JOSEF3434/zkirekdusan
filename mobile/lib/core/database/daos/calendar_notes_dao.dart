// lib/core/database/daos/calendar_notes_dao.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../app_database.dart';
import '../tables/local_calendar_notes_table.dart';

part 'calendar_notes_dao.g.dart';

@DriftAccessor(tables: [LocalCalendarNotes, LocalCalendarNoteMedia])
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
          ..where((tbl) =>
              tbl.ethiopianYear.equals(year) &
              tbl.ethiopianMonth.equals(month) &
              tbl.ethiopianDay.equals(day) &
              tbl.deletedAt.isNull())
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
  }

  /// Get all notes for a specific month
  Future<List<LocalCalendarNoteData>> getNotesForMonth({
    required int year,
    required int month,
  }) {
    return (select(localCalendarNotes)
          ..where((tbl) =>
              tbl.ethiopianYear.equals(year) &
              tbl.ethiopianMonth.equals(month) &
              tbl.deletedAt.isNull())
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.ethiopianDay),
            (tbl) => OrderingTerm.desc(tbl.createdAt),
          ]))
        .get();
  }

  /// Get a single note by ID
  Future<LocalCalendarNoteData?> getNoteById(String id) {
    return (select(localCalendarNotes)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert or update a note
  Future<void> upsertNote(LocalCalendarNotesCompanion note) {
    return into(localCalendarNotes).insertOnConflictUpdate(note);
  }

  /// Create a new note (offline-first)
  Future<String> createNote({
    required String userId,
    required int ethiopianYear,
    required int ethiopianMonth,
    required int ethiopianDay,
    required DateTime gregorianDate,
    String? title,
    String? content,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await into(localCalendarNotes).insert(
      LocalCalendarNotesCompanion.insert(
        id: id,
        userId: userId,
        ethiopianYear: ethiopianYear,
        ethiopianMonth: ethiopianMonth,
        ethiopianDay: ethiopianDay,
        gregorianDate: gregorianDate,
        title: Value(title),
        content: Value(content),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
      ),
    );

    return id;
  }

  /// Update a note (offline-first)
  Future<void> updateNote(
    String id, {
    String? title,
    String? content,
  }) async {
    final now = DateTime.now();

    await (update(localCalendarNotes)..where((tbl) => tbl.id.equals(id)))
        .write(
      LocalCalendarNotesCompanion(
        title: Value(title),
        content: Value(content),
        updatedAt: Value(now),
        isSynced: const Value(false),
      ),
    );
  }

  /// Soft delete a note (offline-first)
  Future<void> deleteNote(String id) async {
    final now = DateTime.now();

    await (update(localCalendarNotes)..where((tbl) => tbl.id.equals(id)))
        .write(
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
    return (update(localCalendarNotes)..where((tbl) => tbl.id.equals(id)))
        .write(
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

  // ═══════════════════════════════════════════════════════════════
  // MEDIA CRUD
  // ═══════════════════════════════════════════════════════════════

  /// Get media for a note
  Future<List<LocalCalendarNoteMediaData>> getMediaForNote(String noteId) {
    return (select(localCalendarNoteMedia)
          ..where((tbl) =>
              tbl.noteId.equals(noteId) & tbl.isPendingDelete.equals(false))
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
  Future<void> updateMedia(
    String id, {
    int? order,
    String? caption,
  }) {
    return (update(localCalendarNoteMedia)..where((tbl) => tbl.id.equals(id)))
        .write(
      LocalCalendarNoteMediaCompanion(
        order: order != null ? Value(order) : const Value.absent(),
        caption: Value(caption),
        isSynced: const Value(false),
      ),
    );
  }

  /// Delete media
  Future<void> deleteMedia(String id) {
    return (update(localCalendarNoteMedia)..where((tbl) => tbl.id.equals(id)))
        .write(
      const LocalCalendarNoteMediaCompanion(
        isPendingDelete: Value(true),
        isSynced: Value(false),
      ),
    );
  }

  /// Hard delete media
  Future<void> hardDeleteMedia(String id) {
    return (delete(localCalendarNoteMedia)..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  /// Mark media as synced
  Future<void> markMediaSynced(String id) {
    return (update(localCalendarNoteMedia)..where((tbl) => tbl.id.equals(id)))
        .write(
      const LocalCalendarNoteMediaCompanion(
        isSynced: Value(true),
      ),
    );
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
  Future<void> batchUpsertNotes(
      List<LocalCalendarNotesCompanion> notes) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localCalendarNotes, notes);
    });
  }

  /// Batch upsert media from server
  Future<void> batchUpsertMedia(
      List<LocalCalendarNoteMediaCompanion> mediaList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localCalendarNoteMedia, mediaList);
    });
  }

  /// Clear all notes (for logout/cache clear)
  Future<void> clearAllNotes() async {
    await delete(localCalendarNoteMedia).go();
    await delete(localCalendarNotes).go();
  }
}
