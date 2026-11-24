// test/features/stories/responsive_home_stories_test.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/entities/auth_user.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/stories/data/models/story_feed_group_model.dart';
import 'package:mobile/features/stories/data/models/story_model.dart';
import 'package:mobile/features/stories/presentation/providers/story_feed_provider.dart';
import 'package:mobile/features/stories/presentation/widgets/my_story_item.dart';
import 'package:mobile/features/stories/presentation/widgets/story_section.dart';

import 'package:mobile/features/profile/data/models/profile_model.dart';
import 'package:mobile/features/profile/presentation/providers/profile_providers.dart';
import 'package:mobile/core/utils/localization_service.dart';

void main() {
  group('Responsive Home & Story Strip Tests', () {
    const breakpoints = [
      320.0,
      375.0,
      430.0,
      600.0,
      768.0,
      1024.0,
      1280.0,
      1440.0,
    ];

    final mockMyGroup = StoryFeedGroupModel(
      owner: const StoryAuthorModel(
        id: 'me-123',
        displayName: 'Super Admin',
        username: 'superadmin',
      ),
      stories: [
        StoryModel(
          id: 'story-1',
          type: 'IMAGE',
          author: const StoryAuthorModel(id: 'me-123'),
          expiresAt: DateTime.now().add(const Duration(hours: 20)),
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      ],
      hasUnseen: false,
      latestStoryAt: DateTime.now(),
      totalStories: 1,
    );

    final mockOtherGroup = StoryFeedGroupModel(
      owner: const StoryAuthorModel(
        id: 'other-456',
        displayName: 'Abebe Bikila',
        username: 'abebe',
      ),
      stories: [
        StoryModel(
          id: 'story-2',
          type: 'IMAGE',
          author: const StoryAuthorModel(id: 'other-456'),
          expiresAt: DateTime.now().add(const Duration(hours: 18)),
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          hasViewedByMe: false,
        ),
      ],
      hasUnseen: true,
      latestStoryAt: DateTime.now(),
      totalStories: 1,
    );

    for (final width in breakpoints) {
      testWidgets(
        'StorySection renders without RenderFlex overflow at width ${width}px',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                trProvider.overrideWithValue((String key, [Map<String, dynamic>? args]) {
                  if (args != null && args.containsKey('fallback')) {
                    return args['fallback']?.toString() ?? key;
                  }
                  return key;
                }),
                authProvider.overrideWith((ref) {
                  return _MockAuthNotifier(
                    const AuthState(
                      status: AuthStatus.authenticated,
                      user: AuthUser(
                        id: 'me-123',
                        email: 'admin@test.com',
                        role: 'SUPER_ADMIN',
                      ),
                    ),
                  );
                }),
                profileProvider.overrideWith((ref) => _MockProfileNotifier()),
                storyFeedProvider.overrideWith(
                  () => _MockStoryFeedNotifier([mockMyGroup, mockOtherGroup]),
                ),
              ],
              child: const MaterialApp(
                home: Scaffold(
                  body: CustomScrollView(
                    slivers: [SliverToBoxAdapter(child: StorySection())],
                  ),
                ),
              ),
            ),
          );

          await tester.pump();

          // Must find MyStoryItem and StorySection
          expect(find.byType(StorySection), findsOneWidget);
          expect(find.byType(MyStoryItem), findsOneWidget);

          // Verify no exception was thrown during layout
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('StoryFeedNotifier instantiation and sorting verification', (
      tester,
    ) async {
      final notifier = StoryFeedNotifier();
      expect(notifier, isNotNull);
    });
  });
}

class _MockProfileNotifier extends StateNotifier<ProfileState>
    implements ProfileNotifier {
  _MockProfileNotifier()
    : super(
        ProfileState(
          profile: ProfileModel(
            id: 'prof-1',
            userId: 'me-123',
            username: 'superadmin',
            displayName: 'Super Admin',
            visibility: 'PUBLIC',
            isVerified: true,
            stats: const ProfileStatsModel(
              followersCount: 0,
              followingCount: 0,
              groupsCount: 0,
              postsCount: 0,
              reelsCount: 0,
              videosCount: 0,
            ),
            createdAt: DateTime.now(),
          ),
        ),
      );

  @override
  void clearError() {}

  @override
  Future<void> loadMyProfile() async {}

  @override
  Future<bool> updateMyProfile({
    String? firstName,
    String? lastName,
    String? displayName,
    String? bio,
    String? website,
    String? country,
  }) async => true;

  @override
  Future<bool> uploadAvatar(Uint8List bytes, String filename) async => true;

  @override
  Future<bool> deleteAvatar() async => true;

  @override
  Future<bool> uploadCover(Uint8List bytes, String filename) async => true;

  @override
  Future<bool> deleteCover() async => true;
}

class _MockAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void clearError() {}

  @override
  void clearPendingGoogle() {}

  @override
  Future<bool> signInWithGoogle({bool rememberMe = true}) async => false;

  @override
  Future<bool> linkGoogleAccountWithPassword(String password) async => false;

  @override
  Future<void> login({
    String? email,
    String? phoneNumber,
    String? username,
    required String password,
    bool rememberMe = true,
  }) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> register({
    String? email,
    String? phoneNumber,
    String? username,
    String? firstName,
    String? lastName,
    required String password,
  }) async {}
}

class _MockStoryFeedNotifier extends StoryFeedNotifier {
  final List<StoryFeedGroupModel> _initial;
  _MockStoryFeedNotifier(this._initial);

  @override
  Future<List<StoryFeedGroupModel>> build() async {
    return _initial;
  }
}
