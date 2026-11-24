// lib/features/auth/presentation/providers/auth_providers.dart
// Riverpod providers for auth feature

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/entities/auth_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/data/services/google_sign_in_service.dart';

// ── Google Sign In Service ─────────────────────────────────────────────────

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});

// ── Datasource ─────────────────────────────────────────────────────────────

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  final dio = ref.watch(apiClientProvider);
  return AuthRemoteDatasource(dio);
});

// ── Repository ─────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteDatasourceProvider),
    storage: ref.watch(storageServiceProvider),
  );
});

// ── Auth State ─────────────────────────────────────────────────────────────

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? error;
  final bool isLoading;
  final bool isGoogleLoading;
  final String? pendingGoogleIdToken;
  final String? pendingGoogleEmail;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.isLoading = false,
    this.isGoogleLoading = false,
    this.pendingGoogleIdToken,
    this.pendingGoogleEmail,
  });

  bool get isAnyLoading => isLoading || isGoogleLoading;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? error,
    bool? isLoading,
    bool? isGoogleLoading,
    String? pendingGoogleIdToken,
    String? pendingGoogleEmail,
    bool clearError = false,
    bool clearUser = false,
    bool clearPendingGoogle = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
      isGoogleLoading: isGoogleLoading ?? this.isGoogleLoading,
      pendingGoogleIdToken: clearPendingGoogle
          ? null
          : (pendingGoogleIdToken ?? this.pendingGoogleIdToken),
      pendingGoogleEmail: clearPendingGoogle
          ? null
          : (pendingGoogleEmail ?? this.pendingGoogleEmail),
    );
  }
}

// ── Auth Notifier ───────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final GoogleSignInService _googleSignInService;

  AuthNotifier(
    this._repository, [
    GoogleSignInService? googleSignInService,
  ])  : _googleSignInService = googleSignInService ?? GoogleSignInService(),
        super(const AuthState()) {
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      // If user logged in with Remember Me = OFF, clear session on cold start.
      // We use clearSessionLocally() — NOT logout() — so we don't make a
      // network request during startup (which would fail if offline and would
      // also hang before the first frame is shown).
      final isSessionOnly =
          await _repository.getStoredFlag('session_only') == 'true';
      if (isSessionOnly) {
        await _repository.clearSessionLocally();
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      final isAuth = await _repository.isAuthenticated();
      if (isAuth) {
        // Fast restore from local cache
        final cachedUser = await _repository.getCachedUser();
        state = AuthState(status: AuthStatus.authenticated, user: cachedUser);

        // Asynchronous background revalidation
        try {
          final freshUser = await _repository.fetchMe();
          state = AuthState(status: AuthStatus.authenticated, user: freshUser);
        } catch (e) {
          // If backend check fails (e.g. offline, timeout), verify if token is still locally valid
          final isStillAuth = await _repository.isAuthenticated();
          if (!isStillAuth) {
            state = const AuthState(status: AuthStatus.unauthenticated);
          }
        }
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({
    String? email,
    String? phoneNumber,
    String? username,
    required String password,
    bool rememberMe = true,
  }) async {
    state = state.copyWith(
      isLoading: true,
      isGoogleLoading: false,
      clearError: true,
    );
    try {
      final user = await _repository.login(
        email: email,
        phoneNumber: phoneNumber,
        username: username,
        password: password,
      );
      // Save "session only" flag — cleared on cold start if rememberMe is false
      await _repository.saveFlag('session_only', rememberMe ? 'false' : 'true');
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      String errorMessage;
      if (e is AppException) {
        final raw = e.message;
        final rawLower = raw.toLowerCase();
        final isAuthFailure = e.code == '401' ||
            rawLower.contains('invalid credentials') ||
            rawLower.contains('unauthorized') ||
            rawLower.contains('authentication failed') ||
            rawLower.contains('unexpected error');

        final suppliedCount = [
          email != null && email.isNotEmpty,
          phoneNumber != null && phoneNumber.isNotEmpty,
          username != null && username.isNotEmpty,
        ].where((b) => b).length;

        if (isAuthFailure) {
          if (suppliedCount > 1) {
            errorMessage = 'Incorrect login credentials or password. Please check and try again.';
          } else if (email != null && email.isNotEmpty) {
            errorMessage = 'Incorrect email or password. Please check and try again.';
          } else if (phoneNumber != null && phoneNumber.isNotEmpty) {
            errorMessage = 'Incorrect phone number or password. Please check and try again.';
          } else if (username != null && username.isNotEmpty) {
            errorMessage = 'Incorrect username or password. Please check and try again.';
          } else {
            errorMessage = 'Incorrect login credentials or password. Please try again.';
          }
        } else {
          errorMessage = raw;
        }
      } else {
        errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('AppException: ', '');
      }

      state = state.copyWith(
        isLoading: false,
        isGoogleLoading: false,
        status: AuthStatus.unauthenticated,
        error: errorMessage,
      );
    }
  }

  Future<void> register({
    String? email,
    String? phoneNumber,
    String? username,
    String? firstName,
    String? lastName,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      isGoogleLoading: false,
      clearError: true,
    );
    try {
      final user = await _repository.register(
        email: email,
        phoneNumber: phoneNumber,
        username: username,
        firstName: firstName,
        lastName: lastName,
        password: password,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      final errorMessage = e is AppException
          ? e.message
          : e
              .toString()
              .replaceFirst('Exception: ', '')
              .replaceFirst('AppException: ', '');
      state = state.copyWith(
        isLoading: false,
        isGoogleLoading: false,
        status: AuthStatus.unauthenticated,
        error: errorMessage,
      );
    }
  }

  Future<bool> signInWithGoogle({bool rememberMe = true}) async {
    state = state.copyWith(
      isGoogleLoading: true,
      isLoading: false,
      clearError: true,
      clearPendingGoogle: true,
    );
    try {
      final idToken = await _googleSignInService.signInAndGetIdToken();
      if (idToken == null) {
        // User cancelled account picker
        state = state.copyWith(
          isGoogleLoading: false,
          status: state.status == AuthStatus.authenticated
              ? state.status
              : AuthStatus.unauthenticated,
        );
        return false;
      }

      try {
        final user = await _repository.loginWithGoogle(idToken);
        await _repository.saveFlag(
          'session_only',
          rememberMe ? 'false' : 'true',
        );
        state = AuthState(status: AuthStatus.authenticated, user: user);
        return true;
      } on AppException catch (e) {
        if (e.code == '409' || e.details == 'ACCOUNT_EXISTS_LINK_REQUIRED') {
          // Existing email/password account requires linking
          state = state.copyWith(
            isGoogleLoading: false,
            pendingGoogleIdToken: idToken,
            error: e.message,
          );
          return false;
        }
        rethrow;
      }
    } catch (e) {
      final errorMessage = e is AppException
          ? e.message
          : e
              .toString()
              .replaceFirst('Exception: ', '')
              .replaceFirst('AppException: ', '');
      state = state.copyWith(
        isLoading: false,
        isGoogleLoading: false,
        status: AuthStatus.unauthenticated,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<bool> linkGoogleAccountWithPassword(String password) async {
    final token = state.pendingGoogleIdToken;
    if (token == null) {
      state = state.copyWith(
        error: 'Google session expired. Please tap Continue with Google again.',
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      isGoogleLoading: false,
      clearError: true,
    );
    try {
      final user = await _repository.linkGoogleAccount(token, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      final errorMessage = e is AppException
          ? e.message
          : e
              .toString()
              .replaceFirst('Exception: ', '')
              .replaceFirst('AppException: ', '');
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  void clearPendingGoogle() {
    state = state.copyWith(clearPendingGoogle: true);
  }

  Future<void> logout() async {
    state = state.copyWith(
      isLoading: true,
      isGoogleLoading: false,
      clearError: true,
    );
    try {
      await _repository.logout();
      await _googleSignInService.signOut();
    } finally {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(googleSignInServiceProvider),
  );
});
