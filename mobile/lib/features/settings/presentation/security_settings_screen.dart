// lib/features/settings/presentation/security_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/settings/presentation/providers/social_settings_provider.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_widgets.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(socialSettingsProvider);
    final n = ref.read(socialSettingsProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Security & Sessions'),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Authentication ─────────────────────────────────────────────────
          SettingsGroup(
            label: 'AUTHENTICATION',
            children: [
              SettingsSwitchTile(
                icon: Icons.lock_outlined,
                iconColor: const Color(0xFF00C6FF),
                title: 'Two-Factor Authentication',
                subtitle: s.twoFactorEnabled
                    ? 'Enabled — your account is extra secure'
                    : 'Off — tap to add a second security layer',
                value: s.twoFactorEnabled,
                onChanged: (v) => n.setTwoFactor(v),
              ),
              SettingsSwitchTile(
                icon: Icons.fingerprint_rounded,
                iconColor: const Color(0xFF43E97B),
                title: 'Biometric Lock',
                subtitle: 'Use fingerprint or face ID to unlock app',
                value: s.biometricLockEnabled,
                onChanged: (v) => n.setBiometricLock(v),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Alerts ────────────────────────────────────────────────────────
          SettingsGroup(
            label: 'SECURITY ALERTS',
            children: [
              SettingsSwitchTile(
                icon: Icons.notifications_active_outlined,
                iconColor: const Color(0xFFFF9F43),
                title: 'Login Alerts',
                subtitle: 'Notify me of new sign-ins to my account',
                value: s.loginAlerts,
                onChanged: (v) => n.setLoginAlerts(v),
              ),
              SettingsNavTile(
                icon: Icons.key_outlined,
                iconColor: const Color(0xFF6C63FF),
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: () => _showChangePassword(context),
              ),
              SettingsNavTile(
                icon: Icons.email_outlined,
                iconColor: const Color(0xFFFF6584),
                title: 'Change Email',
                subtitle: 'Update your login email address',
                onTap: () {},
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Active Sessions ─────────────────────────────────────────────────
          SettingsGroup(
            label: 'ACTIVE SESSIONS',
            children: [
              ...s.sessions.map((session) => _SessionTile(
                    session: session,
                    onTerminate: session.isCurrent
                        ? null
                        : () => _confirmTerminate(context, ref, session.id, session.deviceName),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          if (s.sessions.length > 1)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.phonelink_erase_rounded, color: Colors.red),
                label: const Text(
                  'Terminate All Other Sessions',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _confirmTerminateAll(context, ref),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
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
            const Text('Change Password',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.check_circle_outline),
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
                    const SnackBar(content: Text('Password updated successfully')),
                  );
                },
                child: const Text('Update Password',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmTerminate(BuildContext context, WidgetRef ref, String id, String deviceName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Terminate Session'),
        content: Text('Remove "$deviceName" from your active sessions?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ref.read(socialSettingsProvider.notifier).terminateSession(id);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmTerminateAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Terminate All Sessions'),
        content: const Text(
            'This will log you out of all other devices. You will remain logged in on this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ref.read(socialSettingsProvider.notifier).terminateAllOtherSessions();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All other sessions terminated')),
              );
            },
            child: const Text('Terminate All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final SessionItem session;
  final VoidCallback? onTerminate;

  const _SessionTile({required this.session, this.onTerminate});

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
              child: const Text(
                'This device',
                style: TextStyle(
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
              tooltip: 'Terminate session',
            )
          : null,
    );
  }
}
