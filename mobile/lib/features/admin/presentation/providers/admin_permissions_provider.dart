// lib/features/admin/presentation/providers/admin_permissions_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

/// Representation of the active admin's access rights.
class AdminPermissions {
  final String role;
  final bool isAuthenticated;

  const AdminPermissions({
    required this.role,
    required this.isAuthenticated,
  });

  bool get isSuperAdmin => isAuthenticated && role == 'SUPER_ADMIN';
  bool get isAdmin => isAuthenticated && (role == 'SUPER_ADMIN' || role == 'ADMIN');
  bool get isModerator => isAuthenticated && role == 'MODERATOR';
  bool get isSupport => isAuthenticated && role == 'SUPPORT';

  /// True if user has any administrative or operational role
  bool get hasAdminAccess =>
      isAuthenticated &&
      (role == 'SUPER_ADMIN' ||
          role == 'ADMIN' ||
          role == 'MODERATOR' ||
          role == 'SUPPORT');

  bool get canManageUsers =>
      isAuthenticated &&
      (role == 'SUPER_ADMIN' || role == 'ADMIN' || role == 'SUPPORT');

  bool get canManageRoles => isAuthenticated && (role == 'SUPER_ADMIN' || role == 'ADMIN');

  bool get canManageGroups =>
      isAuthenticated &&
      (role == 'SUPER_ADMIN' || role == 'ADMIN' || role == 'MODERATOR');

  bool get canManageChannels =>
      isAuthenticated &&
      (role == 'SUPER_ADMIN' || role == 'ADMIN' || role == 'MODERATOR');

  bool get canManageContent =>
      isAuthenticated &&
      (role == 'SUPER_ADMIN' || role == 'ADMIN' || role == 'MODERATOR');

  bool get canManageReports =>
      isAuthenticated &&
      (role == 'SUPER_ADMIN' || role == 'ADMIN' || role == 'MODERATOR');

  bool get canManageLive =>
      isAuthenticated &&
      (role == 'SUPER_ADMIN' || role == 'ADMIN' || role == 'MODERATOR');

  bool get canManageChat =>
      isAuthenticated &&
      (role == 'SUPER_ADMIN' || role == 'ADMIN' || role == 'MODERATOR');

  bool get canManageStorage =>
      isAuthenticated && (role == 'SUPER_ADMIN' || role == 'ADMIN');

  bool get canManageNotifications =>
      isAuthenticated && (role == 'SUPER_ADMIN' || role == 'ADMIN');

  bool get canViewAudit =>
      isAuthenticated && (role == 'SUPER_ADMIN' || role == 'ADMIN');

  bool get canManageSystem => isAuthenticated && role == 'SUPER_ADMIN';

  bool hasPermission(String requiredResource) {
    if (isSuperAdmin) return true;
    switch (requiredResource) {
      case 'users':
        return canManageUsers;
      case 'roles':
        return canManageRoles;
      case 'groups':
        return canManageGroups;
      case 'channels':
        return canManageChannels;
      case 'content':
        return canManageContent;
      case 'reports':
        return canManageReports;
      case 'live':
        return canManageLive;
      case 'chat':
        return canManageChat;
      case 'storage':
        return canManageStorage;
      case 'notifications':
        return canManageNotifications;
      case 'audit':
        return canViewAudit;
      case 'system':
        return canManageSystem;
      default:
        return hasAdminAccess;
    }
  }
}

final adminPermissionsProvider = Provider<AdminPermissions>((ref) {
  final authState = ref.watch(authProvider);
  final user = authState.user;
  final isAuthenticated = authState.status == AuthStatus.authenticated && user != null;
  return AdminPermissions(
    role: user?.role ?? 'USER',
    isAuthenticated: isAuthenticated,
  );
});
