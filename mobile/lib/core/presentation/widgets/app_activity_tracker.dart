// lib/core/presentation/widgets/app_activity_tracker.dart
//
// Wraps the entire application widget tree with a [Listener] that intercepts
// pointer-down events at the root level and forwards them to
// [AppLockNotifier.recordActivity()].
//
// Design decisions:
//   • Uses [Listener] (not [GestureDetector]) because it does NOT participate
//     in the gesture-arena and therefore never blocks child gestures.
//   • Only [PointerDownEvent] is tracked — continuous drag/scroll events do not
//     re-trigger this, preventing event storms on scroll.
//   • Media playback frames (video/live) never produce pointer events, so the
//     auto-lock timer is NOT reset by passive video viewing. Only actual touch
//     interactions reset it — tapping, seeking, pressing player controls, etc.
//   • The widget is stateless and purely passes events to the provider. All
//     timer logic lives in [AppLockNotifier].

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/security/presentation/providers/app_lock_provider.dart';

class AppActivityTracker extends ConsumerWidget {
  final Widget child;

  const AppActivityTracker({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        // Forward to the notifier; it silently ignores the call when locked.
        ref.read(appLockProvider.notifier).recordActivity();
      },
      child: child,
    );
  }
}
