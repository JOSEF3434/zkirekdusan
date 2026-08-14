// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatSenderDtoImpl _$$ChatSenderDtoImplFromJson(Map<String, dynamic> json) =>
    _$ChatSenderDtoImpl(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$$ChatSenderDtoImplToJson(_$ChatSenderDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
    };

_$ChatMessageDtoImpl _$$ChatMessageDtoImplFromJson(Map<String, dynamic> json) =>
    _$ChatMessageDtoImpl(
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

Map<String, dynamic> _$$ChatMessageDtoImplToJson(
  _$ChatMessageDtoImpl instance,
) => <String, dynamic>{
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

_$ChatReactionEventImpl _$$ChatReactionEventImplFromJson(
  Map<String, dynamic> json,
) => _$ChatReactionEventImpl(
  messageId: json['messageId'] as String,
  emoji: json['emoji'] as String,
  count: (json['count'] as num).toInt(),
  reactionId: json['reactionId'] as String,
);

Map<String, dynamic> _$$ChatReactionEventImplToJson(
  _$ChatReactionEventImpl instance,
) => <String, dynamic>{
  'messageId': instance.messageId,
  'emoji': instance.emoji,
  'count': instance.count,
  'reactionId': instance.reactionId,
};

_$ChatHistoryResponseImpl _$$ChatHistoryResponseImplFromJson(
  Map<String, dynamic> json,
) => _$ChatHistoryResponseImpl(
  messages: (json['messages'] as List<dynamic>)
      .map((e) => ChatMessageDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['nextCursor'] as String?,
  hasMore: json['hasMore'] as bool? ?? false,
);

Map<String, dynamic> _$$ChatHistoryResponseImplToJson(
  _$ChatHistoryResponseImpl instance,
) => <String, dynamic>{
  'messages': instance.messages,
  'nextCursor': instance.nextCursor,
  'hasMore': instance.hasMore,
};
