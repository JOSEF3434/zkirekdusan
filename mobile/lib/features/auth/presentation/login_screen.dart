// lib/features/auth/presentation/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/data/models/login_policy_model.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/auth/presentation/providers/login_policy_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Single identifier field (used when any permitted identifier is allowed)
  final _identifierCtrl = TextEditingController();

  // Distinct identifier fields (used in Dual/All modes or single-exclusive modes)
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();

  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _hasNavigated = false;
  bool _rememberMe = true; // Default ON — professional UX

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit(LoginPolicyConfig policy) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(authProvider.notifier).clearError();

    final password = _passwordCtrl.text;
    String? email;
    String? phone;
    String? username;

    if (policy.isSingle) {
      final isEmailOnly =
          policy.allowEmail && !policy.allowPhone && !policy.allowUsername;
      final isPhoneOnly =
          !policy.allowEmail && policy.allowPhone && !policy.allowUsername;
      final isUsernameOnly =
          !policy.allowEmail && !policy.allowPhone && policy.allowUsername;

      if (isEmailOnly) {
        email = _emailCtrl.text.trim();
      } else if (isPhoneOnly) {
        phone = _phoneCtrl.text.trim();
      } else if (isUsernameOnly) {
        username = _usernameCtrl.text.trim();
      } else {
        // Multi-identifier single input field
        final raw = _identifierCtrl.text.trim();
        final cleanDigits = raw.replaceAll(RegExp(r'[\s\-]'), '');
        final isPhoneMatch = (raw.startsWith('+') ||
                RegExp(r'^[0-9]{7,15}$').hasMatch(cleanDigits)) &&
            !raw.contains(RegExp(r'[a-zA-Z]'));

        if (raw.contains('@') && policy.allowEmail) {
          email = raw;
        } else if (isPhoneMatch && policy.allowPhone) {
          phone = cleanDigits;
        } else if (policy.allowUsername) {
          username = raw;
        } else if (policy.allowEmail) {
          email = raw;
        } else if (policy.allowPhone) {
          phone = cleanDigits;
        }
      }
    } else if (policy.isDual) {
      final combo = policy.dualCombination ?? 'EMAIL_PHONE';
      if (combo == 'EMAIL_PHONE') {
        email = _emailCtrl.text.trim();
        phone = _phoneCtrl.text.trim();
      } else if (combo == 'EMAIL_USERNAME') {
        email = _emailCtrl.text.trim();
        username = _usernameCtrl.text.trim();
      } else {
        phone = _phoneCtrl.text.trim();
        username = _usernameCtrl.text.trim();
      }
    } else if (policy.isAll) {
      email = _emailCtrl.text.trim();
      phone = _phoneCtrl.text.trim();
      username = _usernameCtrl.text.trim();
    }

    ref.read(authProvider.notifier).login(
          email: email,
          phoneNumber: phone,
          username: username,
          password: password,
          rememberMe: _rememberMe,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final policyAsync = ref.watch(loginPolicyProvider);
    final policy = policyAsync.value ??
        const LoginPolicyConfig(
          activePolicy: 'SINGLE_IDENTIFIER',
          allowEmail: true,
          allowPhone: true,
          allowUsername: true,
        );

    // Navigate on successful login
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.status == AuthStatus.authenticated && !_hasNavigated) {
        _hasNavigated = true;
        context.go('/home');
      }
    });

    final cs = Theme.of(context).colorScheme;
    final tr = ref.watch(trProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.stream_rounded,
                              size: 56,
                              color: cs.primary,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('auth.welcome_back'),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr('auth.sign_in_to'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Policy Info Banner (when Dual or All identifiers are required)
                    if (!policy.isSingle) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.shield_outlined,
                                color: cs.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                policy.isDual
                                    ? tr('auth.policy_dual_banner')
                                    : tr('auth.policy_all_banner'),
                                style: TextStyle(
                                  color: cs.primary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Error banner
                    if (authState.error != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: cs.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: cs.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                authState.error!,
                                style: TextStyle(
                                  color: cs.onErrorContainer,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Dynamic Identifier Input Fields
                    ..._buildDynamicIdentifierFields(cs, tr, policy),

                    const SizedBox(height: 16),

                    // Password field (Always required in all policies)
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(policy),
                      decoration: InputDecoration(
                        labelText: tr('auth.password_label'),
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
                    const SizedBox(height: 12),

                    // Remember Me
                    GestureDetector(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (v) =>
                                  setState(() => _rememberMe = v ?? true),
                              activeColor: cs.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            tr('auth.remember_me'),
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    FilledButton(
                      onPressed:
                          authState.isLoading ? null : () => _submit(policy),
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
                              tr('auth.sign_in'),
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Register link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          tr('auth.no_account'),
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/register'),
                          child: Text(
                            tr('auth.sign_up'),
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

  List<Widget> _buildDynamicIdentifierFields(
    ColorScheme cs,
    String Function(String) tr,
    LoginPolicyConfig policy,
  ) {
    if (policy.isSingle) {
      final isEmailOnly =
          policy.allowEmail && !policy.allowPhone && !policy.allowUsername;
      final isPhoneOnly =
          !policy.allowEmail && policy.allowPhone && !policy.allowUsername;
      final isUsernameOnly =
          !policy.allowEmail && !policy.allowPhone && policy.allowUsername;

      if (isEmailOnly) {
        return [
          _buildEmailFormField(tr),
        ];
      } else if (isPhoneOnly) {
        return [
          _buildPhoneFormField(tr),
        ];
      } else if (isUsernameOnly) {
        return [
          _buildUsernameFormField(tr),
        ];
      } else {
        // Multi-option single identifier field
        final label = _buildSingleIdentifierLabel(policy, tr);
        return [
          TextFormField(
            controller: _identifierCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return tr('auth.validation.identifier_required');
              }
              return null;
            },
          ),
        ];
      }
    } else if (policy.isDual) {
      final combo = policy.dualCombination ?? 'EMAIL_PHONE';
      if (combo == 'EMAIL_PHONE') {
        return [
          _buildEmailFormField(tr),
          const SizedBox(height: 14),
          _buildPhoneFormField(tr),
        ];
      } else if (combo == 'EMAIL_USERNAME') {
        return [
          _buildEmailFormField(tr),
          const SizedBox(height: 14),
          _buildUsernameFormField(tr),
        ];
      } else {
        return [
          _buildPhoneFormField(tr),
          const SizedBox(height: 14),
          _buildUsernameFormField(tr),
        ];
      }
    } else {
      // ALL_IDENTIFIERS
      return [
        _buildEmailFormField(tr),
        const SizedBox(height: 14),
        _buildPhoneFormField(tr),
        const SizedBox(height: 14),
        _buildUsernameFormField(tr),
      ];
    }
  }

  String _buildSingleIdentifierLabel(
    LoginPolicyConfig policy,
    String Function(String) tr,
  ) {
    final parts = <String>[];
    if (policy.allowEmail) parts.add(tr('auth.email_label').replaceAll(' *', ''));
    if (policy.allowPhone) parts.add(tr('admin.auth_policy.allow_phone'));
    if (policy.allowUsername) parts.add(tr('auth.username_label').replaceAll(' (optional)', ''));
    return parts.join(' / ');
  }

  Widget _buildEmailFormField(String Function(String) tr) {
    return TextFormField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: tr('auth.email_label').replaceAll(' *', ''),
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return tr('auth.validation.email_required');
        }
        if (!v.contains('@')) {
          return tr('auth.validation.email_invalid');
        }
        return null;
      },
    );
  }

  Widget _buildPhoneFormField(String Function(String) tr) {
    return TextFormField(
      controller: _phoneCtrl,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: tr('admin.auth_policy.phone_label'),
        hintText: '+12025550123',
        prefixIcon: const Icon(Icons.phone_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return tr('auth.validation.identifier_required');
        }
        return null;
      },
    );
  }

  Widget _buildUsernameFormField(String Function(String) tr) {
    return TextFormField(
      controller: _usernameCtrl,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: tr('auth.username_label').replaceAll(' (optional)', ''),
        prefixIcon: const Icon(Icons.account_circle_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return tr('auth.validation.identifier_required');
        }
        if (v.trim().length < 3) {
          return tr('auth.validation.username_min_length');
        }
        return null;
      },
    );
  }
}
