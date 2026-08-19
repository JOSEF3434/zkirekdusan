// lib/features/groups/domain/group_context_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/features/creator/domain/creator_enums.dart';
import 'package:mobile/features/groups/domain/group_enums.dart';

part 'group_context_dto.freezed.dart';
part 'group_context_dto.g.dart';

// ---------------------------------------------------------------------------
// Video channel summary (lightweight, for channel picker and header)
// ---------------------------------------------------------------------------

@freezed
class VideoChannelSummaryDto with _$VideoChannelSummaryDto {
  const factory VideoChannelSummaryDto({
    required String id,
    required String name,
    required String slug,
    required String handle,
    String? description,
    required String status,
    /// Backend GroupRole string, controls who may upload
    required String uploadPermission,
    required int subscribersCount,
    required int videosCount,
  }) = _VideoChannelSummaryDto;

  factory VideoChannelSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$VideoChannelSummaryDtoFromJson(json);
}

// ---------------------------------------------------------------------------
// Caller-specific capability summary — display hints only.
// Every capability is re-enforced server-side.
// ---------------------------------------------------------------------------

@freezed
class GroupCapabilities with _$GroupCapabilities {
  const factory GroupCapabilities({
    @Default(false) bool canViewGroup,
    @Default(false) bool canUploadVideo,
    @Default(false) bool canManageVideos,
    @Default(false) bool canCreatePlaylist,
    @Default(false) bool canManagePlaylists,
    @Default(false) bool canViewMembers,
    @Default(false) bool canManageMembers,
    @Default(false) bool canEditGroup,
    @Default(false) bool canUpdateGroup,
    @Default(false) bool canDeleteGroup,
    @Default(false) bool canManagePermissions,
    @Default(false) bool canManageChannels,
    @Default(false) bool canManageSettings,
    @Default(false) bool canModerateChat,
    @Default(false) bool canStartLive,
    @Default(false) bool canApproveGroup,
    @Default(false) bool canArchiveGroup,
  }) = _GroupCapabilities;

  factory GroupCapabilities.fromJson(Map<String, dynamic> json) =>
      _$GroupCapabilitiesFromJson(json);

  /// All-denied capabilities (unauthenticated / non-member).
  factory GroupCapabilities.none() => const GroupCapabilities();
}

// ---------------------------------------------------------------------------
// Full group context returned by GET /groups/:id/context
// ---------------------------------------------------------------------------

@freezed
class GroupContextDto with _$GroupContextDto {
  const factory GroupContextDto({
    // Group identity
    required String id,
    required String name,
    required String slug,
    String? description,
    required GroupStatus status,
    required GroupVisibility visibility,
    required int membersCount,
    String? avatarUrl,
    String? coverUrl,
    String? website,
    String? country,
    required String createdById,
    String? approvedById,
    DateTime? approvedAt,
    required DateTime createdAt,

    // Caller membership info
    /// null = not a member or unauthenticated
    GroupRole? callerRole,
    required GroupCapabilities capabilities,

    // Video channels
    required List<VideoChannelSummaryDto> videoChannels,

    /// Deterministically resolved primary channel ID.
    /// null means the group has no active video channels.
    String? defaultVideoChannelId,
  }) = _GroupContextDto;

  factory GroupContextDto.fromJson(Map<String, dynamic> json) =>
      _$GroupContextDtoFromJson(json);
}

extension GroupContextX on GroupContextDto {
  bool get hasVideoChannels => videoChannels.isNotEmpty;
  bool get hasActiveChannel => defaultVideoChannelId != null;

  VideoChannelSummaryDto? get primaryChannel => defaultVideoChannelId == null
      ? null
      : videoChannels.firstWhere(
          (c) => c.id == defaultVideoChannelId,
          orElse: () => videoChannels.first,
        );
}
