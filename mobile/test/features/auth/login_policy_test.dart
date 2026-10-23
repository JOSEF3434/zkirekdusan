// test/features/auth/login_policy_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/data/models/login_policy_model.dart';
import 'package:mobile/features/auth/domain/entities/auth_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/login_screen.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/auth/presentation/providers/login_policy_provider.dart';

class MockAuthRepo implements AuthRepository {
  LoginPolicyConfig config;
  String? lastLoginEmail;
  String? lastLoginPhone;
  String? lastLoginUsername;
  String? lastLoginPassword;

  MockAuthRepo({this.config = const LoginPolicyConfig()});

  @override
  Future<LoginPolicyConfig> getLoginPolicyConfig() async => config;

  @override
  Future<AuthUser> login({
    String? email,
    String? phoneNumber,
    String? username,
    required String password,
  }) async {
    lastLoginEmail = email;
    lastLoginPhone = phoneNumber;
    lastLoginUsername = username;
    lastLoginPassword = password;
    return const AuthUser(
      id: 'usr-1',
      email: 'test@example.com',
      username: 'testuser',
      role: 'USER',
    );
  }

  @override
  Future<AuthUser> register({
    String? email,
    String? phoneNumber,
    String? username,
    String? firstName,
    String? lastName,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<void> refreshTokens() async {}

  @override
  Future<AuthUser> fetchMe() async => const AuthUser(id: 'usr-1', role: 'USER');

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<AuthUser?> getCachedUser() async => null;

  @override
  Future<void> saveFlag(String key, String value) async {}

  @override
  Future<String?> getStoredFlag(String key) async => null;

  @override
  Future<void> clearSessionLocally() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginPolicyConfig Model Tests', () {
    test(
      'Default configuration should be SINGLE_IDENTIFIER with all enabled',
      () {
        const config = LoginPolicyConfig();
        expect(config.isSingle, isTrue);
        expect(config.isDual, isFalse);
        expect(config.isAll, isFalse);
        expect(config.allowEmail, isTrue);
        expect(config.allowPhone, isTrue);
        expect(config.allowUsername, isTrue);
      },
    );

    test(
      'DUAL_IDENTIFIER EMAIL_PHONE correctly flags requiresEmail and requiresPhone',
      () {
        const config = LoginPolicyConfig(
          activePolicy: 'DUAL_IDENTIFIER',
          dualCombination: 'EMAIL_PHONE',
        );
        expect(config.isDual, isTrue);
        expect(config.requiresEmail, isTrue);
        expect(config.requiresPhone, isTrue);
        expect(config.requiresUsername, isFalse);
      },
    );

    test('ALL_IDENTIFIERS requires all three', () {
      const config = LoginPolicyConfig(activePolicy: 'ALL_IDENTIFIERS');
      expect(config.isAll, isTrue);
      expect(config.requiresEmail, isTrue);
      expect(config.requiresPhone, isTrue);
      expect(config.requiresUsername, isTrue);
    });

    test('JSON serialization round-trip', () {
      final json = {
        'activePolicy': 'DUAL_IDENTIFIER',
        'allowEmail': true,
        'allowPhone': false,
        'allowUsername': false,
        'dualCombination': 'EMAIL_USERNAME',
      };
      final parsed = LoginPolicyConfig.fromJson(json);
      expect(parsed.activePolicy, 'DUAL_IDENTIFIER');
      expect(parsed.dualCombination, 'EMAIL_USERNAME');
      expect(parsed.toJson()['dualCombination'], 'EMAIL_USERNAME');
    });
  });

  group('Dynamic Login Screen Widget Tests', () {
    testWidgets('SINGLE_IDENTIFIER policy displays unified identifier field', (
      tester,
    ) async {
      final repo = MockAuthRepo(
        config: const LoginPolicyConfig(
          activePolicy: 'SINGLE_IDENTIFIER',
          allowEmail: true,
          allowPhone: true,
          allowUsername: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            trProvider.overrideWithValue(
              (String key, [Map<String, dynamic>? args]) => key,
            ),
            loginPolicyProvider.overrideWith(
              (ref) =>
                  LoginPolicyNotifier(repo)..updateLocalPolicy(repo.config),
            ),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Password field is present
      expect(
        find.byType(TextFormField),
        findsNWidgets(2),
      ); // 1 identifier + 1 password
    });

    testWidgets(
      'DUAL_IDENTIFIER (EMAIL_PHONE) renders both fields + password',
      (tester) async {
        final repo = MockAuthRepo(
          config: const LoginPolicyConfig(
            activePolicy: 'DUAL_IDENTIFIER',
            dualCombination: 'EMAIL_PHONE',
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(repo),
              trProvider.overrideWithValue(
                (String key, [Map<String, dynamic>? args]) => key,
              ),
              loginPolicyProvider.overrideWith(
                (ref) =>
                    LoginPolicyNotifier(repo)..updateLocalPolicy(repo.config),
              ),
            ],
            child: const MaterialApp(home: LoginScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // 2 identifier fields + 1 password field = 3 TextFormFields
        expect(find.byType(TextFormField), findsNWidgets(3));
      },
    );

    testWidgets('ALL_IDENTIFIERS renders all three fields + password', (
      tester,
    ) async {
      final repo = MockAuthRepo(
        config: const LoginPolicyConfig(activePolicy: 'ALL_IDENTIFIERS'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            trProvider.overrideWithValue(
              (String key, [Map<String, dynamic>? args]) => key,
            ),
            loginPolicyProvider.overrideWith(
              (ref) =>
                  LoginPolicyNotifier(repo)..updateLocalPolicy(repo.config),
            ),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 3 identifier fields + 1 password field = 4 TextFormFields
      expect(find.byType(TextFormField), findsNWidgets(4));
    });
  });
}
