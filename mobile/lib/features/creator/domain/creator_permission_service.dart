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

    // Admin bypass
    if (isGlobalAdmin) return true;

    // Check channel upload permission requirements
    switch (channel.uploadPermission) {
      case UploadPermission.guest:
      case UploadPermission.member:
        // Because the API returns active groups, and we assume the user is a member
        // (or it's public enough for members/guests), we allow it.
        // True validation happens on the backend.
        return true;
      case UploadPermission.moderator:
      case UploadPermission.groupAdmin:
        // We do not have a way to check if a user is a group admin/moderator via the API
        // in this context, except checking if they created the group.
        if (group.createdById == currentUserId) return true;
        // Otherwise, we must be conservative on the frontend to prevent failing requests,
        // or optimistic and let the backend reject. We'll be conservative.
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
