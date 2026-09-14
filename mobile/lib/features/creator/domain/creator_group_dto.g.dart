// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creator_group_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreatorGroupDto _$CreatorGroupDtoFromJson(Map<String, dynamic> json) =>
    _CreatorGroupDto(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      status: $enumDecode(_$GroupStatusEnumMap, json['status']),
      visibility: $enumDecode(_$GroupVisibilityEnumMap, json['visibility']),
      createdById: json['createdById'] as String,
      approvedById: json['approvedById'] as String?,
      approvedAt: json['approvedAt'] == null
          ? null
          : DateTime.parse(json['approvedAt'] as String),
      membersCount: (json['membersCount'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      avatarUrl: json['avatarUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
    );

Map<String, dynamic> _$CreatorGroupDtoToJson(_CreatorGroupDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'description': instance.description,
      'status': _$GroupStatusEnumMap[instance.status]!,
      'visibility': _$GroupVisibilityEnumMap[instance.visibility]!,
      'createdById': instance.createdById,
      'approvedById': instance.approvedById,
      'approvedAt': instance.approvedAt?.toIso8601String(),
      'membersCount': instance.membersCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'avatarUrl': instance.avatarUrl,
      'coverUrl': instance.coverUrl,
    };

const _$GroupStatusEnumMap = {
  GroupStatus.pendingApproval: 'PENDING_APPROVAL',
  GroupStatus.active: 'ACTIVE',
  GroupStatus.suspended: 'SUSPENDED',
  GroupStatus.archived: 'ARCHIVED',
  GroupStatus.rejected: 'REJECTED',
};

const _$GroupVisibilityEnumMap = {
  GroupVisibility.public: 'PUBLIC',
  GroupVisibility.private: 'PRIVATE',
  GroupVisibility.inviteOnly: 'INVITE_ONLY',
};
