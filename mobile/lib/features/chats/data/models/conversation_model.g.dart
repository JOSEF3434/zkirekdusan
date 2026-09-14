// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ConversationModel _$ConversationModelFromJson(Map<String, dynamic> json) =>
    _ConversationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      groupId: json['groupId'] as String?,
      channelId: json['channelId'] as String?,
      title: json['title'] as String?,
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
      lastMessage: json['lastMessage'] == null
          ? null
          : MessagePreviewModel.fromJson(
              json['lastMessage'] as Map<String, dynamic>,
            ),
      members:
          (json['members'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ConversationMemberModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] == null
          ? null
          : ConversationMetadataModel.fromJson(
              json['metadata'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$ConversationModelToJson(_ConversationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'groupId': instance.groupId,
      'channelId': instance.channelId,
      'title': instance.title,
      'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
      'lastMessage': instance.lastMessage,
      'members': instance.members,
      'createdAt': instance.createdAt.toIso8601String(),
      'metadata': instance.metadata,
    };

_ConversationMemberModel _$ConversationMemberModelFromJson(
  Map<String, dynamic> json,
) => _ConversationMemberModel(
  userId: json['userId'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
  isMuted: json['isMuted'] as bool? ?? false,
  isPinned: json['isPinned'] as bool? ?? false,
  isOnline: json['isOnline'] as bool? ?? false,
  lastSeen: json['lastSeen'] as String?,
  typingStatus: json['typingStatus'] == null
      ? null
      : TypingStatusModel.fromJson(
          json['typingStatus'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ConversationMemberModelToJson(
  _ConversationMemberModel instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'username': instance.username,
  'displayName': instance.displayName,
  'avatarUrl': instance.avatarUrl,
  'unreadCount': instance.unreadCount,
  'isMuted': instance.isMuted,
  'isPinned': instance.isPinned,
  'isOnline': instance.isOnline,
  'lastSeen': instance.lastSeen,
  'typingStatus': instance.typingStatus,
};

_MessagePreviewModel _$MessagePreviewModelFromJson(Map<String, dynamic> json) =>
    _MessagePreviewModel(
      id: json['id'] as String,
      content: json['content'] as String?,
      type: json['type'] as String,
      senderName: json['senderName'] as String?,
      isMe: json['isMe'] as bool?,
      attachmentPreview: json['attachmentPreview'] as String?,
    );

Map<String, dynamic> _$MessagePreviewModelToJson(
  _MessagePreviewModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'content': instance.content,
  'type': instance.type,
  'senderName': instance.senderName,
  'isMe': instance.isMe,
  'attachmentPreview': instance.attachmentPreview,
};

_ConversationMetadataModel _$ConversationMetadataModelFromJson(
  Map<String, dynamic> json,
) => _ConversationMetadataModel(
  groupName: json['groupName'] as String?,
  groupAvatar: json['groupAvatar'] as String?,
  memberCount: (json['memberCount'] as num?)?.toInt(),
  isVerified: json['isVerified'] as bool?,
  channelName: json['channelName'] as String?,
  description: json['description'] as String?,
);

Map<String, dynamic> _$ConversationMetadataModelToJson(
  _ConversationMetadataModel instance,
) => <String, dynamic>{
  'groupName': instance.groupName,
  'groupAvatar': instance.groupAvatar,
  'memberCount': instance.memberCount,
  'isVerified': instance.isVerified,
  'channelName': instance.channelName,
  'description': instance.description,
};

_TypingStatusModel _$TypingStatusModelFromJson(Map<String, dynamic> json) =>
    _TypingStatusModel(
      isTyping: json['isTyping'] as bool,
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
    );

Map<String, dynamic> _$TypingStatusModelToJson(_TypingStatusModel instance) =>
    <String, dynamic>{
      'isTyping': instance.isTyping,
      'startedAt': instance.startedAt?.toIso8601String(),
    };
