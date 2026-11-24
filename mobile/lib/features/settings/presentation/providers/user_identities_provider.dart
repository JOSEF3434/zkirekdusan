// lib/features/settings/presentation/providers/user_identities_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

class UserIdentitiesState {
  final bool isLoading;
  final bool hasPassword;
  final String? googleEmail;
  final bool isGoogleConnected;
  final String? error;

  const UserIdentitiesState({
    this.isLoading = false,
    this.hasPassword = true,
    this.googleEmail,
    this.isGoogleConnected = false,
    this.error,
  });

  UserIdentitiesState copyWith({
    bool? isLoading,
    bool? hasPassword,
    String? googleEmail,
    bool? isGoogleConnected,
    String? error,
    bool clearError = false,
  }) {
    return UserIdentitiesState(
      isLoading: isLoading ?? this.isLoading,
      hasPassword: hasPassword ?? this.hasPassword,
      googleEmail: googleEmail ?? this.googleEmail,
      isGoogleConnected: isGoogleConnected ?? this.isGoogleConnected,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UserIdentitiesNotifier extends StateNotifier<UserIdentitiesState> {
  final Ref _ref;

  UserIdentitiesNotifier(this._ref) : super(const UserIdentitiesState()) {
    loadIdentities();
  }

  Future<void> loadIdentities() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(authRepositoryProvider);
      final data = await repo.getIdentities();
      final hasPassword = data['hasPassword'] == true;
      final identities = data['identities'] as List? ?? [];
      final googleIdentity = identities.firstWhere(
        (i) => i is Map && i['provider'] == 'google',
        orElse: () => null,
      );

      state = state.copyWith(
        isLoading: false,
        hasPassword: hasPassword,
        isGoogleConnected: googleIdentity != null,
        googleEmail: googleIdentity != null ? googleIdentity['email']?.toString() : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', '').replaceFirst('AppException: ', ''),
      );
    }
  }

  Future<bool> connectGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final googleService = _ref.read(googleSignInServiceProvider);
      final idToken = await googleService.signInAndGetIdToken();
      if (idToken == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      final repo = _ref.read(authRepositoryProvider);
      await repo.connectGoogle(idToken);
      await loadIdentities();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', '').replaceFirst('AppException: ', ''),
      );
      return false;
    }
  }

  Future<bool> disconnectGoogle() async {
    if (!state.hasPassword) {
      state = state.copyWith(
        error:
            'Cannot disconnect Google because you have not set a password. Please set a password first in security settings.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.disconnectGoogle();
      final googleService = _ref.read(googleSignInServiceProvider);
      await googleService.signOut();
      await loadIdentities();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', '').replaceFirst('AppException: ', ''),
      );
      return false;
    }
  }
}

final userIdentitiesProvider =
    StateNotifierProvider<UserIdentitiesNotifier, UserIdentitiesState>((ref) {
  return UserIdentitiesNotifier(ref);
});
