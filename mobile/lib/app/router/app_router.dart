// lib/app/router/app_router.dart

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/splash/presentation/splash_screen.dart';
import 'package:mobile/features/auth/presentation/login_screen.dart';
import 'package:mobile/features/auth/presentation/register_screen.dart';
import 'package:mobile/features/home/presentation/home_screen.dart';
import 'package:mobile/features/profile/presentation/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    // Redirect logic: prevents logged-in users from seeing Auth screens
    // and logged-out users from seeing Home/Profile screens.
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      
      final isAuthRoute = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/register';
      
      final isSplashRoute = state.matchedLocation == '/';
      
      // If we are still checking auth, stay on splash
      if (authState.status == AuthStatus.unknown) {
        return isSplashRoute ? null : '/';
      }
      
      // If authenticated and trying to access auth/splash screens, go home
      if (authState.status == AuthStatus.authenticated) {
        if (isAuthRoute || isSplashRoute) {
          return '/home';
        }
      }
      
      // If unauthenticated and trying to access protected screens, go to login
      if (authState.status == AuthStatus.unauthenticated) {
        if (!isAuthRoute && !isSplashRoute) {
          return '/login';
        }
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
