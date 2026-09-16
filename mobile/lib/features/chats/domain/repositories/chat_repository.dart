import 'package:mobile/features/chats/data/models/conversation_model.dart';
import 'package:mobile/features/chats/data/models/chat_discovery_model.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';

abstract class ChatRepository {
  // Conversations & Discovery
  Future<ChatDiscoveryModel> getChatDiscovery();
  Future<List<ConversationModel>> getUserConversations();
  Future<List<ConversationModel>> getCachedConversations();
  Future<ConversationModel> getConversationById(String conversationId);
  Future<ConversationModel> createDirectConversation(String recipientId);
  Future<ConversationModel> createOrGetGroupConversation(String groupId);
  Future<Map<String, dynamic>> createGroup({
    required String name,
    required String slug,
    String? description,
    String visibility = 'PUBLIC',
  });
  Future<Map<String, dynamic>> getGroupInviteLink(String groupId);
  Future<Map<String, dynamic>> joinGroupByInvite(String token);
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
    String? clientId,
    List<MessageAttachmentModel>? initialAttachments,
    MessageVoiceNoteModel? voiceNote,
  });
  
  Future<MessageModel> editMessage({
    required String messageId,
    required String content,
  });
  
  Future<void> deleteMessage(String messageId, {bool forEveryone = false});

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
