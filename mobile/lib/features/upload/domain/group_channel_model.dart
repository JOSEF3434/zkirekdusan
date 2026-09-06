// lib/features/upload/domain/group_channel_model.dart

class VideoChannelDto {
  final String id;
  final String groupId;
  final String name;
  final String? description;
  final String? coverUrl;
  final String? avatarUrl;
  final String? handle;
  final String type;
  final String uploadPermission;

  const VideoChannelDto({
    required this.id,
    required this.groupId,
    required this.name,
    this.description,
    this.coverUrl,
    this.avatarUrl,
    this.handle,
    required this.type,
    required this.uploadPermission,
  });

  factory VideoChannelDto.fromJson(Map<String, dynamic> json) {
    return VideoChannelDto(
      id: json['id'] as String? ?? '',
      groupId: json['groupId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      coverUrl: json['coverUrl'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      handle: json['handle'] as String?,
      type: json['type'] as String? ?? '',
      uploadPermission: json['uploadPermission'] as String? ?? '',
    );
  }
}

class GroupDto {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String? coverUrl;
  final String status;

  const GroupDto({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.coverUrl,
    this.status = 'ACTIVE',
  });

  factory GroupDto.fromJson(Map<String, dynamic> json) {
    return GroupDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }
}
