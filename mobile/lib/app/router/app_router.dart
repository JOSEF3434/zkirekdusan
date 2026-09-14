// lib/app/router/app_router.dart

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/features/splash/presentation/splash_screen.dart';
import 'package:mobile/features/splash/presentation/onboarding_screen.dart';
import 'package:mobile/features/splash/presentation/providers/splash_provider.dart';
import 'package:mobile/features/auth/presentation/login_screen.dart';
import 'package:mobile/features/auth/presentation/register_screen.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';
import 'package:mobile/features/profile/presentation/profile_screen.dart';
import 'package:mobile/features/profile/presentation/edit_profile_screen.dart';
import 'package:mobile/features/library/presentation/library_screen.dart';
import 'package:mobile/features/library/presentation/continue_watching_screen.dart';
import 'package:mobile/features/settings/presentation/settings_screen.dart';
import 'package:mobile/features/settings/presentation/playback_preferences_screen.dart';
import 'package:mobile/features/settings/presentation/preferences_settings_screens.dart';
import 'package:mobile/features/settings/presentation/admin_settings_screen.dart';
import 'package:mobile/features/settings/presentation/security_settings_screen.dart';
import 'package:mobile/features/settings/presentation/privacy_settings_screen.dart';
import 'package:mobile/features/settings/presentation/notification_settings_screen.dart';
import 'package:mobile/features/settings/presentation/content_settings_screen.dart';
import 'package:mobile/features/settings/presentation/downloads_settings_screen.dart';
import 'package:mobile/features/settings/presentation/data_usage_settings_screen.dart';
import 'package:mobile/features/settings/presentation/cache_settings_screen.dart';
import 'package:mobile/features/settings/presentation/screens/storage_settings_screen.dart';
import 'package:mobile/features/library/presentation/watch_history_screen.dart';
import 'package:mobile/features/library/presentation/downloads_screen.dart';
import 'package:mobile/features/library/presentation/playlists_screen.dart';
import 'package:mobile/features/library/presentation/liked_videos_screen.dart';
import 'package:mobile/features/library/presentation/bookmarks_screen.dart';

import 'package:mobile/features/explore/presentation/explore_screen.dart';
import 'package:mobile/features/books/presentation/screens/books_screen.dart';
import 'package:mobile/features/calendar/presentation/calendar_screen.dart';
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
import 'package:mobile/features/creator/presentation/screens/upload_channel_selector_screen.dart';
import 'package:mobile/features/creator/domain/creator_group_dto.dart';
import 'package:mobile/features/creator_analytics/domain/creator_video_dto.dart';
import 'package:mobile/features/creator_analytics/presentation/screens/admin_moderation_screen.dart';
import 'package:mobile/features/creator_analytics/presentation/screens/creator_channel_dashboard_screen.dart';
import 'package:mobile/features/creator_analytics/presentation/screens/creator_comment_moderation_screen.dart';
import 'package:mobile/features/creator_analytics/presentation/screens/creator_dashboard_screen.dart';
import 'package:mobile/features/creator_analytics/presentation/screens/creator_video_edit_screen.dart';
import 'package:mobile/features/creator_analytics/presentation/screens/creator_video_management_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_roles_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_channels_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_content_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_live_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_chat_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_storage_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_notifications_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_audit_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_system_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_spam_screen.dart';
import 'package:mobile/features/admin/presentation/screens/group_management_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_reports_screen.dart';
import 'package:mobile/features/profile/presentation/widgets/qr_scanner_screen.dart';
import 'package:mobile/features/groups/presentation/screens/group_channel_screen.dart';
import 'package:mobile/features/groups/presentation/screens/playlist_detail_screen.dart';
import 'package:mobile/features/stories/presentation/screens/story_viewer_screen.dart';
import 'package:mobile/features/stories/presentation/screens/story_creation_screen.dart';
import 'package:mobile/features/chats/presentation/screens/conversation_screen.dart';
import 'package:mobile/features/chats/presentation/screens/chat_search_screen.dart';
import 'package:mobile/features/calls/presentation/screens/call_screen.dart';
import 'package:mobile/features/calls/presentation/screens/incoming_call_screen.dart';
import 'package:mobile/features/calls/providers/call_state_provider.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, next) => notifyListeners());
    _ref.listen(preferencesProvider, (_, next) => notifyListeners());
    _ref.listen(splashCompletedProvider, (_, next) => notifyListeners());
    _ref.listen(callStateProvider, (prev, next) {
      if (prev?.status != next.status) {
        notifyListeners();
      }
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);
    final prefsState = _ref.read(preferencesProvider);
    final splashCompleted = _ref.read(splashCompletedProvider);

    final location = state.matchedLocation;
    final isAuthRoute = location == '/login' || location == '/register';
    final isSplashRoute = location == '/';
    final isOnboardingRoute = location == '/onboarding';

    // Handle Incoming Call: immediately route to /call/incoming
    final callState = _ref.read(callStateProvider);
    if (callState.status == CallStatus.ringing &&
        location != '/call/incoming') {
      return '/call/incoming';
    }

    // 0. Hold on splash screen route until minimum splash loading time and animations complete
    if (isSplashRoute && !splashCompleted) {
      return null;
    }

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
    // If refreshing on a specific route (e.g. '/home', '/calendar', '/profile'), do NOT wipe it out!
    if (authState.status == AuthStatus.unknown) {
      return null;
    }

    // 4. Authenticated user behavior:
    if (authState.status == AuthStatus.authenticated) {
      if (isAuthRoute || isSplashRoute) {
        return '/home';
      }

      // Administration route permission checks
      if (location.startsWith('/admin')) {
        final role = authState.user?.role ?? 'USER';
        final isAdminUser = ['SUPER_ADMIN', 'ADMIN', 'MODERATOR', 'SUPPORT'].contains(role);
        if (!isAdminUser) {
          return '/home';
        }
        if (location == '/admin/system' && role != 'SUPER_ADMIN') {
          return '/admin';
        }
        if ((location == '/admin/roles' ||
                location == '/admin/audit' ||
                location == '/admin/storage' ||
                location == '/admin/notifications') &&
            !(role == 'SUPER_ADMIN' || role == 'ADMIN')) {
          return '/admin';
        }
      }

      return null; // Stay on requested route
    }

    // 5. Unauthenticated / Guest user behavior:
    if (authState.status == AuthStatus.unauthenticated) {
      if (isSplashRoute) {
        return '/home'; // Guests land on Home
      }

      final isProtectedRoute =
          location.startsWith('/admin') ||
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
        path: '/call/active',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CallScreen(),
      ),
      GoRoute(
        path: '/call/incoming',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const IncomingCallScreen(),
      ),
      GoRoute(
        path: '/story-viewer',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra as StoryViewerArgs;
          return StoryViewerScreen(args: args);
        },
      ),
      GoRoute(
        path: '/explore',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: rootNavigatorKey,
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
        path: '/creator/upload',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final groupId = state.uri.queryParameters['groupId'];
          return UploadChannelSelectorScreen(initialGroupId: groupId);
        },
      ),
      GoRoute(
        path: '/creator/groups/:id/channels',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final group = state.extra as CreatorGroupDto?;
          if (group != null) {
            return ChannelSelectorScreen(group: group);
          }
          return UploadChannelSelectorScreen(initialGroupId: id);
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
      // Administration Routes
      GoRoute(
        path: '/admin',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/roles',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminRolesScreen(),
      ),
      GoRoute(
        path: '/admin/channels',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminChannelsScreen(),
      ),
      GoRoute(
        path: '/admin/content',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminContentScreen(),
      ),
      GoRoute(
        path: '/admin/live',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminLiveScreen(),
      ),
      GoRoute(
        path: '/admin/chat',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminChatScreen(),
      ),
      GoRoute(
        path: '/admin/storage',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminStorageScreen(),
      ),
      GoRoute(
        path: '/admin/notifications',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminNotificationsScreen(),
      ),
      GoRoute(
        path: '/admin/audit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminAuditScreen(),
      ),
      GoRoute(
        path: '/admin/system',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminSystemScreen(),
      ),
      GoRoute(
        path: '/admin/spam',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminSpamScreen(),
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
        path: '/admin/reports',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: '/qr-scan',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const QrScannerScreen(),
      ),

      // ─────────────────────────────────────────────
      // Canonical Deep Link Redirect Routes
      // ─────────────────────────────────────────────
      GoRoute(
        path: '/u/:username',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) {
          final username = state.pathParameters['username'];
          return '/profile/user/$username';
        },
      ),
      GoRoute(
        path: '/g/:id',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) {
          final id = state.pathParameters['id'];
          return '/groups/$id';
        },
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
        path: '/chats/search',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ChatSearchScreen(),
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
            path: 'security',
            builder: (context, state) => const SecuritySettingsScreen(),
          ),
          GoRoute(
            path: 'privacy',
            builder: (context, state) => const PrivacySettingsScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: 'content',
            builder: (context, state) => const ContentSettingsScreen(),
          ),
          GoRoute(
            path: 'downloads',
            builder: (context, state) => const DownloadsSettingsScreen(),
          ),
          GoRoute(
            path: 'data-usage',
            builder: (context, state) => const DataUsageSettingsScreen(),
          ),
          GoRoute(
            path: 'cache',
            builder: (context, state) => const CacheSettingsScreen(),
          ),
          GoRoute(
            path: 'storage',
            builder: (context, state) => const StorageSettingsScreen(),
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
                path: '/calendar',
                builder: (context, state) => const CalendarScreen(),
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
                path: '/books',
                builder: (context, state) => const BooksScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
