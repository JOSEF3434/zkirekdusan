// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CommentAuthorDto _$CommentAuthorDtoFromJson(Map<String, dynamic> json) =>
    _CommentAuthorDto(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$CommentAuthorDtoToJson(_CommentAuthorDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
    };

_CommentResponseDto _$CommentResponseDtoFromJson(Map<String, dynamic> json) =>
    _CommentResponseDto(
      id: json['id'] as String,
      postId: json['postId'] as String,
      parentId: json['parentId'] as String?,
      content: json['content'] as String,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      author: CommentAuthorDto.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      replies:
          (json['replies'] as List<dynamic>?)
              ?.map(
                (e) => CommentResponseDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CommentResponseDtoToJson(_CommentResponseDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'postId': instance.postId,
      'parentId': instance.parentId,
      'content': instance.content,
      'likesCount': instance.likesCount,
      'author': instance.author,
      'createdAt': instance.createdAt.toIso8601String(),
      'replies': instance.replies,
    };
