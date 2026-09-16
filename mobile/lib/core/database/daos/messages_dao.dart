// lib/core/database/daos/messages_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/local_messages_table.dart';

part 'messages_dao.g.dart';

@DriftAccessor(tables: [LocalMessages])
class MessagesDao extends DatabaseAccessor<AppDatabase>
    with _$MessagesDaoMixin {
  MessagesDao(super.db);

  Future<void> insertMessage(LocalMessagesCompanion message) {
    return into(localMessages).insertOnConflictUpdate(message);
  }

  Future<void> upsertMessages(List<LocalMessagesCompanion> messages) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(localMessages, messages);
    });
  }

  Future<List<LocalMessageData>> getMessagesForConversation(
    String conversationId, {
    int limit = 50,
    DateTime? before,
  }) {
    final query = select(localMessages)
      ..where((tbl) =>
          tbl.conversationId.equals(conversationId) &
          tbl.isDeleted.equals(false));

    if (before != null) {
      query.where((tbl) => tbl.createdAt.isSmallerThanValue(before));
    }

    query
      ..orderBy([
        (tbl) => OrderingTerm(
            expression: tbl.createdAt, mode: OrderingMode.desc)
      ])
      ..limit(limit);

    return query.get();
  }

  Stream<List<LocalMessageData>> watchMessagesForConversation(
    String conversationId, {
    int limit = 100,
  }) {
    return (select(localMessages)
          ..where((tbl) =>
              tbl.conversationId.equals(conversationId) &
              tbl.isDeleted.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.createdAt, mode: OrderingMode.asc)
          ])
          ..limit(limit))
        .watch();
  }

  Future<LocalMessageData?> getMessageByLocalId(String localId) {
    return (select(localMessages)..where((tbl) => tbl.localId.equals(localId)))
        .getSingleOrNull();
  }

  Future<LocalMessageData?> getMessageByClientId(String clientId) {
    return (select(localMessages)..where((tbl) => tbl.clientId.equals(clientId)))
        .getSingleOrNull();
  }

  Future<LocalMessageData?> getMessageByServerId(String serverId) {
    return (select(localMessages)..where((tbl) => tbl.serverId.equals(serverId)))
        .getSingleOrNull();
  }

  Future<void> reconcileServerMessage({
    required String clientId,
    required String serverId,
    String status = 'sent',
    String? attachmentsJson,
    String? voiceNoteJson,
  }) {
    return (update(localMessages)..where((tbl) => tbl.clientId.equals(clientId)))
        .write(
      LocalMessagesCompanion(
        serverId: Value(serverId),
        status: Value(status),
        attachmentsJson: attachmentsJson != null ? Value(attachmentsJson) : const Value.absent(),
        voiceNoteJson: voiceNoteJson != null ? Value(voiceNoteJson) : const Value.absent(),
        isPendingSync: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateMessageStatus(String localId, String status) {
    return (update(localMessages)..where((tbl) => tbl.localId.equals(localId)))
        .write(
      LocalMessagesCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateMessageContent(
      String localId, String content, DateTime editedAt) {
    return (update(localMessages)..where((tbl) => tbl.localId.equals(localId)))
        .write(
      LocalMessagesCompanion(
        content: Value(content),
        isEdited: const Value(true),
        editedAt: Value(editedAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markMessageDeleted(String localId, DateTime deletedAt) {
    return (update(localMessages)..where((tbl) => tbl.localId.equals(localId)))
        .write(
      LocalMessagesCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(deletedAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<LocalMessageData>> getPendingMessages() {
    return (select(localMessages)
          ..where((tbl) => tbl.isPendingSync.equals(true))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.createdAt, mode: OrderingMode.asc)
          ]))
        .get();
  }

  Future<int> deleteMessage(String localId) {
    return (delete(localMessages)..where((tbl) => tbl.localId.equals(localId)))
        .go();
  }

  Future<int> clearMessagesForConversation(String conversationId) {
    return (delete(localMessages)
          ..where((tbl) => tbl.conversationId.equals(conversationId)))
        .go();
  }
}
