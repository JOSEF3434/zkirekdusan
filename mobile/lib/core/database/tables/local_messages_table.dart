// lib/core/database/tables/local_messages_table.dart
import 'package:drift/drift.dart';

@DataClassName('LocalMessageData')
class LocalMessages extends Table {
  TextColumn get localId => text()(); // Client UUID as PK
  TextColumn get serverId => text().nullable()(); // Server message ID once synced
  TextColumn get clientId => text()(); // Idempotency reference for sync
  TextColumn get conversationId => text()();
  TextColumn get channelId => text().nullable()();

  // Sender info
  TextColumn get senderId => text()();
  TextColumn get senderUsername => text().nullable()();
  TextColumn get senderDisplayName => text().nullable()();
  TextColumn get senderAvatarUrl => text().nullable()();

  // Content
  TextColumn get content => text().nullable()();
  TextColumn get messageType => text().withDefault(const Constant('TEXT'))();

  // Threading / Reply
  TextColumn get replyToMessageId => text().nullable()();
  TextColumn get replyToJson => text().nullable()();

  // Status & Synchronization
  // pending | sending | sent | delivered | read | failed
  TextColumn get status => text().withDefault(const Constant('sent'))();
  BoolColumn get isPendingSync => boolean().withDefault(const Constant(false))();
  BoolColumn get isEdited => boolean().withDefault(const Constant(false))();
  DateTimeColumn get editedAt => dateTime().nullable()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  // Media & Attachments
  TextColumn get attachmentUrl => text().nullable()();
  TextColumn get localAttachmentPath => text().nullable()();
  TextColumn get attachmentsJson => text().nullable()();
  TextColumn get voiceNoteJson => text().nullable()();

  // Reactions & Read states
  TextColumn get reactionsJson => text().nullable()();
  TextColumn get readByJson => text().nullable()();
  TextColumn get deliveredToJson => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {localId};
}
