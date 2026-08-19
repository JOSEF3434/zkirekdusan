// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_playlist_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChannelPlaylistItemDtoImpl _$$ChannelPlaylistItemDtoImplFromJson(
  Map<String, dynamic> json,
) => _$ChannelPlaylistItemDtoImpl(
  id: json['id'] as String,
  order: (json['order'] as num).toInt(),
  videoId: json['videoId'] as String,
  videoTitle: json['videoTitle'] as String?,
  videoSlug: json['videoSlug'] as String?,
  videoDuration: (json['videoDuration'] as num?)?.toDouble(),
  videoThumbnailUrl: json['videoThumbnailUrl'] as String?,
  videoViewsCount: (json['videoViewsCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$$ChannelPlaylistItemDtoImplToJson(
  _$ChannelPlaylistItemDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'order': instance.order,
  'videoId': instance.videoId,
  'videoTitle': instance.videoTitle,
  'videoSlug': instance.videoSlug,
  'videoDuration': instance.videoDuration,
  'videoThumbnailUrl': instance.videoThumbnailUrl,
  'videoViewsCount': instance.videoViewsCount,
};

_$ChannelPlaylistDtoImpl _$$ChannelPlaylistDtoImplFromJson(
  Map<String, dynamic> json,
) => _$ChannelPlaylistDtoImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  visibility: json['visibility'] as String,
  videosCount: (json['videosCount'] as num).toInt(),
  ownerId: json['ownerId'] as String,
  ownerUsername: json['ownerUsername'] as String?,
  videoChannelId: json['videoChannelId'] as String?,
  channelName: json['channelName'] as String?,
  items:
      (json['items'] as List<dynamic>?)
          ?.map(
            (e) => ChannelPlaylistItemDto.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$ChannelPlaylistDtoImplToJson(
  _$ChannelPlaylistDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'visibility': instance.visibility,
  'videosCount': instance.videosCount,
  'ownerId': instance.ownerId,
  'ownerUsername': instance.ownerUsername,
  'videoChannelId': instance.videoChannelId,
  'channelName': instance.channelName,
  'items': instance.items,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
