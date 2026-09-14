// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroupMemberDto _$GroupMemberDtoFromJson(Map<String, dynamic> json) =>
    _GroupMemberDto(
      id: json['id'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      role: $enumDecode(_$GroupRoleEnumMap, json['role']),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );

Map<String, dynamic> _$GroupMemberDtoToJson(_GroupMemberDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'username': instance.username,
      'displayName': instance.displayName,
      'role': _$GroupRoleEnumMap[instance.role]!,
      'joinedAt': instance.joinedAt.toIso8601String(),
    };

const _$GroupRoleEnumMap = {
  GroupRole.groupAdmin: 'GROUP_ADMIN',
  GroupRole.moderator: 'MODERATOR',
  GroupRole.member: 'MEMBER',
  GroupRole.guest: 'GUEST',
};
