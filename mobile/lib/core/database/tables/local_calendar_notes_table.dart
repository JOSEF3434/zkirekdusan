// lib/core/database/tables/local_calendar_notes_table.dart
import 'package:drift/drift.dart';

@DataClassName('LocalCalendarNoteData')
class LocalCalendarNotes extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  // Ethiopian date
  IntColumn get ethiopianYear => integer()();
  IntColumn get ethiopianMonth => integer()();
  IntColumn get ethiopianDay => integer()();

  // Gregorian date (for sorting/filtering)
  DateTimeColumn get gregorianDate => dateTime()();

  // Content
  TextColumn get title => text().nullable()();
  TextColumn get content => text().nullable()();

  // Reminders
  BoolColumn get hasReminder => boolean().withDefault(const Constant(false))();
  DateTimeColumn get reminderDateTime => dateTime().nullable()();
  BoolColumn get reminderNotified =>
      boolean().withDefault(const Constant(false))();
  TextColumn get reminderRepeat => text().withDefault(const Constant('NONE'))();
  IntColumn get reminderEthiopianMonth => integer().nullable()();
  IntColumn get reminderEthiopianDay => integer().nullable()();
  IntColumn get reminderHour => integer().nullable()();
  IntColumn get reminderMinute => integer().nullable()();
  TextColumn get reminderTimezone =>
      text().withDefault(const Constant('Africa/Addis_Ababa'))();
  DateTimeColumn get reminderNextOccurrence => dateTime().nullable()();

  // Timestamps
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  // Category and Recurrence/Publication Configuration
  TextColumn get category => text().nullable()();
  TextColumn get recurrenceType => text().withDefault(const Constant('NONE'))();
  BoolColumn get isAutoPublishEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get autoPublishTime => text().nullable()();
  TextColumn get publicationStatus => text().nullable()();
  TextColumn get nextPublicationDate => text().nullable()();
  TextColumn get generatedPostId => text().nullable()();
  TextColumn get remoteId => text().nullable()();

  // Sync status
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isPendingDelete =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [];
}

@DataClassName('LocalCalendarSyncMetadataData')
class LocalCalendarSyncMetadata extends Table {
  TextColumn get id => text()();
  TextColumn get activeWindowStart => text()();
  TextColumn get activeWindowEnd => text()();
  DateTimeColumn get lastSuccessfulSyncAt => dateTime().nullable()();
  TextColumn get lastSyncCursor => text().nullable()();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalCalendarNoteMediaData')
class LocalCalendarNoteMedia extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text()();
  TextColumn get fileId => text()();

  IntColumn get order => integer()();
  TextColumn get caption => text().nullable()();

  // File metadata (cached for offline viewing)
  TextColumn get fileUrl => text().nullable()();
  TextColumn get fileName => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get fileSize => integer().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  // Sync status
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isPendingDelete =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
