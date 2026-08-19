// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_video_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChannelVideoDtoImpl _$$ChannelVideoDtoImplFromJson(
  Map<String, dynamic> json,
) => _$ChannelVideoDtoImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  slug: json['slug'] as String,
  description: json['description'] as String?,
  status: json['status'] as String,
  visibility: json['visibility'] as String,
  thumbnailUrl: json['thumbnailUrl'] as String?,
  hlsUrl: json['hlsUrl'] as String?,
  duration: (json['duration'] as num?)?.toDouble(),
  viewsCount: (json['viewsCount'] as num).toInt(),
  likesCount: (json['likesCount'] as num).toInt(),
  commentsCount: (json['commentsCount'] as num).toInt(),
  videoChannelId: json['videoChannelId'] as String,
  channelName: json['channelName'] as String?,
  channelHandle: json['channelHandle'] as String?,
  groupId: json['groupId'] as String?,
  uploadedById: json['uploadedById'] as String,
  uploaderUsername: json['uploaderUsername'] as String?,
  uploaderDisplayName: json['uploaderDisplayName'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  publishedAt: json['publishedAt'] == null
      ? null
      : DateTime.parse(json['publishedAt'] as String),
);

Map<String, dynamic> _$$ChannelVideoDtoImplToJson(
  _$ChannelVideoDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'slug': instance.slug,
  'description': instance.description,
  'status': instance.status,
  'visibility': instance.visibility,
  'thumbnailUrl': instance.thumbnailUrl,
  'hlsUrl': instance.hlsUrl,
  'duration': instance.duration,
  'viewsCount': instance.viewsCount,
  'likesCount': instance.likesCount,
  'commentsCount': instance.commentsCount,
  'videoChannelId': instance.videoChannelId,
  'channelName': instance.channelName,
  'channelHandle': instance.channelHandle,
  'groupId': instance.groupId,
  'uploadedById': instance.uploadedById,
  'uploaderUsername': instance.uploaderUsername,
  'uploaderDisplayName': instance.uploaderDisplayName,
  'createdAt': instance.createdAt.toIso8601String(),
  'publishedAt': instance.publishedAt?.toIso8601String(),
};
