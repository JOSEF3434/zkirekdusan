// lib/features/live/domain/chat_message_model.dart
// Models for live stream chat messages, reactions, and related events.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message_model.freezed.dart';
part 'chat_message_model.g.dart';

enum ChatMessageType {
  @JsonValue('TEXT')
  text,
  @JsonValue('SYSTEM')
  system,
  @JsonValue('STICKER')
  sticker,
  @JsonValue('GIFT')
  gift,
}

@freezed
abstract class ChatSenderDto with _$ChatSenderDto {
  const factory ChatSenderDto({
    required String id,
    String? username,
    String? displayName,
    String? avatarUrl,
  }) = _ChatSenderDto;

  factory ChatSenderDto.fromJson(Map<String, dynamic> json) =>
      _$ChatSenderDtoFromJson(json);
}

@freezed
abstract class ChatMessageDto with _$ChatMessageDto {
  const factory ChatMessageDto({
    required String id,
    required String content,
    @Default(ChatMessageType.text) ChatMessageType type,
    @Default(false) bool isPinned,
    @Default(false) bool isDeleted,
    required String createdAt,
    ChatSenderDto? sender,
    // Locally tracked send status (not from backend)
    @Default(false) bool isPending,
    @Default(false) bool isError,
  }) = _ChatMessageDto;

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageDtoFromJson(json);
}

@freezed
abstract class ChatReactionEvent with _$ChatReactionEvent {
  const factory ChatReactionEvent({
    required String messageId,
    required String emoji,
    required int count,
    required String reactionId,
  }) = _ChatReactionEvent;

  factory ChatReactionEvent.fromJson(Map<String, dynamic> json) =>
      _$ChatReactionEventFromJson(json);
}

@freezed
abstract class ChatHistoryResponse with _$ChatHistoryResponse {
  const factory ChatHistoryResponse({
    required List<ChatMessageDto> messages,
    String? nextCursor,
    @Default(false) bool hasMore,
  }) = _ChatHistoryResponse;

  factory ChatHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatHistoryResponseFromJson(json);
}

// Floating reaction (emoji bursts on screen)
class ReactionBroadcastEvent {
  final String emoji;
  final int count;

  const ReactionBroadcastEvent({required this.emoji, required this.count});

  factory ReactionBroadcastEvent.fromJson(Map<String, dynamic> json) =>
      ReactionBroadcastEvent(
        emoji: json['emoji'] as String? ?? '❤️',
        count: json['count'] as int? ?? 1,
      );
}
