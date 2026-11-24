// lib/features/auth/presentation/providers/recovery_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

enum RecoveryStepStatus {
  idle,
  requesting,
  otpSent,
  verifying,
  otpVerified,
  resetting,
  success,
  error,
}

enum RecoveryMethodChoice {
  email,
  phone,
}

class RecoveryState {
  final RecoveryStepStatus status;
  final RecoveryMethodChoice method;
  final String identifier;
  final String maskedDestination;
  final String resetToken;
  final int cooldownSeconds;
  final String? errorMessage;
  final String? successMessage;

  const RecoveryState({
    this.status = RecoveryStepStatus.idle,
    this.method = RecoveryMethodChoice.email,
    this.identifier = '',
    this.maskedDestination = '',
    this.resetToken = '',
    this.cooldownSeconds = 0,
    this.errorMessage,
    this.successMessage,
  });

  bool get isLoading =>
      status == RecoveryStepStatus.requesting ||
      status == RecoveryStepStatus.verifying ||
      status == RecoveryStepStatus.resetting;

  RecoveryState copyWith({
    RecoveryStepStatus? status,
    RecoveryMethodChoice? method,
    String? identifier,
    String? maskedDestination,
    String? resetToken,
    int? cooldownSeconds,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
  }) {
    return RecoveryState(
      status: status ?? this.status,
      method: method ?? this.method,
      identifier: identifier ?? this.identifier,
      maskedDestination: maskedDestination ?? this.maskedDestination,
      resetToken: resetToken ?? this.resetToken,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

class RecoveryNotifier extends StateNotifier<RecoveryState> {
  final AuthRepository _repository;
  Timer? _timer;

  RecoveryNotifier(this._repository) : super(const RecoveryState());

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void setMethod(RecoveryMethodChoice method) {
    state = state.copyWith(method: method, clearError: true);
  }

  void setIdentifier(String identifier) {
    state = state.copyWith(identifier: identifier, clearError: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    _timer?.cancel();
    state = const RecoveryState();
  }

  void startCooldown(int seconds) {
    _timer?.cancel();
    state = state.copyWith(cooldownSeconds: seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.cooldownSeconds <= 1) {
        timer.cancel();
        state = state.copyWith(cooldownSeconds: 0);
      } else {
        state = state.copyWith(cooldownSeconds: state.cooldownSeconds - 1);
      }
    });
  }

  /// Request recovery code or email link
  Future<bool> requestRecovery({String? identifier}) async {
    final target = identifier ?? state.identifier;
    if (target.trim().isEmpty) {
      state = state.copyWith(
        status: RecoveryStepStatus.error,
        errorMessage: 'Please enter your email or phone number.',
      );
      return false;
    }

    state = state.copyWith(
      status: RecoveryStepStatus.requesting,
      identifier: target.trim(),
      clearError: true,
    );

    try {
      final methodStr =
          state.method == RecoveryMethodChoice.email ? 'EMAIL' : 'PHONE';
      final res = await _repository.requestPasswordRecovery(
        method: methodStr,
        identifier: target.trim(),
      );

      final cooldown = (res['resendCooldownSeconds'] as num?)?.toInt() ?? 60;
      final masked = res['destinationMasked']?.toString() ?? target.trim();
      final message = res['message']?.toString() ?? 'Recovery sent.';

      startCooldown(cooldown);

      state = state.copyWith(
        status: state.method == RecoveryMethodChoice.phone
            ? RecoveryStepStatus.otpSent
            : RecoveryStepStatus.idle,
        maskedDestination: masked,
        successMessage: message,
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        status: RecoveryStepStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: RecoveryStepStatus.error,
        errorMessage: 'Failed to request recovery: $e',
      );
      return false;
    }
  }

  /// Verify phone OTP
  Future<bool> verifyOtp(String code) async {
    if (code.trim().length != 6) {
      state = state.copyWith(
        status: RecoveryStepStatus.error,
        errorMessage: 'Please enter the 6-digit verification code.',
      );
      return false;
    }

    state = state.copyWith(
      status: RecoveryStepStatus.verifying,
      clearError: true,
    );

    try {
      final res = await _repository.verifyRecoveryCode(
        method: 'PHONE',
        destination: state.identifier,
        code: code.trim(),
      );

      final resetToken = res['resetToken']?.toString() ?? '';
      state = state.copyWith(
        status: RecoveryStepStatus.otpVerified,
        resetToken: resetToken,
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        status: RecoveryStepStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: RecoveryStepStatus.error,
        errorMessage: 'Code verification failed: $e',
      );
      return false;
    }
  }

  /// Validate email reset token (e.g. from deep link)
  Future<bool> validateToken(String token) async {
    state = state.copyWith(
      status: RecoveryStepStatus.verifying,
      clearError: true,
    );

    try {
      final res = await _repository.validateRecoveryToken(token);
      final isValid = res['valid'] == true;

      if (isValid) {
        state = state.copyWith(
          status: RecoveryStepStatus.otpVerified,
          resetToken: token,
          maskedDestination: res['email']?.toString() ?? '',
          method: RecoveryMethodChoice.email,
        );
        return true;
      } else {
        state = state.copyWith(
          status: RecoveryStepStatus.error,
          errorMessage:
              res['message']?.toString() ?? 'Invalid or expired recovery link.',
        );
        return false;
      }
    } on AppException catch (e) {
      state = state.copyWith(
        status: RecoveryStepStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: RecoveryStepStatus.error,
        errorMessage: 'Failed to validate recovery token: $e',
      );
      return false;
    }
  }

  /// Resend recovery code/email
  Future<bool> resendCode() async {
    if (state.cooldownSeconds > 0) return false;

    state = state.copyWith(
      status: RecoveryStepStatus.requesting,
      clearError: true,
    );

    try {
      final methodStr =
          state.method == RecoveryMethodChoice.email ? 'EMAIL' : 'PHONE';
      final res = await _repository.resendRecoveryCode(
        method: methodStr,
        identifier: state.identifier,
      );

      final cooldown = (res['resendCooldownSeconds'] as num?)?.toInt() ?? 60;
      startCooldown(cooldown);

      state = state.copyWith(
        status: state.method == RecoveryMethodChoice.phone
            ? RecoveryStepStatus.otpSent
            : RecoveryStepStatus.idle,
        successMessage: res['message']?.toString() ?? 'Recovery resent.',
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        status: RecoveryStepStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: RecoveryStepStatus.error,
        errorMessage: 'Failed to resend code: $e',
      );
      return false;
    }
  }

  /// Complete password reset
  Future<bool> resetPassword(String newPassword) async {
    state = state.copyWith(
      status: RecoveryStepStatus.resetting,
      clearError: true,
    );

    try {
      final methodStr =
          state.method == RecoveryMethodChoice.email ? 'EMAIL' : 'PHONE';

      final res = await _repository.resetPassword(
        method: methodStr,
        destination: state.identifier.isNotEmpty ? state.identifier : null,
        resetToken: state.resetToken.isNotEmpty ? state.resetToken : null,
        token: state.resetToken.isNotEmpty ? state.resetToken : null,
        password: newPassword,
      );

      final success = res['success'] == true;
      if (success) {
        state = state.copyWith(status: RecoveryStepStatus.success);
        return true;
      } else {
        state = state.copyWith(
          status: RecoveryStepStatus.error,
          errorMessage:
              res['message']?.toString() ?? 'Password update failed.',
        );
        return false;
      }
    } on AppException catch (e) {
      state = state.copyWith(
        status: RecoveryStepStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: RecoveryStepStatus.error,
        errorMessage: 'Password reset failed: $e',
      );
      return false;
    }
  }
}

final recoveryProvider =
    StateNotifierProvider.autoDispose<RecoveryNotifier, RecoveryState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RecoveryNotifier(repository);
});
