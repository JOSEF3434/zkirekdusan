// lib/app/router/app_router.dart

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/features/splash/presentation/splash_screen.dart';
import 'package:mobile/features/splash/presentation/onboarding_screen.dart';
import 'package:mobile/features/auth/presentation/login_screen.dart';
import 'package:mobile/features/auth/presentation/register_screen.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';
import 'package:mobile/features/profile/presentation/profile_screen.dart';
import 'package:mobile/features/profile/presentation/edit_profile_screen.dart';
import 'package:mobile/features/library/presentation/library_screen.dart';
import 'package:mobile/features/library/presentation/continue_watching_screen.dart';
import 'package:mobile/features/settings/presentation/settings_screen.dart';
import 'package:mobile/features/settings/presentation/playback_preferences_screen.dart';
import 'package:mobile/features/library/presentation/watch_history_screen.dart';
import 'package:mobile/features/library/presentation/downloads_screen.dart';
import 'package:mobile/features/library/presentation/playlists_screen.dart';
import 'package:mobile/features/library/presentation/liked_videos_screen.dart';
import 'package:mobile/features/library/presentation/bookmarks_screen.dart';
import 'package:mobile/features/settings/presentation/preferences_settings_screens.dart';
import 'package:mobile/features/settings/presentation/admin_settings_screen.dart';
import 'package:mobile/features/explore/presentation/explore_screen.dart';
import 'package:mobile/features/upload/presentation/upload_screen.dart';
import 'package:mobile/features/chats/presentation/chats_screen.dart';
import 'package:mobile/features/explore/presentation/search_screen.dart';
import 'package:mobile/features/profile/presentation/public_profile_screen.dart';
import 'package:mobile/features/player/presentation/video_player_screen.dart';
import 'package:mobile/features/profile/data/models/profile_model.dart';
import 'package:mobile/features/live/presentation/screens/live_discovery_screen.dart';
import 'package:mobile/features/live/presentation/screens/live_room_screen.dart';
import 'package:mobile/features/live/presentation/screens/live_studio_screen.dart';
import 'package:mobile/core/presentation/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/notifications/presentation/notifications_screen.dart';
import 'package:mobile/features/social/presentation/followers_screen.dart';
import 'package:mobile/features/creator/presentation/screens/creator_workspace_screen.dart';
import 'package:mobile/features/creator/presentation/screens/create_group_screen.dart';
import 'package:mobile/features/creator/presentation/screens/channel_selector_screen.dart';
import 'package:mobile/features/creator/domain/creator_group_dto.dart';
import 'package:mobile/features/creator_analytics/domain/creator_video_dto.dart';
import 'package:mobile/features/creator_analytics/presentation/screens/admin_moderation_screen.dart';
import 'package:mobile/features/creator_analytics/presentation/screens/creator_channel_dashboard_screen.dart';
import 'package:mobile/features/creator_analytics/presentation/screens/creator_comment_moderation_screen.dart';
import 'package:mobile/features/creator_analytics/presentation/screens/creator_dashboard_screen.dart';
import 'package:mobile/features/creator_analytics/presentation/screens/creator_video_edit_screen.dart';
import 'package:mobile/features/creator_analytics/presentation/screens/creator_video_management_screen.dart';
import 'package:mobile/features/admin/presentation/screens/group_management_screen.dart';
import 'package:mobile/features/groups/presentation/screens/group_channel_screen.dart';
import 'package:mobile/features/groups/presentation/screens/playlist_detail_screen.dart';
import 'package:mobile/features/stories/presentation/screens/story_viewer_screen.dart';
import 'package:mobile/features/stories/presentation/screens/story_creation_screen.dart';
import 'package:mobile/features/chats/presentation/screens/conversation_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, _) => notifyListeners());
    _ref.listen(preferencesProvider, (_, _) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);
    final prefsState = _ref.read(preferencesProvider);

    final location = state.matchedLocation;
    final isAuthRoute = location == '/login' || location == '/register';
    final isSplashRoute = location == '/';
    final isOnboardingRoute = location == '/onboarding';

    // 1. Onboarding is top priority on first launch
    if (prefsState.isFirstLaunch) {
      if (isOnboardingRoute) return null;
      return '/onboarding';
    }

    // 2. If first launch is finished, do not stay on /onboarding
    if (!prefsState.isFirstLaunch && isOnboardingRoute) {
      return '/home';
    }

    // 3. While auth status is initializing (unknown):
    // If on splash '/', stay on splash.
    // If refreshing on a specific route (e.g. '/home', '/explore', '/profile'), do NOT wipe it out!
    if (authState.status == AuthStatus.unknown) {
      return null;
    }

    // 4. Authenticated user behavior:
    if (authState.status == AuthStatus.authenticated) {
      if (isAuthRoute || isSplashRoute) {
        return '/home';
      }
      return null; // Stay on requested route
    }

    // 5. Unauthenticated / Guest user behavior:
    if (authState.status == AuthStatus.unauthenticated) {
      if (isSplashRoute) {
        return '/home'; // Guests land on Home
      }

      final isProtectedRoute =
          location.startsWith('/creator') ||
          location.startsWith('/live/studio') ||
          location.startsWith('/profile/edit') ||
          location.startsWith('/settings/account') ||
          location.startsWith('/story/create');

      if (isProtectedRoute) {
        return '/login';
      }

      return null; // Public routes like /home, /explore, /login, /register are permitted
    }

    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Full-screen routes above the shell
      GoRoute(
        path: '/story-viewer',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra as StoryViewerArgs;
          return StoryViewerScreen(args: args);
        },
      ),
      GoRoute(
        path: '/story/create',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const StoryCreationScreen(),
      ),
      GoRoute(
        path: '/live/discover',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LiveDiscoveryScreen(),
      ),
      GoRoute(
        path: '/video/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VideoPlayerScreen(videoId: id);
        },
      ),
      GoRoute(
        path: '/live/studio',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          // channelId is now selected in-screen via group/channel dropdown
          return const LiveStudioScreen();
        },
      ),
      GoRoute(
        path: '/live/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return LiveRoomScreen(streamId: id);
        },
      ),
      GoRoute(
        // Upload pushed as full-screen modal ABOVE the shell navigation
        path: '/upload',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const UploadScreen(),
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/creator/workspace',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreatorWorkspaceScreen(),
      ),
      GoRoute(
        path: '/creator/create-group',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/creator/groups/:id/channels',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final group = state.extra as CreatorGroupDto;
          return ChannelSelectorScreen(group: group);
        },
      ),
      GoRoute(
        path: '/creator/dashboard',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreatorDashboardScreen(),
      ),
      GoRoute(
        path: '/creator/dashboard/channel/:channelId/analytics',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final channelId = state.pathParameters['channelId']!;
          final extra = state.extra as Map<String, dynamic>;
          return CreatorChannelDashboardScreen(
            channelId: channelId,
            groupId: extra['groupId'] as String,
            channelName: extra['channelName'] as String,
          );
        },
      ),
      GoRoute(
        path: '/creator/dashboard/channel/:channelId/videos',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final channelId = state.pathParameters['channelId']!;
          return CreatorVideoManagementScreen(channelId: channelId);
        },
      ),
      GoRoute(
        path: '/creator/dashboard/video/:channelId/:videoId/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final channelId = state.pathParameters['channelId']!;
          final videoId = state.pathParameters['videoId']!;
          final initialVideo = state.extra as CreatorVideoDto?;
          return CreatorVideoEditScreen(
            channelId: channelId,
            videoId: videoId,
            initialVideo: initialVideo,
          );
        },
      ),
      GoRoute(
        path: '/creator/dashboard/video/:channelId/:videoId/comments',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final channelId = state.pathParameters['channelId']!;
          final videoId = state.pathParameters['videoId']!;
          return CreatorCommentModerationScreen(
            channelId: channelId,
            videoId: videoId,
          );
        },
      ),
      GoRoute(
        path: '/admin/moderation',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminModerationScreen(),
      ),
      GoRoute(
        path: '/admin/groups',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GroupManagementScreen(),
      ),
      GoRoute(
        path: '/groups/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final tab = state.uri.queryParameters['tab'];
          return GroupChannelScreen(groupId: id, initialTab: tab);
        },
      ),
      GoRoute(
        path: '/playlists/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PlaylistDetailScreen(playlistId: id);
        },
      ),
      GoRoute(
        path: '/chats/conversation/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ConversationScreen(conversationId: id);
        },
      ),

      // Settings Routes
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'appearance',
            builder: (context, state) => const AppearanceSettingsScreen(),
          ),
          GoRoute(
            path: 'language',
            builder: (context, state) => const LanguageSettingsScreen(),
          ),
          GoRoute(
            path: 'playback',
            builder: (context, state) => const PlaybackPreferencesScreen(),
          ),
          GoRoute(
            path: 'admin',
            redirect: (context, state) {
              final authState = ref.read(authProvider);
              final role = authState.user?.role;
              if (role != 'ADMIN' && role != 'SUPER_ADMIN') {
                return '/home';
              }
              return null;
            },
            builder: (context, state) => const AdminSettingsScreen(),
          ),
        ],
      ),

      // Library Routes
      GoRoute(
        path: '/library',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LibraryScreen(),
        routes: [
          GoRoute(
            path: 'history',
            builder: (context, state) => const WatchHistoryScreen(),
          ),
          GoRoute(
            path: 'downloads',
            builder: (context, state) => const DownloadsScreen(),
          ),
          GoRoute(
            path: 'playlists',
            builder: (context, state) => const PlaylistsScreen(),
          ),
          GoRoute(
            path: 'continue-watching',
            builder: (context, state) => const ContinueWatchingScreen(),
          ),
          GoRoute(
            path: 'liked',
            builder: (context, state) => const LikedVideosScreen(),
          ),
          GoRoute(
            path: 'bookmarks',
            builder: (context, state) => const BookmarksScreen(),
          ),
        ],
      ),

      // Shell with bottom nav / rail
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              // Placeholder branch for the center Create button index
              // Actual navigation is done via context.push('/upload')
              GoRoute(
                path: '/create-placeholder',
                builder: (context, state) => const SizedBox.shrink(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chats',
                builder: (context, state) => const ChatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final profile = state.extra as ProfileModel?;
                      return EditProfileScreen(initialProfile: profile);
                    },
                  ),
                  GoRoute(
                    path: 'user/:username',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final username = state.pathParameters['username']!;
                      return PublicProfileScreen(username: username);
                    },
                  ),
                  GoRoute(
                    path: ':id/followers',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return FollowersScreen(profileId: id, initialTabIndex: 0);
                    },
                  ),
                  GoRoute(
                    path: ':id/following',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return FollowersScreen(profileId: id, initialTabIndex: 1);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
