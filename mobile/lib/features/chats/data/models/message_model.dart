// lib/features/chats/data/models/message_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
abstract class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String id,
    required String conversationId,
    String? channelId,
    required MessageSenderModel sender,
    String? content,
    required String type,
    String? replyToId,
    MessageReplyModel? replyTo,
    @Default(false) bool isEdited,
    @Default(false) bool isPinned,
    @Default([]) List<MessageAttachmentModel> attachments,
    @Default([]) List<MessageReactionModel> reactions,
    @Default([]) List<String> readBy,
    @Default([]) List<String> deliveredTo,
    MessageVoiceNoteModel? voiceNote,
    MessageForwardModel? forward,
    @Default([]) List<String> mentions,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);
}

@freezed
abstract class MessageSenderModel with _$MessageSenderModel {
  const factory MessageSenderModel({
    required String id,
    required String username,
    String? displayName,
    String? avatarUrl,
  }) = _MessageSenderModel;

  factory MessageSenderModel.fromJson(Map<String, dynamic> json) =>
      _$MessageSenderModelFromJson(json);
}

@freezed
abstract class MessageReplyModel with _$MessageReplyModel {
  const factory MessageReplyModel({
    required String id,
    String? content,
    required String type,
    required MessageSenderModel sender,
  }) = _MessageReplyModel;

  factory MessageReplyModel.fromJson(Map<String, dynamic> json) =>
      _$MessageReplyModelFromJson(json);
}

@freezed
abstract class MessageAttachmentModel with _$MessageAttachmentModel {
  const factory MessageAttachmentModel({
    required String fileId,
    required String url,
    required String fileType,
    required String mimeType,
    required String originalName,
    int? width,
    int? height,
    double? duration,
    int? size,
    String? thumbnailUrl,
  }) = _MessageAttachmentModel;

  factory MessageAttachmentModel.fromJson(Map<String, dynamic> json) =>
      _$MessageAttachmentModelFromJson(json);
}

@freezed
abstract class MessageReactionModel with _$MessageReactionModel {
  const factory MessageReactionModel({
    required String emoji,
    required int count,
    required List<String> userIds,
  }) = _MessageReactionModel;

  factory MessageReactionModel.fromJson(Map<String, dynamic> json) =>
      _$MessageReactionModelFromJson(json);
}

@freezed
abstract class MessageVoiceNoteModel with _$MessageVoiceNoteModel {
  const factory MessageVoiceNoteModel({
    required String fileId,
    required String url,
    required int duration,
    List<double>? waveform,
  }) = _MessageVoiceNoteModel;

  factory MessageVoiceNoteModel.fromJson(Map<String, dynamic> json) =>
      _$MessageVoiceNoteModelFromJson(json);
}

@freezed
abstract class MessageForwardModel with _$MessageForwardModel {
  const factory MessageForwardModel({
    required String originalMessageId,
    required MessageSenderModel originalSender,
    required DateTime originalCreatedAt,
  }) = _MessageForwardModel;

  factory MessageForwardModel.fromJson(Map<String, dynamic> json) =>
      _$MessageForwardModelFromJson(json);
}

@freezed
abstract class PaginatedMessagesModel with _$PaginatedMessagesModel {
  const factory PaginatedMessagesModel({
    required List<MessageModel> data,
    String? nextCursor,
    @Default(false) bool hasMore,
  }) = _PaginatedMessagesModel;

  factory PaginatedMessagesModel.fromJson(Map<String, dynamic> json) =>
      _$PaginatedMessagesModelFromJson(json);
}

// Message type constants
class MessageType {
  static const text = 'TEXT';
  static const image = 'IMAGE';
  static const video = 'VIDEO';
  static const audio = 'AUDIO';
  static const document = 'DOCUMENT';
  static const voiceNote = 'VOICE_NOTE';
  static const announcement = 'ANNOUNCEMENT';
  static const system = 'SYSTEM';
}
