// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageModel _$MessageModelFromJson(
  Map<String, dynamic> json,
) => _MessageModel(
  id: json['id'] as String,
  conversationId: json['conversationId'] as String,
  channelId: json['channelId'] as String?,
  sender: MessageSenderModel.fromJson(json['sender'] as Map<String, dynamic>),
  content: json['content'] as String?,
  type: json['type'] as String,
  replyToId: json['replyToId'] as String?,
  replyTo: json['replyTo'] == null
      ? null
      : MessageReplyModel.fromJson(json['replyTo'] as Map<String, dynamic>),
  isEdited: json['isEdited'] as bool? ?? false,
  isPinned: json['isPinned'] as bool? ?? false,
  attachments:
      (json['attachments'] as List<dynamic>?)
          ?.map(
            (e) => MessageAttachmentModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  reactions:
      (json['reactions'] as List<dynamic>?)
          ?.map((e) => MessageReactionModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  readBy:
      (json['readBy'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  deliveredTo:
      (json['deliveredTo'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  voiceNote: json['voiceNote'] == null
      ? null
      : MessageVoiceNoteModel.fromJson(
          json['voiceNote'] as Map<String, dynamic>,
        ),
  forward: json['forward'] == null
      ? null
      : MessageForwardModel.fromJson(json['forward'] as Map<String, dynamic>),
  mentions:
      (json['mentions'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$MessageModelToJson(_MessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversationId': instance.conversationId,
      'channelId': instance.channelId,
      'sender': instance.sender,
      'content': instance.content,
      'type': instance.type,
      'replyToId': instance.replyToId,
      'replyTo': instance.replyTo,
      'isEdited': instance.isEdited,
      'isPinned': instance.isPinned,
      'attachments': instance.attachments,
      'reactions': instance.reactions,
      'readBy': instance.readBy,
      'deliveredTo': instance.deliveredTo,
      'voiceNote': instance.voiceNote,
      'forward': instance.forward,
      'mentions': instance.mentions,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

_MessageSenderModel _$MessageSenderModelFromJson(Map<String, dynamic> json) =>
    _MessageSenderModel(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$MessageSenderModelToJson(_MessageSenderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
    };

_MessageReplyModel _$MessageReplyModelFromJson(Map<String, dynamic> json) =>
    _MessageReplyModel(
      id: json['id'] as String,
      content: json['content'] as String?,
      type: json['type'] as String,
      sender: MessageSenderModel.fromJson(
        json['sender'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$MessageReplyModelToJson(_MessageReplyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'type': instance.type,
      'sender': instance.sender,
    };

_MessageAttachmentModel _$MessageAttachmentModelFromJson(
  Map<String, dynamic> json,
) => _MessageAttachmentModel(
  fileId: json['fileId'] as String,
  url: json['url'] as String,
  fileType: json['fileType'] as String,
  mimeType: json['mimeType'] as String,
  originalName: json['originalName'] as String,
  width: (json['width'] as num?)?.toInt(),
  height: (json['height'] as num?)?.toInt(),
  duration: (json['duration'] as num?)?.toDouble(),
  size: (json['size'] as num?)?.toInt(),
  thumbnailUrl: json['thumbnailUrl'] as String?,
);

Map<String, dynamic> _$MessageAttachmentModelToJson(
  _MessageAttachmentModel instance,
) => <String, dynamic>{
  'fileId': instance.fileId,
  'url': instance.url,
  'fileType': instance.fileType,
  'mimeType': instance.mimeType,
  'originalName': instance.originalName,
  'width': instance.width,
  'height': instance.height,
  'duration': instance.duration,
  'size': instance.size,
  'thumbnailUrl': instance.thumbnailUrl,
};

_MessageReactionModel _$MessageReactionModelFromJson(
  Map<String, dynamic> json,
) => _MessageReactionModel(
  emoji: json['emoji'] as String,
  count: (json['count'] as num).toInt(),
  userIds: (json['userIds'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$MessageReactionModelToJson(
  _MessageReactionModel instance,
) => <String, dynamic>{
  'emoji': instance.emoji,
  'count': instance.count,
  'userIds': instance.userIds,
};

_MessageVoiceNoteModel _$MessageVoiceNoteModelFromJson(
  Map<String, dynamic> json,
) => _MessageVoiceNoteModel(
  fileId: json['fileId'] as String,
  url: json['url'] as String,
  duration: (json['duration'] as num).toInt(),
  waveform: (json['waveform'] as List<dynamic>?)
      ?.map((e) => (e as num).toDouble())
      .toList(),
);

Map<String, dynamic> _$MessageVoiceNoteModelToJson(
  _MessageVoiceNoteModel instance,
) => <String, dynamic>{
  'fileId': instance.fileId,
  'url': instance.url,
  'duration': instance.duration,
  'waveform': instance.waveform,
};

_MessageForwardModel _$MessageForwardModelFromJson(Map<String, dynamic> json) =>
    _MessageForwardModel(
      originalMessageId: json['originalMessageId'] as String,
      originalSender: MessageSenderModel.fromJson(
        json['originalSender'] as Map<String, dynamic>,
      ),
      originalCreatedAt: DateTime.parse(json['originalCreatedAt'] as String),
    );

Map<String, dynamic> _$MessageForwardModelToJson(
  _MessageForwardModel instance,
) => <String, dynamic>{
  'originalMessageId': instance.originalMessageId,
  'originalSender': instance.originalSender,
  'originalCreatedAt': instance.originalCreatedAt.toIso8601String(),
};

_PaginatedMessagesModel _$PaginatedMessagesModelFromJson(
  Map<String, dynamic> json,
) => _PaginatedMessagesModel(
  data: (json['data'] as List<dynamic>)
      .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['nextCursor'] as String?,
  hasMore: json['hasMore'] as bool? ?? false,
);

Map<String, dynamic> _$PaginatedMessagesModelToJson(
  _PaginatedMessagesModel instance,
) => <String, dynamic>{
  'data': instance.data,
  'nextCursor': instance.nextCursor,
  'hasMore': instance.hasMore,
};
