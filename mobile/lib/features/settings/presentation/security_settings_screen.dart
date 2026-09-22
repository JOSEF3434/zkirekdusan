// lib/features/settings/presentation/security_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/settings/presentation/providers/social_settings_provider.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_widgets.dart';
import 'package:mobile/features/security/presentation/providers/app_lock_settings_provider.dart';
import 'package:mobile/features/security/presentation/providers/app_lock_provider.dart';
import 'package:mobile/features/security/presentation/pin_setup_screen.dart';
import 'package:mobile/features/security/presentation/pattern_setup_screen.dart';
import 'package:mobile/features/security/data/pin_service.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final s = ref.watch(socialSettingsProvider);
    final n = ref.read(socialSettingsProvider.notifier);
    final lockSettings = ref.watch(appLockSettingsProvider);
    final lockNotifier = ref.read(appLockSettingsProvider.notifier);
    final biometricAvailable = ref.watch(biometricAvailableProvider);
    final biometricType = ref.watch(biometricHardwareTypeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(tr('settings.security')),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── App Lock ──────────────────────────────────────────────────
          SettingsGroup(
            label: 'App Lock',
            children: [
              // Enable / Disable toggle
              SettingsSwitchTile(
                icon: Icons.screen_lock_portrait_rounded,
                iconColor: const Color(0xFF6C63FF),
                title: 'Enable App Lock',
                subtitle: lockSettings.isEnabled
                    ? 'Lock screen shown when app is backgrounded'
                    : 'App opens without a lock screen',
                value: lockSettings.isEnabled,
                onChanged: (v) async {
                  if (v) {
                    // Choose setup type based on current method preference
                    await _showEnableDialog(context, ref, lockSettings);
                  } else {
                    await lockNotifier.disable();
                    await ref.read(appLockProvider.notifier).disable();
                  }
                },
              ),

              if (lockSettings.isEnabled) ...[
                // ── Lock Method ───────────────────────────────────────
                ListTile(
                  leading: _iconBox(
                    const Color(0xFF43E97B),
                    Icons.fingerprint_rounded,
                  ),
                  title: const Text('Lock Method',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text(_methodLabel(
                      lockSettings.method,
                      biometricType.asData?.value ??
                          BiometricHardwareType.fingerprint)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showMethodPicker(
                    context,
                    lockSettings,
                    lockNotifier,
                    biometricAvailable.asData?.value ?? false,
                    biometricType.asData?.value ??
                        BiometricHardwareType.fingerprint,
                    ref,
                  ),
                ),

                // ── PIN Type (only when method uses PIN) ─────────────
                if (lockSettings.method.usesPin)
                  ListTile(
                    leading: _iconBox(
                      const Color(0xFF00C6FF),
                      Icons.dialpad_rounded,
                    ),
                    title: const Text('PIN Type',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Text(lockSettings.pinType.label),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () =>
                        _showPinTypePicker(context, lockSettings, lockNotifier),
                  ),

                // ── Auto-lock timeout ─────────────────────────────────
                ListTile(
                  leading: _iconBox(
                    const Color(0xFFFF9F43),
                    Icons.timer_outlined,
                  ),
                  title: const Text('Auto-lock After',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text(_timeoutLabel(lockSettings.timeoutMinutes)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      _showTimeoutPicker(context, lockSettings, lockNotifier),
                ),

                // ── Change PIN / Change Pattern ───────────────────────
                if (lockSettings.method.usesPin)
                  ListTile(
                    leading: _iconBox(
                      const Color(0xFF6C63FF),
                      Icons.dialpad_rounded,
                    ),
                    title: const Text('Change PIN',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: const Text('Set a new PIN or password'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              const PinSetupScreen(isChange: true)),
                    ),
                  ),

                if (lockSettings.method.usesPattern)
                  ListTile(
                    leading: _iconBox(
                      const Color(0xFF6C63FF),
                      Icons.grid_view_rounded,
                    ),
                    title: const Text('Change Pattern',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: const Text('Draw a new unlock pattern'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              const PatternSetupScreen(isChange: true)),
                    ),
                  ),

                // ── Lock Now ──────────────────────────────────────────
                ListTile(
                  leading: _iconBox(
                    Colors.red.withValues(alpha: 0.8),
                    Icons.lock_rounded,
                  ),
                  title: const Text(
                    'Lock Now',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.redAccent),
                  ),
                  subtitle: const Text('Immediately lock the app'),
                  onTap: () {
                    ref.read(appLockProvider.notifier).lock();
                    context.go('/lock');
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // ── Authentication ───────────────────────────────────────────
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

          // ── Active Sessions ──────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.security.active_sessions'),
            children: [
              ...s.sessions.map((session) => _SessionTile(
                    session: session,
                    thisDeviceLabel: tr('settings.security.this_device'),
                    terminateTooltip:
                        tr('settings.security.terminate_tooltip'),
                    onTerminate: session.isCurrent
                        ? null
                        : () => _confirmTerminate(
                            context, ref, session.id, session.deviceName, tr),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          if (s.sessions.length > 1)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.phonelink_erase_rounded,
                    color: Colors.red),
                label: Text(
                  tr('settings.security.terminate_all_other'),
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _confirmTerminateAll(context, ref, tr),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Helper icon box ──────────────────────────────────────────────────────

  static Widget _iconBox(Color color, IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  // ── App Lock helpers ─────────────────────────────────────────────────────

  String _methodLabel(AppLockMethod method, BiometricHardwareType hwType) {
    final bioLabel = hwType == BiometricHardwareType.face ? 'Face ID' : 'Touch ID';
    switch (method) {
      case AppLockMethod.biometric:
        return '$bioLabel (biometric only)';
      case AppLockMethod.biometricWithPin:
        return '$bioLabel + PIN fallback';
      case AppLockMethod.pattern:
        return 'Pattern Lock';
      default:
        return 'PIN / Password';
    }
  }

  String _timeoutLabel(int minutes) {
    if (minutes == 0) return 'Immediately';
    if (minutes < 0) return 'Never';
    if (minutes == 1) return '1 minute';
    return '$minutes minutes';
  }

  // ── Enable flow dialog ────────────────────────────────────────────────────

  Future<void> _showEnableDialog(
    BuildContext context,
    WidgetRef ref,
    AppLockSettings settings,
  ) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Choose Lock Type',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.dialpad_rounded,
                      color: Color(0xFF6C63FF), size: 22),
                ),
                title: const Text('PIN / Password',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                    '4-digit, 6-digit, or alphanumeric passcode'),
                onTap: () => Navigator.pop(sheetContext, 'pin'),
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF43E97B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.grid_view_rounded,
                      color: Color(0xFF43E97B), size: 22),
                ),
                title: const Text('Pattern Lock',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Draw a 3×3 pattern to unlock'),
                onTap: () => Navigator.pop(sheetContext, 'pattern'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (choice == null || !context.mounted) return;

    if (choice == 'pin') {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
      );
    } else if (choice == 'pattern') {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const PatternSetupScreen()),
      );
    }
  }

  void _showMethodPicker(
    BuildContext context,
    AppLockSettings settings,
    AppLockSettingsNotifier notifier,
    bool biometricAvail,
    BiometricHardwareType hwType,
    WidgetRef ref,
  ) {
    final bioLabel = hwType == BiometricHardwareType.face ? 'Face ID' : 'Touch ID';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Lock Method',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            _MethodTile(
              label: 'PIN / Password',
              sublabel: 'Numeric PIN or alphanumeric password',
              icon: Icons.dialpad_rounded,
              selected: settings.method == AppLockMethod.pin,
              onTap: () {
                notifier.setMethod(AppLockMethod.pin);
                Navigator.pop(context);
              },
            ),

            _MethodTile(
              label: 'Pattern Lock',
              sublabel: 'Draw a 3×3 unlock pattern',
              icon: Icons.grid_view_rounded,
              selected: settings.method == AppLockMethod.pattern,
              onTap: () {
                notifier.setMethod(AppLockMethod.pattern);
                Navigator.pop(context);
              },
            ),

            if (biometricAvail) ...[
              _MethodTile(
                label: '$bioLabel Only',
                sublabel: 'Biometric with OS-level fallback',
                icon: hwType == BiometricHardwareType.face
                    ? Icons.face_rounded
                    : Icons.fingerprint_rounded,
                selected: settings.method == AppLockMethod.biometric,
                onTap: () {
                  notifier.setMethod(AppLockMethod.biometric);
                  Navigator.pop(context);
                },
              ),
              _MethodTile(
                label: '$bioLabel + PIN fallback',
                sublabel:
                    'Biometric first; switches to PIN after 5 failures',
                icon: Icons.security_rounded,
                selected: settings.method == AppLockMethod.biometricWithPin,
                onTap: () {
                  notifier.setMethod(AppLockMethod.biometricWithPin);
                  Navigator.pop(context);
                },
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPinTypePicker(
    BuildContext context,
    AppLockSettings settings,
    AppLockSettingsNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            const Text('PIN Type',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...PinType.values.map((type) => ListTile(
                  leading: Icon(
                    settings.pinType == type
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: settings.pinType == type
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(type.label),
                  subtitle: Text(type == PinType.pin4
                      ? '4-digit numeric code'
                      : type == PinType.pin6
                          ? '6-digit numeric code (default)'
                          : 'Letters, numbers, and symbols'),
                  onTap: () {
                    notifier.setPinType(type);
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showTimeoutPicker(BuildContext context, AppLockSettings settings,
      AppLockSettingsNotifier notifier) {
    const options = [0, 1, 5, 15, 30, -1];
    const labels = [
      'Immediately',
      '1 minute',
      '5 minutes',
      '15 minutes',
      '30 minutes',
      'Never'
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            const Text('Auto-lock After',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...List.generate(
              options.length,
              (i) => ListTile(
                leading: Icon(
                  settings.timeoutMinutes == options[i]
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: settings.timeoutMinutes == options[i]
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(labels[i]),
                onTap: () {
                  notifier.setTimeout(options[i]);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context,
      String Function(String, [Map<String, dynamic>?]) tr) {
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
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('settings.security.change_password_label'),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            tr('settings.security.password_changed'))),
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

  void _confirmTerminate(
    BuildContext context,
    WidgetRef ref,
    String id,
    String deviceName,
    String Function(String, [Map<String, dynamic>?]) tr,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('settings.security.terminate_session')),
        content: Text(tr(
            'settings.security.terminate_session_confirm',
            {'device': deviceName})),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('common.cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(socialSettingsProvider.notifier)
                  .terminateSession(id);
            },
            child: Text(tr('settings.security.remove'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmTerminateAll(BuildContext context, WidgetRef ref,
      String Function(String, [Map<String, dynamic>?]) tr) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('settings.security.terminate_all_title')),
        content: Text(tr('settings.security.terminate_all_desc')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('common.cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(socialSettingsProvider.notifier)
                  .terminateAllOtherSessions();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        tr('settings.security.all_sessions_terminated'))),
              );
            },
            child: Text(tr('settings.security.terminate_all_other'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── _SessionTile ─────────────────────────────────────────────────────────

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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
          session.platform.contains('Android') ||
                  session.platform.contains('iOS')
              ? Icons.smartphone_rounded
              : session.platform.contains('Mac') ||
                      session.platform.contains('Windows')
                  ? Icons.laptop_rounded
                  : Icons.web_rounded,
          color: session.isCurrent
              ? const Color(0xFF43E97B)
              : const Color(0xFF6C63FF),
          size: 22,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              session.deviceName,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          if (session.isCurrent)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:
                    const Color(0xFF43E97B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                thisDeviceLabel,
                style: const TextStyle(
                    color: Color(0xFF43E97B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
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
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.5))),
          Text('${session.location} • ${session.lastActive}',
              style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.4))),
        ],
      ),
      trailing: onTerminate != null
          ? IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: Colors.red, size: 20),
              onPressed: onTerminate,
              tooltip: terminateTooltip,
            )
          : null,
    );
  }
}

// ── _MethodTile ──────────────────────────────────────────────────────────

class _MethodTile extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? theme.colorScheme.primary : null,
        size: 26,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(sublabel,
          style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
      trailing: selected
          ? Icon(Icons.check_circle_rounded,
              color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
