// lib/features/auth/data/models/login_policy_model.dart

class LoginPolicyConfig {
  final String activePolicy;
  final bool allowEmail;
  final bool allowPhone;
  final bool allowUsername;
  final String? dualCombination;

  const LoginPolicyConfig({
    this.activePolicy = 'SINGLE_IDENTIFIER',
    this.allowEmail = true,
    this.allowPhone = true,
    this.allowUsername = true,
    this.dualCombination,
  });

  bool get isSingle => activePolicy == 'SINGLE_IDENTIFIER';
  bool get isDual => activePolicy == 'DUAL_IDENTIFIER';
  bool get isAll => activePolicy == 'ALL_IDENTIFIERS';

  bool get requiresEmail =>
      isAll ||
      (isDual &&
          (dualCombination == 'EMAIL_PHONE' ||
              dualCombination == 'EMAIL_USERNAME'));

  bool get requiresPhone =>
      isAll ||
      (isDual &&
          (dualCombination == 'EMAIL_PHONE' ||
              dualCombination == 'PHONE_USERNAME'));

  bool get requiresUsername =>
      isAll ||
      (isDual &&
          (dualCombination == 'EMAIL_USERNAME' ||
              dualCombination == 'PHONE_USERNAME'));

  factory LoginPolicyConfig.fromJson(Map<String, dynamic> json) {
    return LoginPolicyConfig(
      activePolicy: json['activePolicy'] as String? ?? 'SINGLE_IDENTIFIER',
      allowEmail: json['allowEmail'] as bool? ?? true,
      allowPhone: json['allowPhone'] as bool? ?? true,
      allowUsername: json['allowUsername'] as bool? ?? true,
      dualCombination: json['dualCombination'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'activePolicy': activePolicy,
        'allowEmail': allowEmail,
        'allowPhone': allowPhone,
        'allowUsername': allowUsername,
        'dualCombination': dualCombination,
      };

  LoginPolicyConfig copyWith({
    String? activePolicy,
    bool? allowEmail,
    bool? allowPhone,
    bool? allowUsername,
    String? dualCombination,
  }) {
    return LoginPolicyConfig(
      activePolicy: activePolicy ?? this.activePolicy,
      allowEmail: allowEmail ?? this.allowEmail,
      allowPhone: allowPhone ?? this.allowPhone,
      allowUsername: allowUsername ?? this.allowUsername,
      dualCombination: dualCombination ?? this.dualCombination,
    );
  }
}

class LoginPolicyAuditItem {
  final String id;
  final String? actorId;
  final String? actorUsername;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final String? reason;
  final DateTime createdAt;

  LoginPolicyAuditItem({
    required this.id,
    this.actorId,
    this.actorUsername,
    this.before,
    this.after,
    this.reason,
    required this.createdAt,
  });

  factory LoginPolicyAuditItem.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>?;
    return LoginPolicyAuditItem(
      id: json['id'] as String? ?? '',
      actorId: json['actorId'] as String?,
      actorUsername: actor?['username'] as String? ?? actor?['email'] as String?,
      before: json['before'] as Map<String, dynamic>?,
      after: json['after'] as Map<String, dynamic>?,
      reason: json['reason'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
