import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/router/app_router.dart';
import 'package:mobile/app/theme/app_theme.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/core/services/deep_link_service.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calls/data/call_lifecycle_manager.dart';
import 'package:mobile/features/chats/presentation/providers/chat_socket_lifecycle_provider.dart';
import 'package:mobile/features/notifications/data/notification_lifecycle_manager.dart';
import 'package:mobile/core/presentation/widgets/floating_mini_player.dart';
import 'package:mobile/core/presentation/widgets/app_activity_tracker.dart';
import 'package:mobile/features/calls/presentation/widgets/floating_call_overlay.dart';

/// Global scroll behavior supporting mouse, trackpad, and touch drag gestures across Web & Native
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class StreamHubApp extends ConsumerStatefulWidget {
  const StreamHubApp({super.key});

  @override
  ConsumerState<StreamHubApp> createState() => _StreamHubAppState();
}

class _StreamHubAppState extends ConsumerState<StreamHubApp> {
  bool _deepLinkInitialized = false;

  @override
  Widget build(BuildContext context) {
    // Keep background socket listeners alive
    ref.watch(callLifecycleProvider);
    ref.watch(notificationLifecycleProvider);
    ref.watch(chatSocketLifecycleProvider);

    final router = ref.watch(routerProvider);
    final prefsState = ref.watch(preferencesProvider);
    final tr = ref.watch(trProvider);

    // Initialize deep link service once after the router is ready (mobile only)
    if (!kIsWeb && !_deepLinkInitialized) {
      _deepLinkInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DeepLinkService.initialize(router);
      });
    }

    return MaterialApp.router(
      title: tr('app.name'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: prefsState.themeMode,
      locale: Locale(prefsState.languageCode),
      scrollBehavior: const AppScrollBehavior(),

      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        // AppActivityTracker sits at the very root of the widget tree.
        // It intercepts pointer-down events (not continuous scroll/drag frames)
        // and forwards them to AppLockNotifier.recordActivity().
        // Video/live playback frames never produce pointer events, so passive
        // media viewing does NOT reset the inactivity timer.
        return AppActivityTracker(
          child: Stack(
            children: [
              child,
              const FloatingMiniPlayer(),
              const FloatingCallOverlay(),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    DeepLinkService.dispose();
    super.dispose();
  }
}
