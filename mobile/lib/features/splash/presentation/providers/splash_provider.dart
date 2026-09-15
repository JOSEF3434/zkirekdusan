// lib/features/splash/presentation/providers/splash_provider.dart
//
// Synchronised splash gate:
//   • SplashNotifier manages the "splash completed" flag.
//   • Navigation is held until BOTH conditions are true:
//       1. The minimum timer floor has elapsed (kSplashMinimumDuration).
//       2. The SplashScreen explicitly signals that every visual animation
//          has finished by calling SplashNotifier.signalAnimationsComplete().
//   • This prevents premature navigation, race conditions, and double-splash.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Minimum time the splash must be visible regardless of animation speed.
/// Aligns with the longest non-looping animation: _loadingController (8 000 ms)
/// plus a short buffer so the final frame is fully painted before the
/// transition begins.
const Duration kSplashMinimumDuration = Duration(milliseconds: 8500);

class SplashNotifier extends StateNotifier<bool> {
  Timer? _timer;
  bool _timerDone = false;
  bool _animationsDone = false;

  SplashNotifier() : super(false) {
    _timer = Timer(kSplashMinimumDuration, () {
      _timerDone = true;
      _timer = null;
      _tryComplete();
    });
  }

  /// Called by SplashScreen once every non-looping animation has finished.
  void signalAnimationsComplete() {
    if (_animationsDone) return; // guard against duplicate calls
    _animationsDone = true;
    _tryComplete();
  }

  void _tryComplete() {
    if (!mounted) return;
    if (_timerDone && _animationsDone) {
      state = true;
    }
  }

  /// Emergency escape hatch (e.g. fatal init error). Cancels the timer and
  /// marks both conditions satisfied so the router can navigate.
  void completeImmediately() {
    _timer?.cancel();
    _timer = null;
    _timerDone = true;
    _animationsDone = true;
    if (mounted) state = true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Guards navigation: `true` only when the splash is fully done.
final splashCompletedProvider = StateNotifierProvider<SplashNotifier, bool>(
  (ref) => SplashNotifier(),
);
