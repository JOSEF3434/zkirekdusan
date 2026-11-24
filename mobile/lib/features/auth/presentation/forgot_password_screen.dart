// lib/features/auth/presentation/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/data/models/login_policy_model.dart';
import 'package:mobile/features/auth/presentation/providers/login_policy_provider.dart';
import 'package:mobile/features/auth/presentation/providers/recovery_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final recoveryNotifier = ref.read(recoveryProvider.notifier);
    final recoveryState = ref.read(recoveryProvider);

    final identifier = recoveryState.method == RecoveryMethodChoice.email
        ? _emailCtrl.text.trim()
        : _phoneCtrl.text.trim();

    final success = await recoveryNotifier.requestRecovery(identifier: identifier);

    if (success && mounted) {
      if (recoveryState.method == RecoveryMethodChoice.phone) {
        context.push('/verify-otp');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final cs = Theme.of(context).colorScheme;
    final recovery = ref.watch(recoveryProvider);
    final policyAsync = ref.watch(loginPolicyProvider);
    final policy = policyAsync.value ?? const LoginPolicyConfig();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('auth.recovery_title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_reset_rounded,
                          size: 40,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('auth.recovery_title'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('auth.recovery_subtitle'),
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Method Selection Segmented Button
                    if (!policy.allowPasswordReset) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.errorContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cs.error.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: cs.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tr('auth.recovery_disabled'),
                                style: TextStyle(
                                  color: cs.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SegmentedButton<RecoveryMethodChoice>(
                      segments: [
                        ButtonSegment(
                          value: RecoveryMethodChoice.email,
                          label: Text(tr('auth.recovery_method_email')),
                          icon: const Icon(Icons.email_outlined),
                        ),
                        ButtonSegment(
                          value: RecoveryMethodChoice.phone,
                          label: Text(tr('auth.recovery_method_phone')),
                          icon: const Icon(Icons.phone_android_outlined),
                        ),
                      ],
                      selected: {recovery.method},
                      onSelectionChanged: (newSelection) {
                        ref
                            .read(recoveryProvider.notifier)
                            .setMethod(newSelection.first);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Error Banner
                    if (recovery.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: cs.onErrorContainer, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                recovery.errorMessage!,
                                style: TextStyle(
                                  color: cs.onErrorContainer,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Input Field (Email or Phone)
                    if (recovery.method == RecoveryMethodChoice.email) ...[
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: tr('auth.recovery_email_label'),
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return tr('auth.validation.email_required');
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return tr('auth.validation.email_invalid');
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: tr('auth.recovery_phone_label'),
                          helperText: tr('auth.recovery_phone_hint'),
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return tr('auth.validation.phone_invalid');
                          }
                          final digits = v.replaceAll(RegExp(r'[\s\-\+]'), '');
                          if (digits.length < 9 || digits.length > 12) {
                            return tr('auth.validation.phone_invalid');
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Submit Button
                    FilledButton(
                      onPressed: recovery.isLoading || !policy.allowPasswordReset ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: recovery.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              tr('auth.recovery_send_btn'),
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),

                    // Email Info Banner if already sent
                    if (recovery.method == RecoveryMethodChoice.email &&
                        recovery.successMessage != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.mark_email_read_outlined,
                                    color: cs.primary, size: 22),
                                const SizedBox(width: 8),
                                const Text(
                                  'Check Your Inbox',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              recovery.successMessage!,
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: recovery.cooldownSeconds > 0
                                  ? null
                                  : () => ref
                                      .read(recoveryProvider.notifier)
                                      .resendCode(),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              child: Text(
                                recovery.cooldownSeconds > 0
                                    ? tr('auth.resend_cooldown',
                                        {'seconds': recovery.cooldownSeconds})
                                    : tr('auth.resend_code'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(tr('auth.back_to_login')),
                    ),
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
