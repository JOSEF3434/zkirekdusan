import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/router/app_router.dart';
import 'package:mobile/app/theme/app_theme.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calls/data/call_lifecycle_manager.dart';
import 'package:mobile/features/chats/presentation/providers/chat_socket_lifecycle_provider.dart';
import 'package:mobile/features/notifications/data/notification_lifecycle_manager.dart';
import 'package:mobile/features/security/presentation/providers/app_lock_provider.dart';
import 'package:mobile/features/security/presentation/providers/app_lock_settings_provider.dart';

import 'package:mobile/core/presentation/widgets/floating_mini_player.dart';

class StreamHubApp extends ConsumerWidget {
  const StreamHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep background socket listeners alive
    ref.watch(callLifecycleProvider);
    ref.watch(notificationLifecycleProvider);
    ref.watch(chatSocketLifecycleProvider);

    final router = ref.watch(routerProvider);
    final prefsState = ref.watch(preferencesProvider);
    final tr = ref.watch(trProvider);

    return MaterialApp.router(
      title: tr('app.name'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: prefsState.themeMode,
      locale: Locale(prefsState.languageCode),

      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            const FloatingMiniPlayer(),
            // Privacy overlay: covers sensitive content while app is
            // transitioning to background or the lock screen is active.
            const _AppPrivacyOverlay(),
          ],
        );
      },
    );
  }
}

/// A semi-opaque overlay that appears when the application is locked and
/// transitioning to or from the background.
///
/// This provides an extra layer of protection on platforms where the OS
/// may capture a screenshot of the app's current content (e.g. iOS app
/// switcher snapshot). By the time the snapshot is taken the overlay is
/// already rendered on top of any sensitive content.
///
/// Note: This overlay is intentionally minimal — it does NOT replace the
/// dedicated /lock route. It is a defensive measure for the brief window
/// between the app entering the background and the OS capturing a preview.
class _AppPrivacyOverlay extends ConsumerStatefulWidget {
  const _AppPrivacyOverlay();

  @override
  ConsumerState<_AppPrivacyOverlay> createState() => _AppPrivacyOverlayState();
}

class _AppPrivacyOverlayState extends ConsumerState<_AppPrivacyOverlay>
    with WidgetsBindingObserver {
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lockSettings = ref.read(appLockSettingsProvider);
    if (!lockSettings.isEnabled) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Show overlay as soon as app starts to background
        if (mounted) setState(() => _showOverlay = true);
        break;
      case AppLifecycleState.resumed:
        // Keep overlay while lock screen is deciding what to show.
        // The /lock route will handle unlocking; once unlocked the overlay
        // is no longer needed.
        final lockState = ref.read(appLockProvider);
        if (lockState.status != AppLockStatus.locked) {
          if (mounted) setState(() => _showOverlay = false);
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Also watch lock state to dismiss overlay when unlocked via UI
    final lockState = ref.watch(appLockProvider);
    final lockSettings = ref.watch(appLockSettingsProvider);

    final shouldShow = lockSettings.isEnabled &&
        (_showOverlay || lockState.status == AppLockStatus.locked);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: shouldShow
          ? _PrivacyScreen(key: const ValueKey('overlay'))
          : const SizedBox.shrink(key: ValueKey('none')),
    );
  }
}

class _PrivacyScreen extends StatelessWidget {
  const _PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/logo.jpg',
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Icon(Icons.lock_rounded, color: Colors.white54, size: 24),
            const SizedBox(height: 8),
            const Text(
              'ዝክረ ቅዱሳን',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
