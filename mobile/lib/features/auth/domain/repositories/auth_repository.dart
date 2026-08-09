// lib/features/auth/domain/repositories/auth_repository.dart
// Abstract repository contract for auth feature

import 'package:mobile/features/auth/domain/entities/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> register({
    String? email,
    String? phoneNumber,
    String? username,
    String? firstName,
    String? lastName,
    required String password,
  });

  Future<AuthUser> login({
    String? email,
    String? phoneNumber,
    String? username,
    required String password,
  });

  Future<void> logout();

  Future<void> refreshTokens();

  /// Returns true if a valid access token is stored
  Future<bool> isAuthenticated();

  /// Returns the currently cached auth user, if any
  Future<AuthUser?> getCachedUser();
}
