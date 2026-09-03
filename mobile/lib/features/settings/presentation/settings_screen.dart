// lib/features/settings/presentation/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/auth/domain/entities/auth_user.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'ADMIN' || user?.role == 'SUPER_ADMIN';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, theme, isDark, user),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // ── Account Management ─────────────────────────────────────
                  _SectionHeader(label: 'ACCOUNT MANAGEMENT'),
                  _SettingsTile(
                    icon: Icons.manage_accounts_outlined,
                    iconColor: const Color(0xFF6C63FF),
                    title: 'Profile Management',
                    subtitle: 'Edit name, bio, avatar & links',
                    onTap: () => context.push('/profile'),
                  ),
                  _SettingsTile(
                    icon: Icons.security_outlined,
                    iconColor: const Color(0xFF00C6FF),
                    title: 'Security & Sessions',
                    subtitle: 'Password, 2FA, active devices',
                    onTap: () => context.push('/settings/security'),
                  ),
                  const SizedBox(height: 20),
                  // ── Appearance & Theme ─────────────────────────────────────
                  _SectionHeader(label: 'APPEARANCE & THEME'),
                  _SettingsTile(
                    icon: Icons.palette_outlined,
                    iconColor: const Color(0xFFFF6584),
                    title: 'Appearance & Theme',
                    subtitle: 'Dark mode, colors, font size',
                    onTap: () => context.push('/settings/appearance'),
                  ),
                  _SettingsTile(
                    icon: Icons.language_outlined,
                    iconColor: const Color(0xFF43E97B),
                    title: 'Language',
                    subtitle: 'English, አማርኛ, ግእዝ',
                    onTap: () => context.push('/settings/language'),
                  ),
                  const SizedBox(height: 20),
                  // ── Privacy ─────────────────────────────────────────────────
                  _SectionHeader(label: 'PRIVACY'),
                  _SettingsTile(
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFFFF9F43),
                    title: 'Privacy',
                    subtitle: 'Last seen, blocked users, read receipts',
                    onTap: () => context.push('/settings/privacy'),
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_active_outlined,
                    iconColor: const Color(0xFFEE5A24),
                    title: 'Notification Preferences',
                    subtitle: 'Messages, stories, live alerts',
                    onTap: () => context.push('/settings/notifications'),
                  ),
                  _SettingsTile(
                    icon: Icons.tune_outlined,
                    iconColor: const Color(0xFF9B59B6),
                    title: 'Content Preferences',
                    subtitle: 'Filters, autoplay, sensitive content',
                    onTap: () => context.push('/settings/content'),
                  ),
                  _SettingsTile(
                    icon: Icons.play_circle_outline_rounded,
                    iconColor: const Color(0xFF00B894),
                    title: 'Playback & Media',
                    subtitle: 'Speed, quality, autoplay behavior',
                    onTap: () => context.push('/settings/playback'),
                  ),
                  const SizedBox(height: 20),
                  // ── Downloads & Storage ─────────────────────────────────────
                  _SectionHeader(label: 'DOWNLOADS & STORAGE'),
                  _SettingsTile(
                    icon: Icons.download_for_offline_outlined,
                    iconColor: const Color(0xFF00C6FF),
                    title: 'Downloads & Storage',
                    subtitle: 'Quality, location, auto-download',
                    onTap: () => context.push('/settings/downloads'),
                  ),
                  _SettingsTile(
                    icon: Icons.data_usage_outlined,
                    iconColor: const Color(0xFF6C63FF),
                    title: 'Data Usage',
                    subtitle: 'Data saver, network statistics',
                    onTap: () => context.push('/settings/data-usage'),
                  ),
                  _SettingsTile(
                    icon: Icons.cleaning_services_outlined,
                    iconColor: const Color(0xFFFF6584),
                    title: 'Cache Management',
                    subtitle: 'Clear videos, images, app data',
                    onTap: () => context.push('/settings/cache'),
                    isLast: true,
                  ),
                  const SizedBox(height: 20),
                  // ── Support ─────────────────────────────────────────────────
                  _SectionHeader(label: 'SUPPORT & INFO'),
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    iconColor: const Color(0xFF00C6FF),
                    title: 'Help & FAQ',
                    subtitle: 'Get support, FAQs, community',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: const Color(0xFF43E97B),
                    title: 'About',
                    subtitle: 'App version, terms, privacy policy',
                    onTap: () => _showAboutDialog(context, theme),
                  ),
                  _SettingsTile(
                    icon: Icons.bug_report_outlined,
                    iconColor: const Color(0xFFFF9F43),
                    title: 'Report a Problem',
                    subtitle: 'Send feedback to the dev team',
                    onTap: () {},
                    isLast: true,
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 20),
                    _SectionHeader(label: 'ADMINISTRATION'),
                    _SettingsTile(
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: Colors.redAccent,
                      title: 'Admin Panel',
                      subtitle: 'Manage users, content, platform',
                      titleColor: Colors.redAccent,
                      onTap: () => context.push('/settings/admin'),
                      isLast: true,
                    ),
                  ],
                  const SizedBox(height: 24),
                  // ── Logout ──────────────────────────────────────────────────
                  _LogoutButton(onTap: () => _confirmLogout(context, ref)),
                  const SizedBox(height: 12),
                  // ── App Version ─────────────────────────────────────────────
                  Text(
                    'Zkirek Dusan v1.0.0 (build 42)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ThemeData theme, bool isDark, AuthUser? user) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1A2E), Color(0xFF0F0F0F)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE8F4FD), Color(0xFFF0F2F5)],
                  ),
          ),
          child: user != null
              ? Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 60, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              user.displayIdentifier,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF00C6FF),
                              ),
                            ),
                            if (user.email != null)
                              Text(
                                user.email!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF00C6FF).withValues(alpha: 0.3),
                          child: Text(
                            user.displayIdentifier.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF00C6FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('About'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Zkirek Dusan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            SizedBox(height: 4),
            Text('Version 1.0.0 (build 42)'),
            SizedBox(height: 16),
            Text('A modern social media platform for sharing, streaming, and connecting.'),
            SizedBox(height: 16),
            Text('© 2026 Zkirek Dusan. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () {}, child: const Text('Privacy Policy')),
          TextButton(onPressed: () {}, child: const Text('Terms of Service')),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Widgets ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: const Color(0xFF00C6FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final bool isLast;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 1),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(isLast ? 0 : 0),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: titleColor ?? theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
        label: const Text(
          'Log Out',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
