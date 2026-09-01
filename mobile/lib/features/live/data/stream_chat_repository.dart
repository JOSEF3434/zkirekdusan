// lib/features/live/data/stream_chat_repository.dart
// HTTP calls for stream chat history and moderation.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/live/domain/chat_message_model.dart';

final streamChatRepositoryProvider = Provider<StreamChatRepository>((ref) {
  return StreamChatRepository(ref.read(apiClientProvider));
});

class StreamChatRepository {
  final Dio _dio;

  StreamChatRepository(this._dio);

  /// GET /streams/:streamId/chat  (cursor-based pagination)
  Future<ChatHistoryResponse> getChatHistory(
    String streamId, {
    int limit = 50,
    String? cursor,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        '/streams/$streamId/chat',
        queryParameters: {
          'limit': limit,
          if (cursor != null) 'cursor': cursor,
        },
        cancelToken: cancelToken,
      );
      final raw = response.data;
      // Backend returns {success, data: {messages: [...], nextCursor, hasMore}}
      final envelope = parseEnvelope(raw);
      final messagesJson =
          (envelope['messages'] as List?) ?? (envelope['data'] as List?) ?? [];
      final messages = messagesJson
          .map((e) => ChatMessageDto.fromJson(e as Map<String, dynamic>))
          .toList();
      return ChatHistoryResponse(
        messages: messages,
        nextCursor: envelope['nextCursor'] as String?,
        hasMore: envelope['hasMore'] as bool? ?? false,
      );
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  /// DELETE /streams/:streamId/chat/:messageId (moderator)
  Future<void> deleteMessage(String streamId, String messageId) async {
    try {
      await _dio.delete('/streams/$streamId/chat/$messageId');
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  /// POST /streams/:streamId/chat/:messageId/pin (moderator)
  Future<void> pinMessage(
    String streamId,
    String messageId, {
    bool pin = true,
  }) async {
    try {
      if (pin) {
        await _dio.post('/streams/$streamId/chat/$messageId/pin');
      } else {
        await _dio.delete('/streams/$streamId/chat/$messageId/pin');
      }
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  String _parseDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is String) return msg;
      if (msg is List) return (msg).join(', ');
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout => 'Connection timed out.',
      DioExceptionType.connectionError => 'Could not connect to the server.',
      _ => 'An unexpected error occurred.',
    };
  }
}
