// lib/features/splash/presentation/providers/splash_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configurable minimum splash screen display and loading duration
/// Total splash experience: ~4500ms (allows full entrance animation + branding to complete)
final splashLoadingDurationProvider = Provider<Duration>((ref) {
  return const Duration(milliseconds: 5000);
});

class SplashNotifier extends StateNotifier<bool> {
  final Duration _duration;
  Timer? _timer;

  SplashNotifier(this._duration) : super(false) {
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer(_duration, () {
      if (mounted) {
        state = true;
      }
    });
  }

  void completeImmediately() {
    _timer?.cancel();
    state = true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provides whether the splash loading time and presentation has completed
final splashCompletedProvider = StateNotifierProvider<SplashNotifier, bool>((
  ref,
) {
  final duration = ref.watch(splashLoadingDurationProvider);
  return SplashNotifier(duration);
});
