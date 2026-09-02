// lib/features/calls/data/call_lifecycle_manager.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/calls/services/call_service.dart';

final callLifecycleProvider = Provider<void>((ref) {
  final auth = ref.watch(authProvider);
  final callService = ref.watch(callServiceProvider);

  if (auth.status == AuthStatus.authenticated) {
    callService.init();
  }
});
