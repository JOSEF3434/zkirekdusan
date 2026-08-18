// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlaylistDtoImpl _$$PlaylistDtoImplFromJson(Map<String, dynamic> json) =>
    _$PlaylistDtoImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      privacy: json['privacy'] as String? ?? 'private',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => PlaylistItemDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$PlaylistDtoImplToJson(_$PlaylistDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'title': instance.title,
      'description': instance.description,
      'privacy': instance.privacy,
      'items': instance.items,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

_$PlaylistItemDtoImpl _$$PlaylistItemDtoImplFromJson(
  Map<String, dynamic> json,
) => _$PlaylistItemDtoImpl(
  videoId: json['videoId'] as String,
  addedAt: DateTime.parse(json['addedAt'] as String),
);

Map<String, dynamic> _$$PlaylistItemDtoImplToJson(
  _$PlaylistItemDtoImpl instance,
) => <String, dynamic>{
  'videoId': instance.videoId,
  'addedAt': instance.addedAt.toIso8601String(),
};
