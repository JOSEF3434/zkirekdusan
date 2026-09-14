// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_context_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VideoChannelSummaryDto _$VideoChannelSummaryDtoFromJson(
  Map<String, dynamic> json,
) => _VideoChannelSummaryDto(
  id: json['id'] as String,
  name: json['name'] as String,
  slug: json['slug'] as String,
  handle: json['handle'] as String,
  description: json['description'] as String?,
  status: json['status'] as String,
  uploadPermission: json['uploadPermission'] as String,
  subscribersCount: (json['subscribersCount'] as num).toInt(),
  videosCount: (json['videosCount'] as num).toInt(),
);

Map<String, dynamic> _$VideoChannelSummaryDtoToJson(
  _VideoChannelSummaryDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
  'handle': instance.handle,
  'description': instance.description,
  'status': instance.status,
  'uploadPermission': instance.uploadPermission,
  'subscribersCount': instance.subscribersCount,
  'videosCount': instance.videosCount,
};

_GroupCapabilities _$GroupCapabilitiesFromJson(Map<String, dynamic> json) =>
    _GroupCapabilities(
      canViewGroup: json['canViewGroup'] as bool? ?? false,
      canUploadVideo: json['canUploadVideo'] as bool? ?? false,
      canManageVideos: json['canManageVideos'] as bool? ?? false,
      canCreatePlaylist: json['canCreatePlaylist'] as bool? ?? false,
      canManagePlaylists: json['canManagePlaylists'] as bool? ?? false,
      canViewMembers: json['canViewMembers'] as bool? ?? false,
      canManageMembers: json['canManageMembers'] as bool? ?? false,
      canEditGroup: json['canEditGroup'] as bool? ?? false,
      canUpdateGroup: json['canUpdateGroup'] as bool? ?? false,
      canDeleteGroup: json['canDeleteGroup'] as bool? ?? false,
      canManagePermissions: json['canManagePermissions'] as bool? ?? false,
      canManageChannels: json['canManageChannels'] as bool? ?? false,
      canManageSettings: json['canManageSettings'] as bool? ?? false,
      canModerateChat: json['canModerateChat'] as bool? ?? false,
      canStartLive: json['canStartLive'] as bool? ?? false,
      canApproveGroup: json['canApproveGroup'] as bool? ?? false,
      canArchiveGroup: json['canArchiveGroup'] as bool? ?? false,
    );

Map<String, dynamic> _$GroupCapabilitiesToJson(_GroupCapabilities instance) =>
    <String, dynamic>{
      'canViewGroup': instance.canViewGroup,
      'canUploadVideo': instance.canUploadVideo,
      'canManageVideos': instance.canManageVideos,
      'canCreatePlaylist': instance.canCreatePlaylist,
      'canManagePlaylists': instance.canManagePlaylists,
      'canViewMembers': instance.canViewMembers,
      'canManageMembers': instance.canManageMembers,
      'canEditGroup': instance.canEditGroup,
      'canUpdateGroup': instance.canUpdateGroup,
      'canDeleteGroup': instance.canDeleteGroup,
      'canManagePermissions': instance.canManagePermissions,
      'canManageChannels': instance.canManageChannels,
      'canManageSettings': instance.canManageSettings,
      'canModerateChat': instance.canModerateChat,
      'canStartLive': instance.canStartLive,
      'canApproveGroup': instance.canApproveGroup,
      'canArchiveGroup': instance.canArchiveGroup,
    };

_GroupContextDto _$GroupContextDtoFromJson(Map<String, dynamic> json) =>
    _GroupContextDto(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      status: $enumDecode(_$GroupStatusEnumMap, json['status']),
      visibility: $enumDecode(_$GroupVisibilityEnumMap, json['visibility']),
      membersCount: (json['membersCount'] as num).toInt(),
      avatarUrl: json['avatarUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      website: json['website'] as String?,
      country: json['country'] as String?,
      createdById: json['createdById'] as String,
      approvedById: json['approvedById'] as String?,
      approvedAt: json['approvedAt'] == null
          ? null
          : DateTime.parse(json['approvedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      callerRole: $enumDecodeNullable(_$GroupRoleEnumMap, json['callerRole']),
      capabilities: GroupCapabilities.fromJson(
        json['capabilities'] as Map<String, dynamic>,
      ),
      videoChannels: (json['videoChannels'] as List<dynamic>)
          .map(
            (e) => VideoChannelSummaryDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      defaultVideoChannelId: json['defaultVideoChannelId'] as String?,
    );

Map<String, dynamic> _$GroupContextDtoToJson(_GroupContextDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'description': instance.description,
      'status': _$GroupStatusEnumMap[instance.status]!,
      'visibility': _$GroupVisibilityEnumMap[instance.visibility]!,
      'membersCount': instance.membersCount,
      'avatarUrl': instance.avatarUrl,
      'coverUrl': instance.coverUrl,
      'website': instance.website,
      'country': instance.country,
      'createdById': instance.createdById,
      'approvedById': instance.approvedById,
      'approvedAt': instance.approvedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'callerRole': _$GroupRoleEnumMap[instance.callerRole],
      'capabilities': instance.capabilities,
      'videoChannels': instance.videoChannels,
      'defaultVideoChannelId': instance.defaultVideoChannelId,
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

const _$GroupRoleEnumMap = {
  GroupRole.groupAdmin: 'GROUP_ADMIN',
  GroupRole.moderator: 'MODERATOR',
  GroupRole.member: 'MEMBER',
  GroupRole.guest: 'GUEST',
};
