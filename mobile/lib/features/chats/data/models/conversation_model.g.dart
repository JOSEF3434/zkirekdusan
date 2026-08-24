// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConversationModelImpl _$$ConversationModelImplFromJson(
  Map<String, dynamic> json,
) => _$ConversationModelImpl(
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
            (e) => ConversationMemberModel.fromJson(e as Map<String, dynamic>),
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

Map<String, dynamic> _$$ConversationModelImplToJson(
  _$ConversationModelImpl instance,
) => <String, dynamic>{
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

_$ConversationMemberModelImpl _$$ConversationMemberModelImplFromJson(
  Map<String, dynamic> json,
) => _$ConversationMemberModelImpl(
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

Map<String, dynamic> _$$ConversationMemberModelImplToJson(
  _$ConversationMemberModelImpl instance,
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

_$MessagePreviewModelImpl _$$MessagePreviewModelImplFromJson(
  Map<String, dynamic> json,
) => _$MessagePreviewModelImpl(
  id: json['id'] as String,
  content: json['content'] as String?,
  type: json['type'] as String,
  senderName: json['senderName'] as String?,
  isMe: json['isMe'] as bool?,
  attachmentPreview: json['attachmentPreview'] as String?,
);

Map<String, dynamic> _$$MessagePreviewModelImplToJson(
  _$MessagePreviewModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'content': instance.content,
  'type': instance.type,
  'senderName': instance.senderName,
  'isMe': instance.isMe,
  'attachmentPreview': instance.attachmentPreview,
};

_$ConversationMetadataModelImpl _$$ConversationMetadataModelImplFromJson(
  Map<String, dynamic> json,
) => _$ConversationMetadataModelImpl(
  groupName: json['groupName'] as String?,
  groupAvatar: json['groupAvatar'] as String?,
  memberCount: (json['memberCount'] as num?)?.toInt(),
  isVerified: json['isVerified'] as bool?,
  channelName: json['channelName'] as String?,
  description: json['description'] as String?,
);

Map<String, dynamic> _$$ConversationMetadataModelImplToJson(
  _$ConversationMetadataModelImpl instance,
) => <String, dynamic>{
  'groupName': instance.groupName,
  'groupAvatar': instance.groupAvatar,
  'memberCount': instance.memberCount,
  'isVerified': instance.isVerified,
  'channelName': instance.channelName,
  'description': instance.description,
};

_$TypingStatusModelImpl _$$TypingStatusModelImplFromJson(
  Map<String, dynamic> json,
) => _$TypingStatusModelImpl(
  isTyping: json['isTyping'] as bool,
  startedAt: json['startedAt'] == null
      ? null
      : DateTime.parse(json['startedAt'] as String),
);

Map<String, dynamic> _$$TypingStatusModelImplToJson(
  _$TypingStatusModelImpl instance,
) => <String, dynamic>{
  'isTyping': instance.isTyping,
  'startedAt': instance.startedAt?.toIso8601String(),
};
