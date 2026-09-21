// lib/features/notifications/domain/notification_model.dart

import 'dart:convert';

class NotificationResponseDto {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationResponseDto({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationResponseDto.fromJson(Map<String, dynamic> json) {
    return NotificationResponseDto(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'SYSTEM',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'body': body,
    if (data != null) 'data': data,
    'isRead': isRead,
    'createdAt': createdAt.toIso8601String(),
  };

  String localizedTitle(String languageCode) {
    final localized = _localizedText(languageCode, 'title');
    if (localized != null) return localized;

    // Older calendar notifications were stored with an Amharic-only title.
    if ((languageCode == 'en' || languageCode == 'gez') &&
        data?['type'] == 'CALENDAR_NOTE') {
      const amharicPrefix = 'አዲስ የዝክረ ቅዱሳን ማስታወሻ: ';
      if (title.startsWith(amharicPrefix)) {
        return 'New Zikre Kidusan note: ${title.substring(amharicPrefix.length)}';
      }
      if (title == 'አዲስ የዝክረ ቅዱሳን ማስታወሻ ተለጥፏል') {
        return 'A new Zikre Kidusan note was published';
      }
    }
    return title;
  }

  String localizedBody(String languageCode) =>
      _localizedText(languageCode, 'body') ?? body;

  String? _localizedText(String languageCode, String field) {
    final rawLocalized = data?['localized'];
    Map<String, dynamic>? localized;

    if (rawLocalized is Map) {
      localized = rawLocalized.cast<String, dynamic>();
    } else if (rawLocalized is String) {
      try {
        final decoded = jsonDecode(rawLocalized);
        if (decoded is Map) {
          localized = decoded.cast<String, dynamic>();
        }
      } on FormatException {
        return null;
      }
    }

    final language = localized?[languageCode];
    if (language is Map) {
      final value = language[field]?.toString();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  NotificationResponseDto copyWith({
    String? id,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationResponseDto(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationResponseDto &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
