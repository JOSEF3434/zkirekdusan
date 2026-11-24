// lib/features/auth/domain/repositories/auth_repository.dart
// Abstract repository contract for auth feature

import 'package:mobile/features/auth/domain/entities/auth_user.dart';
import 'package:mobile/features/auth/data/models/login_policy_model.dart';

abstract class AuthRepository {
  Future<LoginPolicyConfig> getLoginPolicyConfig();
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

  /// Authenticates with Google OpenID Connect ID token
  Future<AuthUser> loginWithGoogle(String idToken);

  /// Links Google identity to an existing account using account credentials
  Future<AuthUser> linkGoogleAccount(String idToken, String password);

  /// Fetches external authentication identities and password status
  Future<Map<String, dynamic>> getIdentities();

  /// Connects Google identity to the currently authenticated account
  Future<void> connectGoogle(String idToken);

  /// Disconnects Google identity from current account
  Future<void> disconnectGoogle();

  Future<void> logout();

  Future<void> refreshTokens();

  /// Fetches the current user from the backend
  Future<AuthUser> fetchMe();

  /// Returns true if a valid access token is stored
  Future<bool> isAuthenticated();

  /// Returns the currently cached auth user, if any
  Future<AuthUser?> getCachedUser();

  /// Save an arbitrary flag to persistent storage (e.g. 'session_only').
  Future<void> saveFlag(String key, String value);

  /// Read a flag previously saved with [saveFlag]. Returns null if not set.
  Future<String?> getStoredFlag(String key);

  /// Clears all session tokens locally WITHOUT making a network request.
  ///
  /// Used on cold-start when Remember Me is OFF — avoids a blocking/failing
  /// network logout call during app initialisation.
  Future<void> clearSessionLocally();

  // ── Password Recovery Methods ──────────────────────────────────────────────

  Future<Map<String, dynamic>> requestPasswordRecovery({
    String? method,
    String? identifier,
    String? email,
    String? phoneNumber,
  }) async {
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>> verifyRecoveryCode({
    required String method,
    required String destination,
    String? code,
    String? token,
  }) async {
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>> validateRecoveryToken(String token) async {
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>> resendRecoveryCode({
    required String method,
    required String identifier,
  }) async {
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>> resetPassword({
    String? method,
    String? destination,
    String? code,
    String? token,
    String? resetToken,
    required String password,
  }) async {
    throw UnimplementedError();
  }
}
