// lib/features/license/presentation/license_gate_screen.dart
//
// Blocking gate screen shown on cold start. Checks device license against
// the backend before allowing access to any other route.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/license/presentation/providers/license_provider.dart';

class LicenseGateScreen extends ConsumerWidget {
  const LicenseGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final licenseAsync = ref.watch(licenseProvider);

    return licenseAsync.when(
      loading: () => const _CheckingScreen(),
      error: (e, _) => _ErrorScreen(error: e.toString()),
      data: (license) {
        if (license.isValid) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/');
          });
          return const _CheckingScreen();
        }
        return _BlockedScreen(reason: license.reason ?? 'UNKNOWN');
      },
    );
  }
}

// ── Internal widgets ──────────────────────────────────────────────────────────

class _CheckingScreen extends StatelessWidget {
  const _CheckingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Verifying license…'),
          ],
        ),
      ),
    );
  }
}

class _BlockedScreen extends ConsumerWidget {
  final String reason;
  const _BlockedScreen({required this.reason});

  static const _messages = {
    'NOT_REGISTERED':
        'This device is not registered.\nPlease enter your activation code.',
    'EXPIRED':
        'Your license has expired.\nPlease contact your administrator.',
    'REVOKED':
        'This license has been revoked.\nPlease contact support.',
    'PENDING':
        'License is pending approval.\nPlease contact your administrator.',
    'NETWORK_ERROR':
        'Could not reach the server.\nGrace period has expired — please reconnect.',
    'UNKNOWN': 'Your app license is not valid.\nPlease contact support.',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = _messages[reason] ?? _messages['UNKNOWN']!;
    final showActivation = reason == 'NOT_REGISTERED';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 72,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Access Restricted',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                if (showActivation)
                  FilledButton.icon(
                    icon: const Icon(Icons.vpn_key_rounded),
                    label: const Text('Enter Activation Code'),
                    onPressed: () => context.push('/license/activate'),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  onPressed: () {
                    ref.invalidate(licenseProvider);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends ConsumerWidget {
  final String error;
  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Could not verify license.\nWorking in offline grace period.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/splash'),
                child: const Text('Continue'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(licenseProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
