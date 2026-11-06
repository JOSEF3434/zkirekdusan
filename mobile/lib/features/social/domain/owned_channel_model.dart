// lib/features/social/domain/owned_channel_model.dart

class OwnedChannelModel {
  final String id;
  final String groupId;
  final String name;
  final String slug;
  final String handle;
  final String? description;
  final String? avatarUrl;
  final String? bannerUrl;
  final int subscribersCount;
  final int videosCount;
  final bool isVerified;
  final bool isOwner;
  final String? groupName;

  const OwnedChannelModel({
    required this.id,
    required this.groupId,
    required this.name,
    required this.slug,
    required this.handle,
    this.description,
    this.avatarUrl,
    this.bannerUrl,
    this.subscribersCount = 0,
    this.videosCount = 0,
    this.isVerified = false,
    this.isOwner = false,
    this.groupName,
  });

  factory OwnedChannelModel.fromJson(Map<String, dynamic> json) {
    return OwnedChannelModel(
      id: json['id']?.toString() ?? '',
      groupId: json['groupId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      handle: json['handle']?.toString() ?? '',
      description: json['description']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      bannerUrl: json['bannerUrl']?.toString(),
      subscribersCount: (json['subscribersCount'] as num?)?.toInt() ?? 0,
      videosCount: (json['videosCount'] as num?)?.toInt() ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      isOwner: json['isOwner'] as bool? ?? false,
      groupName: json['groupName']?.toString(),
    );
  }
}
