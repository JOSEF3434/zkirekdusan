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

class ChatDiscoveryModel {
  final List<ConversationModel> conversations;
  final List<ChatGroupItem> publicGroups;
  final List<ChatGroupItem> myPrivateGroups;
  final List<ChatUserItem> allUsers;

  const ChatDiscoveryModel({
    this.conversations = const [],
    this.publicGroups = const [],
    this.myPrivateGroups = const [],
    this.allUsers = const [],
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
    );
  }
}

enum UnifiedChatType { conversation, user, publicGroup, privateGroup }

class UnifiedChatItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? avatarUrl;
  final UnifiedChatType type;
  final DateTime sortDate;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;
  final bool isOnline;
  final bool isVerified;
  final int? membersCount;
  final String? conversationId;
  final String? targetUserId;
  final String? targetGroupId;
  final ConversationModel? conversation;

  const UnifiedChatItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.avatarUrl,
    required this.type,
    required this.sortDate,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
    this.isOnline = false,
    this.isVerified = false,
    this.membersCount,
    this.conversationId,
    this.targetUserId,
    this.targetGroupId,
    this.conversation,
  });
}
