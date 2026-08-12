import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:mobile/features/profile/data/models/profile_model.dart';

final myProfileProvider =
    AsyncNotifierProvider<MyProfileNotifier, ProfileModel>(() {
      return MyProfileNotifier();
    });

class MyProfileNotifier extends AsyncNotifier<ProfileModel> {
  @override
  Future<ProfileModel> build() async {
    final repo = ref.read(profileRemoteDataSourceProvider);
    return repo.getMyProfile();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(profileRemoteDataSourceProvider);
      final profile = await repo.getMyProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? displayName,
    String? bio,
    String? website,
    String? country,
    String? language,
    String? gender,
    String? visibility,
  }) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // We don't do optimistic update here since it's a full form submission usually
    try {
      final repo = ref.read(profileRemoteDataSourceProvider);
      final updatedProfile = await repo.updateMyProfile(
        firstName: firstName,
        lastName: lastName,
        displayName: displayName,
        bio: bio,
        website: website,
        country: country,
        language: language,
        gender: gender,
        visibility: visibility,
      );
      state = AsyncValue.data(updatedProfile);
    } catch (e) {
      rethrow;
    }
  }
}

final publicProfileProvider =
    AsyncNotifierProviderFamily<PublicProfileNotifier, ProfileModel, String>(
      () {
        return PublicProfileNotifier();
      },
    );

class PublicProfileNotifier extends FamilyAsyncNotifier<ProfileModel, String> {
  @override
  Future<ProfileModel> build(String arg) async {
    final repo = ref.read(profileRemoteDataSourceProvider);
    return repo.getProfileByUsername(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(profileRemoteDataSourceProvider);
      final profile = await repo.getProfileByUsername(arg);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
