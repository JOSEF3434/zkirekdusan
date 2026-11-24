// lib/features/auth/presentation/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/data/models/login_policy_model.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/auth/presentation/providers/login_policy_provider.dart';
import 'package:mobile/features/auth/presentation/widgets/google_sign_in_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _hasNavigated = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(authProvider.notifier).clearError();

    final username = _usernameCtrl.text.trim();

    ref
        .read(authProvider.notifier)
        .register(
          email: _emailCtrl.text.trim(),
          username: username.isNotEmpty ? username : null,
          firstName: _firstNameCtrl.text.trim().isNotEmpty
              ? _firstNameCtrl.text.trim()
              : null,
          lastName: _lastNameCtrl.text.trim().isNotEmpty
              ? _lastNameCtrl.text.trim()
              : null,
          password: _passwordCtrl.text,
        );
  }

  void _handleGoogleSignIn() {
    ref.read(authProvider.notifier).clearError();
    ref.read(authProvider.notifier).signInWithGoogle();
  }

  void _showLinkAccountDialog(
    BuildContext context,
    String Function(String) tr,
  ) {
    final linkPasswordCtrl = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(tr('auth.link_google_title')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('auth.link_google_desc'),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: linkPasswordCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: tr('auth.password_label'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setDialogState(() => obscure = !obscure),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  ref.read(authProvider.notifier).clearPendingGoogle();
                  Navigator.of(dialogCtx).pop();
                },
                child: Text(tr('auth.link_google_cancel')),
              ),
              FilledButton(
                onPressed: () async {
                  final pwd = linkPasswordCtrl.text.trim();
                  if (pwd.isEmpty) return;
                  Navigator.of(dialogCtx).pop();
                  await ref
                      .read(authProvider.notifier)
                      .linkGoogleAccountWithPassword(pwd);
                },
                child: Text(tr('auth.link_google_btn')),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final cs = Theme.of(context).colorScheme;
    final authState = ref.watch(authProvider);
    final policyAsync = ref.watch(loginPolicyProvider);
    final policy = policyAsync.value ?? const LoginPolicyConfig();

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated && !_hasNavigated) {
        _hasNavigated = true;
        context.go('/home');
      } else if (next.pendingGoogleIdToken != null &&
          previous?.pendingGoogleIdToken != next.pendingGoogleIdToken) {
        _showLinkAccountDialog(context, tr);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
        title: Text(tr('auth.register')),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.stream_rounded,
                              size: 48,
                              color: cs.primary,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Error banner
                    if (authState.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: cs.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authState.error!,
                                style: TextStyle(color: cs.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // First name + Last name row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameCtrl,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: tr('auth.first_name_label'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            // firstName is optional — no validator
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameCtrl,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: tr('auth.last_name_label'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            // lastName is optional — no validator
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Email (required)
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: tr('auth.email_label'),
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return tr('auth.validation.email_required');
                        }
                        if (!RegExp(
                          r'^[^@]+@[^@]+\.[^@]+',
                        ).hasMatch(v.trim())) {
                          return tr('auth.validation.email_invalid');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Username (optional)
                    TextFormField(
                      controller: _usernameCtrl,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: tr('auth.username_label'),
                        helperText: tr('auth.username_helper'),
                        prefixIcon: const Icon(Icons.alternate_email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return null; // optional
                        }
                        if (v.trim().length < 3) {
                          return tr('auth.validation.username_min_length');
                        }
                        if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(v.trim())) {
                          return tr('auth.validation.username_chars');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: tr('auth.password_required_label'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return tr('auth.validation.password_required');
                        }
                        if (v.length < 8) {
                          return tr('auth.validation.password_min_length');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm password
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: tr('auth.password_confirm_label'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v != _passwordCtrl.text) {
                          return tr('auth.validation.passwords_mismatch');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit
                    FilledButton(
                      onPressed: authState.isAnyLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              tr('auth.register'),
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                    if (policy.allowGoogleAuth) ...[
                      const SizedBox(height: 18),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: cs.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              tr('auth.or_divider'),
                              style: TextStyle(
                                color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: cs.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Google Sign-In Button
                      GoogleSignInButton(
                        text: tr('auth.continue_with_google'),
                        isLoading: authState.isGoogleLoading,
                        onPressed:
                            authState.isAnyLoading ? null : _handleGoogleSignIn,
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Sign in link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tr('auth.have_account'),
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            tr('auth.sign_in'),
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
