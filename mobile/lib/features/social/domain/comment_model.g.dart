// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommentAuthorDtoImpl _$$CommentAuthorDtoImplFromJson(
  Map<String, dynamic> json,
) => _$CommentAuthorDtoImpl(
  id: json['id'] as String,
  username: json['username'] as String?,
  displayName: json['displayName'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
);

Map<String, dynamic> _$$CommentAuthorDtoImplToJson(
  _$CommentAuthorDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'displayName': instance.displayName,
  'avatarUrl': instance.avatarUrl,
};

_$CommentResponseDtoImpl _$$CommentResponseDtoImplFromJson(
  Map<String, dynamic> json,
) => _$CommentResponseDtoImpl(
  id: json['id'] as String,
  postId: json['postId'] as String,
  parentId: json['parentId'] as String?,
  content: json['content'] as String,
  likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
  author: CommentAuthorDto.fromJson(json['author'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
  replies:
      (json['replies'] as List<dynamic>?)
          ?.map((e) => CommentResponseDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$CommentResponseDtoImplToJson(
  _$CommentResponseDtoImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'postId': instance.postId,
  'parentId': instance.parentId,
  'content': instance.content,
  'likesCount': instance.likesCount,
  'author': instance.author,
  'createdAt': instance.createdAt.toIso8601String(),
  'replies': instance.replies,
};
