// lib/features/auth/data/repositories/auth_repository_impl.dart
// Concrete implementation: delegates to datasource + manages token storage
// ignore_for_file: prefer_initializing_formals

import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mobile/features/auth/data/models/auth_user_model.dart';
import 'package:mobile/features/auth/domain/entities/auth_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';

/// Keys for tokens in secure storage
const _kAccessToken = 'access_token';
const _kRefreshToken = 'refresh_token';
const _kUserId = 'user_id';
const _kUserEmail = 'user_email';
const _kUserPhone = 'user_phone';
const _kUsername = 'username';
const _kUserRole = 'user_role';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;
  final StorageService _storage;

  AuthRepositoryImpl({
    required AuthRemoteDatasource remote,
    required StorageService storage,
  })  : _remote = remote,
        _storage = storage;

  @override
  Future<AuthUser> register({
    String? email,
    String? phoneNumber,
    String? username,
    String? firstName,
    String? lastName,
    required String password,
  }) async {
    final response = await _remote.register(
      email: email,
      phoneNumber: phoneNumber,
      username: username,
      firstName: firstName,
      lastName: lastName,
      password: password,
    );
    await _persistSession(response);
    return _modelToEntity(response.user);
  }

  @override
  Future<AuthUser> login({
    String? email,
    String? phoneNumber,
    String? username,
    required String password,
  }) async {
    final response = await _remote.login(
      email: email,
      phoneNumber: phoneNumber,
      username: username,
      password: password,
    );
    await _persistSession(response);
    return _modelToEntity(response.user);
  }

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } finally {
      await _clearSession();
    }
  }

  @override
  Future<void> refreshTokens() async {
    final storedRefresh = await _storage.getToken(key: _kRefreshToken);
    if (storedRefresh == null) {
      await _clearSession();
      return;
    }
    final tokens = await _remote.refreshToken(storedRefresh);
    await _storage.saveToken(tokens['accessToken']!, key: _kAccessToken);
    await _storage.saveToken(tokens['refreshToken']!, key: _kRefreshToken);
  }

  @override
  Future<AuthUser> fetchMe() async {
    final model = await _remote.me();
    // Update local cache with fresh data
    await Future.wait([
      _storage.saveToken(model.id, key: _kUserId),
      _storage.saveToken(model.role, key: _kUserRole),
      if (model.email != null) _storage.saveToken(model.email!, key: _kUserEmail),
      if (model.phoneNumber != null) _storage.saveToken(model.phoneNumber!, key: _kUserPhone),
      if (model.username != null) _storage.saveToken(model.username!, key: _kUsername),
    ]);
    return _modelToEntity(model);
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _storage.getToken(key: _kAccessToken);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<AuthUser?> getCachedUser() async {
    final id = await _storage.getToken(key: _kUserId);
    if (id == null) return null;
    final role = await _storage.getToken(key: _kUserRole) ?? 'USER';
    return AuthUser(
      id: id,
      email: await _storage.getToken(key: _kUserEmail),
      phoneNumber: await _storage.getToken(key: _kUserPhone),
      username: await _storage.getToken(key: _kUsername),
      role: role,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _persistSession(AuthResponseModel response) async {
    await Future.wait([
      _storage.saveToken(response.accessToken, key: _kAccessToken),
      if (response.refreshToken != null && response.refreshToken!.isNotEmpty)
        _storage.saveToken(response.refreshToken!, key: _kRefreshToken),
      _storage.saveToken(response.user.id, key: _kUserId),
      _storage.saveToken(response.user.role, key: _kUserRole),
      if (response.user.email != null)
        _storage.saveToken(response.user.email!, key: _kUserEmail),
      if (response.user.phoneNumber != null)
        _storage.saveToken(response.user.phoneNumber!, key: _kUserPhone),
      if (response.user.username != null)
        _storage.saveToken(response.user.username!, key: _kUsername),
    ]);
  }

  Future<void> _clearSession() async {
    await Future.wait([
      _storage.deleteToken(key: _kAccessToken),
      _storage.deleteToken(key: _kRefreshToken),
      _storage.deleteToken(key: _kUserId),
      _storage.deleteToken(key: _kUserEmail),
      _storage.deleteToken(key: _kUserPhone),
      _storage.deleteToken(key: _kUsername),
      _storage.deleteToken(key: _kUserRole),
    ]);
  }

  AuthUser _modelToEntity(AuthUserModel model) => AuthUser(
        id: model.id,
        email: model.email,
        phoneNumber: model.phoneNumber,
        username: model.username,
        role: model.role,
      );
}
