// lib/features/auth/presentation/providers/login_policy_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/data/models/login_policy_model.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

final loginPolicyProvider =
    StateNotifierProvider<LoginPolicyNotifier, AsyncValue<LoginPolicyConfig>>(
        (ref) {
  final repo = ref.watch(authRepositoryProvider);
  return LoginPolicyNotifier(repo);
});

class LoginPolicyNotifier
    extends StateNotifier<AsyncValue<LoginPolicyConfig>> {
  final dynamic _repository;

  LoginPolicyNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchPolicy();
  }

  Future<void> fetchPolicy() async {
    try {
      state = const AsyncValue.loading();
      final config = await _repository.getLoginPolicyConfig();
      state = AsyncValue.data(config);
    } catch (_) {
      // In case of error, provide the safe default (Single Identifier with all options)
      state = AsyncValue.data(
        const LoginPolicyConfig(
          activePolicy: 'SINGLE_IDENTIFIER',
          allowEmail: true,
          allowPhone: true,
          allowUsername: true,
        ),
      );
    }
  }

  void updateLocalPolicy(LoginPolicyConfig newConfig) {
    state = AsyncValue.data(newConfig);
  }
}
