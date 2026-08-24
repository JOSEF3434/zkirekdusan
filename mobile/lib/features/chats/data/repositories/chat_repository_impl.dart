// lib/features/chats/data/repositories/chat_repository_impl.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/chats/data/datasources/chat_remote_datasource.dart';
import 'package:mobile/features/chats/data/models/conversation_model.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';
import 'package:mobile/features/chats/domain/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final remoteDatasource = ref.watch(chatRemoteDatasourceProvider);
  return ChatRepositoryImpl(remoteDatasource);
});

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDatasource _remoteDatasource;

  ChatRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<ConversationModel>> getUserConversations() async {
    return await _remoteDatasource.getUserConversations();
  }

  @override
  Future<ConversationModel> getConversationById(String conversationId) async {
    return await _remoteDatasource.getConversationById(conversationId);
  }

  @override
  Future<ConversationModel> createDirectConversation(String recipientId) async {
    return await _remoteDatasource.createDirectConversation(recipientId);
  }

  @override
  Future<void> muteConversation(String conversationId) async {
    await _remoteDatasource.muteConversation(conversationId);
  }

  @override
  Future<void> unmuteConversation(String conversationId) async {
    await _remoteDatasource.unmuteConversation(conversationId);
  }

  @override
  Future<void> pinConversation(String conversationId) async {
    await _remoteDatasource.pinConversation(conversationId);
  }

  @override
  Future<void> unpinConversation(String conversationId) async {
    await _remoteDatasource.unpinConversation(conversationId);
  }

  @override
  Future<void> markConversationAsRead(String conversationId) async {
    await _remoteDatasource.markConversationAsRead(conversationId);
  }

  @override
  Future<PaginatedMessagesModel> getMessages({
    required String conversationId,
    String? cursor,
    int limit = 50,
  }) async {
    return await _remoteDatasource.getMessages(
      conversationId: conversationId,
      cursor: cursor,
      limit: limit,
    );
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    String? content,
    String? replyToId,
    List<String>? attachmentIds,
    String type = 'TEXT',
  }) async {
    return await _remoteDatasource.sendMessage(
      conversationId: conversationId,
      content: content,
      replyToId: replyToId,
      attachmentIds: attachmentIds,
      type: type,
    );
  }

  @override
  Future<MessageModel> editMessage({
    required String messageId,
    required String content,
  }) async {
    return await _remoteDatasource.editMessage(
      messageId: messageId,
      content: content,
    );
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await _remoteDatasource.deleteMessage(messageId);
  }

  @override
  Future<void> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    await _remoteDatasource.addReaction(
      messageId: messageId,
      emoji: emoji,
    );
  }

  @override
  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    await _remoteDatasource.removeReaction(
      messageId: messageId,
      emoji: emoji,
    );
  }

  @override
  Future<void> markAsRead(String messageId) async {
    await _remoteDatasource.markAsRead(messageId);
  }

  @override
  Future<void> pinMessage({
    required String conversationId,
    required String messageId,
  }) async {
    await _remoteDatasource.pinMessage(
      conversationId: conversationId,
      messageId: messageId,
    );
  }

  @override
  Future<void> unpinMessage({
    required String conversationId,
    required String messageId,
  }) async {
    await _remoteDatasource.unpinMessage(
      conversationId: conversationId,
      messageId: messageId,
    );
  }

  @override
  Future<List<MessageModel>> getPinnedMessages(String conversationId) async {
    return await _remoteDatasource.getPinnedMessages(conversationId);
  }

  @override
  Future<void> starMessage(String messageId) async {
    await _remoteDatasource.starMessage(messageId);
  }

  @override
  Future<void> unstarMessage(String messageId) async {
    await _remoteDatasource.unstarMessage(messageId);
  }

  @override
  Future<List<MessageModel>> getStarredMessages() async {
    return await _remoteDatasource.getStarredMessages();
  }

  @override
  Future<Map<String, dynamic>> uploadChatMedia({
    required String filePath,
    required String fileName,
    required String mimeType,
    String? conversationId,
    Function(int, int)? onUploadProgress,
  }) async {
    return await _remoteDatasource.uploadChatMedia(
      filePath: filePath,
      fileName: fileName,
      mimeType: mimeType,
      conversationId: conversationId,
      onUploadProgress: onUploadProgress,
    );
  }

  @override
  Future<List<ConversationModel>> searchConversations(String query) async {
    return await _remoteDatasource.searchConversations(query);
  }

  @override
  Future<List<MessageModel>> searchMessages({
    required String conversationId,
    required String query,
  }) async {
    return await _remoteDatasource.searchMessages(
      conversationId: conversationId,
      query: query,
    );
  }
}
