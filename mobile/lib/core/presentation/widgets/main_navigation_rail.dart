// lib/core/presentation/widgets/main_navigation_rail.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/presentation/app_shell.dart';
import 'package:mobile/core/presentation/widgets/responsive_layout.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/home/presentation/providers/home_refresh_provider.dart';
import 'package:mobile/features/notifications/presentation/providers/unread_count_provider.dart';

/// Reusable desktop/tablet persistent sidebar rail.
/// Displays Home, Calendar, Create, Chats, Books plus trailing shortcuts
/// (Notifications, Downloads, Watch History, Liked Videos, Channels, Cache & Storage, Admin Panel).
class MainNavigationRail extends ConsumerWidget {
  final int? selectedIndex;
  final String? currentPath;
  final Function(int)? onDestinationSelected;

  const MainNavigationRail({
    super.key,
    this.selectedIndex,
    this.currentPath,
    this.onDestinationSelected,
  });

  int? _resolveSelectedIndex(String? path) {
    if (selectedIndex != null) return selectedIndex;
    if (path == null) return null;
    if (path == '/home' || path.startsWith('/home/')) return 0;
    if (path == '/calendar' || path.startsWith('/calendar/')) return 1;
    if (path == '/chats' || path.startsWith('/chats/')) return 3;
    if (path == '/books' || path.startsWith('/books/')) return 4;
    return null;
  }

  void _handleDestinationSelected(int index, BuildContext context, WidgetRef ref) {
    if (onDestinationSelected != null) {
      onDestinationSelected!(index);
      return;
    }

    final tr = ref.read(trProvider);

    if (index == 2) {
      // Create button → show options sheet
      showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: Text(tr('shell.upload_video')),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/creator/upload');
                },
              ),
              ListTile(
                leading: const Icon(Icons.live_tv),
                title: Text(tr('shell.go_live')),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/live/studio');
                },
              ),
              ListTile(
                leading: const Icon(Icons.tv),
                title: Text(tr('shell.create_channel')),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/creator/create-group');
                },
              ),
            ],
          ),
        ),
      );
      return;
    }

    switch (index) {
      case 0:
        if (currentPath == '/home') {
          ref.read(homeRefreshSignalProvider.notifier).state++;
        }
        context.go('/home');
        break;
      case 1:
        context.go('/calendar');
        break;
      case 3:
        context.go('/chats');
        break;
      case 4:
        context.go('/books');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final adminPermissions = ref.watch(adminPermissionsProvider);

    final resolvedIndex = _resolveSelectedIndex(currentPath);
    final path = currentPath ?? '';

    return NavigationRail(
      extended: isDesktop,
      selectedIndex: resolvedIndex,
      onDestinationSelected: (index) => _handleDestinationSelected(index, context, ref),
      labelType: isDesktop ? NavigationRailLabelType.none : NavigationRailLabelType.all,
      trailing: SizedBox(
        width: isDesktop ? 220 : 64,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
              _RailActionItem(
                icon: Icons.notifications_outlined,
                selectedIcon: Icons.notifications,
                label: tr('nav.notifications'),
                isExtended: isDesktop,
                badgeCount: unreadCount > 0 ? unreadCount : null,
                isSelected: path.startsWith('/notifications'),
                onTap: () => context.push('/notifications'),
              ),
              // 2. Downloaded Videos
              _RailActionItem(
                icon: Icons.download_done_rounded,
                selectedIcon: Icons.download_done_rounded,
                label: tr('nav.downloads'),
                isExtended: isDesktop,
                isSelected: path.startsWith('/library/downloads'),
                onTap: () => context.push('/library/downloads'),
              ),
              // 3. Watch History
              _RailActionItem(
                icon: Icons.history_rounded,
                selectedIcon: Icons.history_rounded,
                label: tr('nav.history'),
                isExtended: isDesktop,
                isSelected: path.startsWith('/library/history'),
                onTap: () => context.push('/library/history'),
              ),
              // 4. Liked Videos
              _RailActionItem(
                icon: Icons.thumb_up_alt_outlined,
                selectedIcon: Icons.thumb_up,
                label: tr('nav.liked'),
                isExtended: isDesktop,
                isSelected: path.startsWith('/library/liked'),
                onTap: () => context.push('/library/liked'),
              ),
              // 5. Follow Channels
              _RailActionItem(
                icon: Icons.subscriptions_outlined,
                selectedIcon: Icons.subscriptions,
                label: tr('nav.channels'),
                isExtended: isDesktop,
                isSelected: path.contains('/following'),
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
              _RailActionItem(
                icon: Icons.cleaning_services_outlined,
                selectedIcon: Icons.cleaning_services,
                label: tr('nav.cache_storage'),
                isExtended: isDesktop,
                isSelected: false,
                onTap: () => showCacheStorageDialog(context, ref),
              ),
              // 7. Admin Panel
              if (adminPermissions.hasAdminAccess) ...[
                Divider(
                  indent: isDesktop ? 16 : 8,
                  endIndent: isDesktop ? 16 : 8,
                  height: 16,
                  thickness: 0.5,
                  color: theme.dividerColor.withValues(alpha: 0.2),
                ),
                _RailActionItem(
                  icon: Icons.admin_panel_settings_outlined,
                  selectedIcon: Icons.admin_panel_settings,
                  label: tr('nav.admin_panel'),
                  isExtended: isDesktop,
                  iconColor: const Color(0xFFFFB300),
                  isSelected: path.startsWith('/admin'),
                  onTap: () => context.push('/admin'),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: Text(tr('nav.home')),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.calendar_month_outlined),
          selectedIcon: const Icon(Icons.calendar_month),
          label: Text(tr('nav.calendar')),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.add_circle_outline),
          selectedIcon: const Icon(Icons.add_circle),
          label: Text(tr('nav.create')),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.chat_bubble_outline),
          selectedIcon: const Icon(Icons.chat_bubble),
          label: Text(tr('nav.chats')),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.menu_book_outlined),
          selectedIcon: const Icon(Icons.menu_book),
          label: Text(tr('nav.books')),
        ),
      ],
    );
  }
}

class _RailActionItem extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool isExtended;
  final int? badgeCount;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _RailActionItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.isExtended,
    this.badgeCount,
    this.iconColor,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIcon = isSelected && selectedIcon != null ? selectedIcon! : icon;
    final effectiveColor = isSelected
        ? const Color(0xFF00C6FF)
        : (iconColor ?? (isDark ? Colors.white70 : Colors.black87));

    Widget iconWidget = Icon(effectiveIcon, size: 22, color: effectiveColor);

    if (badgeCount != null && badgeCount! > 0) {
      iconWidget = Badge(
        label: Text(
          badgeCount! > 99 ? '99+' : '$badgeCount',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        child: iconWidget,
      );
    }

    if (!isExtended) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Tooltip(
          message: label,
          child: IconButton(
            icon: iconWidget,
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
          decoration: isSelected
              ? BoxDecoration(
                  color: const Color(0xFF00C6FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Row(
            children: [
              iconWidget,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: effectiveColor,
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
