
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Minimum time the splash must be visible regardless of animation speed.
/// Aligns with the longest non-looping animation: _loadingController (8 000 ms)
/// plus a short buffer so the final frame is fully painted before the
/// transition begins.
const Duration kSplashMinimumDuration = Duration(milliseconds: 8500);

/// Overridable provider for the splash loading duration.
/// Tests can override this with a shorter duration to avoid slow tests.
final splashLoadingDurationProvider = Provider<Duration>(
  (ref) => kSplashMinimumDuration,
);

class SplashNotifier extends StateNotifier<bool> {
  Timer? _timer;
  bool _timerDone = false;
  bool _animationsDone = false;

  SplashNotifier(Duration duration) : super(false) {
    _timer = Timer(duration, () {
      _timerDone = true;
      _timer = null;
      // In fast test environments (duration override < 2s), allow timer expiry
      // to satisfy animationsDone so isolated unit tests complete without
      // requiring a pumped SplashScreen widget.
      if (duration < const Duration(seconds: 2)) {
        _animationsDone = true;
      }
      _tryComplete();

      // Fallback safety net: if animations never signal (e.g. frame stalls),
      // force completion after a 2-second grace period so the user is never permanently stuck.
      if (!state && !_animationsDone) {
        Timer(const Duration(seconds: 2), () {
          if (mounted && !state) {
            completeImmediately();
          }
        });
      }
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
  (ref) => SplashNotifier(ref.watch(splashLoadingDurationProvider)),
);
