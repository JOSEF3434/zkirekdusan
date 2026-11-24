// test/features/auth/password_recovery_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:mobile/features/auth/presentation/otp_verification_screen.dart';
import 'package:mobile/features/auth/presentation/reset_password_screen.dart';
import 'package:mobile/features/auth/presentation/providers/recovery_provider.dart';

class MockRecoveryAuthRepository extends Fake implements AuthRepository {
  bool requestRecoveryCalled = false;
  bool verifyRecoveryCodeCalled = false;
  bool validateRecoveryTokenCalled = false;
  bool resendRecoveryCodeCalled = false;
  bool resetPasswordCalled = false;

  String? lastMethod;
  String? lastIdentifier;
  String? lastDestination;
  String? lastCode;
  String? lastPassword;

  @override
  Future<Map<String, dynamic>> requestPasswordRecovery({
    String? method,
    String? identifier,
    String? email,
    String? phoneNumber,
  }) async {
    requestRecoveryCalled = true;
    lastMethod = method;
    lastIdentifier = identifier ?? email ?? phoneNumber;
    return {
      'success': true,
      'message': 'Recovery sent.',
      'method': method ?? 'EMAIL',
      'destinationMasked': '+25191****44',
      'resendCooldownSeconds': 60,
    };
  }

  @override
  Future<Map<String, dynamic>> verifyRecoveryCode({
    required String method,
    required String destination,
    String? code,
    String? token,
  }) async {
    verifyRecoveryCodeCalled = true;
    lastMethod = method;
    lastDestination = destination;
    lastCode = code;
    return {
      'valid': true,
      'message': 'Code verified.',
      'resetToken': 'verified-challenge-id-123',
    };
  }

  @override
  Future<Map<String, dynamic>> validateRecoveryToken(String token) async {
    validateRecoveryTokenCalled = true;
    return {
      'valid': true,
      'email': 't***@example.com',
      'message': 'Token is valid.',
    };
  }

  @override
  Future<Map<String, dynamic>> resendRecoveryCode({
    required String method,
    required String identifier,
  }) async {
    resendRecoveryCodeCalled = true;
    return {
      'success': true,
      'message': 'Code resent.',
      'resendCooldownSeconds': 60,
    };
  }

  @override
  Future<Map<String, dynamic>> resetPassword({
    String? method,
    String? destination,
    String? code,
    String? token,
    String? resetToken,
    required String password,
  }) async {
    resetPasswordCalled = true;
    lastPassword = password;
    return {
      'success': true,
      'message': 'Password reset successfully.',
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockRecoveryAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockRecoveryAuthRepository();
  });

  group('RecoveryNotifier State Machine Unit Tests', () {
    test('Initial state defaults to email method and idle status', () {
      final notifier = RecoveryNotifier(mockRepo);
      expect(notifier.state.status, RecoveryStepStatus.idle);
      expect(notifier.state.method, RecoveryMethodChoice.email);
      expect(notifier.state.cooldownSeconds, 0);
    });

    test('Switching method updates method choice', () {
      final notifier = RecoveryNotifier(mockRepo);
      notifier.setMethod(RecoveryMethodChoice.phone);
      expect(notifier.state.method, RecoveryMethodChoice.phone);
    });

    test('requestRecovery with phone sets status to otpSent and starts cooldown', () async {
      final notifier = RecoveryNotifier(mockRepo);
      notifier.setMethod(RecoveryMethodChoice.phone);

      final success = await notifier.requestRecovery(identifier: '0911223344');
      expect(success, isTrue);
      expect(mockRepo.requestRecoveryCalled, isTrue);
      expect(notifier.state.status, RecoveryStepStatus.otpSent);
      expect(notifier.state.cooldownSeconds, 60);
      expect(notifier.state.maskedDestination, '+25191****44');
    });

    test('verifyOtp transitions to otpVerified with valid resetToken', () async {
      final notifier = RecoveryNotifier(mockRepo);
      notifier.setMethod(RecoveryMethodChoice.phone);
      notifier.setIdentifier('+251911223344');

      final success = await notifier.verifyOtp('123456');
      expect(success, isTrue);
      expect(mockRepo.verifyRecoveryCodeCalled, isTrue);
      expect(notifier.state.status, RecoveryStepStatus.otpVerified);
      expect(notifier.state.resetToken, 'verified-challenge-id-123');
    });

    test('validateToken transitions to otpVerified for email links', () async {
      final notifier = RecoveryNotifier(mockRepo);

      final success = await notifier.validateToken('raw-email-token-123');
      expect(success, isTrue);
      expect(mockRepo.validateRecoveryTokenCalled, isTrue);
      expect(notifier.state.status, RecoveryStepStatus.otpVerified);
      expect(notifier.state.resetToken, 'raw-email-token-123');
    });

    test('resetPassword calls backend and sets status to success', () async {
      final notifier = RecoveryNotifier(mockRepo);
      notifier.setIdentifier('+251911223344');

      final success = await notifier.resetPassword('NewStrongP@ss1');
      expect(success, isTrue);
      expect(mockRepo.resetPasswordCalled, isTrue);
      expect(mockRepo.lastPassword, 'NewStrongP@ss1');
      expect(notifier.state.status, RecoveryStepStatus.success);
    });
  });

  group('Password Recovery Widget Tests', () {
    testWidgets('ForgotPasswordScreen renders method selection and input', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trProvider.overrideWithValue((key, [args]) => key),
          ],
          child: const MaterialApp(
            home: ForgotPasswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SegmentedButton<RecoveryMethodChoice>), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('OtpVerificationScreen displays 6-digit input and verify button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trProvider.overrideWithValue((key, [args]) => key),
          ],
          child: const MaterialApp(
            home: OtpVerificationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Change phone number'), findsOneWidget);
    });

    testWidgets('ResetPasswordScreen displays password complexity checklist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trProvider.overrideWithValue((key, [args]) => key),
          ],
          child: const MaterialApp(
            home: ResetPasswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2)); // New & Confirm Password
      expect(find.text('Password Requirements:'), findsOneWidget);
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text('Uppercase letter (A-Z)'), findsOneWidget);
      expect(find.text('Lowercase letter (a-z)'), findsOneWidget);
      expect(find.text('Number (0-9)'), findsOneWidget);
      expect(find.text('Special character (@\$!%*?&_-#)'), findsOneWidget);
    });
  });
}
