// lib/features/chats/data/models/conversation_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation_model.freezed.dart';
part 'conversation_model.g.dart';

@freezed
class ConversationModel with _$ConversationModel {
  const factory ConversationModel({
    required String id,
    required String type,
    String? groupId,
    String? channelId,
    String? title,
    DateTime? lastMessageAt,
    MessagePreviewModel? lastMessage,
    @Default([]) List<ConversationMemberModel> members,
    required DateTime createdAt,
    ConversationMetadataModel? metadata,
  }) = _ConversationModel;

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);
}

@freezed
class ConversationMemberModel with _$ConversationMemberModel {
  const factory ConversationMemberModel({
    required String userId,
    required String username,
    String? displayName,
    String? avatarUrl,
    @Default(0) int unreadCount,
    @Default(false) bool isMuted,
    @Default(false) bool isPinned,
    @Default(false) bool isOnline,
    String? lastSeen,
    TypingStatusModel? typingStatus,
  }) = _ConversationMemberModel;

  factory ConversationMemberModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationMemberModelFromJson(json);
}

@freezed
class MessagePreviewModel with _$MessagePreviewModel {
  const factory MessagePreviewModel({
    required String id,
    String? content,
    required String type,
    String? senderName,
    bool? isMe,
    String? attachmentPreview,
  }) = _MessagePreviewModel;

  factory MessagePreviewModel.fromJson(Map<String, dynamic> json) =>
      _$MessagePreviewModelFromJson(json);
}

@freezed
class ConversationMetadataModel with _$ConversationMetadataModel {
  const factory ConversationMetadataModel({
    String? groupName,
    String? groupAvatar,
    int? memberCount,
    bool? isVerified,
    String? channelName,
    String? description,
  }) = _ConversationMetadataModel;

  factory ConversationMetadataModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationMetadataModelFromJson(json);
}

@freezed
class TypingStatusModel with _$TypingStatusModel {
  const factory TypingStatusModel({
    required bool isTyping,
    DateTime? startedAt,
  }) = _TypingStatusModel;

  factory TypingStatusModel.fromJson(Map<String, dynamic> json) =>
      _$TypingStatusModelFromJson(json);
}

// Conversation type constants
class ConversationType {
  static const direct = 'DIRECT';
  static const groupChannel = 'GROUP_CHANNEL';
  static const groupDirect = 'GROUP_DIRECT';
}
