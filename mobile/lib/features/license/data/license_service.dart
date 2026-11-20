// lib/features/license/data/license_service.dart
//
// Validates the app license against the backend on every cold start.
// In kDebugMode the check is bypassed (identical to cndroidPOS LicenseService pattern).
// If the network is unreachable, a 7-day cached grace period is honoured.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/features/license/data/device_id_service.dart';
import 'package:mobile/features/license/model/app_license.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _kLicenseValid = 'app_license_valid';
const _kLicenseCheckedAt = 'app_license_checked_at';
const _kDeviceId = 'app_device_id';
const _kGracePeriodDays = 7;

class LicenseService {
  final Dio _dio;
  final StorageService _storage;

  LicenseService(this._dio, this._storage);

  /// Must be called at app startup before navigation.
  /// Returns the license state. Debug builds always return valid.
  Future<AppLicense> checkLicense() async {
    // Debug bypass — mirrors cndroidPOS kDebugMode behaviour
    if (kDebugMode) {
      return const AppLicense(isValid: true, daysRemaining: 999);
    }

    try {
      final deviceId = await _getOrCacheDeviceId();
      final platform = await DeviceIdService.getPlatform();
      final version = await _getAppVersion();

      final response = await _dio.post(
        '/licenses/validate',
        data: {
          'deviceId': deviceId,
          'platform': platform,
          'appVersion': version,
        },
        options: Options(extra: {'skipAuth': true}),
      );

      final data = parseEnvelope(response.data);
      final license = AppLicense.fromJson(data);

      // Cache result for offline grace period
      await _storage.saveToken(
        license.isValid ? '1' : '0',
        key: _kLicenseValid,
      );
      await _storage.saveToken(
        DateTime.now().toIso8601String(),
        key: _kLicenseCheckedAt,
      );

      return license;
    } on DioException catch (_) {
      // Network error — honour grace period from last successful check
      return _fallbackFromCache();
    } catch (e) {
      debugPrint('[LicenseService] Unexpected error: $e');
      return _fallbackFromCache();
    }
  }

  /// Activate device with an activation code entered by user.
  Future<bool> activate(String activationCode) async {
    final deviceId = await _getOrCacheDeviceId();
    final platform = await DeviceIdService.getPlatform();
    final version = await _getAppVersion();

    final response = await _dio.post(
      '/licenses/activate',
      data: {
        'activationCode': activationCode,
        'deviceId': deviceId,
        'platform': platform,
        'appVersion': version,
      },
      options: Options(extra: {'skipAuth': true}),
    );

    final data = parseEnvelope(response.data);
    return data['activated'] == true;
  }

  Future<String> _getOrCacheDeviceId() async {
    final cached = await _storage.getToken(key: _kDeviceId);
    if (cached != null && cached.isNotEmpty) return cached;
    final id = await DeviceIdService.getDeviceId();
    await _storage.saveToken(id, key: _kDeviceId);
    return id;
  }

  Future<String> _getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return 'unknown';
    }
  }

  Future<AppLicense> _fallbackFromCache() async {
    final cached = await _storage.getToken(key: _kLicenseValid);
    final checkedAt = await _storage.getToken(key: _kLicenseCheckedAt);

    if (cached == '1' && checkedAt != null) {
      final lastCheck = DateTime.tryParse(checkedAt);
      if (lastCheck != null) {
        final age = DateTime.now().difference(lastCheck);
        if (age.inDays < _kGracePeriodDays) {
          debugPrint('[LicenseService] Offline grace period — ${_kGracePeriodDays - age.inDays} days remaining');
          return const AppLicense(isValid: true);
        }
      }
    }

    return const AppLicense(isValid: false, reason: 'NETWORK_ERROR');
  }
}

final licenseServiceProvider = Provider<LicenseService>((ref) {
  final dio = ref.read(apiClientProvider);
  final storage = ref.read(storageServiceProvider);
  return LicenseService(dio, storage);
});
