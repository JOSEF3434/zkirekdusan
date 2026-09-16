// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ConversationModel _$ConversationModelFromJson(Map<String, dynamic> json) =>
    _ConversationModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'DIRECT',
      groupId: json['groupId']?.toString(),
      channelId: json['channelId']?.toString(),
      title: json['title']?.toString(),
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.tryParse(json['lastMessageAt'].toString()),
      lastMessage: json['lastMessage'] == null
          ? null
          : (json['lastMessage'] is Map<String, dynamic>
              ? MessagePreviewModel.fromJson(
                  json['lastMessage'] as Map<String, dynamic>,
                )
              : null),
      members: (json['members'] as List<dynamic>?)
              ?.map(
                (e) => e is Map<String, dynamic>
                    ? ConversationMemberModel.fromJson(e)
                    : null,
              )
              .whereType<ConversationMemberModel>()
              .toList() ??
          const [],
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      metadata: json['metadata'] == null
          ? null
          : (json['metadata'] is Map<String, dynamic>
              ? ConversationMetadataModel.fromJson(
                  json['metadata'] as Map<String, dynamic>,
                )
              : null),
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
  userId: json['userId']?.toString() ?? '',
  username: json['username']?.toString() ?? '',
  displayName: json['displayName']?.toString(),
  avatarUrl: json['avatarUrl']?.toString(),
  unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
  isMuted: json['isMuted'] as bool? ?? false,
  isPinned: json['isPinned'] as bool? ?? false,
  isOnline: json['isOnline'] as bool? ?? false,
  lastSeen: json['lastSeen']?.toString(),
  typingStatus: json['typingStatus'] == null
      ? null
      : (json['typingStatus'] is Map<String, dynamic>
          ? TypingStatusModel.fromJson(
              json['typingStatus'] as Map<String, dynamic>,
            )
          : null),
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
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString(),
      type: json['type']?.toString() ?? 'TEXT',
      senderName: json['senderName']?.toString(),
      isMe: json['isMe'] as bool?,
      attachmentPreview: json['attachmentPreview']?.toString(),
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
  groupName: json['groupName']?.toString(),
  groupAvatar: json['groupAvatar']?.toString(),
  memberCount: (json['memberCount'] as num?)?.toInt(),
  isVerified: json['isVerified'] as bool?,
  channelName: json['channelName']?.toString(),
  description: json['description']?.toString(),
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
      isTyping: json['isTyping'] as bool? ?? false,
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.tryParse(json['startedAt'].toString()),
    );

Map<String, dynamic> _$TypingStatusModelToJson(_TypingStatusModel instance) =>
    <String, dynamic>{
      'isTyping': instance.isTyping,
      'startedAt': instance.startedAt?.toIso8601String(),
    };
