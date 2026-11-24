// lib/features/auth/data/services/google_sign_in_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  final GoogleSignIn _googleSignIn;

  static const String _defaultWebClientId =
      '632083728397-q7bp82rggdpbnl2kqoei443rak4lh1k0.apps.googleusercontent.com';

  static String? _getEnv(String key) {
    try {
      if (dotenv.isInitialized) {
        final val = dotenv.env[key];
        if (val != null && val.trim().isNotEmpty) return val.trim();
      }
    } catch (_) {}
    return null;
  }

  GoogleSignInService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email'],
              clientId: kIsWeb
                  ? (_getEnv('GOOGLE_CLIENT_ID_WEB') ?? _defaultWebClientId)
                  : null,
              serverClientId: kIsWeb
                  ? null
                  : (_getEnv('GOOGLE_CLIENT_ID_WEB') ??
                      _getEnv('GOOGLE_SERVER_CLIENT_ID') ??
                      _defaultWebClientId),
            );

  /// Initiates Google Sign-In and extracts the verified OpenID Connect ID token.
  /// Returns null if the user cancelled the dialog.
  Future<String?> signInAndGetIdToken() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // User closed or cancelled the account picker
        return null;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;
      final String? accessToken = auth.accessToken;

      // On Android/iOS, idToken is provided directly by Google Play Services/iOS SDK.
      // On Flutter Web standard OAuth popup, Google returns an accessToken.
      final String? token = (idToken != null && idToken.isNotEmpty)
          ? idToken
          : accessToken;

      if (token == null || token.isEmpty) {
        throw Exception(
          'Google authentication succeeded but no valid token was provided.',
        );
      }

      return token;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('canceled') ||
          msg.contains('cancelled') ||
          msg.contains('sign_in_canceled') ||
          msg.contains('popup_closed_by_user')) {
        return null;
      }
      if (msg.contains('people.googleapis.com') ||
          msg.contains('people api')) {
        throw Exception(
          'Google People API is disabled in your Google Cloud Project. '
          'Please enable it at https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=632083728397 and retry.',
        );
      }
      rethrow;
    }
  }

  /// Silent sign-in to check if a Google session already exists.
  Future<String?> signInSilently() async {
    try {
      final GoogleSignInAccount? account =
          await _googleSignIn.signInSilently();
      if (account == null) return null;
      final auth = await account.authentication;
      return auth.idToken;
    } catch (_) {
      return null;
    }
  }

  /// Signs out from Google session
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
