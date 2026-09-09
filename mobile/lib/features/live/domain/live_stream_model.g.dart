// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_stream_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StreamCreatorDto _$StreamCreatorDtoFromJson(Map<String, dynamic> json) =>
    _StreamCreatorDto(
      id: json['id'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$StreamCreatorDtoToJson(_StreamCreatorDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'avatarUrl': instance.avatarUrl,
    };

_StreamChannelDto _$StreamChannelDtoFromJson(Map<String, dynamic> json) =>
    _StreamChannelDto(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$StreamChannelDtoToJson(_StreamChannelDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
    };

_StreamGroupDto _$StreamGroupDtoFromJson(Map<String, dynamic> json) =>
    _StreamGroupDto(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$StreamGroupDtoToJson(_StreamGroupDto instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};

_LiveStreamDto _$LiveStreamDtoFromJson(
  Map<String, dynamic> json,
) => _LiveStreamDto(
  id: json['id'] as String,
  videoChannelId: json['videoChannelId'] as String,
  groupId: json['groupId'] as String,
  createdById: json['createdById'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  slug: json['slug'] as String,
  status: $enumDecode(_$LiveStreamStatusEnumMap, json['status']),
  visibility: $enumDecode(_$LiveStreamVisibilityEnumMap, json['visibility']),
  protocol: $enumDecode(_$StreamProtocolEnumMap, json['protocol']),
  hlsUrl: json['hlsUrl'] as String?,
  dashUrl: json['dashUrl'] as String?,
  webrtcUrl: json['webrtcUrl'] as String?,
  rtmpIngestUrl: json['rtmpIngestUrl'] as String?,
  thumbnailUrl: json['thumbnailUrl'] as String?,
  categories:
      (json['categories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  hashtags:
      (json['hashtags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  scheduledAt: json['scheduledAt'] as String?,
  startedAt: json['startedAt'] as String?,
  endedAt: json['endedAt'] as String?,
  isRecordingEnabled: json['isRecordingEnabled'] as bool? ?? true,
  isDvrEnabled: json['isDvrEnabled'] as bool? ?? true,
  isReplayEnabled: json['isReplayEnabled'] as bool? ?? true,
  isChatEnabled: json['isChatEnabled'] as bool? ?? true,
  isChatSlowMode: json['isChatSlowMode'] as bool? ?? false,
  chatSlowModeSeconds: (json['chatSlowModeSeconds'] as num?)?.toInt() ?? 0,
  isMembersOnlyChat: json['isMembersOnlyChat'] as bool? ?? false,
  isSubscribersOnlyChat: json['isSubscribersOnlyChat'] as bool? ?? false,
  peakViewerCount: (json['peakViewerCount'] as num?)?.toInt() ?? 0,
  currentViewerCount: (json['currentViewerCount'] as num?)?.toInt() ?? 0,
  totalViewerCount: (json['totalViewerCount'] as num?)?.toInt() ?? 0,
  totalChatMessages: (json['totalChatMessages'] as num?)?.toInt() ?? 0,
  totalReactions: (json['totalReactions'] as num?)?.toInt() ?? 0,
  likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
  duration: (json['duration'] as num?)?.toInt(),
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
  createdBy: json['createdBy'] == null
      ? null
      : StreamCreatorDto.fromJson(json['createdBy'] as Map<String, dynamic>),
  group: json['group'] == null
      ? null
      : StreamGroupDto.fromJson(json['group'] as Map<String, dynamic>),
  videoChannel: json['videoChannel'] == null
      ? null
      : StreamChannelDto.fromJson(json['videoChannel'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LiveStreamDtoToJson(_LiveStreamDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'videoChannelId': instance.videoChannelId,
      'groupId': instance.groupId,
      'createdById': instance.createdById,
      'title': instance.title,
      'description': instance.description,
      'slug': instance.slug,
      'status': _$LiveStreamStatusEnumMap[instance.status]!,
      'visibility': _$LiveStreamVisibilityEnumMap[instance.visibility]!,
      'protocol': _$StreamProtocolEnumMap[instance.protocol]!,
      'hlsUrl': instance.hlsUrl,
      'dashUrl': instance.dashUrl,
      'webrtcUrl': instance.webrtcUrl,
      'rtmpIngestUrl': instance.rtmpIngestUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'categories': instance.categories,
      'tags': instance.tags,
      'hashtags': instance.hashtags,
      'scheduledAt': instance.scheduledAt,
      'startedAt': instance.startedAt,
      'endedAt': instance.endedAt,
      'isRecordingEnabled': instance.isRecordingEnabled,
      'isDvrEnabled': instance.isDvrEnabled,
      'isReplayEnabled': instance.isReplayEnabled,
      'isChatEnabled': instance.isChatEnabled,
      'isChatSlowMode': instance.isChatSlowMode,
      'chatSlowModeSeconds': instance.chatSlowModeSeconds,
      'isMembersOnlyChat': instance.isMembersOnlyChat,
      'isSubscribersOnlyChat': instance.isSubscribersOnlyChat,
      'peakViewerCount': instance.peakViewerCount,
      'currentViewerCount': instance.currentViewerCount,
      'totalViewerCount': instance.totalViewerCount,
      'totalChatMessages': instance.totalChatMessages,
      'totalReactions': instance.totalReactions,
      'likesCount': instance.likesCount,
      'duration': instance.duration,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'createdBy': instance.createdBy,
      'group': instance.group,
      'videoChannel': instance.videoChannel,
    };

const _$LiveStreamStatusEnumMap = {
  LiveStreamStatus.draft: 'DRAFT',
  LiveStreamStatus.scheduled: 'SCHEDULED',
  LiveStreamStatus.live: 'LIVE',
  LiveStreamStatus.ended: 'ENDED',
  LiveStreamStatus.processing: 'PROCESSING',
  LiveStreamStatus.vodReady: 'VOD_READY',
  LiveStreamStatus.cancelled: 'CANCELLED',
  LiveStreamStatus.failed: 'FAILED',
};

const _$LiveStreamVisibilityEnumMap = {
  LiveStreamVisibility.public: 'PUBLIC',
  LiveStreamVisibility.private: 'PRIVATE',
  LiveStreamVisibility.groupOnly: 'GROUP_ONLY',
  LiveStreamVisibility.unlisted: 'UNLISTED',
};

const _$StreamProtocolEnumMap = {
  StreamProtocol.rtmp: 'RTMP',
  StreamProtocol.webrtc: 'WEBRTC',
  StreamProtocol.hlsPull: 'HLS_PULL',
};

_StreamKeyDto _$StreamKeyDtoFromJson(Map<String, dynamic> json) =>
    _StreamKeyDto(
      channelId: json['channelId'] as String,
      keyPrefix: json['keyPrefix'] as String?,
      rtmpUrl: json['rtmpUrl'] as String?,
      rawKey: json['rawKey'] as String?,
    );

Map<String, dynamic> _$StreamKeyDtoToJson(_StreamKeyDto instance) =>
    <String, dynamic>{
      'channelId': instance.channelId,
      'keyPrefix': instance.keyPrefix,
      'rtmpUrl': instance.rtmpUrl,
      'rawKey': instance.rawKey,
    };
