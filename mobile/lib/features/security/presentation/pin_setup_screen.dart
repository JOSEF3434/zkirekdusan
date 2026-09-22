// lib/features/security/presentation/pin_setup_screen.dart
//
// Two-step PIN setup: enter a new PIN, then confirm it.
// Supports 4-digit PIN, 6-digit PIN, and alphanumeric password.
// Called when enabling App Lock for the first time, or when changing PIN.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/security/data/pin_service.dart';
import 'package:mobile/features/security/data/biometric_service.dart';
import 'package:mobile/features/security/presentation/providers/app_lock_settings_provider.dart';
import 'package:mobile/features/security/presentation/providers/app_lock_provider.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  /// If true, the screen is shown for changing an existing PIN.
  final bool isChange;

  /// Override the initial PinType. Defaults to [PinType.pin6].
  final PinType? initialPinType;

  const PinSetupScreen({
    super.key,
    this.isChange = false,
    this.initialPinType,
  });

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  late PinType _pinType;

  String _firstPin = '';
  String _confirmPin = '';
  bool _confirming = false;
  String? _errorMessage;
  bool _passwordVisible = false;

  final TextEditingController _firstCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pinType = widget.initialPinType ??
        ref.read(appLockSettingsProvider).pinType;
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  int get _pinLength => _pinType.length ?? 0;
  bool get _isPassword => _pinType == PinType.password;

  // ── Digit pad handlers (numeric modes) ──────────────────────────────────

  void _onDigitTap(String digit) {
    if (_isPassword) return;
    setState(() {
      _errorMessage = null;
      if (!_confirming) {
        if (_firstPin.length < _pinLength) {
          _firstPin += digit;
          if (_firstPin.length == _pinLength) {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) setState(() => _confirming = true);
            });
          }
        }
      } else {
        if (_confirmPin.length < _pinLength) {
          _confirmPin += digit;
          if (_confirmPin.length == _pinLength) {
            _submit();
          }
        }
      }
    });
  }

  void _onBackspace() {
    if (_isPassword) return;
    setState(() {
      _errorMessage = null;
      if (_confirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _confirming = false;
          _firstPin = '';
        }
      } else {
        if (_firstPin.isNotEmpty) {
          _firstPin = _firstPin.substring(0, _firstPin.length - 1);
        }
      }
    });
  }

  // ── Password mode next step ─────────────────────────────────────────────

  void _onPasswordNext() {
    final value = _firstCtrl.text.trim();
    if (value.isEmpty) {
      setState(() => _errorMessage = 'Please enter a password.');
      return;
    }
    setState(() {
      _firstPin = value;
      _confirming = true;
      _errorMessage = null;
    });
  }

  void _onPasswordConfirm() {
    final value = _confirmCtrl.text.trim();
    if (value.isEmpty) {
      setState(() => _errorMessage = 'Please confirm your password.');
      return;
    }
    _confirmPin = value;
    _submit();
  }

  // ── Submit ──────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final first = _isPassword ? _firstPin : _firstPin;
    final confirm = _isPassword ? _confirmCtrl.text.trim() : _confirmPin;

    if (first != confirm) {
      setState(() {
        _errorMessage = '${_isPassword ? "Passwords" : "PINs"} do not match. Please try again.';
        _confirming = false;
        _firstPin = '';
        _confirmPin = '';
        _firstCtrl.clear();
        _confirmCtrl.clear();
      });
      return;
    }

    final pinService = ref.read(pinServiceProvider);
    await pinService.setPin(first, type: _pinType);

    // Persist selected PinType in settings
    await ref.read(appLockSettingsProvider.notifier).setPinType(_pinType);
    await ref.read(appLockSettingsProvider.notifier).setEnabled(true);

    // If not a change and biometrics available → use biometricWithPin
    if (!widget.isChange) {
      final biometricService = ref.read(biometricServiceProvider);
      final hasBiometrics = await biometricService.isAvailable();
      if (hasBiometrics) {
        await ref
            .read(appLockSettingsProvider.notifier)
            .setMethod(AppLockMethod.biometricWithPin);
      } else {
        await ref
            .read(appLockSettingsProvider.notifier)
            .setMethod(AppLockMethod.pin);
      }
    }

    ref.read(appLockProvider.notifier).onPinSet();
    if (mounted) Navigator.of(context).pop(true);
  }

  // ── Reset on type change ───────────────────────────────────────────────

  void _changePinType(PinType type) {
    setState(() {
      _pinType = type;
      _firstPin = '';
      _confirmPin = '';
      _confirming = false;
      _errorMessage = null;
      _firstCtrl.clear();
      _confirmCtrl.clear();
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF0F4FF);
    final currentPin = _confirming ? _confirmPin : _firstPin;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () {
            if (_confirming) {
              setState(() {
                _confirming = false;
                _confirmPin = '';
                _confirmCtrl.clear();
              });
            } else {
              Navigator.of(context).pop(false);
            }
          },
        ),
        title: Text(
          widget.isChange ? 'Change Passcode' : 'Set Up Passcode',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
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

                  // ── Passcode type selector (chips) ──────────────────
                  if (!_confirming) ...[
                    _PinTypeSelector(
                      selected: _pinType,
                      onChanged: _changePinType,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Lock icon ───────────────────────────────────────
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.primary.withValues(alpha: 0.2),
                          cs.primary.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: cs.primary.withValues(alpha: 0.3)),
                    ),
                    child: Icon(
                      _isPassword
                          ? Icons.password_rounded
                          : Icons.lock_rounded,
                      color: cs.primary,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Title ───────────────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _confirming
                          ? 'Confirm your ${_pinType.label}'
                          : 'Choose a ${_pinType.label}',
                      key: ValueKey('$_confirming-$_pinType'),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _confirming
                          ? 'Re-enter the same ${_pinType.label} to confirm'
                          : 'This will lock the app when you\'re away',
                      key: ValueKey('sub-$_confirming-$_pinType'),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Password mode ────────────────────────────────────
                  if (_isPassword) ...[
                    _PasswordField(
                      controller: _confirming ? _confirmCtrl : _firstCtrl,
                      visible: _passwordVisible,
                      label: _confirming ? 'Confirm password' : 'Enter password',
                      onToggle: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                      onSubmit: _confirming
                          ? _onPasswordConfirm
                          : _onPasswordNext,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _confirming
                            ? _onPasswordConfirm
                            : _onPasswordNext,
                        child: Text(
                          _confirming ? 'Confirm' : 'Next',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ] else ...[
                    // ── PIN dot indicators ──────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pinLength, (i) {
                        final filled = i < currentPin.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: filled ? 16 : 12,
                          height: filled ? 16 : 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? cs.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: filled
                                  ? cs.primary
                                  : (isDark
                                      ? Colors.white38
                                      : Colors.black26),
                              width: 2,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],

                  // ── Error message ────────────────────────────────────
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      margin:
                          const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (!_isPassword) ...[
                    const SizedBox(height: 28),
                    _NumPad(
                        onDigit: _onDigitTap, onBackspace: _onBackspace),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── PIN type selector chips ───────────────────────────────────────────────

class _PinTypeSelector extends StatelessWidget {
  final PinType selected;
  final void Function(PinType) onChanged;

  const _PinTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: PinType.values.map((type) {
        final isSelected = type == selected;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(
              type == PinType.pin4
                  ? '4-Digit'
                  : type == PinType.pin6
                      ? '6-Digit'
                      : 'Password',
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : cs.onSurface,
              ),
            ),
            selected: isSelected,
            selectedColor: cs.primary,
            backgroundColor: cs.surfaceContainerHigh,
            onSelected: (_) => onChanged(type),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        );
      }).toList(),
    );
  }
}

// ── Password field ────────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool visible;
  final String label;
  final VoidCallback onToggle;
  final VoidCallback onSubmit;

  const _PasswordField({
    required this.controller,
    required this.visible,
    required this.label,
    required this.onToggle,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      obscureText: !visible,
      autofocus: true,
      onSubmitted: (_) => onSubmit(),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
              visible ? Icons.visibility_off_rounded : Icons.visibility_rounded),
          onPressed: onToggle,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),
    );
  }
}

// ── Numeric Keypad ─────────────────────────────────────────────────────────

class _NumPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  const _NumPad({required this.onDigit, required this.onBackspace});

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
                      .map((d) =>
                          _DialButton(label: d, onTap: () => onDigit(d)))
                      .toList(),
                ),
              )),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(width: 64, height: 64),
                _DialButton(label: '0', onTap: () => onDigit('0')),
                _BackspaceButton(onTap: onBackspace),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DialButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
            color: cs.surfaceContainerHigh,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _BackspaceButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackspaceButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Icon(Icons.backspace_outlined,
              color: cs.onSurface, size: 24),
        ),
      ),
    );
  }
}
