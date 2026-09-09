// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatSenderDto _$ChatSenderDtoFromJson(Map<String, dynamic> json) =>
    _ChatSenderDto(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$ChatSenderDtoToJson(_ChatSenderDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
    };

_ChatMessageDto _$ChatMessageDtoFromJson(Map<String, dynamic> json) =>
    _ChatMessageDto(
      id: json['id'] as String,
      content: json['content'] as String,
      type:
          $enumDecodeNullable(_$ChatMessageTypeEnumMap, json['type']) ??
          ChatMessageType.text,
      isPinned: json['isPinned'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] as String,
      sender: json['sender'] == null
          ? null
          : ChatSenderDto.fromJson(json['sender'] as Map<String, dynamic>),
      isPending: json['isPending'] as bool? ?? false,
      isError: json['isError'] as bool? ?? false,
    );

Map<String, dynamic> _$ChatMessageDtoToJson(_ChatMessageDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'type': _$ChatMessageTypeEnumMap[instance.type]!,
      'isPinned': instance.isPinned,
      'isDeleted': instance.isDeleted,
      'createdAt': instance.createdAt,
      'sender': instance.sender,
      'isPending': instance.isPending,
      'isError': instance.isError,
    };

const _$ChatMessageTypeEnumMap = {
  ChatMessageType.text: 'TEXT',
  ChatMessageType.system: 'SYSTEM',
  ChatMessageType.sticker: 'STICKER',
  ChatMessageType.gift: 'GIFT',
};

_ChatReactionEvent _$ChatReactionEventFromJson(Map<String, dynamic> json) =>
    _ChatReactionEvent(
      messageId: json['messageId'] as String,
      emoji: json['emoji'] as String,
      count: (json['count'] as num).toInt(),
      reactionId: json['reactionId'] as String,
    );

Map<String, dynamic> _$ChatReactionEventToJson(_ChatReactionEvent instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'emoji': instance.emoji,
      'count': instance.count,
      'reactionId': instance.reactionId,
    };

_ChatHistoryResponse _$ChatHistoryResponseFromJson(Map<String, dynamic> json) =>
    _ChatHistoryResponse(
      messages: (json['messages'] as List<dynamic>)
          .map((e) => ChatMessageDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
      hasMore: json['hasMore'] as bool? ?? false,
    );

Map<String, dynamic> _$ChatHistoryResponseToJson(
  _ChatHistoryResponse instance,
) => <String, dynamic>{
  'messages': instance.messages,
  'nextCursor': instance.nextCursor,
  'hasMore': instance.hasMore,
};
