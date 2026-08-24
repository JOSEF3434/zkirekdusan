// lib/features/chats/domain/repositories/chat_repository.dart

//import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/chats/data/models/conversation_model.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';

abstract class ChatRepository {
  // Conversations
  Future<List<ConversationModel>> getUserConversations();
  Future<ConversationModel> getConversationById(String conversationId);
  Future<ConversationModel> createDirectConversation(String recipientId);
  Future<void> muteConversation(String conversationId);
  Future<void> unmuteConversation(String conversationId);
  Future<void> pinConversation(String conversationId);
  Future<void> unpinConversation(String conversationId);
  Future<void> markConversationAsRead(String conversationId);

  // Messages
  Future<PaginatedMessagesModel> getMessages({
    required String conversationId,
    String? cursor,
    int limit = 50,
  });
  
  Future<MessageModel> sendMessage({
    required String conversationId,
    String? content,
    String? replyToId,
    List<String>? attachmentIds,
    String type = 'TEXT',
  });
  
  Future<MessageModel> editMessage({
    required String messageId,
    required String content,
  });
  
  Future<void> deleteMessage(String messageId);

  // Reactions
  Future<void> addReaction({
    required String messageId,
    required String emoji,
  });
  
  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  });

  // Read receipts
  Future<void> markAsRead(String messageId);

  // Pin messages
  Future<void> pinMessage({
    required String conversationId,
    required String messageId,
  });
  
  Future<void> unpinMessage({
    required String conversationId,
    required String messageId,
  });
  
  Future<List<MessageModel>> getPinnedMessages(String conversationId);

  // Star messages
  Future<void> starMessage(String messageId);
  Future<void> unstarMessage(String messageId);
  Future<List<MessageModel>> getStarredMessages();

  // Media upload
  Future<Map<String, dynamic>> uploadChatMedia({
    required String filePath,
    required String fileName,
    required String mimeType,
    String? conversationId,
    Function(int, int)? onUploadProgress,
  });

  // Search
  Future<List<ConversationModel>> searchConversations(String query);
  Future<List<MessageModel>> searchMessages({
    required String conversationId,
    required String query,
  });
}
