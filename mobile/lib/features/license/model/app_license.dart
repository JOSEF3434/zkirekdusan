// lib/features/license/model/app_license.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_license.freezed.dart';
part 'app_license.g.dart';

@freezed
class AppLicense with _$AppLicense {
  const factory AppLicense({
    @Default(false) bool isValid,
    String? reason,
    DateTime? expiresAt,
    int? daysRemaining,
    String? licenseId,
  }) = _AppLicense;

  factory AppLicense.fromJson(Map<String, dynamic> json) =>
      _$AppLicenseFromJson(json);
}

extension AppLicenseX on AppLicense {
  static AppLicense invalid(String reason) =>
      AppLicense(isValid: false, reason: reason);

  bool get isExpired => reason == 'EXPIRED';
  bool get isRevoked => reason == 'REVOKED';
  bool get isNotRegistered => reason == 'NOT_REGISTERED';
  bool get isPending => reason == 'PENDING';

  bool get isExpiringSoon =>
      isValid && daysRemaining != null && daysRemaining! <= 30;
}
