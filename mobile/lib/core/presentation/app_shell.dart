// lib/core/presentation/app_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/core/presentation/widgets/main_navigation_rail.dart';
import 'package:mobile/core/presentation/widgets/offline_status_banner.dart';
import 'package:mobile/core/presentation/widgets/responsive_layout.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:mobile/core/storage/download_service.dart';
import 'package:mobile/features/home/presentation/providers/home_refresh_provider.dart';
import 'package:mobile/features/notifications/data/fcm_service.dart';
import 'package:mobile/features/notifications/data/notification_lifecycle_manager.dart';
import 'package:mobile/core/utils/localization_service.dart';

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
      final tr = ref.read(trProvider);
      // Create button → show options
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: Text(tr('shell.upload_video')),
                onTap: () {
                  context.pop(); // close sheet
                  context.push('/creator/upload');
                },
              ),
              ListTile(
                leading: const Icon(Icons.live_tv),
                title: Text(tr('shell.go_live')),
                onTap: () {
                  context.pop(); // close sheet
                  context.push('/live/studio');
                },
              ),
              ListTile(
                leading: const Icon(Icons.tv),
                title: Text(tr('shell.create_channel')),
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

    // If tapping Home while already on Home branch, trigger home feed refresh & scroll to top
    if (index == 0 && widget.navigationShell.currentIndex == 0) {
      ref.read(homeRefreshSignalProvider.notifier).state++;
    }

    // Adjust index for shell branches (branch 2 is the Create placeholder;
    // tapping 0 → home, 1 → calendar, 3 → chats, 4 → books)
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
    final tr = ref.watch(trProvider);

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
                content: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(tr('shell.offline')),
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
                content: Row(
                  children: [
                    const Icon(Icons.wifi, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(tr('shell.back_online')),
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
      return Scaffold(
        body: Stack(
          children: [
            Row(
              children: [
                MainNavigationRail(
                  selectedIndex: _adjustedSelectedIndex,
                  onDestinationSelected: (index) =>
                      _onItemTapped(index, context),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Column(
                    children: [
                      const OfflineStatusBanner(),
                      Expanded(child: widget.navigationShell),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          const OfflineStatusBanner(),
          Expanded(child: widget.navigationShell),
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
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: tr('nav.home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month),
              label: tr('nav.calendar'),
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
              label: tr('nav.create'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.chat_bubble_outline),
              selectedIcon: const Icon(Icons.chat_bubble),
              label: tr('nav.chats'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book),
              label: tr('nav.books'),
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

void showCacheStorageDialog(BuildContext context, WidgetRef ref) {
  final tr = ref.read(trProvider);
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
      title: Row(
        children: [
          const Icon(Icons.cleaning_services_rounded, color: Color(0xFF00C6FF)),
          const SizedBox(width: 12),
          Text(
            tr('dialog.cache_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('dialog.cache_desc'),
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
                    const Icon(
                      Icons.image_outlined,
                      size: 20,
                      color: Color(0xFF00C6FF),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      tr('dialog.cache_temp'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      tr('settings.auto'),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(
                      Icons.offline_pin_rounded,
                      size: 20,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      tr('dialog.cache_downloaded'),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      '${completedDownloads.length} ${tr(completedDownloads.length == 1 ? 'common.video' : 'common.videos')} ($downloadsSizeMB MB)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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
          child: Text(tr('common.close')),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.download_rounded, size: 16),
          label: Text(tr('settings.downloads')),
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
          label: Text(tr('dialog.cache_clear')),
          onPressed: () async {
            try {
              PaintingBinding.instance.imageCache.clear();
              PaintingBinding.instance.imageCache.clearLiveImages();
              await DefaultCacheManager().emptyCache();
            } catch (_) {}
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr('dialog.cache_cleared')),
                  backgroundColor: const Color(0xFF10B981),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ],
    ),
  );
}

