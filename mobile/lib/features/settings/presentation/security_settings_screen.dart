// lib/features/settings/presentation/security_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/settings/presentation/providers/social_settings_provider.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_widgets.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final s = ref.watch(socialSettingsProvider);
    final n = ref.read(socialSettingsProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(tr('settings.security')),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Authentication ─────────────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.security.authentication'),
            children: [
              SettingsSwitchTile(
                icon: Icons.lock_outlined,
                iconColor: const Color(0xFF00C6FF),
                title: tr('settings.security.two_factor'),
                subtitle: s.twoFactorEnabled
                    ? tr('settings.security.two_factor_enabled')
                    : tr('settings.security.two_factor_disabled'),
                value: s.twoFactorEnabled,
                onChanged: (v) => n.setTwoFactor(v),
              ),
              SettingsSwitchTile(
                icon: Icons.fingerprint_rounded,
                iconColor: const Color(0xFF43E97B),
                title: tr('settings.security.biometric'),
                subtitle: tr('settings.security.biometric_desc'),
                value: s.biometricLockEnabled,
                onChanged: (v) => n.setBiometricLock(v),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Alerts ────────────────────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.security.alerts'),
            children: [
              SettingsSwitchTile(
                icon: Icons.notifications_active_outlined,
                iconColor: const Color(0xFFFF9F43),
                title: tr('settings.security.login_alerts'),
                subtitle: tr('settings.security.login_alerts_desc'),
                value: s.loginAlerts,
                onChanged: (v) => n.setLoginAlerts(v),
              ),
              SettingsNavTile(
                icon: Icons.key_outlined,
                iconColor: const Color(0xFF6C63FF),
                title: tr('settings.security.change_password_label'),
                subtitle: tr('settings.security.change_password_desc'),
                onTap: () => _showChangePassword(context, tr),
              ),
              SettingsNavTile(
                icon: Icons.email_outlined,
                iconColor: const Color(0xFFFF6584),
                title: tr('settings.security.change_email'),
                subtitle: tr('settings.security.change_email_desc'),
                onTap: () {},
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Active Sessions ─────────────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.security.active_sessions'),
            children: [
              ...s.sessions.map((session) => _SessionTile(
                    session: session,
                    thisDeviceLabel: tr('settings.security.this_device'),
                    terminateTooltip: tr('settings.security.terminate_tooltip'),
                    onTerminate: session.isCurrent
                        ? null
                        : () => _confirmTerminate(context, ref, session.id, session.deviceName, tr),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          if (s.sessions.length > 1)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.phonelink_erase_rounded, color: Colors.red),
                label: Text(
                  tr('settings.security.terminate_all_other'),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _confirmTerminateAll(context, ref, tr),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context, String Function(String, [Map<String, dynamic>?]) tr) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 20, right: 20, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('settings.security.change_password_label'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: tr('settings.security.current_password'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: tr('settings.security.new_password'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_reset_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: tr('settings.security.confirm_new_password'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.check_circle_outline),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C6FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('settings.security.password_changed'))),
                  );
                },
                child: Text(tr('settings.security.update_password'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmTerminate(BuildContext context, WidgetRef ref, String id, String deviceName, String Function(String, [Map<String, dynamic>?]) tr) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('settings.security.terminate_session')),
        content: Text(tr('settings.security.terminate_session_confirm', {'device': deviceName})),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(tr('common.cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ref.read(socialSettingsProvider.notifier).terminateSession(id);
            },
            child: Text(tr('settings.security.remove'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmTerminateAll(BuildContext context, WidgetRef ref, String Function(String, [Map<String, dynamic>?]) tr) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('settings.security.terminate_all_title')),
        content: Text(tr('settings.security.terminate_all_desc')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(tr('common.cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ref.read(socialSettingsProvider.notifier).terminateAllOtherSessions();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr('settings.security.all_sessions_terminated'))),
              );
            },
            child: Text(tr('settings.security.terminate_all_other'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final SessionItem session;
  final String thisDeviceLabel;
  final String terminateTooltip;
  final VoidCallback? onTerminate;

  const _SessionTile({
    required this.session,
    required this.thisDeviceLabel,
    required this.terminateTooltip,
    this.onTerminate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: session.isCurrent
              ? const Color(0xFF43E97B).withValues(alpha: 0.15)
              : const Color(0xFF6C63FF).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          session.platform.contains('Android') || session.platform.contains('iOS')
              ? Icons.smartphone_rounded
              : session.platform.contains('Mac') || session.platform.contains('Windows')
                  ? Icons.laptop_rounded
                  : Icons.web_rounded,
          color: session.isCurrent ? const Color(0xFF43E97B) : const Color(0xFF6C63FF),
          size: 22,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              session.deviceName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          if (session.isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF43E97B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                thisDeviceLabel,
                style: const TextStyle(
                    color: Color(0xFF43E97B), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(session.platform,
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          Text('${session.location} • ${session.lastActive}',
              style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
        ],
      ),
      trailing: onTerminate != null
          ? IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
              onPressed: onTerminate,
              tooltip: terminateTooltip,
            )
          : null,
    );
  }
}
