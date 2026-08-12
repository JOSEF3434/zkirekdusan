// lib/features/profile/presentation/providers/profile_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:mobile/features/profile/data/models/profile_model.dart';

// ── Profile State ───────────────────────────────────────────────────────────

class ProfileState {
  final ProfileModel? profile;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
    this.isSaving = false,
  });

  ProfileState copyWith({
    ProfileModel? profile,
    bool? isLoading,
    String? error,
    bool? isSaving,
    bool clearError = false,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

// ── Profile Notifier ────────────────────────────────────────────────────────

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRemoteDatasource _datasource;

  ProfileNotifier(this._datasource) : super(const ProfileState());

  Future<void> loadMyProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _datasource.getMyProfile();
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is AppException
            ? e.message
            : e.toString().replaceFirst('AppException: ', ''),
      );
    }
  }

  Future<bool> updateMyProfile({
    String? firstName,
    String? lastName,
    String? displayName,
    String? bio,
    String? website,
    String? country,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = await _datasource.updateMyProfile(
        firstName: firstName,
        lastName: lastName,
        displayName: displayName,
        bio: bio,
        website: website,
        country: country,
      );
      state = state.copyWith(profile: updated, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e is AppException
            ? e.message
            : e.toString().replaceFirst('AppException: ', ''),
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  return ProfileNotifier(ref.watch(profileRemoteDataSourceProvider));
});
