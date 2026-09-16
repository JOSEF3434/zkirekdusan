// lib/core/presentation/widgets/responsive_desktop_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/presentation/widgets/main_navigation_rail.dart';
import 'package:mobile/core/presentation/widgets/mini_player_overlay.dart';
import 'package:mobile/core/presentation/widgets/offline_status_banner.dart';
import 'package:mobile/core/presentation/widgets/responsive_layout.dart';

/// Wraps feature screens (Profile, Settings, Admin, Global Search, Notifications, Library, etc.)
/// on wide/desktop screens with the persistent MainNavigationRail.
/// On mobile screens, it renders [child] directly so mobile users get standard full-screen views.
class ResponsiveDesktopShell extends ConsumerWidget {
  final Widget child;

  const ResponsiveDesktopShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWideScreen = !ResponsiveLayout.isMobile(context);

    if (!isWideScreen) {
      return child;
    }

    final currentPath = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              MainNavigationRail(currentPath: currentPath),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: Column(
                  children: [
                    const OfflineStatusBanner(),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
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
}
