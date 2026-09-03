// lib/core/presentation/app_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/core/presentation/widgets/mini_player_overlay.dart';
import 'package:mobile/core/presentation/widgets/responsive_layout.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:mobile/core/storage/download_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/notifications/data/fcm_service.dart';
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
      // Initialize notification socket & FCM lifecycle (connect/disconnect with auth)
      ref.read(notificationLifecycleProvider);
      ref.read(fcmServiceProvider).init();
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
                leading: const Icon(Icons.tv),
                title: const Text('Create Channel'),
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
        body: Stack(
          children: [
            Row(
              children: [
                NavigationRail(
                  extended: isDesktop,
                  selectedIndex: _adjustedSelectedIndex,
                  onDestinationSelected: (index) => _onItemTapped(index, context),
                  labelType: isDesktop
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  trailing: SizedBox(
                    width: isDesktop ? 220 : 64,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Divider(
                          indent: isDesktop ? 16 : 8,
                          endIndent: isDesktop ? 16 : 8,
                          height: 16,
                          thickness: 0.5,
                          color: theme.dividerColor.withValues(alpha: 0.2),
                        ),
                        // 1. Notifications with Badge
                        _RailActionButton(
                          icon: Icons.notifications_outlined,
                          selectedIcon: Icons.notifications,
                          label: 'Notifications',
                          isExtended: isDesktop,
                          badgeCount: unreadCount > 0 ? unreadCount : null,
                          onTap: () => context.push('/notifications'),
                        ),
                        // 2. Downloaded Videos
                        _RailActionButton(
                          icon: Icons.download_done_rounded,
                          label: 'Downloads',
                          isExtended: isDesktop,
                          onTap: () => context.push('/library/downloads'),
                        ),
                        // 3. Watch History
                        _RailActionButton(
                          icon: Icons.history_rounded,
                          label: 'Watch History',
                          isExtended: isDesktop,
                          onTap: () => context.push('/library/history'),
                        ),
                        // 4. Liked Videos
                        _RailActionButton(
                          icon: Icons.thumb_up_alt_outlined,
                          label: 'Liked Videos',
                          isExtended: isDesktop,
                          onTap: () => context.push('/library/liked'),
                        ),
                        // 5. Follow Channels
                        _RailActionButton(
                          icon: Icons.subscriptions_outlined,
                          label: 'Channels',
                          isExtended: isDesktop,
                          onTap: () {
                            final authUser = ref.read(authProvider).user;
                            if (authUser != null) {
                              context.push('/profile/${authUser.id}/following');
                            } else {
                              context.push('/explore');
                            }
                          },
                        ),
                        // 6. Cache & Storage
                        _RailActionButton(
                          icon: Icons.cleaning_services_outlined,
                          label: 'Cache & Storage',
                          isExtended: isDesktop,
                          onTap: () => _showCacheStorageDialog(context, ref),
                        ),
                        const SizedBox(height: 12),
                      ],
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
            // ── Mini player overlay (floats above all shell content) ──
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayerOverlay(),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          widget.navigationShell,
          // ── Mini player overlay (floats above nav bar) ──
          const Positioned(
            left: 0,
            right: 0,
            bottom: 65, // offset above the bottom navigation bar height
            child: MiniPlayerOverlay(),
          ),
        ],
      ),
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
            const NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Chats',
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

// ──────────────────────────────────────────────────────────────────────────────
// Cache & Storage Dialog
// ──────────────────────────────────────────────────────────────────────────────

void _showCacheStorageDialog(BuildContext context, WidgetRef ref) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final downloadState = ref.read(downloadServiceProvider);
  final completedDownloads = downloadState.downloads.values.toList();
  final totalBytes = completedDownloads.fold<int>(
    0,
    (sum, item) => sum + item.sizeBytes,
  );
  final downloadsSizeMB = (totalBytes / (1024 * 1024)).toStringAsFixed(1);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF161C28) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.cleaning_services_rounded, color: Color(0xFF00C6FF)),
          SizedBox(width: 12),
          Text(
            'Cache & Storage',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage app temporary cache and downloaded media files on your device.',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2638) : Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.image_outlined,
                        size: 20, color: Color(0xFF00C6FF)),
                    const SizedBox(width: 10),
                    const Text('Temporary Image Cache',
                        style: TextStyle(fontSize: 14)),
                    const Spacer(),
                    Text('Auto',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.offline_pin_rounded,
                        size: 20, color: Color(0xFF10B981)),
                    const SizedBox(width: 10),
                    const Text('Downloaded Videos',
                        style: TextStyle(fontSize: 14)),
                    const Spacer(),
                    Text(
                      '${completedDownloads.length} videos ($downloadsSizeMB MB)',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('View Downloads'),
          onPressed: () {
            Navigator.pop(ctx);
            context.push('/library/downloads');
          },
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00C6FF),
            foregroundColor: Colors.black,
          ),
          icon: const Icon(Icons.delete_sweep_rounded, size: 16),
          label: const Text('Clear Cache'),
          onPressed: () async {
            try {
              PaintingBinding.instance.imageCache.clear();
              PaintingBinding.instance.imageCache.clearLiveImages();
              await DefaultCacheManager().emptyCache();
            } catch (_) {}
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Temporary cache cleared successfully!'),
                  backgroundColor: Color(0xFF10B981),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ],
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// NavigationRail action button for large devices
// ──────────────────────────────────────────────────────────────────────────────

class _RailActionButton extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool isExtended;
  final int? badgeCount;
  final VoidCallback onTap;

  const _RailActionButton({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.isExtended,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconWidget = Icon(
      icon,
      size: 22,
      color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
    );

    final badgedIcon = badgeCount != null && badgeCount! > 0
        ? Badge(
            label: Text(badgeCount! > 99 ? '99+' : '$badgeCount'),
            backgroundColor: const Color(0xFF00C6FF),
            textColor: Colors.black,
            child: iconWidget,
          )
        : iconWidget;

    if (!isExtended) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Tooltip(
          message: label,
          child: IconButton(
            icon: badgedIcon,
            onPressed: onTap,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              badgedIcon,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
