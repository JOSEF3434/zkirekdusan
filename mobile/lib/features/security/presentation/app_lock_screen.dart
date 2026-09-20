// lib/features/security/presentation/app_lock_screen.dart
//
// Full-screen app lock overlay shown when AppLockStatus == locked.
// Supports PIN entry, biometric unlock, cooldown timer, brute-force guard,
// and a "Forgot PIN → Logout" escape hatch.
// Design: dark glassmorphism with gradient, matching the app's premium aesthetic.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/security/presentation/providers/app_lock_provider.dart';
import 'package:mobile/features/security/presentation/providers/app_lock_settings_provider.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen>
    with WidgetsBindingObserver {
  String _pin = '';
  bool _isLoading = false;
  String? _errorMessage;

  // Cooldown countdown
  Timer? _cooldownTimer;
  int _cooldownSecondsLeft = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tryBiometricIfAvailable();
    _startCooldownIfNeeded();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Auto-trigger biometric prompt on screen open
  Future<void> _tryBiometricIfAvailable() async {
    final settings = ref.read(appLockSettingsProvider);
    if (settings.method == AppLockMethod.biometric ||
        settings.method == AppLockMethod.biometricWithPin) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _authenticateWithBiometric();
    }
  }

  void _startCooldownIfNeeded() {
    final lockState = ref.read(appLockProvider);
    if (lockState.isInCooldown && lockState.cooldownUntil != null) {
      _updateCooldown(lockState.cooldownUntil!);
    }
  }

  void _updateCooldown(DateTime until) {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final left = until.difference(DateTime.now()).inSeconds;
      setState(() => _cooldownSecondsLeft = left > 0 ? left : 0);
      if (left <= 0) {
        _cooldownTimer?.cancel();
        setState(() => _cooldownSecondsLeft = 0);
      }
    });
  }

  void _onDigitTap(String digit) {
    if (_isLoading) return;
    final lockState = ref.read(appLockProvider);
    if (lockState.isInCooldown) return;

    setState(() {
      _errorMessage = null;
      if (_pin.length < 6) {
        _pin += digit;
        if (_pin.length == 6) _verifyPin();
      }
    });
  }

  void _onBackspace() {
    if (_isLoading) return;
    setState(() {
      _errorMessage = null;
      if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _verifyPin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final success =
        await ref.read(appLockProvider.notifier).verifyPin(_pin);

    if (!mounted) return;

    final lockState = ref.read(appLockProvider);

    if (success) {
      // Unlocked — router redirect handles navigation
    } else {
      setState(() {
        _pin = '';
        _isLoading = false;
      });

      if (lockState.shouldForceLogout) {
        _forceLogout();
        return;
      }

      if (lockState.isInCooldown && lockState.cooldownUntil != null) {
        _updateCooldown(lockState.cooldownUntil!);
        setState(() {
          _errorMessage = 'Too many attempts. Wait ${_cooldownSecondsLeft}s.';
        });
      } else {
        final remaining = kMaxAttempts - lockState.failedAttempts;
        setState(() {
          _errorMessage = remaining > 0
              ? 'Wrong PIN. $remaining attempt${remaining == 1 ? '' : 's'} left.'
              : 'Wrong PIN.';
        });
      }
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    await ref.read(appLockProvider.notifier).authenticateWithBiometric();
    if (mounted) setState(() => _isLoading = false);
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Forgot PIN?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'You will be logged out of the app. You can log back in with your account credentials.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _forceLogout();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _forceLogout() async {
    await ref.read(appLockProvider.notifier).disable();
    await ref.read(appLockSettingsProvider.notifier).disable();
    if (mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);
    final settings = ref.watch(appLockSettingsProvider);
    final biometricAvailable = ref.watch(biometricAvailableProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // If unlocked → router should redirect; show blank while transitioning
    if (lockState.status != AppLockStatus.locked) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox.shrink(),
      );
    }

    final showBiometric =
        settings.method == AppLockMethod.biometric ||
            settings.method == AppLockMethod.biometricWithPin;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0A0E1A), const Color(0xFF111827)]
                : [const Color(0xFF1A237E), const Color(0xFF283593)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    // App logo + title
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.lock_rounded,
                              color: Colors.white, size: 36),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'ዝክረ ቅዱሳን',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter your PIN to continue',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // PIN dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (i) {
                        final filled = i < _pin.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: filled ? 16 : 12,
                          height: filled ? 16 : 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.25),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                        );
                      }),
                    ),

                    // Error / cooldown message
                    if (_errorMessage != null || _cooldownSecondsLeft > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.red.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.redAccent, size: 16),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _cooldownSecondsLeft > 0
                                    ? 'Too many attempts. Wait ${_cooldownSecondsLeft}s'
                                    : _errorMessage ?? '',
                                style: const TextStyle(
                                    color: Colors.redAccent, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Biometric button (if available)
                    if (showBiometric)
                      biometricAvailable.when(
                        data: (available) => available
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: IconButton(
                                  iconSize: 42,
                                  onPressed: _authenticateWithBiometric,
                                  icon: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: const Icon(Icons.fingerprint_rounded,
                                        color: Colors.white, size: 36),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (error, stackTrace) => const SizedBox.shrink(),
                      ),

                    // Number Pad
                    _LockNumPad(
                      onDigit: _onDigitTap,
                      onBackspace: _onBackspace,
                      disabled: _isLoading || lockState.isInCooldown,
                    ),
                    const SizedBox(height: 16),

                    // Forgot PIN
                    TextButton(
                      onPressed: _showForgotPinDialog,
                      child: Text(
                        'Forgot PIN? Log out',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Numeric Keypad ─────────────────────────────────────────────────────────

class _LockNumPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final bool disabled;

  const _LockNumPad({
    required this.onDigit,
    required this.onBackspace,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    const digits = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...digits.map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row
                      .map((d) => _LockDialButton(
                            label: d,
                            onTap: disabled ? null : () => onDigit(d),
                          ))
                      .toList(),
                ),
              )),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(width: 64, height: 64),
                _LockDialButton(
                    label: '0', onTap: disabled ? null : () => onDigit('0')),
                SizedBox(
                  width: 64,
                  height: 64,
                  child: IconButton(
                    onPressed: disabled ? null : onBackspace,
                    icon: Icon(
                      Icons.backspace_outlined,
                      color: disabled
                          ? Colors.white24
                          : Colors.white.withValues(alpha: 0.8),
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LockDialButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _LockDialButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: onTap != null
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}
