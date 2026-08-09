// lib/features/profile/data/datasources/profile_remote_datasource.dart
// Calls real backend profile endpoints from profiles.controller.ts

import 'package:dio/dio.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/profile/data/models/profile_model.dart';

class ProfileRemoteDatasource {
  final Dio _dio;

  ProfileRemoteDatasource(this._dio);

  /// GET /profiles/me  (requires Bearer token)
  Future<ProfileModel> getMyProfile() async {
    try {
      final response = await _dio.get('/profiles/me');
      return ProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  /// PATCH /profiles/me  (requires Bearer token)
  /// Fields: firstName, lastName, displayName, bio, website, country, language, gender, visibility
  Future<ProfileModel> updateMyProfile({
    String? firstName,
    String? lastName,
    String? displayName,
    String? bio,
    String? website,
    String? country,
    String? language,
    String? gender,
    String? visibility,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['firstName'] = firstName;
      if (lastName != null) body['lastName'] = lastName;
      if (displayName != null) body['displayName'] = displayName;
      if (bio != null) body['bio'] = bio;
      if (website != null) body['website'] = website;
      if (country != null) body['country'] = country;
      if (language != null) body['language'] = language;
      if (gender != null) body['gender'] = gender;
      if (visibility != null) body['visibility'] = visibility;

      final response = await _dio.patch('/profiles/me', data: body);
      return ProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  /// GET /profiles/:username  (public, no auth required)
  Future<ProfileModel> getProfileByUsername(String username) async {
    try {
      final response = await _dio.get('/profiles/$username');
      return ProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException(_parseDioError(e));
    }
  }

  String _parseDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is String) return msg;
      if (msg is List) return msg.join(', ');
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out.';
      case DioExceptionType.connectionError:
        return 'Could not connect to the server.';
      default:
        return 'An unexpected error occurred.';
    }
  }
}
