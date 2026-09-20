// lib/features/security/presentation/pin_setup_screen.dart
//
// Two-step PIN setup: enter a new 6-digit PIN, then confirm it.
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

  const PinSetupScreen({super.key, this.isChange = false});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  static const _pinLength = 6;

  String _firstPin = '';
  String _confirmPin = '';
  bool _confirming = false;
  String? _errorMessage;

  void _onDigitTap(String digit) {
    setState(() {
      _errorMessage = null;
      if (!_confirming) {
        if (_firstPin.length < _pinLength) {
          _firstPin += digit;
          if (_firstPin.length == _pinLength) {
            // Auto-advance to confirm step
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
    setState(() {
      _errorMessage = null;
      if (_confirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          // Go back to first PIN entry
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

  Future<void> _submit() async {
    if (_firstPin != _confirmPin) {
      setState(() {
        _errorMessage = 'PINs do not match. Please try again.';
        _confirming = false;
        _firstPin = '';
        _confirmPin = '';
      });
      return;
    }

    final pinService = ref.read(pinServiceProvider);
    await pinService.setPin(_firstPin);

    // Enable App Lock in settings
    await ref.read(appLockSettingsProvider.notifier).setEnabled(true);

    // If setting up for the first time and device supports biometrics, enable biometricWithPin
    if (!widget.isChange) {
      final biometricService = ref.read(biometricServiceProvider);
      final hasBiometrics = await biometricService.isAvailable();
      if (hasBiometrics) {
        await ref
            .read(appLockSettingsProvider.notifier)
            .setMethod(AppLockMethod.biometricWithPin);
      }
    }

    // Notify lock provider that PIN was set
    ref.read(appLockProvider.notifier).onPinSet();

    if (mounted) Navigator.of(context).pop(true);
  }

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
              });
            } else {
              Navigator.of(context).pop(false);
            }
          },
        ),
        title: Text(
          widget.isChange ? 'Change PIN' : 'Set Up PIN',
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

                  // Icon
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
                      border:
                          Border.all(color: cs.primary.withValues(alpha: 0.3)),
                    ),
                    child:
                        Icon(Icons.lock_rounded, color: cs.primary, size: 34),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    _confirming ? 'Confirm your PIN' : 'Choose a 6-digit PIN',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _confirming
                        ? 'Re-enter the same PIN to confirm'
                        : 'This PIN will lock the app when you\'re away',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // PIN dots
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
                          color: filled ? cs.primary : Colors.transparent,
                          border: Border.all(
                            color: filled
                                ? cs.primary
                                : (isDark ? Colors.white38 : Colors.black26),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
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

                  const SizedBox(height: 28),

                  // Number Pad
                  _NumPad(onDigit: _onDigitTap, onBackspace: _onBackspace),
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
          child: Icon(Icons.backspace_outlined, color: cs.onSurface, size: 24),
        ),
      ),
    );
  }
}
