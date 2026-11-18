// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_notes_dao.dart';

// ignore_for_file: type=lint
mixin _$CalendarNotesDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalCalendarNotesTable get localCalendarNotes =>
      attachedDatabase.localCalendarNotes;
  $LocalCalendarNoteMediaTable get localCalendarNoteMedia =>
      attachedDatabase.localCalendarNoteMedia;
  $LocalCalendarSyncMetadataTable get localCalendarSyncMetadata =>
      attachedDatabase.localCalendarSyncMetadata;
  CalendarNotesDaoManager get managers => CalendarNotesDaoManager(this);
}

class CalendarNotesDaoManager {
  final _$CalendarNotesDaoMixin _db;
  CalendarNotesDaoManager(this._db);
  $$LocalCalendarNotesTableTableManager get localCalendarNotes =>
      $$LocalCalendarNotesTableTableManager(
        _db.attachedDatabase,
        _db.localCalendarNotes,
      );
  $$LocalCalendarNoteMediaTableTableManager get localCalendarNoteMedia =>
      $$LocalCalendarNoteMediaTableTableManager(
        _db.attachedDatabase,
        _db.localCalendarNoteMedia,
      );
  $$LocalCalendarSyncMetadataTableTableManager get localCalendarSyncMetadata =>
      $$LocalCalendarSyncMetadataTableTableManager(
        _db.attachedDatabase,
        _db.localCalendarSyncMetadata,
      );
}
