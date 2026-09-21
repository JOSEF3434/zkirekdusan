// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mobile/firebase_options.dart';
import 'package:mobile/app/app.dart';
import 'package:mobile/app/env/env.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/database/app_database.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/core/sync/background_sync_service.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/notifications/data/fcm_service.dart';
import 'package:mobile/features/calendar/data/calendar_background_sync.dart';
import 'package:mobile/features/calendar/data/calendar_notifications_service.dart';
import 'package:mobile/features/calendar/data/calendar_reminder_worker.dart';
import 'package:mobile/core/services/app_lifecycle_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize environment variables
  await Env.init();

  // 2. Initialize Firebase safely
  try {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Register top-level background messaging handler on mobile platforms
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
      }
    }
  } catch (e) {
    debugPrint('[Firebase] Initialization error: $e');
  }

  // 3. Initialize SQLite local database (offline-first foundation)
  final appDatabase = AppDatabase();

  // 4. Initialize Background Sync Service
  if (!kIsWeb) {
    await BackgroundSyncService.initialize();

    // Initialize Calendar Background Sync
    await CalendarBackgroundSyncManager.initialize(
      apiBaseUrl: Env.apiBaseUrl,
      // authToken: null, // Token will be set after user login
    );

    // Register periodic sync (every 15 minutes)
    await CalendarBackgroundSyncManager.registerPeriodicSync(
      apiBaseUrl: Env.apiBaseUrl,
      frequency: const Duration(minutes: 15),
    );

    // Initialize Calendar Reminder System
    final calendarNotifications = CalendarNotificationsService();
    await calendarNotifications.initialize();

    await CalendarReminderManager.initialize();
    await CalendarReminderManager.registerPeriodicReminderCheck();
  }

  // 5. Initialize SharedPreferences
  final sharedPrefs = await SharedPreferences.getInstance();

  // 6. Initialize Localization
  final localizationService = LocalizationService();
  await localizationService.init();

  // Create a ProviderContainer so we can pass a Ref to the lifecycle observer
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(appDatabase),
      sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      localizationServiceProvider.overrideWithValue(localizationService),
    ],
  );

  // Register lifecycle observer for App Lock auto-lock on background/foreground
  final lifecycleObserver = AppLifecycleObserver(container);
  WidgetsBinding.instance.addObserver(lifecycleObserver);

  // 7. Wire FCM locale sync: when the user changes language, re-register the
  //    device token with the new locale so the backend generates notifications
  //    in the correct language.
  PreferencesNotifier.onLanguageChanged = (String languageCode) async {
    try {
      final fcm = container.read(fcmServiceProvider);
      await fcm.syncLocale(languageCode);
    } catch (e) {
      debugPrint('[Main] FCM locale sync failed: $e');
    }
  };

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const StreamHubApp(),
    ),
  );
}
