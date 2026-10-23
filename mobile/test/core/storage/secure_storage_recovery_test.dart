// test/core/storage/secure_storage_recovery_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FailingSecureStorage extends Fake implements FlutterSecureStorage {
  bool throwDecryptionErrorOnRead = false;
  bool throwDecryptionErrorOnFirstWrite = false;
  bool deleteAllCalled = false;
  final Map<String, String> data = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (throwDecryptionErrorOnFirstWrite) {
      throwDecryptionErrorOnFirstWrite = false;
      throw PlatformException(
        code: 'FAILED_TO_DECRYPT',
        message: 'Could not decrypt key from Keystore: BadPaddingException',
      );
    }
    if (value != null) {
      data[key] = value;
    } else {
      data.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (throwDecryptionErrorOnRead) {
      throw PlatformException(
        code: 'FAILED_TO_DECRYPT',
        message: 'Could not decrypt key from Keystore: BadPaddingException',
      );
    }
    return data[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    data.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    deleteAllCalled = true;
    data.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService Secure Storage Recovery Tests', () {
    late FailingSecureStorage fakeStorage;
    late SharedPreferences prefs;

    setUp(() async {
      fakeStorage = FailingSecureStorage();
      SharedPreferences.setMockInitialValues({
        'app_theme_mode': 'dark',
        'app_locale': 'am',
      });
      prefs = await SharedPreferences.getInstance();
    });

    test('On native, tokens are stored in secure storage without mirroring to plaintext preferences', () async {
      final service = StorageService(fakeStorage, prefs);
      await service.saveToken('jwt_valid_token_123', key: 'auth_token');

      final readToken = await service.getToken(key: 'auth_token');
      expect(readToken, equals('jwt_valid_token_123'));
      expect(fakeStorage.data['auth_token'], equals('jwt_valid_token_123'));
      // Must NOT mirror to unencrypted SharedPreferences on native platforms
      expect(prefs.getString('sec_auth_token'), isNull,
          reason: 'Credentials must never be mirrored into unencrypted preferences on native');
    });

    test('saveToken recovers from Keystore corruption by resetting partition and rewriting token', () async {
      final service = StorageService(fakeStorage, prefs);
      fakeStorage.throwDecryptionErrorOnFirstWrite = true;

      await service.saveToken('token_after_reset', key: 'access_token');

      expect(fakeStorage.deleteAllCalled, isTrue,
          reason: 'Corrupted secure partition must be reset on decryption error');
      expect(fakeStorage.data['access_token'], equals('token_after_reset'),
          reason: 'Token must be successfully written after partition reset');
    });

    test('If Keystore is permanently invalidated on read, returns null safely for clean re-authentication', () async {
      final service = StorageService(fakeStorage, prefs);
      fakeStorage.data['access_token'] = 'invalidated_key';
      fakeStorage.throwDecryptionErrorOnRead = true;

      final retrieved = await service.getToken(key: 'access_token');
      expect(retrieved, isNull,
          reason: 'Must return null gracefully to trigger clean re-auth without throwing or crashing');
    });

    test('deleteAll clears secure tokens and preserves non-credential app preferences', () async {
      final service = StorageService(fakeStorage, prefs);
      await service.saveToken('token_to_wipe', key: 'session_key');

      expect(fakeStorage.data['session_key'], equals('token_to_wipe'));
      expect(prefs.getString('app_theme_mode'), equals('dark'));
      expect(prefs.getString('app_locale'), equals('am'));

      await service.deleteAll();

      expect(fakeStorage.data['session_key'], isNull);
      expect(prefs.getString('app_theme_mode'), equals('dark'),
          reason: 'Non-credential app preferences must NOT be deleted');
      expect(prefs.getString('app_locale'), equals('am'),
          reason: 'Non-credential app preferences must NOT be deleted');
    });
  });
}
