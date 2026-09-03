// lib/features/chats/data/datasources/chat_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/chats/data/models/conversation_model.dart';
import 'package:mobile/features/chats/data/models/chat_discovery_model.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';

final chatRemoteDatasourceProvider = Provider<ChatRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatRemoteDatasource(apiClient);
});

class ChatRemoteDatasource {
  final Dio _apiClient;

  ChatRemoteDatasource(this._apiClient);

  // ══════════════════════════════════════════════════════════════
  // CONVERSATIONS & DISCOVERY
  // ══════════════════════════════════════════════════════════════

  Future<ChatDiscoveryModel> getChatDiscovery() async {
    try {
      final response = await _apiClient.get('/conversations/discover');
      final data = parseEnvelope(response.data);
      return ChatDiscoveryModel.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ConversationModel>> getUserConversations() async {
    try {
      final response = await _apiClient.get('/conversations');
      final list = parseEnvelopeList(response.data);
      return list
          .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ConversationModel> getConversationById(String conversationId) async {
    try {
      final response = await _apiClient.get('/conversations/$conversationId');
      final data = parseEnvelope(response.data);
      return ConversationModel.fromJson(data);
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
      final data = parseEnvelope(response.data);
      return ConversationModel.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ConversationModel> createOrGetGroupConversation(String groupId) async {
    try {
      final response = await _apiClient.post('/conversations/group/$groupId');
      final data = parseEnvelope(response.data);
      return ConversationModel.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createGroup({
    required String name,
    required String slug,
    String? description,
    String visibility = 'PUBLIC', // 'PUBLIC' or 'PRIVATE'
  }) async {
    try {
      final response = await _apiClient.post(
        '/groups',
        data: {
          'name': name,
          'slug': slug,
          'description': ?description,
          'visibility': visibility,
        },
      );
      return parseEnvelope(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getGroupInviteLink(String groupId) async {
    try {
      final response = await _apiClient.get('/groups/$groupId/invite-link');
      return parseEnvelope(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> joinGroupByInvite(String token) async {
    try {
      final response = await _apiClient.post('/groups/invites/$token/join');
      return parseEnvelope(response.data);
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
          'cursor': ?cursor,
          'limit': limit,
        },
      );
      final data = parseEnvelope(response.data);
      return PaginatedMessagesModel.fromJson(data);
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
    String? clientId,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'type': type,
      };
      if (content != null) body['content'] = content;
      if (replyToId != null) body['replyToId'] = replyToId;
      if (attachmentIds != null && attachmentIds.isNotEmpty) {
        body['attachmentIds'] = attachmentIds;
        body['fileIds'] = attachmentIds;
      }
      if (clientId != null) body['clientId'] = clientId;

      final response = await _apiClient.post(
        '/conversations/$conversationId/messages',
        data: body,
      );
      final data = parseEnvelope(response.data);
      return MessageModel.fromJson(data);
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
      final data = parseEnvelope(response.data);
      return MessageModel.fromJson(data);
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
      final list = parseEnvelopeList(response.data);
      return list
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
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
      final list = parseEnvelopeList(response.data);
      return list
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
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
        'conversationId': ?conversationId,
      });

      final response = await _apiClient.post(
        '/uploads/chat',
        data: formData,
        onSendProgress: onUploadProgress,
      );

      final data = parseEnvelope(response.data);
      return data;
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
      final list = parseEnvelopeList(response.data);
      return list
          .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
          .toList();
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
      final list = parseEnvelopeList(response.data);
      return list
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
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
        final data = error.response?.data;
        if (data is Map<String, dynamic>) {
          final message = data['message'] ?? data['error'];
          if (message is List) {
            return Exception(message.join(', '));
          } else if (message != null) {
            return Exception(message.toString());
          }
        }
        return Exception('Server Error (${error.response?.statusCode})');
      }
      return Exception('Network Error: ${error.message}');
    }
    return Exception(error.toString().replaceFirst('Exception: ', ''));
  }
}
