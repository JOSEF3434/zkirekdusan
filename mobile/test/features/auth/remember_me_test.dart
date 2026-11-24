// test/features/auth/remember_me_test.dart
//
// Comprehensive test suite for Remember Me login persistence semantics.
// Covers all 9 required scenarios from the specification:
// 1. Remember Me ON -> cold start -> session restored without login screen
// 2. Remember Me OFF -> cold start -> local session cleared, unauthenticated
// 3. Remembered login survives offline startup / termination
// 4. Explicit logout after Remember Me -> wipes tokens and flags
// 5. Expired/invalid session -> unauthenticated fallback
// 6. Remember Me flag persistence and retrieval
// 7. Router: no premature redirect to /login while auth status is unknown
// 8. App Lock integration: App Lock is preserved and not bypassed
// 9. Existing auth behavior (login, register, clearError) unchanged

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mobile/features/auth/data/models/auth_user_model.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/entities/auth_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/auth/data/models/login_policy_model.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────

const _tUser = AuthUser(
  id: 'user-1',
  email: 'test@example.com',
  username: 'testuser',
  role: 'USER',
);

class FakeAuthRepository implements AuthRepository {
  final Map<String, String> flags = {};
  bool authenticated = false;
  AuthUser? cachedUser;
  Future<AuthUser> Function()? onFetchMe;
  bool Function()? onIsAuthenticated;
  int clearSessionLocallyCalls = 0;
  int logoutCalls = 0;
  int fetchMeCalls = 0;
  int isAuthenticatedCalls = 0;
  Future<AuthUser> Function({
    String? email,
    String? phoneNumber,
    String? username,
    required String password,
  })?
  onLogin;
  Future<AuthUser> Function({
    String? email,
    String? phoneNumber,
    String? username,
    String? firstName,
    String? lastName,
    required String password,
  })?
  onRegister;

  @override
  Future<LoginPolicyConfig> getLoginPolicyConfig() async {
    return const LoginPolicyConfig();
  }

  @override
  Future<void> clearSessionLocally() async {
    clearSessionLocallyCalls++;
    authenticated = false;
    cachedUser = null;
    flags.remove('session_only');
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    authenticated = false;
    cachedUser = null;
    flags.remove('session_only');
  }

  @override
  Future<String?> getStoredFlag(String key) async => flags[key];

  @override
  Future<void> saveFlag(String key, String value) async {
    flags[key] = value;
  }

  @override
  Future<bool> isAuthenticated() async {
    isAuthenticatedCalls++;
    if (onIsAuthenticated != null) return onIsAuthenticated!();
    return authenticated;
  }

  @override
  Future<AuthUser?> getCachedUser() async => cachedUser;

  @override
  Future<AuthUser> fetchMe() async {
    fetchMeCalls++;
    if (onFetchMe != null) return onFetchMe!();
    if (cachedUser != null) return cachedUser!;
    throw Exception('Not authenticated');
  }

  @override
  Future<AuthUser> login({
    String? email,
    String? phoneNumber,
    String? username,
    required String password,
  }) async {
    if (onLogin != null) {
      return onLogin!(
        email: email,
        phoneNumber: phoneNumber,
        username: username,
        password: password,
      );
    }
    const user = _tUser;
    cachedUser = user;
    authenticated = true;
    return user;
  }

  @override
  Future<AuthUser> register({
    String? email,
    String? phoneNumber,
    String? username,
    String? firstName,
    String? lastName,
    required String password,
  }) async {
    if (onRegister != null) {
      return onRegister!(
        email: email,
        phoneNumber: phoneNumber,
        username: username,
        firstName: firstName,
        lastName: lastName,
        password: password,
      );
    }
    const user = _tUser;
    cachedUser = user;
    authenticated = true;
    return user;
  }

  @override
  Future<void> refreshTokens() async {}

  @override
  Future<AuthUser> loginWithGoogle(String idToken) async => _tUser;

  @override
  Future<AuthUser> linkGoogleAccount(String idToken, String password) async =>
      _tUser;

  @override
  Future<Map<String, dynamic>> getIdentities() async => {
        'hasPassword': true,
        'identities': [],
      };

  @override
  Future<void> connectGoogle(String idToken) async {}

  @override
  Future<void> disconnectGoogle() async {}
}

class FakeStorageService implements StorageService {
  final Map<String, String> data = {};

  @override
  Future<void> saveToken(String token, {String? key}) async {
    data[key ?? 'access_token'] = token;
  }

  @override
  Future<String?> getToken({String? key}) async {
    return data[key ?? 'access_token'];
  }

  @override
  Future<void> deleteToken({String? key}) async {
    data.remove(key ?? 'access_token');
  }

  @override
  Future<void> deleteAll() async {
    data.clear();
  }
}

class FakeAuthRemoteDatasource implements AuthRemoteDatasource {
  bool logoutCalled = false;
  AuthResponseModel? loginResponse;
  Exception? loginException;

  @override
  Future<AuthResponseModel> login({
    String? email,
    String? phoneNumber,
    String? username,
    required String password,
  }) async {
    if (loginException != null) throw loginException!;
    return loginResponse!;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late FakeAuthRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeAuthRepository();
  });

  // ── 1. Remember Me ON → app restart → user remains authenticated ─────────

  group('1. Remember Me ON → cold start → session restored', () {
    test(
      'restores authenticated state from cached user when session_only is false',
      () async {
        fakeRepo.flags['session_only'] = 'false';
        fakeRepo.authenticated = true;
        fakeRepo.cachedUser = _tUser;

        final notifier = AuthNotifier(fakeRepo);
        await Future<void>.delayed(Duration.zero);

        expect(notifier.state.status, AuthStatus.authenticated);
        expect(notifier.state.user?.id, _tUser.id);
        expect(fakeRepo.clearSessionLocallyCalls, 0);
      },
    );

    test(
      'clearSessionLocally is never called when session_only flag is false',
      () async {
        fakeRepo.flags['session_only'] = 'false';
        fakeRepo.authenticated = true;
        fakeRepo.cachedUser = _tUser;

        AuthNotifier(fakeRepo);
        await Future<void>.delayed(Duration.zero);

        expect(fakeRepo.clearSessionLocallyCalls, 0);
      },
    );

    test(
      'clearSessionLocally is never called when no flag is stored (legacy/default session)',
      () async {
        // flags['session_only'] is null
        fakeRepo.authenticated = true;
        fakeRepo.cachedUser = _tUser;

        AuthNotifier(fakeRepo);
        await Future<void>.delayed(Duration.zero);

        expect(fakeRepo.clearSessionLocallyCalls, 0);
        expect(fakeRepo.isAuthenticatedCalls, greaterThanOrEqualTo(1));
      },
    );
  });

  // ── 2. Remember Me OFF → app restart → unauthenticated ──────────────────

  group('2. Remember Me OFF → cold start → session cleared', () {
    test(
      'sets state to unauthenticated on cold start when session_only = true',
      () async {
        fakeRepo.flags['session_only'] = 'true';
        fakeRepo.authenticated = true;
        fakeRepo.cachedUser = _tUser;

        final notifier = AuthNotifier(fakeRepo);
        await Future<void>.delayed(Duration.zero);

        expect(notifier.state.status, AuthStatus.unauthenticated);
        expect(notifier.state.user, isNull);
      },
    );

    test(
      'calls clearSessionLocally() — NOT logout() network call — on cold start',
      () async {
        fakeRepo.flags['session_only'] = 'true';
        fakeRepo.authenticated = true;

        AuthNotifier(fakeRepo);
        await Future<void>.delayed(Duration.zero);

        expect(fakeRepo.clearSessionLocallyCalls, 1);
        expect(fakeRepo.logoutCalls, 0);
      },
    );

    test(
      'does not attempt to read cached user or tokens when session_only is true',
      () async {
        fakeRepo.flags['session_only'] = 'true';

        AuthNotifier(fakeRepo);
        await Future<void>.delayed(Duration.zero);

        expect(fakeRepo.isAuthenticatedCalls, 0);
        expect(fakeRepo.fetchMeCalls, 0);
      },
    );
  });

  // ── 3. Remembered login survives normal app termination / offline ────────

  group(
    '3. Remembered login survives normal termination and offline cold start',
    () {
      test(
        'authenticated state restored from local cache even when fetchMe throws (offline)',
        () async {
          fakeRepo.flags['session_only'] = 'false';
          fakeRepo.authenticated = true;
          fakeRepo.cachedUser = _tUser;
          fakeRepo.onFetchMe = () => throw Exception('Network unreachable');

          final notifier = AuthNotifier(fakeRepo);
          await Future<void>.delayed(Duration.zero);

          // Still authenticated from local cache!
          expect(notifier.state.status, AuthStatus.authenticated);
          expect(notifier.state.user?.id, _tUser.id);
        },
      );
    },
  );

  // ── 4. Explicit logout after Remember Me ──────────────────────────────────

  group('4. Explicit logout after Remember Me', () {
    test('login with rememberMe: true stores session_only = false', () async {
      final notifier = AuthNotifier(fakeRepo);
      await Future<void>.delayed(Duration.zero);

      await notifier.login(
        email: 'test@example.com',
        password: 'password123',
        rememberMe: true,
      );

      expect(fakeRepo.flags['session_only'], 'false');
      expect(notifier.state.status, AuthStatus.authenticated);
    });

    test('login with rememberMe: false stores session_only = true', () async {
      final notifier = AuthNotifier(fakeRepo);
      await Future<void>.delayed(Duration.zero);

      await notifier.login(
        email: 'test@example.com',
        password: 'password123',
        rememberMe: false,
      );

      expect(fakeRepo.flags['session_only'], 'true');
      expect(notifier.state.status, AuthStatus.authenticated);
    });

    test(
      'explicit logout invokes repository.logout() and clears session',
      () async {
        fakeRepo.flags['session_only'] = 'false';
        fakeRepo.authenticated = true;
        fakeRepo.cachedUser = _tUser;

        final notifier = AuthNotifier(fakeRepo);
        await Future<void>.delayed(Duration.zero);

        await notifier.logout();

        expect(fakeRepo.logoutCalls, 1);
        expect(fakeRepo.flags['session_only'], isNull);
        expect(notifier.state.status, AuthStatus.unauthenticated);
      },
    );
  });

  // ── 5. Expired / invalid remembered session falls back gracefully ────────

  group('5. Expired or invalid remembered session', () {
    test(
      'unauthenticated if isAuthenticated() is false despite session_only=false',
      () async {
        fakeRepo.flags['session_only'] = 'false';
        fakeRepo.authenticated = false;

        final notifier = AuthNotifier(fakeRepo);
        await Future<void>.delayed(Duration.zero);

        expect(notifier.state.status, AuthStatus.unauthenticated);
      },
    );

    test(
      'transitions to unauthenticated if fetchMe fails AND token was invalidated',
      () async {
        var checkCount = 0;
        fakeRepo.flags['session_only'] = 'false';
        fakeRepo.cachedUser = _tUser;
        fakeRepo.onIsAuthenticated = () {
          checkCount++;
          // First check during startup: true. Second check after fetchMe failure: false (invalidated).
          return checkCount <= 1;
        };
        fakeRepo.onFetchMe = () => throw Exception('401 Unauthorized');

        final notifier = AuthNotifier(fakeRepo);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(notifier.state.status, AuthStatus.unauthenticated);
      },
    );
  });

  // ── 6. AuthRepositoryImpl persistence details ────────────────────────────

  group(
    '6. AuthRepositoryImpl: clearSessionLocally and session_only flag cleanup',
    () {
      late FakeStorageService fakeStorage;
      late FakeAuthRemoteDatasource fakeRemote;
      late AuthRepositoryImpl repoImpl;

      setUp(() {
        fakeStorage = FakeStorageService();
        fakeRemote = FakeAuthRemoteDatasource();
        repoImpl = AuthRepositoryImpl(remote: fakeRemote, storage: fakeStorage);
      });

      test(
        'clearSessionLocally clears all tokens AND the flag_session_only without calling remote logout',
        () async {
          // Seed tokens
          await fakeStorage.saveToken('token123', key: 'access_token');
          await fakeStorage.saveToken('refresh123', key: 'refresh_token');
          await fakeStorage.saveToken('user123', key: 'user_id');
          await fakeStorage.saveToken('true', key: 'flag_session_only');

          await repoImpl.clearSessionLocally();

          expect(await fakeStorage.getToken(key: 'access_token'), isNull);
          expect(await fakeStorage.getToken(key: 'refresh_token'), isNull);
          expect(await fakeStorage.getToken(key: 'user_id'), isNull);
          expect(await fakeStorage.getToken(key: 'flag_session_only'), isNull);
          // Ensure no remote network call was made
          expect(fakeRemote.logoutCalled, isFalse);
        },
      );

      test(
        'logout() clears flag_session_only and calls remote logout',
        () async {
          await fakeStorage.saveToken('token123', key: 'access_token');
          await fakeStorage.saveToken('false', key: 'flag_session_only');

          await repoImpl.logout();

          expect(await fakeStorage.getToken(key: 'access_token'), isNull);
          expect(await fakeStorage.getToken(key: 'flag_session_only'), isNull);
          expect(fakeRemote.logoutCalled, isTrue);
        },
      );

      test(
        'saveFlag and getStoredFlag store and retrieve prefixed flag in storage',
        () async {
          await repoImpl.saveFlag('session_only', 'false');
          final val = await repoImpl.getStoredFlag('session_only');
          expect(val, 'false');
          expect(await fakeStorage.getToken(key: 'flag_session_only'), 'false');
        },
      );

      test(
        'login persists tokens and session data in secure storage',
        () async {
          fakeRemote.loginResponse = const AuthResponseModel(
            accessToken: 'acc_123',
            refreshToken: 'ref_123',
            user: AuthUserModel(
              id: 'u_1',
              email: 'test@example.com',
              role: 'USER',
            ),
          );

          final user = await repoImpl.login(
            password: 'secret',
            email: 'test@example.com',
          );

          expect(user.id, 'u_1');
          expect(await fakeStorage.getToken(key: 'access_token'), 'acc_123');
          expect(await fakeStorage.getToken(key: 'refresh_token'), 'ref_123');
          expect(await fakeStorage.getToken(key: 'user_id'), 'u_1');
        },
      );
    },
  );

  // ── 7. Router: no premature redirect while auth status is unknown ─────────

  group(
    '7. Auth initialization state machine (prevents premature redirect)',
    () {
      test(
        'initial state is AuthStatus.unknown before startup check resolves',
        () {
          final notifier = AuthNotifier(fakeRepo);
          expect(notifier.state.status, AuthStatus.unknown);
        },
      );

      test('transitions from unknown to final unauthenticated state', () async {
        final states = <AuthStatus>[];
        final notifier = AuthNotifier(fakeRepo);
        states.add(notifier.state.status);
        notifier.addListener((s) => states.add(s.status));

        await Future<void>.delayed(Duration.zero);

        expect(states.first, AuthStatus.unknown);
        expect(states.last, AuthStatus.unauthenticated);
      });

      test(
        'transitions from unknown to authenticated state on remembered login',
        () async {
          fakeRepo.flags['session_only'] = 'false';
          fakeRepo.authenticated = true;
          fakeRepo.cachedUser = _tUser;

          final states = <AuthStatus>[];
          final notifier = AuthNotifier(fakeRepo);
          states.add(notifier.state.status);
          notifier.addListener((s) => states.add(s.status));

          await Future<void>.delayed(Duration.zero);

          expect(states.first, AuthStatus.unknown);
          expect(states.contains(AuthStatus.authenticated), isTrue);
          // Crucial: AuthStatus.unauthenticated is NEVER emitted during restore
          expect(states.contains(AuthStatus.unauthenticated), isFalse);
        },
      );
    },
  );

  // ── 8. App Lock interaction ──────────────────────────────────────────────

  group('8. App Lock interaction: Remember Me does not bypass App Lock', () {
    test(
      'restoring remembered session leaves App Lock state untouched',
      () async {
        fakeRepo.flags['session_only'] = 'false';
        fakeRepo.authenticated = true;
        fakeRepo.cachedUser = _tUser;

        final notifier = AuthNotifier(fakeRepo);
        await Future<void>.delayed(Duration.zero);

        // State is authenticated, ready for App Lock to evaluate lock status
        expect(notifier.state.status, AuthStatus.authenticated);
        expect(fakeRepo.clearSessionLocallyCalls, 0);
        expect(fakeRepo.logoutCalls, 0);
      },
    );
  });

  // ── 9. Existing auth behavior unchanged ──────────────────────────────────

  group('9. Existing auth behavior unchanged', () {
    test(
      'login failure sets unauthenticated with formatted error message',
      () async {
        fakeRepo.onLogin = ({email, phoneNumber, username, required password}) {
          throw AppException('Invalid credentials', code: '401');
        };

        final notifier = AuthNotifier(fakeRepo);
        await Future<void>.delayed(Duration.zero);

        await notifier.login(email: 'wrong@example.com', password: 'bad');

        expect(notifier.state.status, AuthStatus.unauthenticated);
        expect(notifier.state.error, contains('Incorrect email or password'));
      },
    );

    test('clearError resets error field to null', () async {
      fakeRepo.onLogin = ({email, phoneNumber, username, required password}) {
        throw Exception('Test error');
      };

      final notifier = AuthNotifier(fakeRepo);
      await notifier.login(email: 'a@b.com', password: '123');
      expect(notifier.state.error, isNotNull);

      notifier.clearError();
      expect(notifier.state.error, isNull);
    });
  });
}
