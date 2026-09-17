import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/router/app_router.dart';
import 'package:mobile/app/theme/app_theme.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calls/data/call_lifecycle_manager.dart';
import 'package:mobile/features/chats/presentation/providers/chat_socket_lifecycle_provider.dart';
import 'package:mobile/features/notifications/data/notification_lifecycle_manager.dart';

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
    );
  }
}
