// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_license.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppLicense _$AppLicenseFromJson(Map<String, dynamic> json) => _AppLicense(
  isValid: json['isValid'] as bool? ?? false,
  reason: json['reason'] as String?,
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
  daysRemaining: (json['daysRemaining'] as num?)?.toInt(),
  licenseId: json['licenseId'] as String?,
);

Map<String, dynamic> _$AppLicenseToJson(_AppLicense instance) =>
    <String, dynamic>{
      'isValid': instance.isValid,
      'reason': instance.reason,
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'daysRemaining': instance.daysRemaining,
      'licenseId': instance.licenseId,
    };
