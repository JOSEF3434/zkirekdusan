// lib/features/auth/domain/entities/auth_user.dart
// Domain entity — decoupled from remote model

class AuthUser {
  final String id;
  final String? email;
  final String? phoneNumber;
  final String? username;
  final String role;

  const AuthUser({
    required this.id,
    this.email,
    this.phoneNumber,
    this.username,
    required this.role,
  });

  /// Display name derived from available identity fields
  String get displayIdentifier => username ?? email ?? phoneNumber ?? id;

  bool get hasUsername => username != null && username!.isNotEmpty;
}
