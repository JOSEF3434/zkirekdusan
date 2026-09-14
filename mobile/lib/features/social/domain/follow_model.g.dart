// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FollowStatusDto _$FollowStatusDtoFromJson(Map<String, dynamic> json) =>
    _FollowStatusDto(
      isFollowing: json['isFollowing'] as bool,
      isFollowedBy: json['isFollowedBy'] as bool,
    );

Map<String, dynamic> _$FollowStatusDtoToJson(_FollowStatusDto instance) =>
    <String, dynamic>{
      'isFollowing': instance.isFollowing,
      'isFollowedBy': instance.isFollowedBy,
    };

_FollowerDto _$FollowerDtoFromJson(Map<String, dynamic> json) => _FollowerDto(
  id: json['id'] as String,
  username: json['username'] as String?,
  displayName: json['displayName'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  isFollowing: json['isFollowing'] as bool? ?? false,
);

Map<String, dynamic> _$FollowerDtoToJson(_FollowerDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'isFollowing': instance.isFollowing,
    };
