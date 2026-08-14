// lib/app/router/app_router.dart

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/splash/presentation/splash_screen.dart';
import 'package:mobile/features/auth/presentation/login_screen.dart';
import 'package:mobile/features/auth/presentation/register_screen.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';
import 'package:mobile/features/profile/presentation/profile_screen.dart';
import 'package:mobile/features/explore/presentation/explore_screen.dart';
import 'package:mobile/features/upload/presentation/upload_screen.dart';
import 'package:mobile/features/chats/presentation/chats_screen.dart';
import 'package:mobile/features/explore/presentation/search_screen.dart';
import 'package:mobile/features/profile/presentation/public_profile_screen.dart';
import 'package:mobile/features/player/presentation/video_player_screen.dart';
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

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      final isSplashRoute = state.matchedLocation == '/';

      if (authState.status == AuthStatus.unknown) {
        return isSplashRoute ? null : '/';
      }

      if (authState.status == AuthStatus.authenticated) {
        if (isAuthRoute || isSplashRoute) {
          return '/home';
        }
      }

      if (authState.status == AuthStatus.unauthenticated) {
        if (!isAuthRoute && !isSplashRoute) {
          return '/login';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Full-screen routes above the shell
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
          // For MVP, just use user's ID as channel ID (assuming they have one channel)
          // or we can read auth state here. Let's pass 'default_channel' if we don't have it in state easily,
          // but better is getting it from AuthState or profile.
          // The backend usually creates a channel matching the user ID for new users.
          return const LiveStudioScreen(
            channelId: 'default_channel',
          ); // We'll fix channel id logic if needed.
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
