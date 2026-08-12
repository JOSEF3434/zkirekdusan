// lib/features/profile/data/models/profile_model.dart
// Matches backend ProfileResponseDto + ProfileStatsDto

class ProfileStatsModel {
  final int followersCount;
  final int followingCount;
  final int groupsCount;
  final int postsCount;
  final int reelsCount;
  final int videosCount;

  const ProfileStatsModel({
    required this.followersCount,
    required this.followingCount,
    required this.groupsCount,
    required this.postsCount,
    required this.reelsCount,
    required this.videosCount,
  });

  factory ProfileStatsModel.fromJson(Map<String, dynamic> json) {
    return ProfileStatsModel(
      followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      groupsCount: (json['groupsCount'] as num?)?.toInt() ?? 0,
      postsCount: (json['postsCount'] as num?)?.toInt() ?? 0,
      reelsCount: (json['reelsCount'] as num?)?.toInt() ?? 0,
      videosCount: (json['videosCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProfileModel {
  final String id;
  final String userId;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? bio;
  final String? website;
  final String? country;
  final String visibility;
  final bool isVerified;
  final String? avatarUrl;
  final String? coverUrl;
  final ProfileStatsModel stats;
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    required this.userId,
    this.username,
    this.firstName,
    this.lastName,
    this.displayName,
    this.bio,
    this.website,
    this.country,
    required this.visibility,
    required this.isVerified,
    this.avatarUrl,
    this.coverUrl,
    required this.stats,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      displayName: json['displayName'] as String?,
      bio: json['bio'] as String?,
      website: json['website'] as String?,
      country: json['country'] as String?,
      visibility: json['visibility'] as String? ?? 'PUBLIC',
      isVerified: json['isVerified'] as bool? ?? false,
      avatarUrl: json['avatarUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      stats: ProfileStatsModel.fromJson(
        json['stats'] as Map<String, dynamic>? ?? {},
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
