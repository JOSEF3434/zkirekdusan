// lib/features/profile/presentation/providers/profile_providers.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/storage/secure_storage.dart';
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
  final StorageService _storage;
  static const String _kCachedMyProfileKey = 'cached_my_profile_data';

  ProfileNotifier(this._datasource, this._storage) : super(const ProfileState()) {
    _hydrateFromCache();
  }

  Future<void> _hydrateFromCache() async {
    try {
      final raw = await _storage.getToken(key: _kCachedMyProfileKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final cached = ProfileModel.fromJson(decoded);
        state = state.copyWith(profile: cached);
      }
    } catch (_) {}
  }

  Future<void> loadMyProfile() async {
    if (state.profile == null) {
      await _hydrateFromCache();
    }
    if (state.profile == null) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final profile = await _datasource.getMyProfile();
      state = state.copyWith(profile: profile, isLoading: false, clearError: true);
      await _storage.saveToken(
        jsonEncode(profile.toJson()),
        key: _kCachedMyProfileKey,
      );
    } catch (e) {
      // If we already have a cached profile, keep it and don't block the UI with an error screen
      if (state.profile != null) {
        state = state.copyWith(isLoading: false, clearError: true);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: e is AppException
              ? e.message
              : e.toString().replaceFirst('AppException: ', ''),
        );
      }
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
      await _storage.saveToken(
        jsonEncode(updated.toJson()),
        key: _kCachedMyProfileKey,
      );
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
  return ProfileNotifier(
    ref.watch(profileRemoteDataSourceProvider),
    ref.watch(storageServiceProvider),
  );
});
