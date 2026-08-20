// lib/core/presentation/app_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/core/presentation/widgets/responsive_layout.dart';
import 'package:mobile/features/notifications/data/notification_lifecycle_manager.dart';
import 'package:mobile/features/notifications/presentation/providers/unread_count_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  // Track previous connectivity to only show banner on transitions
  ConnectivityStatus? _previousStatus;

  @override
  void initState() {
    super.initState();
    // Initial state — don't show banner on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _previousStatus = ref.read(connectivityProvider).status;
      // Initialize notification socket lifecycle (connect/disconnect with auth)
      ref.read(notificationLifecycleProvider);
    });
  }

  void _onItemTapped(int index, BuildContext context) {
    if (index == 2) {
      // Create button → show options
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Upload Video'),
                onTap: () {
                  context.pop(); // close sheet
                  context.push(
                    '/creator/workspace',
                  ); // F6: Upload video uses Creator Workspace
                },
              ),
              ListTile(
                leading: const Icon(Icons.live_tv),
                title: const Text('Go Live'),
                onTap: () {
                  context.pop(); // close sheet
                  context.push('/live/studio');
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_add),
                title: const Text('Create Group'),
                onTap: () {
                  context.pop(); // close sheet
                  context.push('/creator/create-group');
                },
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Adjust index for shell branches (branch 2 is now a placeholder;
    // tapping 3 → chats at branch index 3, etc.)
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityProvider);
    final isWideScreen = !ResponsiveLayout.isMobile(context);
    final theme = Theme.of(context);

    // Show connectivity banner on state transition
    if (_previousStatus != null && connectivity.isInitialized) {
      final current = connectivity.status;
      if (current != _previousStatus) {
        _previousStatus = current;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          if (current == ConnectivityStatus.offline) {
            messenger.showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text("You're offline. Some content may be unavailable."),
                  ],
                ),
                backgroundColor: Colors.grey[800],
                duration: const Duration(seconds: 6),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            messenger.showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.wifi, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text("You're back online."),
                  ],
                ),
                backgroundColor: Colors.green[700],
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
      }
    } else if (_previousStatus == null && connectivity.isInitialized) {
      _previousStatus = connectivity.status;
    }

    if (isWideScreen) {
      final unreadCount = ref.watch(unreadNotificationCountProvider);
      final isDesktop = ResponsiveLayout.isDesktop(context);

      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: isDesktop,
              selectedIndex: _adjustedSelectedIndex,
              onDestinationSelected: (index) => _onItemTapped(index, context),
              labelType: isDesktop
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              trailing: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: IconButton(
                  icon: unreadCount > 0
                      ? Badge(
                          label: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                          ),
                          child: const Icon(Icons.notifications_outlined),
                        )
                      : const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifications',
                  onPressed: () => context.push('/notifications'),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: Text('Explore'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.add_circle_outline),
                  selectedIcon: Icon(Icons.add_circle),
                  label: Text('Create'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble),
                  label: Text('Chats'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: widget.navigationShell),
          ],
        ),
      );
    }

    final unreadCount = ref.watch(unreadNotificationCountProvider);
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          height: 65,
          elevation: 0,
          backgroundColor: theme.colorScheme.surface,
          indicatorColor: theme.colorScheme.primaryContainer,
          selectedIndex: _adjustedSelectedIndex,
          onDestinationSelected: (index) => _onItemTapped(index, context),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.add_circle,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              selectedIcon: Icon(
                Icons.add_circle,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              label: 'Create',
            ),
            NavigationDestination(
              icon: unreadCount > 0
                  ? Badge(
                      label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
                      child: const Icon(Icons.notifications_outlined),
                    )
                  : const Icon(Icons.notifications_outlined),
              selectedIcon: const Icon(Icons.notifications_rounded),
              label: 'Alerts',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  /// Maps shell branch index to nav bar index.
  /// Branch 2 is the placeholder; we never highlight it.
  int get _adjustedSelectedIndex {
    final idx = widget.navigationShell.currentIndex;
    return idx; // branches 0,1,2(placeholder),3,4 map 1:1 to nav items
  }
}
