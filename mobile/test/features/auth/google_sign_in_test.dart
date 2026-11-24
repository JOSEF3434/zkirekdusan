// test/features/auth/google_sign_in_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/auth/data/models/login_policy_model.dart';
import 'package:mobile/features/auth/data/services/google_sign_in_service.dart';
import 'package:mobile/features/auth/domain/entities/auth_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/auth/presentation/widgets/google_sign_in_button.dart';

class MockAuthRepository implements AuthRepository {
  bool loginWithGoogleCalled = false;
  bool linkGoogleAccountCalled = false;
  String? lastIdToken;
  String? lastPassword;
  AppException? exceptionToThrow;

  final AuthUser dummyUser = const AuthUser(
    id: 'user-google-1',
    email: 'test@gmail.com',
    role: 'USER',
  );

  @override
  Future<AuthUser> loginWithGoogle(String idToken) async {
    loginWithGoogleCalled = true;
    lastIdToken = idToken;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return dummyUser;
  }

  @override
  Future<AuthUser> linkGoogleAccount(String idToken, String password) async {
    linkGoogleAccountCalled = true;
    lastIdToken = idToken;
    lastPassword = password;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return dummyUser;
  }

  @override
  Future<Map<String, dynamic>> getIdentities() async {
    return {
      'hasPassword': true,
      'identities': [
        {'provider': 'google', 'email': 'test@gmail.com'}
      ],
    };
  }

  @override
  Future<void> connectGoogle(String idToken) async {}

  @override
  Future<void> disconnectGoogle() async {}

  @override
  Future<void> clearSessionLocally() async {}

  @override
  Future<AuthUser> fetchMe() async => dummyUser;

  @override
  Future<AuthUser?> getCachedUser() async => null;

  @override
  Future<LoginPolicyConfig> getLoginPolicyConfig() async =>
      const LoginPolicyConfig();

  @override
  Future<String?> getStoredFlag(String key) async => null;

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<AuthUser> login({
    String? email,
    String? phoneNumber,
    String? username,
    required String password,
  }) async =>
      dummyUser;

  @override
  Future<void> logout() async {}

  @override
  Future<void> refreshTokens() async {}

  @override
  Future<AuthUser> register({
    String? email,
    String? phoneNumber,
    String? username,
    String? firstName,
    String? lastName,
    required String password,
  }) async =>
      dummyUser;

  @override
  Future<void> saveFlag(String key, String value) async {}
}

class FakeGoogleSignInService extends GoogleSignInService {
  String? idTokenToReturn;
  bool signOutCalled = false;

  FakeGoogleSignInService({this.idTokenToReturn});

  @override
  Future<String?> signInAndGetIdToken() async => idTokenToReturn;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

void main() {
  group('Google Sign-In AuthNotifier Tests', () {
    late MockAuthRepository mockRepo;

    setUp(() {
      mockRepo = MockAuthRepository();
    });

    test('Successful Google Sign-In authenticates user', () async {
      final fakeGoogle = FakeGoogleSignInService(idTokenToReturn: 'valid-id-token');
      final notifier = AuthNotifier(mockRepo, fakeGoogle);

      final result = await notifier.signInWithGoogle();

      expect(result, isTrue);
      expect(mockRepo.loginWithGoogleCalled, isTrue);
      expect(mockRepo.lastIdToken, equals('valid-id-token'));
      expect(notifier.state.status, equals(AuthStatus.authenticated));
      expect(notifier.state.user?.email, equals('test@gmail.com'));
      expect(notifier.state.error, isNull);
    });

    test('User cancellation of Google account picker does not show error', () async {
      final fakeGoogle = FakeGoogleSignInService(idTokenToReturn: null); // cancelled
      final notifier = AuthNotifier(mockRepo, fakeGoogle);

      final result = await notifier.signInWithGoogle();

      expect(result, isFalse);
      expect(mockRepo.loginWithGoogleCalled, isFalse);
      expect(notifier.state.status, equals(AuthStatus.unauthenticated));
      expect(notifier.state.error, isNull);
      expect(notifier.state.isLoading, isFalse);
    });

    test('409 Conflict triggers pendingGoogleIdToken for account linking', () async {
      final fakeGoogle = FakeGoogleSignInService(idTokenToReturn: 'valid-token');
      mockRepo.exceptionToThrow = AppException(
        'An account with this email already exists.',
        code: '409',
        details: 'ACCOUNT_EXISTS_LINK_REQUIRED',
      );
      final notifier = AuthNotifier(mockRepo, fakeGoogle);

      final result = await notifier.signInWithGoogle();

      expect(result, isFalse);
      expect(notifier.state.status, equals(AuthStatus.unauthenticated));
      expect(notifier.state.pendingGoogleIdToken, equals('valid-token'));
      expect(notifier.state.error, contains('already exists'));

      // Now link with password
      mockRepo.exceptionToThrow = null;
      final linkResult = await notifier.linkGoogleAccountWithPassword('MySecretPassword123');

      expect(linkResult, isTrue);
      expect(mockRepo.linkGoogleAccountCalled, isTrue);
      expect(mockRepo.lastPassword, equals('MySecretPassword123'));
      expect(notifier.state.status, equals(AuthStatus.authenticated));
    });

    test('Logout also signs out of Google', () async {
      final fakeGoogle = FakeGoogleSignInService();
      final notifier = AuthNotifier(mockRepo, fakeGoogle);

      await notifier.logout();

      expect(fakeGoogle.signOutCalled, isTrue);
      expect(notifier.state.status, equals(AuthStatus.unauthenticated));
    });
  });

  group('GoogleSignInButton Widget Tests', () {
    testWidgets('Renders GoogleSignInButton with official text', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GoogleSignInButton(
              onPressed: () => tapped = true,
              text: 'Continue with Google',
            ),
          ),
        ),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(GoogleIconWidget), findsOneWidget);

      await tester.tap(find.byType(GoogleSignInButton));
      expect(tapped, isTrue);
    });

    testWidgets('Shows CircularProgressIndicator when loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GoogleSignInButton(
              onPressed: null,
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Continue with Google'), findsNothing);
    });
  });
}
