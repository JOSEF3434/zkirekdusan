import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/app/router/app_router.dart';
import 'package:mobile/features/auth/domain/entities/auth_user.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('RouterNotifier.redirectPath - Deep Link & Profile Access Rules', () {
    test('unauthenticated visitor on /u/:userId is allowed (returns null, NOT /login)', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(
              const AuthState(status: AuthStatus.unauthenticated),
            ),
          ),
          preferencesProvider.overrideWith(
            (ref) => FakePreferencesNotifier(
              const PreferencesState(
                themeMode: ThemeMode.system,
                languageCode: 'en',
                isFirstLaunch: false,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(routerNotifierProvider);
      final destination = notifier.redirectPath(
        '/u/0e599727-5c5c-4219-be29-7bfdcdea6147',
      );

      expect(
        destination,
        isNull,
        reason: 'Unauthenticated user must be allowed to view public /u/ profile',
      );
    });

    test('first-launch visitor with public link is NOT forced to /onboarding', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(
              const AuthState(status: AuthStatus.unauthenticated),
            ),
          ),
          preferencesProvider.overrideWith(
            (ref) => FakePreferencesNotifier(
              const PreferencesState(
                themeMode: ThemeMode.system,
                languageCode: 'en',
                isFirstLaunch: true, // Cold start first launch!
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(routerNotifierProvider);
      final destination = notifier.redirectPath(
        '/u/0e599727-5c5c-4219-be29-7bfdcdea6147',
      );

      expect(
        destination,
        isNull,
        reason: 'Public deep links must not be hijacked by onboarding on first launch',
      );
    });

    test('first-launch visitor on private route /home IS routed to /onboarding', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(
              const AuthState(status: AuthStatus.unauthenticated),
            ),
          ),
          preferencesProvider.overrideWith(
            (ref) => FakePreferencesNotifier(
              const PreferencesState(
                themeMode: ThemeMode.system,
                languageCode: 'en',
                isFirstLaunch: true,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(routerNotifierProvider);
      final destination = notifier.redirectPath('/home');

      expect(destination, equals('/onboarding'));
    });

    test('unauthenticated visitor on root username /john1 is allowed as public route', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(
              const AuthState(status: AuthStatus.unauthenticated),
            ),
          ),
          preferencesProvider.overrideWith(
            (ref) => FakePreferencesNotifier(
              const PreferencesState(
                themeMode: ThemeMode.system,
                languageCode: 'en',
                isFirstLaunch: false,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(routerNotifierProvider);
      final destination = notifier.redirectPath('/john1');

      expect(destination, isNull);
    });

    test('unauthenticated visitor on private route /creator/workspace IS redirected to /login', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(
              const AuthState(status: AuthStatus.unauthenticated),
            ),
          ),
          preferencesProvider.overrideWith(
            (ref) => FakePreferencesNotifier(
              const PreferencesState(
                themeMode: ThemeMode.system,
                languageCode: 'en',
                isFirstLaunch: false,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(routerNotifierProvider);
      final destination = notifier.redirectPath('/creator/workspace');

      expect(destination, equals('/login'));
    });

    test('authenticated user stays on /profile/user/:username', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(
              const AuthState(
                status: AuthStatus.authenticated,
                user: AuthUser(
                  id: 'logged-in-user',
                  email: 'user@example.com',
                  username: 'tester',
                  role: 'USER',
                ),
              ),
            ),
          ),
          preferencesProvider.overrideWith(
            (ref) => FakePreferencesNotifier(
              const PreferencesState(
                themeMode: ThemeMode.system,
                languageCode: 'en',
                isFirstLaunch: false,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(routerNotifierProvider);
      final destination = notifier.redirectPath(
        '/profile/user/0e599727-5c5c-4219-be29-7bfdcdea6147',
      );

      expect(destination, isNull);
    });

    test('unauthenticated visitor on /jj is allowed as public username profile route', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(
              const AuthState(status: AuthStatus.unauthenticated),
            ),
          ),
          preferencesProvider.overrideWith(
            (ref) => FakePreferencesNotifier(
              const PreferencesState(
                themeMode: ThemeMode.system,
                languageCode: 'en',
                isFirstLaunch: false,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(routerNotifierProvider);
      final destination = notifier.redirectPath('/jj');

      expect(destination, isNull, reason: '/jj must be treated as public profile route');
    });

    test('first-launch cold start on /jj is NOT redirected to /onboarding', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(
              const AuthState(status: AuthStatus.unauthenticated),
            ),
          ),
          preferencesProvider.overrideWith(
            (ref) => FakePreferencesNotifier(
              const PreferencesState(
                themeMode: ThemeMode.system,
                languageCode: 'en',
                isFirstLaunch: true,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(routerNotifierProvider);
      final destination = notifier.redirectPath('/jj');

      expect(destination, isNull, reason: 'Cold start on /jj must display public profile without onboarding redirect');
    });

    test('static asset /index.html is reserved and redirected to /login for unauthenticated users', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(
              const AuthState(status: AuthStatus.unauthenticated),
            ),
          ),
          preferencesProvider.overrideWith(
            (ref) => FakePreferencesNotifier(
              const PreferencesState(
                themeMode: ThemeMode.system,
                languageCode: 'en',
                isFirstLaunch: false,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(routerNotifierProvider);
      final destination = notifier.redirectPath('/index.html');

      expect(destination, equals('/login'), reason: '/index.html is reserved and must not be treated as a username');
    });

    test('GoRouter route tree has direct builder for /:username, /u/:username, and /@:username', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith(
            (ref) => FakeAuthNotifier(
              const AuthState(status: AuthStatus.unauthenticated),
            ),
          ),
          preferencesProvider.overrideWith(
            (ref) => FakePreferencesNotifier(
              const PreferencesState(
                themeMode: ThemeMode.system,
                languageCode: 'en',
                isFirstLaunch: false,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      // Verify /u/:username route exists with builder
      final uRoute = router.configuration.routes
          .whereType<GoRoute>()
          .firstWhere((r) => r.path == '/u/:username');
      expect(uRoute.builder, isNotNull);

      // Verify /:username route exists with builder
      final usernameRoute = router.configuration.routes
          .whereType<GoRoute>()
          .firstWhere((r) => r.path == '/:username');
      expect(usernameRoute.builder, isNotNull);

      // Verify /@:username route exists with builder
      final atRoute = router.configuration.routes
          .whereType<GoRoute>()
          .firstWhere((r) => r.path == '/@:username');
      expect(atRoute.builder, isNotNull);
    });
  });
}

class FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePreferencesNotifier extends StateNotifier<PreferencesState>
    implements PreferencesNotifier {
  FakePreferencesNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
