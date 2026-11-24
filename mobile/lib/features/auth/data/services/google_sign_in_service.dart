// lib/features/auth/data/services/google_sign_in_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  final GoogleSignIn _googleSignIn;

  static String? _getEnv(String key) {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env[key];
      }
    } catch (_) {}
    return null;
  }

  GoogleSignInService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
              clientId: kIsWeb ? _getEnv('GOOGLE_CLIENT_ID_WEB') : null,
              serverClientId: _getEnv('GOOGLE_CLIENT_ID_WEB') ??
                  _getEnv('GOOGLE_SERVER_CLIENT_ID'),
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

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google authentication succeeded but no ID token was provided.',
        );
      }

      return idToken;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('canceled') ||
          msg.contains('cancelled') ||
          msg.contains('sign_in_canceled')) {
        return null;
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
