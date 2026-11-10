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
