// lib/features/security/presentation/app_lock_screen.dart
//
// Full-screen app lock overlay — Telegram-inspired biometric-first design.
//
// Flow:
//   • biometric / biometricWithPin  → biometric prompt fires automatically on open.
//     After 5 biometric failures, switches to PIN/pattern entry automatically.
//     User can also tap "Use PIN/Pattern instead" at any time.
//   • pin                           → PIN keypad shown directly.
//   • pattern                       → Pattern grid shown directly.
//
// Brute-force guard: 5 wrong PIN/pattern → 30-second cooldown.
// 10 wrong attempts → force logout.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/security/presentation/providers/app_lock_provider.dart';
import 'package:mobile/features/security/presentation/providers/app_lock_settings_provider.dart';
import 'package:mobile/features/security/presentation/widgets/pattern_lock_widget.dart';
import 'package:mobile/features/security/data/pin_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen>
    with WidgetsBindingObserver {
  // ── State ──────────────────────────────────────────────────────────────

  String _pin = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _showFallback = false; // true = show PIN/pattern instead of biometric

  // Password visibility for alphanumeric mode
  bool _passwordVisible = false;
  final TextEditingController _passwordCtrl = TextEditingController();

  // Cooldown countdown
  Timer? _cooldownTimer;
  int _cooldownSecondsLeft = 0;

  // Pattern state
  PatternLockState _patternState = PatternLockState.idle;
  final GlobalKey<PatternLockWidgetState> _patternKey = GlobalKey();

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
    _passwordCtrl.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Biometric auto-trigger ─────────────────────────────────────────────

  Future<void> _tryBiometricIfAvailable() async {
    final settings = ref.read(appLockSettingsProvider);
    if (settings.method.usesBiometric) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted && !_showFallback) _authenticateWithBiometric();
    }
  }

  // ── Cooldown timer ─────────────────────────────────────────────────────

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

  // ── PIN handlers ───────────────────────────────────────────────────────

  void _onDigitTap(String digit) {
    if (_isLoading) return;
    final lockState = ref.read(appLockProvider);
    if (lockState.isInCooldown) return;

    final settings = ref.read(appLockSettingsProvider);
    final expectedLen = settings.pinType.length; // null for password

    setState(() {
      _errorMessage = null;
      if (expectedLen == null || _pin.length < expectedLen) {
        _pin += digit;
        if (expectedLen != null && _pin.length == expectedLen) _verifyPin();
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
    final settings = ref.read(appLockSettingsProvider);

    // For password mode, read from text controller
    final pinToVerify = settings.pinType == PinType.password
        ? _passwordCtrl.text
        : _pin;

    if (pinToVerify.isEmpty) return;
    setState(() => _isLoading = true);

    final success =
        await ref.read(appLockProvider.notifier).verifyPin(pinToVerify);

    if (!mounted) return;

    final lockState = ref.read(appLockProvider);

    if (!success) {
      setState(() {
        _pin = '';
        _passwordCtrl.clear();
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
    } else {
      setState(() => _isLoading = false);
    }
  }

  // ── Biometric auth ─────────────────────────────────────────────────────

  Future<void> _authenticateWithBiometric() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    await ref.read(appLockProvider.notifier).authenticateWithBiometric();

    if (!mounted) return;

    final lockState = ref.read(appLockProvider);
    setState(() => _isLoading = false);

    // After 5 biometric failures → auto-switch to fallback
    if (lockState.biometricExhausted && !_showFallback) {
      setState(() {
        _showFallback = true;
        _errorMessage =
            'Biometric unavailable. Use your PIN or pattern instead.';
      });
    }
  }

  // ── Pattern handler ────────────────────────────────────────────────────

  Future<void> _onPatternComplete(List<int> nodes) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _patternState = PatternLockState.active;
    });

    final success =
        await ref.read(appLockProvider.notifier).verifyPattern(nodes);

    if (!mounted) return;

    final lockState = ref.read(appLockProvider);

    if (success) {
      setState(() => _patternState = PatternLockState.success);
    } else {
      setState(() {
        _isLoading = false;
        _patternState = PatternLockState.error;
      });

      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;

      _patternKey.currentState?.reset();
      setState(() => _patternState = PatternLockState.idle);

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
              ? 'Wrong pattern. $remaining attempt${remaining == 1 ? '' : 's'} left.'
              : 'Wrong pattern.';
        });
      }
    }
  }

  // ── Forgot / Force logout ──────────────────────────────────────────────

  void _showForgotDialog() {
    final settings = ref.read(appLockSettingsProvider);
    final what = settings.method.usesPattern ? 'Pattern' : 'PIN';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Forgot $what?',
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
      if (mounted) context.go('/login');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);
    final settings = ref.watch(appLockSettingsProvider);

    // Auto-switch when biometric is exhausted
    if (lockState.biometricExhausted && !_showFallback) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showFallback = true);
      });
    }

    if (lockState.status != AppLockStatus.locked) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox.shrink(),
      );
    }

    final isBiometricFirst =
        settings.method.usesBiometric && !_showFallback;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E1A), Color(0xFF111827)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: isBiometricFirst
                      ? _BiometricPanel(
                          key: const ValueKey('biometric'),
                          lockState: lockState,
                          settings: settings,
                          isLoading: _isLoading,
                          errorMessage: _errorMessage,
                          onBiometricTap: _authenticateWithBiometric,
                          onSwitchToFallback: () =>
                              setState(() => _showFallback = true),
                          onForgot: _showForgotDialog,
                        )
                      : settings.method.usesPattern
                          ? _PatternPanel(
                              key: const ValueKey('pattern'),
                              lockState: lockState,
                              patternState: _patternState,
                              patternKey: _patternKey,
                              errorMessage: _errorMessage,
                              cooldownSecondsLeft: _cooldownSecondsLeft,
                              onPatternComplete: _onPatternComplete,
                              onForgot: _showForgotDialog,
                              showBiometricSwitch:
                                  settings.method.usesBiometric,
                              onSwitchToBiometric: () => setState(() {
                                _showFallback = false;
                                _errorMessage = null;
                              }),
                            )
                          : _PinPanel(
                              key: const ValueKey('pin'),
                              lockState: lockState,
                              settings: settings,
                              pin: _pin,
                              isLoading: _isLoading,
                              errorMessage: _errorMessage,
                              cooldownSecondsLeft: _cooldownSecondsLeft,
                              passwordCtrl: _passwordCtrl,
                              passwordVisible: _passwordVisible,
                              onDigit: _onDigitTap,
                              onBackspace: _onBackspace,
                              onSubmitPassword: _verifyPin,
                              onTogglePasswordVisibility: () => setState(
                                  () => _passwordVisible = !_passwordVisible),
                              onForgot: _showForgotDialog,
                              showBiometricSwitch:
                                  settings.method.usesBiometric,
                              onSwitchToBiometric: () => setState(() {
                                _showFallback = false;
                                _errorMessage = null;
                              }),
                            ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Biometric panel ────────────────────────────────────────────────────────

class _BiometricPanel extends ConsumerWidget {
  final AppLockState lockState;
  final AppLockSettings settings;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onBiometricTap;
  final VoidCallback onSwitchToFallback;
  final VoidCallback onForgot;

  const _BiometricPanel({
    super.key,
    required this.lockState,
    required this.settings,
    required this.isLoading,
    required this.errorMessage,
    required this.onBiometricTap,
    required this.onSwitchToFallback,
    required this.onForgot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricType = ref.watch(biometricHardwareTypeProvider);

    final biometricIcon = biometricType.when(
      data: (type) => type == BiometricHardwareType.face
          ? Icons.face_rounded
          : Icons.fingerprint_rounded,
      loading: () => Icons.fingerprint_rounded,
      error: (_, _) => Icons.fingerprint_rounded,
    );

    final biometricLabel = biometricType.when(
      data: (type) => type == BiometricHardwareType.face ? 'Face ID' : 'Touch ID',
      loading: () => 'Biometric',
      error: (_, _) => 'Biometric',
    );

    final fallbackLabel = settings.method == AppLockMethod.biometricWithPin
        ? 'Use PIN instead'
        : 'Use Passcode instead';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        _AppLogo(),
        const SizedBox(height: 20),
        const Text(
          'ዝክረ ቅዱሳን',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Verify your identity to continue',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
        ),
        const SizedBox(height: 40),

        // Biometric button
        _PulsatingBiometricButton(
          icon: biometricIcon,
          label: biometricLabel,
          isLoading: isLoading,
          onTap: onBiometricTap,
        ),
        const SizedBox(height: 24),

        // Error message
        if (errorMessage != null) _ErrorBanner(message: errorMessage!),

        const SizedBox(height: 20),

        // Switch to PIN/pattern
        TextButton(
          onPressed: onSwitchToFallback,
          child: Text(
            fallbackLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        TextButton(
          onPressed: onForgot,
          child: Text(
            'Forgot? Log out',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── PIN panel ──────────────────────────────────────────────────────────────

class _PinPanel extends StatelessWidget {
  final AppLockState lockState;
  final AppLockSettings settings;
  final String pin;
  final bool isLoading;
  final String? errorMessage;
  final int cooldownSecondsLeft;
  final TextEditingController passwordCtrl;
  final bool passwordVisible;
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmitPassword;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onForgot;
  final bool showBiometricSwitch;
  final VoidCallback onSwitchToBiometric;

  const _PinPanel({
    super.key,
    required this.lockState,
    required this.settings,
    required this.pin,
    required this.isLoading,
    required this.errorMessage,
    required this.cooldownSecondsLeft,
    required this.passwordCtrl,
    required this.passwordVisible,
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmitPassword,
    required this.onTogglePasswordVisibility,
    required this.onForgot,
    required this.showBiometricSwitch,
    required this.onSwitchToBiometric,
  });

  @override
  Widget build(BuildContext context) {
    final isPassword = settings.pinType == PinType.password;
    final pinLength = settings.pinType.length ?? 6;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        _AppLogo(),
        const SizedBox(height: 16),
        const Text(
          'ዝክረ ቅዱሳን',
          style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          isPassword ? 'Enter your passcode' : 'Enter your PIN to continue',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
        ),
        const SizedBox(height: 28),

        if (isPassword) ...[
          // Text-field mode for alphanumeric password
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: TextField(
              controller: passwordCtrl,
              obscureText: !passwordVisible,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
              autofocus: true,
              onSubmitted: (_) => onSubmitPassword(),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                hintText: 'Password',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3), fontSize: 16),
                suffixIcon: IconButton(
                  icon: Icon(
                    passwordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  onPressed: onTogglePasswordVisibility,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmitPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Unlock',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ] else ...[
          // Dot indicators
          _PinDots(filled: pin.length, total: pinLength),
          const SizedBox(height: 8),
        ],

        // Error / cooldown banner
        if (errorMessage != null || cooldownSecondsLeft > 0)
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: _ErrorBanner(
              message: cooldownSecondsLeft > 0
                  ? 'Too many attempts. Wait ${cooldownSecondsLeft}s'
                  : errorMessage ?? '',
            ),
          ),

        if (!isPassword) ...[
          const SizedBox(height: 20),
          _LockNumPad(
            onDigit: onDigit,
            onBackspace: onBackspace,
            disabled: isLoading || lockState.isInCooldown,
          ),
        ],

        const SizedBox(height: 16),

        // Switch back to biometric if available
        if (showBiometricSwitch)
          TextButton.icon(
            onPressed: onSwitchToBiometric,
            icon: const Icon(Icons.fingerprint_rounded,
                color: Colors.white54, size: 18),
            label: Text(
              'Use Biometric instead',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            ),
          ),

        TextButton(
          onPressed: onForgot,
          child: Text(
            'Forgot PIN? Log out',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Pattern panel ──────────────────────────────────────────────────────────

class _PatternPanel extends StatelessWidget {
  final AppLockState lockState;
  final PatternLockState patternState;
  final GlobalKey<PatternLockWidgetState> patternKey;
  final String? errorMessage;
  final int cooldownSecondsLeft;
  final PatternCompleteCallback onPatternComplete;
  final VoidCallback onForgot;
  final bool showBiometricSwitch;
  final VoidCallback onSwitchToBiometric;

  const _PatternPanel({
    super.key,
    required this.lockState,
    required this.patternState,
    required this.patternKey,
    required this.errorMessage,
    required this.cooldownSecondsLeft,
    required this.onPatternComplete,
    required this.onForgot,
    required this.showBiometricSwitch,
    required this.onSwitchToBiometric,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        _AppLogo(),
        const SizedBox(height: 16),
        const Text(
          'ዝክረ ቅዱሳን',
          style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Draw your unlock pattern',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
        ),
        const SizedBox(height: 32),

        // Pattern grid
        PatternLockWidget(
          key: patternKey,
          onPatternComplete: onPatternComplete,
          lockState: patternState,
          disabled: lockState.isInCooldown,
          size: 270,
        ),

        // Error / cooldown
        if (errorMessage != null || cooldownSecondsLeft > 0)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _ErrorBanner(
              message: cooldownSecondsLeft > 0
                  ? 'Too many attempts. Wait ${cooldownSecondsLeft}s'
                  : errorMessage ?? '',
            ),
          ),

        const SizedBox(height: 20),

        // Switch back to biometric
        if (showBiometricSwitch)
          TextButton.icon(
            onPressed: onSwitchToBiometric,
            icon: const Icon(Icons.fingerprint_rounded,
                color: Colors.white54, size: 18),
            label: Text(
              'Use Biometric instead',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            ),
          ),

        TextButton(
          onPressed: onForgot,
          child: Text(
            'Forgot pattern? Log out',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Shared sub-widgets ─────────────────────────────────────────────────────

class _AppLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
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
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.lock_rounded, color: Colors.white, size: 36),
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  final int filled;
  final int total;

  const _PinDots({required this.filled, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isFilled = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 7),
          width: isFilled ? 16 : 12,
          height: isFilled ? 16 : 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? Colors.white : Colors.white.withValues(alpha: 0.2),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.45), width: 1.5),
          ),
        );
      }),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsatingBiometricButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _PulsatingBiometricButton({
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_PulsatingBiometricButton> createState() =>
      _PulsatingBiometricButtonState();
}

class _PulsatingBiometricButtonState extends State<_PulsatingBiometricButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScaleTransition(
          scale: _scale,
          child: GestureDetector(
            onTap: widget.isLoading ? null : widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6C63FF).withValues(alpha: 0.35),
                    const Color(0xFF6C63FF).withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: widget.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white70),
                    )
                  : Icon(widget.icon, color: Colors.white, size: 48),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          widget.isLoading ? 'Verifying…' : 'Tap to use ${widget.label}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Numeric keypad ─────────────────────────────────────────────────────────

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
                    label: '0',
                    onTap: disabled ? null : () => onDigit('0')),
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
            color: Colors.white.withValues(alpha: 0.07),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.13), width: 1),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: onTap != null
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.25),
            ),
          ),
        ),
      ),
    );
  }
}
