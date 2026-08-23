// lib/features/live/domain/live_stream_model.dart
// Strongly typed models mirroring the NestJS StreamResponseDto and Prisma enums.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'live_stream_model.freezed.dart';
part 'live_stream_model.g.dart';

// ---------------------------------------------------------------------------
// Enums (mirror Prisma / NestJS)
// ---------------------------------------------------------------------------

enum LiveStreamStatus {
  @JsonValue('DRAFT')
  draft,
  @JsonValue('SCHEDULED')
  scheduled,
  @JsonValue('LIVE')
  live,
  @JsonValue('ENDED')
  ended,
  @JsonValue('PROCESSING')
  processing,
  @JsonValue('VOD_READY')
  vodReady,
  @JsonValue('CANCELLED')
  cancelled,
  @JsonValue('FAILED')
  failed,
}

enum LiveStreamVisibility {
  @JsonValue('PUBLIC')
  public,
  @JsonValue('PRIVATE')
  private,
  @JsonValue('GROUP_ONLY')
  groupOnly,
  @JsonValue('UNLISTED')
  unlisted,
}

enum StreamProtocol {
  @JsonValue('RTMP')
  rtmp,
  @JsonValue('WEBRTC')
  webrtc,
  @JsonValue('HLS_PULL')
  hlsPull,
}

// ---------------------------------------------------------------------------
// Nested DTOs
// ---------------------------------------------------------------------------

@freezed
class StreamCreatorDto with _$StreamCreatorDto {
  const factory StreamCreatorDto({
    required String id,
    String? username,
    String? avatarUrl,
  }) = _StreamCreatorDto;

  factory StreamCreatorDto.fromJson(Map<String, dynamic> json) =>
      _$StreamCreatorDtoFromJson(json);
}

@freezed
class StreamChannelDto with _$StreamChannelDto {
  const factory StreamChannelDto({
    required String id,
    required String name,
    String? avatarUrl,
  }) = _StreamChannelDto;

  factory StreamChannelDto.fromJson(Map<String, dynamic> json) =>
      _$StreamChannelDtoFromJson(json);
}

@freezed
class StreamGroupDto with _$StreamGroupDto {
  const factory StreamGroupDto({required String id, required String name}) =
      _StreamGroupDto;

  factory StreamGroupDto.fromJson(Map<String, dynamic> json) =>
      _$StreamGroupDtoFromJson(json);
}

// ---------------------------------------------------------------------------
// Main DTO
// ---------------------------------------------------------------------------

@freezed
class LiveStreamDto with _$LiveStreamDto {
  const factory LiveStreamDto({
    required String id,
    required String videoChannelId,
    required String groupId,
    required String createdById,
    required String title,
    String? description,
    required String slug,
    required LiveStreamStatus status,
    required LiveStreamVisibility visibility,
    required StreamProtocol protocol,
    String? hlsUrl,
    String? dashUrl,
    String? webrtcUrl,
    String? rtmpIngestUrl,
    String? thumbnailUrl,
    @Default([]) List<String> categories,
    @Default([]) List<String> tags,
    @Default([]) List<String> hashtags,
    String? scheduledAt,
    String? startedAt,
    String? endedAt,
    @Default(true) bool isRecordingEnabled,
    @Default(true) bool isDvrEnabled,
    @Default(true) bool isReplayEnabled,
    @Default(true) bool isChatEnabled,
    @Default(false) bool isChatSlowMode,
    @Default(0) int chatSlowModeSeconds,
    @Default(false) bool isMembersOnlyChat,
    @Default(false) bool isSubscribersOnlyChat,
    @Default(0) int peakViewerCount,
    @Default(0) int currentViewerCount,
    @Default(0) int totalViewerCount,
    @Default(0) int totalChatMessages,
    @Default(0) int totalReactions,
    @Default(0) int likesCount,
    int? duration,
    required String createdAt,
    required String updatedAt,
    StreamCreatorDto? createdBy,
    StreamGroupDto? group,
    StreamChannelDto? videoChannel,
  }) = _LiveStreamDto;

  factory LiveStreamDto.fromJson(Map<String, dynamic> json) =>
      _$LiveStreamDtoFromJson(json);
}

// ---------------------------------------------------------------------------
// Stream Key DTO
// ---------------------------------------------------------------------------

@freezed
class StreamKeyDto with _$StreamKeyDto {
  const factory StreamKeyDto({
    required String channelId,
    String? keyPrefix,
    String? rtmpUrl,
    // Only present when regenerated — the full key shown once
    String? rawKey,
  }) = _StreamKeyDto;

  factory StreamKeyDto.fromJson(Map<String, dynamic> json) =>
      _$StreamKeyDtoFromJson({
        'channelId': json['channelId'] as String? ?? '',
        'keyPrefix': json['keyPrefix'] as String?,
        'rtmpUrl': json['rtmpUrl'] as String?,
        'rawKey': (json['rawKey'] ?? json['streamKey']) as String?,
      });
}

// ---------------------------------------------------------------------------
// Create / Update DTO (sent to API)
// ---------------------------------------------------------------------------

class CreateLiveStreamRequest {
  final String title;
  final String? description;
  final LiveStreamVisibility? visibility;
  final StreamProtocol? protocol;
  final String? scheduledAt;
  final List<String>? categories;
  final List<String>? tags;
  final bool? isRecordingEnabled;
  final bool? isChatEnabled;
  final bool? isChatSlowMode;
  final int? chatSlowModeSeconds;

  const CreateLiveStreamRequest({
    required this.title,
    this.description,
    this.visibility,
    this.protocol,
    this.scheduledAt,
    this.categories,
    this.tags,
    this.isRecordingEnabled,
    this.isChatEnabled,
    this.isChatSlowMode,
    this.chatSlowModeSeconds,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    if (description != null) 'description': description,
    if (visibility != null) 'visibility': visibility!.name.toUpperCase(),
    if (protocol != null) 'protocol': protocol!.name.toUpperCase(),
    if (scheduledAt != null) 'scheduledAt': scheduledAt,
    if (categories != null) 'categories': categories,
    if (tags != null) 'tags': tags,
    if (isRecordingEnabled != null) 'isRecordingEnabled': isRecordingEnabled,
    if (isChatEnabled != null) 'isChatEnabled': isChatEnabled,
    if (isChatSlowMode != null) 'isChatSlowMode': isChatSlowMode,
    if (chatSlowModeSeconds != null) 'chatSlowModeSeconds': chatSlowModeSeconds,
  };
}
