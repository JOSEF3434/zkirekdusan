// lib/core/database/tables/local_conversations_table.dart
import 'package:drift/drift.dart';

@DataClassName('LocalConversationData')
class LocalConversations extends Table {
  TextColumn get id => text()(); // Conversation ID
  TextColumn get type => text()(); // DIRECT, GROUP_CHANNEL, GROUP_DIRECT
  TextColumn get groupId => text().nullable()();
  TextColumn get channelId => text().nullable()();
  TextColumn get title => text().nullable()();

  // Last message snippet for instant conversation list rendering
  TextColumn get lastMessageId => text().nullable()();
  TextColumn get lastMessageContent => text().nullable()();
  TextColumn get lastMessageType => text().nullable()();
  TextColumn get lastMessageSenderName => text().nullable()();
  TextColumn get lastMessageSenderId => text().nullable()();
  DateTimeColumn get lastMessageAt => dateTime().nullable()();

  // Flags & state
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  BoolColumn get isMuted => boolean().withDefault(const Constant(false))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  // Serialized metadata
  TextColumn get membersJson => text().nullable()();
  TextColumn get metadataJson => text().nullable()();

  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
