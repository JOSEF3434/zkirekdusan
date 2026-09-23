// lib/features/live/presentation/widgets/live_side_rail.dart
// Compact circular-icon navigation rail for the Live feature screens.
// Shows icons in filled circles — matching the main app sidebar style.

import 'package:flutter/material.dart';
import 'package:mobile/core/navigation/navigation_service.dart';

class LiveSideRail extends StatefulWidget {
  /// Which item is currently active. Null = none.
  final LiveRailItem? activeItem;

  const LiveSideRail({super.key, this.activeItem});

  @override
  State<LiveSideRail> createState() => _LiveSideRailState();
}

class _LiveSideRailState extends State<LiveSideRail> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111318) : const Color(0xFFF3F4F8);
    final divColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.07);
    // Keep touch-sized layouts compact, while desktop and medium desktop
    // windows reserve space for the full navigation labels.
    final isExpanded = MediaQuery.sizeOf(context).width >= 900;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: isExpanded ? 184 : 64,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: divColor, width: 0.8)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ── Primary nav items ────────────────────────────────────────────
            _RailCircleItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isActive: widget.activeItem == LiveRailItem.home,
              isExpanded: isExpanded,
              onTap: () => NavigationService.instance.goTo('/home'),
            ),
            _RailCircleItem(
              icon: Icons.sensors_rounded,
              label: 'Live',
              isActive: widget.activeItem == LiveRailItem.live,
              activeColor: Colors.redAccent,
              isExpanded: isExpanded,
              onTap: () => NavigationService.instance.goTo('/live/discover'),
            ),
            _RailCircleItem(
              icon: Icons.videocam_rounded,
              label: 'Studio',
              isActive: widget.activeItem == LiveRailItem.studio,
              isExpanded: isExpanded,
              onTap: () =>
                  NavigationService.instance.navigateTo('/live/studio'),
            ),
            _RailCircleItem(
              icon: Icons.event_available_rounded,
              label: 'Schedule',
              isActive: widget.activeItem == LiveRailItem.schedule,
              isExpanded: isExpanded,
              onTap: () => NavigationService.instance.navigateTo(
                '/live/studio?schedule=true',
              ),
            ),

            const SizedBox(height: 8),
            Divider(
              height: 1,
              thickness: 0.5,
              indent: 12,
              endIndent: 12,
              color: divColor,
            ),
            const SizedBox(height: 8),

            // ── Secondary items ───────────────────────────────────────────────
            _RailCircleItem(
              icon: Icons.explore_outlined,
              label: 'Explore',
              isActive: false,
              isExpanded: isExpanded,
              onTap: () => NavigationService.instance.goTo('/home'),
            ),
            _RailCircleItem(
              icon: Icons.video_library_outlined,
              label: 'Library',
              isActive: widget.activeItem == LiveRailItem.library,
              isExpanded: isExpanded,
              onTap: () => NavigationService.instance.navigateTo('/library'),
            ),
            _RailCircleItem(
              icon: Icons.analytics_outlined,
              label: 'Creator',
              isActive: widget.activeItem == LiveRailItem.creator,
              isExpanded: isExpanded,
              onTap: () => NavigationService.instance.navigateTo('/creator'),
            ),

            const Spacer(),
            Divider(
              height: 1,
              thickness: 0.5,
              indent: 12,
              endIndent: 12,
              color: divColor,
            ),
            const SizedBox(height: 8),

            // ── Bottom settings ───────────────────────────────────────────────
            _RailCircleItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              isActive: false,
              isExpanded: isExpanded,
              onTap: () => NavigationService.instance.navigateTo('/settings'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Items that can be "active" in the live rail.
enum LiveRailItem { home, live, studio, schedule, library, creator }

// ─── Single circular icon button ─────────────────────────────────────────────

class _RailCircleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isExpanded;
  final Color? activeColor;
  final VoidCallback onTap;

  const _RailCircleItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isExpanded,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = activeColor ?? theme.colorScheme.primary;

    final Color iconColor;
    final Color circleColor;

    if (isActive) {
      iconColor = accent;
      circleColor = accent.withValues(alpha: isDark ? 0.18 : 0.12);
    } else {
      iconColor = isDark ? Colors.white54 : Colors.black45;
      circleColor = Colors.transparent;
    }

    return Tooltip(
      message: isExpanded ? '' : label,
      preferBelow: false,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(
            horizontal: isExpanded ? 8 : 10,
            vertical: 4,
          ),
          width: isExpanded ? 168 : 44,
          height: 44,
          decoration: BoxDecoration(
            color: circleColor,
            borderRadius: BorderRadius.circular(isExpanded ? 12 : 24),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Center(child: Icon(icon, size: 22, color: iconColor)),
              ),
              if (isExpanded)
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
