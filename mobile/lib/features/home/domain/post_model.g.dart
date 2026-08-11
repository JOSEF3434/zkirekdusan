// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostAuthorDtoImpl _$$PostAuthorDtoImplFromJson(Map<String, dynamic> json) =>
    _$PostAuthorDtoImpl(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$$PostAuthorDtoImplToJson(_$PostAuthorDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
    };

_$PostMediaItemDtoImpl _$$PostMediaItemDtoImplFromJson(
  Map<String, dynamic> json,
) => _$PostMediaItemDtoImpl(
  id: json['id'] as String,
  url: json['url'] as String,
  fileType: json['fileType'] as String,
  order: (json['order'] as num).toInt(),
);

Map<String, dynamic> _$$PostMediaItemDtoImplToJson(
  _$PostMediaItemDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'url': instance.url,
  'fileType': instance.fileType,
  'order': instance.order,
};

_$PostResponseDtoImpl _$$PostResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$PostResponseDtoImpl(
  id: json['id'] as String,
  type: json['type'] as String,
  visibility: json['visibility'] as String,
  content: json['content'] as String?,
  hashtags: (json['hashtags'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  likesCount: (json['likesCount'] as num).toInt(),
  commentsCount: (json['commentsCount'] as num).toInt(),
  viewsCount: (json['viewsCount'] as num).toInt(),
  author: PostAuthorDto.fromJson(json['author'] as Map<String, dynamic>),
  groupId: json['groupId'] as String?,
  media: (json['media'] as List<dynamic>)
      .map((e) => PostMediaItemDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  isLiked: json['isLiked'] as bool?,
  isSaved: json['isSaved'] as bool?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$PostResponseDtoImplToJson(
  _$PostResponseDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'visibility': instance.visibility,
  'content': instance.content,
  'hashtags': instance.hashtags,
  'likesCount': instance.likesCount,
  'commentsCount': instance.commentsCount,
  'viewsCount': instance.viewsCount,
  'author': instance.author,
  'groupId': instance.groupId,
  'media': instance.media,
  'isLiked': instance.isLiked,
  'isSaved': instance.isSaved,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
