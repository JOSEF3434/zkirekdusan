// lib/features/chats/data/datasources/chat_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/chats/data/models/conversation_model.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';

final chatRemoteDatasourceProvider = Provider<ChatRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatRemoteDatasource(apiClient);
});

class ChatRemoteDatasource {
  final Dio _apiClient;

  ChatRemoteDatasource(this._apiClient);

  // ══════════════════════════════════════════════════════════════
  // CONVERSATIONS
  // ══════════════════════════════════════════════════════════════

  Future<List<ConversationModel>> getUserConversations() async {
    try {
      final response = await _apiClient.get('/conversations');
      final data = response.data as List;
      return data.map((json) => ConversationModel.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ConversationModel> getConversationById(String conversationId) async {
    try {
      final response = await _apiClient.get('/conversations/$conversationId');
      return ConversationModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ConversationModel> createDirectConversation(String recipientId) async {
    try {
      final response = await _apiClient.post(
        '/conversations/direct',
        data: {'recipientId': recipientId},
      );
      return ConversationModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> muteConversation(String conversationId) async {
    try {
      await _apiClient.post('/conversations/$conversationId/mute');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> unmuteConversation(String conversationId) async {
    try {
      await _apiClient.post('/conversations/$conversationId/unmute');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> pinConversation(String conversationId) async {
    try {
      await _apiClient.post('/conversations/$conversationId/pin');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> unpinConversation(String conversationId) async {
    try {
      await _apiClient.post('/conversations/$conversationId/unpin');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await _apiClient.post('/conversations/$conversationId/mark-read');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ══════════════════════════════════════════════════════════════
  // MESSAGES
  // ══════════════════════════════════════════════════════════════

  Future<PaginatedMessagesModel> getMessages({
    required String conversationId,
    String? cursor,
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/conversations/$conversationId/messages',
        queryParameters: {
          ...?(cursor == null ? null : {'cursor': cursor}),
          'limit': limit,
        },
      );
      return PaginatedMessagesModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<MessageModel> sendMessage({
    required String conversationId,
    String? content,
    String? replyToId,
    List<String>? attachmentIds,
    String type = 'TEXT',
  }) async {
    try {
      final response = await _apiClient.post(
        '/conversations/$conversationId/messages',
        data: {
          ...?(content == null ? null : {'content': content}),
          'type': type,
          ...?(replyToId == null ? null : {'replyToId': replyToId}),
          ...?(attachmentIds == null || attachmentIds.isEmpty
              ? null
              : {'attachmentIds': attachmentIds}),
        },
      );
      return MessageModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<MessageModel> editMessage({
    required String messageId,
    required String content,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/messages/$messageId',
        data: {'content': content},
      );
      return MessageModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _apiClient.delete('/messages/$messageId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      await _apiClient.post(
        '/messages/$messageId/reactions',
        data: {'emoji': emoji},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      await _apiClient.delete(
        '/messages/$messageId/reactions',
        data: {'emoji': emoji},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markAsRead(String messageId) async {
    try {
      await _apiClient.post('/messages/$messageId/read');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> pinMessage({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      await _apiClient.post(
        '/conversations/$conversationId/messages/$messageId/pin',
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> unpinMessage({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      await _apiClient.delete(
        '/conversations/$conversationId/messages/$messageId/pin',
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<MessageModel>> getPinnedMessages(String conversationId) async {
    try {
      final response = await _apiClient.get(
        '/conversations/$conversationId/messages/pinned',
      );
      final data = response.data as List;
      return data.map((json) => MessageModel.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> starMessage(String messageId) async {
    try {
      await _apiClient.post('/messages/$messageId/star');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> unstarMessage(String messageId) async {
    try {
      await _apiClient.delete('/messages/$messageId/star');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<MessageModel>> getStarredMessages() async {
    try {
      final response = await _apiClient.get('/messages/starred');
      final data = response.data as List;
      return data.map((json) => MessageModel.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ══════════════════════════════════════════════════════════════
  // MEDIA UPLOAD
  // ══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> uploadChatMedia({
    required String filePath,
    required String fileName,
    required String mimeType,
    String? conversationId,
    Function(int, int)? onUploadProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        ...?(conversationId == null
            ? null
            : {'conversationId': conversationId}),
      });

      final response = await _apiClient.post(
        '/uploads/chat',
        data: formData,
        onSendProgress: onUploadProgress,
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ══════════════════════════════════════════════════════════════
  // SEARCH
  // ══════════════════════════════════════════════════════════════

  Future<List<ConversationModel>> searchConversations(String query) async {
    try {
      final response = await _apiClient.get(
        '/conversations/search',
        queryParameters: {'q': query},
      );
      final data = response.data as List;
      return data.map((json) => ConversationModel.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<MessageModel>> searchMessages({
    required String conversationId,
    required String query,
  }) async {
    try {
      final response = await _apiClient.get(
        '/conversations/$conversationId/messages/search',
        queryParameters: {'q': query},
      );
      final data = response.data as List;
      return data.map((json) => MessageModel.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ══════════════════════════════════════════════════════════════
  // ERROR HANDLING
  // ══════════════════════════════════════════════════════════════

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final message = error.response?.data['message'] ?? error.message;
        return Exception('Chat API Error: $message');
      }
      return Exception('Network Error: ${error.message}');
    }
    return Exception('Unknown Error: $error');
  }
}
