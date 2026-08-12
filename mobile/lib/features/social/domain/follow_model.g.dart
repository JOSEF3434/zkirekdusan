// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FollowStatusDtoImpl _$$FollowStatusDtoImplFromJson(
  Map<String, dynamic> json,
) => _$FollowStatusDtoImpl(
  isFollowing: json['isFollowing'] as bool,
  isFollowedBy: json['isFollowedBy'] as bool,
);

Map<String, dynamic> _$$FollowStatusDtoImplToJson(
  _$FollowStatusDtoImpl instance,
) => <String, dynamic>{
  'isFollowing': instance.isFollowing,
  'isFollowedBy': instance.isFollowedBy,
};

_$FollowerDtoImpl _$$FollowerDtoImplFromJson(Map<String, dynamic> json) =>
    _$FollowerDtoImpl(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isFollowing: json['isFollowing'] as bool? ?? false,
    );

Map<String, dynamic> _$$FollowerDtoImplToJson(_$FollowerDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'isFollowing': instance.isFollowing,
    };
