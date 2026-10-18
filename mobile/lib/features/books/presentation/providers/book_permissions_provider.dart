// lib/features/books/presentation/providers/book_permissions_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

class BookPermissions {
  final String role;
  final bool isAuthenticated;

  const BookPermissions({
    required this.role,
    required this.isAuthenticated,
  });

  bool get isSuperAdmin => isAuthenticated && role == 'SUPER_ADMIN';
  bool get isAdmin =>
      isAuthenticated && (role == 'SUPER_ADMIN' || role == 'ADMIN');
  bool get isModerator => isAuthenticated && role == 'MODERATOR';

  /// Permission to view public books
  bool get canView => true;

  /// Permission to create books (SUPER_ADMIN, ADMIN, MODERATOR)
  bool get canCreate =>
      isAuthenticated &&
      (role == 'SUPER_ADMIN' || role == 'ADMIN' || role == 'MODERATOR');

  /// Permission to update book metadata, cover, content, chapters
  bool get canUpdate =>
      isAuthenticated &&
      (role == 'SUPER_ADMIN' || role == 'ADMIN' || role == 'MODERATOR');

  /// Permission to soft-delete or permanently delete books (SUPER_ADMIN, ADMIN)
  bool get canDelete =>
      isAuthenticated && (role == 'SUPER_ADMIN' || role == 'ADMIN');

  /// Permission to publish or unpublish books
  bool get canPublish =>
      isAuthenticated &&
      (role == 'SUPER_ADMIN' || role == 'ADMIN' || role == 'MODERATOR');

  /// Permission to manage categories (hierarchical CRUD, reordering)
  bool get canManageCategories =>
      isAuthenticated && (role == 'SUPER_ADMIN' || role == 'ADMIN');

  /// Permission to access the central book management interface
  bool get canManageLibrary =>
      isAuthenticated &&
      (role == 'SUPER_ADMIN' || role == 'ADMIN' || role == 'MODERATOR');

  /// Whether the user has any book management capability
  bool get hasAnyManagementAccess =>
      canCreate ||
      canUpdate ||
      canDelete ||
      canPublish ||
      canManageCategories ||
      canManageLibrary;
}

final bookPermissionsProvider = Provider<BookPermissions>((ref) {
  final authState = ref.watch(authProvider);
  final user = authState.user;
  final isAuthenticated =
      authState.status == AuthStatus.authenticated && user != null;
  return BookPermissions(
    role: user?.role ?? 'USER',
    isAuthenticated: isAuthenticated,
  );
});
