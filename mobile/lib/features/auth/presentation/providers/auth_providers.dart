// lib/features/auth/presentation/providers/auth_providers.dart
// Riverpod providers for auth feature

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/entities/auth_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';

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

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? error,
    bool? isLoading,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ── Auth Notifier ───────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      final isAuth = await _repository.isAuthenticated();
      if (isAuth) {
        // Fallback to cached user immediately for fast UI
        final cachedUser = await _repository.getCachedUser();
        state = AuthState(status: AuthStatus.authenticated, user: cachedUser);

        // Then verify with backend (silently refreshes if needed due to interceptor)
        final freshUser = await _repository.fetchMe();
        state = AuthState(status: AuthStatus.authenticated, user: freshUser);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      // If fetchMe fails (e.g. refresh failed, network error), we drop to unauthenticated.
      // Or we could stay authenticated if it's just a network error, but the interceptor
      // will clear the session if the refresh token is invalid.
      final isAuthNow = await _repository.isAuthenticated();
      if (isAuthNow) {
        final cachedUser = await _repository.getCachedUser();
        state = AuthState(status: AuthStatus.authenticated, user: cachedUser);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    }
  }

  Future<void> login({
    String? email,
    String? phoneNumber,
    String? username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.login(
        email: email,
        phoneNumber: phoneNumber,
        username: username,
        password: password,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.unauthenticated,
        error: e.toString().replaceFirst('AppException: ', ''),
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
    state = state.copyWith(isLoading: true, clearError: true);
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
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.unauthenticated,
        error: e.toString().replaceFirst('AppException: ', ''),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.logout();
    } finally {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
