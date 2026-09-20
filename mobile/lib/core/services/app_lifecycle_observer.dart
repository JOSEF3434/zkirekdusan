// lib/core/services/app_lifecycle_observer.dart
//
// Watches app lifecycle transitions.
// On pause/inactive → saves timestamp.
// On resume → checks if the timeout has elapsed and locks if so.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/security/presentation/providers/app_lock_provider.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  final ProviderContainer _container;

  AppLifecycleObserver(this._container);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Save the "last active" timestamp so we can measure elapsed time on resume
        _container.read(appLockProvider.notifier).onPaused();
        break;
      case AppLifecycleState.resumed:
        // Check if inactivity exceeded the configured timeout
        _container.read(appLockProvider.notifier).onResumed();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }
}
