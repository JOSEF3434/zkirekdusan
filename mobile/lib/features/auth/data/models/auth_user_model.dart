// lib/features/auth/data/models/auth_user_model.dart
// Maps to backend AuthResponseDto.UserSummaryDto

class AuthUserModel {
  final String id;
  final String? email;
  final String? phoneNumber;
  final String? username;
  final String role;

  const AuthUserModel({
    required this.id,
    this.email,
    this.phoneNumber,
    this.username,
    required this.role,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      username: json['username'] as String?,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phoneNumber': phoneNumber,
        'username': username,
        'role': role,
      };
}

class AuthResponseModel {
  final AuthUserModel user;
  final String accessToken;
  final String refreshToken;

  const AuthResponseModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: AuthUserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}
