// lib/features/license/presentation/activation_screen.dart
//
// Allows the user to enter a XXXX-XXXX-XXXX-XXXX activation code
// to register their device with a valid license.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/license/data/license_service.dart';
import 'package:mobile/features/license/presentation/providers/license_provider.dart';

class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key});

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activate App'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Activation Code',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the activation code provided by your administrator.\nFormat: XXXX-XXXX-XXXX-XXXX',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'XXXX-XXXX-XXXX-XXXX',
                errorText: _error,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                counterText: '',
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 19,
              onChanged: _onCodeChanged,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _activate,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Activate'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCodeChanged(String val) {
    // Strip all dashes, uppercase, limit to 16 chars
    final raw = val.replaceAll('-', '').toUpperCase();
    final capped = raw.length > 16 ? raw.substring(0, 16) : raw;

    // Insert dashes every 4 characters
    final parts = <String>[];
    for (int i = 0; i < capped.length; i += 4) {
      parts.add(capped.substring(i, (i + 4).clamp(0, capped.length)));
    }
    final formatted = parts.join('-');

    if (formatted != val) {
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _activate() async {
    final code = _controller.text.trim();

    // Validate format: XXXX-XXXX-XXXX-XXXX = 19 chars
    final regex = RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$');
    if (!regex.hasMatch(code)) {
      setState(() => _error = 'Please enter a valid 16-character activation code');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = ref.read(licenseServiceProvider);
      final success = await service.activate(code);

      if (success) {
        // Invalidate so the gate re-checks with the newly activated license
        ref.invalidate(licenseProvider);
        if (mounted) context.go('/license-gate'); // gate will re-check
      } else {
        setState(() => _error = 'Invalid activation code. Please try again.');
      }
    } catch (e) {
      setState(() => _error = 'Activation failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
