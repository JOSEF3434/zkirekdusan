// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creator_channel_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreatorChannelDto _$CreatorChannelDtoFromJson(Map<String, dynamic> json) =>
    _CreatorChannelDto(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      handle: json['handle'] as String,
      description: json['description'] as String?,
      status: $enumDecode(_$ChannelStatusEnumMap, json['status']),
      isVerified: json['isVerified'] as bool,
      uploadPermission: $enumDecode(
        _$UploadPermissionEnumMap,
        json['uploadPermission'],
      ),
      subscribersCount: (json['subscribersCount'] as num?)?.toInt() ?? 0,
      videosCount: (json['videosCount'] as num?)?.toInt() ?? 0,
      totalViewsCount: json['totalViewsCount'] as String?,
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CreatorChannelDtoToJson(_CreatorChannelDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'name': instance.name,
      'slug': instance.slug,
      'handle': instance.handle,
      'description': instance.description,
      'status': _$ChannelStatusEnumMap[instance.status]!,
      'isVerified': instance.isVerified,
      'uploadPermission': _$UploadPermissionEnumMap[instance.uploadPermission]!,
      'subscribersCount': instance.subscribersCount,
      'videosCount': instance.videosCount,
      'totalViewsCount': instance.totalViewsCount,
      'categories': instance.categories,
      'tags': instance.tags,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$ChannelStatusEnumMap = {
  ChannelStatus.active: 'ACTIVE',
  ChannelStatus.suspended: 'SUSPENDED',
  ChannelStatus.archived: 'ARCHIVED',
};

const _$UploadPermissionEnumMap = {
  UploadPermission.groupAdmin: 'GROUP_ADMIN',
  UploadPermission.moderator: 'MODERATOR',
  UploadPermission.member: 'MEMBER',
  UploadPermission.guest: 'GUEST',
};
