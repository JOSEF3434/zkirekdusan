// test/core/presentation/widgets/main_navigation_rail_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/presentation/widgets/main_navigation_rail.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/notifications/presentation/providers/unread_count_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'MainNavigationRail renders Settings action item and handles selection',
    (tester) async {
      // Set desktop screen size so NavigationRail is extended
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Scaffold(
              body: Row(
                children: [
                  MainNavigationRail(currentPath: state.uri.toString()),
                  const Expanded(child: Text('Home Content')),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => Scaffold(
              body: Row(
                children: [
                  MainNavigationRail(currentPath: state.uri.toString()),
                  const Expanded(child: Text('Settings Content')),
                ],
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trProvider.overrideWithValue((key, [args]) {
              if (key == 'settings.title') return 'Settings';
              if (key == 'nav.settings') return 'Settings';
              if (key == 'nav.home') return 'Home';
              if (key == 'nav.calendar') return 'Calendar';
              if (key == 'nav.create') return 'Create';
              if (key == 'nav.chats') return 'Chats';
              if (key == 'nav.books') return 'Books';
              if (key == 'nav.notifications') return 'Notifications';
              if (key == 'nav.downloads') return 'Downloads';
              if (key == 'nav.history') return 'Watch History';
              if (key == 'nav.liked') return 'Liked Videos';
              if (key == 'nav.channels') return 'Channels';
              if (key == 'nav.cache_storage') return 'Cache & Storage';
              return key;
            }),
            unreadNotificationCountProvider.overrideWith((ref) => 0),
            adminPermissionsProvider.overrideWith(
              (ref) =>
                  const AdminPermissions(role: 'USER', isAuthenticated: false),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Settings is rendered in the sidebar
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      // Tap Settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Verify router navigated to /settings and Settings screen content is shown
      expect(find.text('Settings Content'), findsOneWidget);
      // When on /settings, selected icon (Icons.settings) should be displayed
      expect(find.byIcon(Icons.settings), findsOneWidget);
    },
  );
}
