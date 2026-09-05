// lib/features/creator/domain/creator_permission_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/creator/domain/creator_enums.dart';
import 'package:mobile/features/creator/domain/creator_group_dto.dart';
import 'package:mobile/features/creator/domain/creator_channel_dto.dart';

final creatorPermissionServiceProvider = Provider<CreatorPermissionService>((
  ref,
) {
  final authUser = ref.watch(authProvider).user;
  return CreatorPermissionService(
    currentUserId: authUser?.id,
    currentUserRole: authUser?.role,
  );
});

class CreatorPermissionService {
  final String? currentUserId;
  final String? currentUserRole;

  CreatorPermissionService({
    required this.currentUserId,
    required this.currentUserRole,
  });

  bool get isAuthenticated => currentUserId != null;
  bool get isGlobalAdmin =>
      currentUserRole == 'ADMIN' || currentUserRole == 'SUPER_ADMIN';

  /// Returns true if the user can view the workspace.
  bool canAccessWorkspace() {
    return isAuthenticated;
  }

  /// Returns true if the user can create a new group.
  bool canCreateGroup() {
    return isAuthenticated; // Assuming any authenticated user can create a group (it goes to pending)
  }

  /// Checks if a user has permission to upload to a specific channel within a group.
  bool canUploadToChannel(CreatorGroupDto group, CreatorChannelDto channel) {
    if (!isAuthenticated) return false;

    // Admin or group creator bypass (creators own the group and are GROUP_ADMIN)
    if (isGlobalAdmin || group.createdById == currentUserId || group.createdById.isEmpty) {
      return true;
    }

    // Check channel upload permission requirements for other users
    switch (channel.uploadPermission) {
      case UploadPermission.guest:
      case UploadPermission.member:
        return true;
      case UploadPermission.moderator:
      case UploadPermission.groupAdmin:
        return false;
    }
  }

  /// Checks if a user has permission to create a channel in a group.
  bool canCreateChannel(CreatorGroupDto group) {
    if (!isAuthenticated) return false;
    if (isGlobalAdmin) return true;

    // Only the creator (or group admin) can create channels.
    // Since we only know createdById, we use that.
    return group.createdById == currentUserId;
  }

  /// Checks if a user can edit or delete a video.
  bool canManageVideo(String uploadedById) {
    if (!isAuthenticated) return false;
    if (isGlobalAdmin) return true;
    return uploadedById == currentUserId;
  }

  /// Checks if a user can moderate comments on a video.
  /// (Uploader or Admin)
  bool canModerateComments(String uploadedById) {
    return canManageVideo(uploadedById);
  }

  /// Checks if a user can view channel analytics (Moderator or Group Admin)
  bool canViewChannelAnalytics(CreatorGroupDto group) {
    if (!isAuthenticated) return false;
    if (isGlobalAdmin) return true;
    // We assume only the group creator can view analytics for now
    return group.createdById == currentUserId;
  }
}
