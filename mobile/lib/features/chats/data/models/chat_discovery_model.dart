// lib/features/chats/data/models/chat_discovery_model.dart

import 'package:mobile/features/chats/data/models/conversation_model.dart';

class ChatUserItem {
  final String id;
  final String? username;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final DateTime createdAt;

  const ChatUserItem({
    required this.id,
    this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.isOnline = false,
    this.lastSeenAt,
    required this.createdAt,
  });

  factory ChatUserItem.fromJson(Map<String, dynamic> json) {
    return ChatUserItem(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: (json['displayName'] ?? json['username'] ?? 'User') as String,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.tryParse(json['lastSeenAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ChatUserItem copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    bool? isOnline,
    DateTime? lastSeenAt,
    DateTime? createdAt,
  }) {
    return ChatUserItem(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ChatGroupItem {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? avatarUrl;
  final String? coverUrl;
  final String visibility; // PUBLIC / PRIVATE
  final String status;
  final int membersCount;
  final String? conversationId;
  final bool isMember;
  final DateTime createdAt;

  const ChatGroupItem({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.avatarUrl,
    this.coverUrl,
    this.visibility = 'PUBLIC',
    this.status = 'ACTIVE',
    this.membersCount = 0,
    this.conversationId,
    this.isMember = false,
    required this.createdAt,
  });

  factory ChatGroupItem.fromJson(Map<String, dynamic> json) {
    return ChatGroupItem(
      id: json['id'] as String,
      name: (json['name'] ?? 'Group') as String,
      slug: (json['slug'] ?? '') as String,
      description: json['description'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      visibility: (json['visibility'] ?? 'PUBLIC') as String,
      status: (json['status'] ?? 'ACTIVE') as String,
      membersCount: (json['membersCount'] is num) ? (json['membersCount'] as num).toInt() : 0,
      conversationId: json['conversationId'] as String?,
      isMember: json['isMember'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ChatChannelItem {
  final String id;
  final String name;
  final String handle;
  final String slug;
  final String? description;
  final String? avatarUrl;
  final String? bannerUrl;
  final int subscribersCount;
  final int videosCount;
  final bool isVerified;
  final bool isSubscribed;
  final bool isOwner;
  final String status;
  final String? latestContentTitle;
  final DateTime? latestContentAt;
  final DateTime createdAt;

  const ChatChannelItem({
    required this.id,
    required this.name,
    required this.handle,
    required this.slug,
    this.description,
    this.avatarUrl,
    this.bannerUrl,
    this.subscribersCount = 0,
    this.videosCount = 0,
    this.isVerified = false,
    this.isSubscribed = false,
    this.isOwner = false,
    this.status = 'ACTIVE',
    this.latestContentTitle,
    this.latestContentAt,
    required this.createdAt,
  });

  factory ChatChannelItem.fromJson(Map<String, dynamic> json) {
    return ChatChannelItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Channel',
      handle: json['handle'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      subscribersCount: (json['subscribersCount'] is num)
          ? (json['subscribersCount'] as num).toInt()
          : 0,
      videosCount: (json['videosCount'] is num)
          ? (json['videosCount'] as num).toInt()
          : 0,
      isVerified: json['isVerified'] as bool? ?? false,
      isSubscribed: json['isSubscribed'] as bool? ?? false,
      isOwner: json['isOwner'] as bool? ?? false,
      status: json['status'] as String? ?? 'ACTIVE',
      latestContentTitle: json['latestContentTitle'] as String?,
      latestContentAt: json['latestContentAt'] != null
          ? DateTime.tryParse(json['latestContentAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ChatDiscoveryModel {
  final List<ConversationModel> conversations;
  final List<ChatGroupItem> publicGroups;
  final List<ChatGroupItem> myPrivateGroups;
  final List<ChatUserItem> allUsers;
  final List<ChatChannelItem> channels;

  const ChatDiscoveryModel({
    this.conversations = const [],
    this.publicGroups = const [],
    this.myPrivateGroups = const [],
    this.allUsers = const [],
    this.channels = const [],
  });

  factory ChatDiscoveryModel.fromJson(Map<String, dynamic> json) {
    return ChatDiscoveryModel(
      conversations: (json['conversations'] as List<dynamic>?)
              ?.map((c) => ConversationModel.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      publicGroups: (json['publicGroups'] as List<dynamic>?)
              ?.map((g) => ChatGroupItem.fromJson(g as Map<String, dynamic>))
              .toList() ??
          [],
      myPrivateGroups: (json['myPrivateGroups'] as List<dynamic>?)
              ?.map((g) => ChatGroupItem.fromJson(g as Map<String, dynamic>))
              .toList() ??
          [],
      allUsers: (json['allUsers'] as List<dynamic>?)
              ?.map((u) => ChatUserItem.fromJson(u as Map<String, dynamic>))
              .toList() ??
          [],
      channels: (json['channels'] as List<dynamic>?)
              ?.map((ch) => ChatChannelItem.fromJson(ch as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  ChatDiscoveryModel copyWith({
    List<ConversationModel>? conversations,
    List<ChatGroupItem>? publicGroups,
    List<ChatGroupItem>? myPrivateGroups,
    List<ChatUserItem>? allUsers,
    List<ChatChannelItem>? channels,
  }) {
    return ChatDiscoveryModel(
      conversations: conversations ?? this.conversations,
      publicGroups: publicGroups ?? this.publicGroups,
      myPrivateGroups: myPrivateGroups ?? this.myPrivateGroups,
      allUsers: allUsers ?? this.allUsers,
      channels: channels ?? this.channels,
    );
  }
}

enum UnifiedChatType { conversation, user, publicGroup, privateGroup, channel }

class UnifiedChatItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? avatarUrl;
  final String? bannerUrl;
  final UnifiedChatType type;
  final DateTime sortDate;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;
  final bool isOnline;
  final bool isVerified;
  final int? membersCount;
  final int? subscribersCount;
  final int? videosCount;
  final String? handle;
  final String? status;
  final bool isSubscribed;
  final bool isOwner;
  final String? conversationId;
  final String? targetUserId;
  final String? targetGroupId;
  final String? targetChannelId;
  final ConversationModel? conversation;

  const UnifiedChatItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.avatarUrl,
    this.bannerUrl,
    required this.type,
    required this.sortDate,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
    this.isOnline = false,
    this.isVerified = false,
    this.membersCount,
    this.subscribersCount,
    this.videosCount,
    this.handle,
    this.status,
    this.isSubscribed = false,
    this.isOwner = false,
    this.conversationId,
    this.targetUserId,
    this.targetGroupId,
    this.targetChannelId,
    this.conversation,
  });
}
