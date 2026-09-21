// lib/features/settings/presentation/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/domain/entities/auth_user.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final user = ref.watch(authProvider).user;
    final perms = ref.watch(adminPermissionsProvider);
    final isAdmin = perms.hasAdminAccess;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, theme, isDark, user, tr),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // ── Account Management ─────────────────────────────────────
                  _SectionHeader(label: tr('settings.section.account_management')),
                  _SettingsTile(
                    icon: Icons.manage_accounts_outlined,
                    iconColor: const Color(0xFF6C63FF),
                    title: tr('settings.profile'),
                    subtitle: tr('settings.profile_subtitle'),
                    onTap: () => context.push('/profile'),
                  ),
                  _SettingsTile(
                    icon: Icons.security_outlined,
                    iconColor: const Color(0xFF00C6FF),
                    title: tr('settings.security'),
                    subtitle: tr('settings.security_subtitle'),
                    onTap: () => context.push('/settings/security'),
                  ),
                  const SizedBox(height: 20),
                  // ── Appearance & Theme ─────────────────────────────────────
                  _SectionHeader(label: tr('settings.section.appearance_theme')),
                  _SettingsTile(
                    icon: Icons.palette_outlined,
                    iconColor: const Color(0xFFFF6584),
                    title: tr('settings.appearance'),
                    subtitle: tr('settings.appearance_subtitle'),
                    onTap: () => context.push('/settings/appearance'),
                  ),
                  _SettingsTile(
                    icon: Icons.language_outlined,
                    iconColor: const Color(0xFF43E97B),
                    title: tr('settings.language'),
                    subtitle: tr('settings.language_subtitle'),
                    onTap: () => context.push('/settings/language'),
                  ),
                  const SizedBox(height: 20),
                  // ── Privacy ─────────────────────────────────────────────────
                  _SectionHeader(label: tr('settings.section.privacy')),
                  _SettingsTile(
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFFFF9F43),
                    title: tr('settings.privacy'),
                    subtitle: tr('settings.privacy_subtitle'),
                    onTap: () => context.push('/settings/privacy'),
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_active_outlined,
                    iconColor: const Color(0xFFEE5A24),
                    title: tr('settings.notifications'),
                    subtitle: tr('settings.notifications_subtitle'),
                    onTap: () => context.push('/settings/notifications'),
                  ),
                  _SettingsTile(
                    icon: Icons.tune_outlined,
                    iconColor: const Color(0xFF9B59B6),
                    title: tr('settings.content_preferences'),
                    subtitle: tr('settings.content_preferences_subtitle'),
                    onTap: () => context.push('/settings/content'),
                  ),
                  _SettingsTile(
                    icon: Icons.play_circle_outline_rounded,
                    iconColor: const Color(0xFF00B894),
                    title: tr('settings.playback'),
                    subtitle: tr('settings.playback_subtitle'),
                    onTap: () => context.push('/settings/playback'),
                  ),
                  const SizedBox(height: 20),
                  // ── Downloads & Storage ─────────────────────────────────────
                  _SectionHeader(label: tr('settings.section.downloads_storage')),
                  _SettingsTile(
                    icon: Icons.download_for_offline_outlined,
                    iconColor: const Color(0xFF00C6FF),
                    title: tr('settings.downloads'),
                    subtitle: tr('settings.downloads_subtitle'),
                    onTap: () => context.push('/settings/downloads'),
                  ),
                  _SettingsTile(
                    icon: Icons.data_usage_outlined,
                    iconColor: const Color(0xFF6C63FF),
                    title: tr('settings.data_usage'),
                    subtitle: tr('settings.data_usage_subtitle'),
                    onTap: () => context.push('/settings/data-usage'),
                  ),
                  _SettingsTile(
                    icon: Icons.cleaning_services_outlined,
                    iconColor: const Color(0xFFFF6584),
                    title: tr('settings.cache'),
                    subtitle: tr('settings.cache_subtitle'),
                    onTap: () => context.push('/settings/cache'),
                    isLast: true,
                  ),
                  const SizedBox(height: 20),
                  // ── Support ─────────────────────────────────────────────────
                  _SectionHeader(label: tr('settings.section.support_info')),
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    iconColor: const Color(0xFF00C6FF),
                    title: tr('settings.help'),
                    subtitle: tr('settings.help_subtitle'),
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: const Color(0xFF43E97B),
                    title: tr('settings.about'),
                    subtitle: tr('settings.about_subtitle'),
                    onTap: () => _showAboutDialog(context, theme, tr),
                  ),
                  _SettingsTile(
                    icon: Icons.bug_report_outlined,
                    iconColor: const Color(0xFFFF9F43),
                    title: tr('settings.report_problem'),
                    subtitle: tr('settings.report_problem_subtitle'),
                    onTap: () {},
                    isLast: true,
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 20),
                    _SectionHeader(label: tr('settings.section.administration')),
                    _SettingsTile(
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: Colors.redAccent,
                      title: tr('settings.admin.panel'),
                      subtitle: tr('settings.admin.panel_subtitle'),
                      titleColor: Colors.redAccent,
                      onTap: () => context.push('/settings/admin'),
                      isLast: true,
                    ),
                  ],
                  const SizedBox(height: 24),
                  // ── Logout ──────────────────────────────────────────────────
                  _LogoutButton(
                    label: tr('dialog.logout_btn_settings'),
                    onTap: () => _confirmLogout(context, ref, tr),
                  ),
                  const SizedBox(height: 12),
                  // ── App Version ─────────────────────────────────────────────
                  Text(
                    tr('app.version'),
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

  Widget _buildSliverAppBar(BuildContext context, ThemeData theme, bool isDark, AuthUser? user, String Function(String, [Map<String, dynamic>?]) tr) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: Text(
          tr('settings.title'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
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

  void _showAboutDialog(BuildContext context, ThemeData theme, String Function(String, [Map<String, dynamic>?]) tr) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('dialog.about_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('app.name'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 4),
            Text(tr('dialog.about_version')),
            const SizedBox(height: 16),
            Text(tr('dialog.about_description')),
            const SizedBox(height: 16),
            Text(tr('dialog.about_copyright')),
          ],
        ),
        actions: [
          TextButton(onPressed: () {}, child: Text(tr('dialog.privacy_policy'))),
          TextButton(onPressed: () {}, child: Text(tr('dialog.terms_of_service'))),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('common.close'))),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref, String Function(String, [Map<String, dynamic>?]) tr) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('dialog.logout_title')),
        content: Text(tr('dialog.logout_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('common.cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: Text(tr('dialog.logout_btn_settings'), style: const TextStyle(color: Colors.white)),
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
  final String label;
  const _LogoutButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
        label: Text(
          label,
          style: const TextStyle(
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
