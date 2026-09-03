// lib/core/database/daos/conversations_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/local_conversations_table.dart';

part 'conversations_dao.g.dart';

@DriftAccessor(tables: [LocalConversations])
class ConversationsDao extends DatabaseAccessor<AppDatabase>
    with _$ConversationsDaoMixin {
  ConversationsDao(super.db);

  Future<void> upsertConversation(LocalConversationsCompanion conv) {
    return into(localConversations).insertOnConflictUpdate(conv);
  }

  Future<void> upsertConversations(
      List<LocalConversationsCompanion> convs) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(localConversations, convs);
    });
  }

  Future<List<LocalConversationData>> getConversations() {
    return (select(localConversations)
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.isPinned, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(
                expression: tbl.lastMessageAt, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(
                expression: tbl.updatedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Stream<List<LocalConversationData>> watchConversations() {
    return (select(localConversations)
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.isPinned, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(
                expression: tbl.lastMessageAt, mode: OrderingMode.desc),
            (tbl) => OrderingTerm(
                expression: tbl.updatedAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<LocalConversationData?> getConversationById(String id) {
    return (select(localConversations)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<LocalConversationData?> watchConversationById(String id) {
    return (select(localConversations)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<void> updateLastMessage({
    required String conversationId,
    required String lastMessageId,
    required String? lastMessageContent,
    required String lastMessageType,
    required String? lastMessageSenderName,
    required String? lastMessageSenderId,
    required DateTime lastMessageAt,
    bool incrementUnread = false,
  }) async {
    final existing = await getConversationById(conversationId);
    final unread = (existing?.unreadCount ?? 0) + (incrementUnread ? 1 : 0);
    await (update(localConversations)
          ..where((tbl) => tbl.id.equals(conversationId)))
        .write(
      LocalConversationsCompanion(
        lastMessageId: Value(lastMessageId),
        lastMessageContent: Value(lastMessageContent),
        lastMessageType: Value(lastMessageType),
        lastMessageSenderName: Value(lastMessageSenderName),
        lastMessageSenderId: Value(lastMessageSenderId),
        lastMessageAt: Value(lastMessageAt),
        unreadCount: Value(unread),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> resetUnreadCount(String conversationId) {
    return (update(localConversations)
          ..where((tbl) => tbl.id.equals(conversationId)))
        .write(
      const LocalConversationsCompanion(
        unreadCount: Value(0),
      ),
    );
  }

  Future<int> deleteConversation(String id) {
    return (delete(localConversations)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> clearConversations() {
    return delete(localConversations).go();
  }
}
