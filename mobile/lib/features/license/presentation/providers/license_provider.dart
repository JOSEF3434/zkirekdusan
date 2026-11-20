// lib/features/license/presentation/providers/license_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/license/data/license_service.dart';
import 'package:mobile/features/license/model/app_license.dart';

/// FutureProvider that runs the license check on first access (cold start gate).
/// Invalidate to force a re-check (e.g. after activation).
final licenseProvider = FutureProvider<AppLicense>((ref) async {
  final service = ref.read(licenseServiceProvider);
  return service.checkLicense();
});
