// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_note_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CalendarNoteModel _$CalendarNoteModelFromJson(Map<String, dynamic> json) =>
    _CalendarNoteModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      ethiopianYear: (json['ethiopianYear'] as num).toInt(),
      ethiopianMonth: (json['ethiopianMonth'] as num).toInt(),
      ethiopianDay: (json['ethiopianDay'] as num).toInt(),
      gregorianDate: DateTime.parse(json['gregorianDate'] as String),
      title: json['title'] as String?,
      content: json['content'] as String?,
      hasReminder: json['hasReminder'] as bool? ?? false,
      reminderDateTime: json['reminderDateTime'] == null
          ? null
          : DateTime.parse(json['reminderDateTime'] as String),
      reminderNotified: json['reminderNotified'] as bool? ?? false,
      media:
          (json['media'] as List<dynamic>?)
              ?.map(
                (e) => CalendarNoteMedia.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );

Map<String, dynamic> _$CalendarNoteModelToJson(_CalendarNoteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'ethiopianYear': instance.ethiopianYear,
      'ethiopianMonth': instance.ethiopianMonth,
      'ethiopianDay': instance.ethiopianDay,
      'gregorianDate': instance.gregorianDate.toIso8601String(),
      'title': instance.title,
      'content': instance.content,
      'hasReminder': instance.hasReminder,
      'reminderDateTime': instance.reminderDateTime?.toIso8601String(),
      'reminderNotified': instance.reminderNotified,
      'media': instance.media,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'deletedAt': instance.deletedAt?.toIso8601String(),
    };

_CalendarNoteMedia _$CalendarNoteMediaFromJson(Map<String, dynamic> json) =>
    _CalendarNoteMedia(
      id: json['id'] as String,
      noteId: json['noteId'] as String,
      fileId: json['fileId'] as String,
      order: (json['order'] as num).toInt(),
      caption: json['caption'] as String?,
      file: json['file'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CalendarNoteMediaToJson(_CalendarNoteMedia instance) =>
    <String, dynamic>{
      'id': instance.id,
      'noteId': instance.noteId,
      'fileId': instance.fileId,
      'order': instance.order,
      'caption': instance.caption,
      'file': instance.file,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_CreateCalendarNoteDto _$CreateCalendarNoteDtoFromJson(
  Map<String, dynamic> json,
) => _CreateCalendarNoteDto(
  ethiopianYear: (json['ethiopianYear'] as num).toInt(),
  ethiopianMonth: (json['ethiopianMonth'] as num).toInt(),
  ethiopianDay: (json['ethiopianDay'] as num).toInt(),
  gregorianDate: json['gregorianDate'] as String,
  title: json['title'] as String?,
  content: json['content'] as String?,
  hasReminder: json['hasReminder'] as bool? ?? false,
  reminderDateTime: json['reminderDateTime'] as String?,
);

Map<String, dynamic> _$CreateCalendarNoteDtoToJson(
  _CreateCalendarNoteDto instance,
) => <String, dynamic>{
  'ethiopianYear': instance.ethiopianYear,
  'ethiopianMonth': instance.ethiopianMonth,
  'ethiopianDay': instance.ethiopianDay,
  'gregorianDate': instance.gregorianDate,
  'title': instance.title,
  'content': instance.content,
  'hasReminder': instance.hasReminder,
  'reminderDateTime': instance.reminderDateTime,
};

_UpdateCalendarNoteDto _$UpdateCalendarNoteDtoFromJson(
  Map<String, dynamic> json,
) => _UpdateCalendarNoteDto(
  ethiopianYear: (json['ethiopianYear'] as num?)?.toInt(),
  ethiopianMonth: (json['ethiopianMonth'] as num?)?.toInt(),
  ethiopianDay: (json['ethiopianDay'] as num?)?.toInt(),
  gregorianDate: json['gregorianDate'] as String?,
  title: json['title'] as String?,
  content: json['content'] as String?,
  hasReminder: json['hasReminder'] as bool?,
  reminderDateTime: json['reminderDateTime'] as String?,
);

Map<String, dynamic> _$UpdateCalendarNoteDtoToJson(
  _UpdateCalendarNoteDto instance,
) => <String, dynamic>{
  'ethiopianYear': instance.ethiopianYear,
  'ethiopianMonth': instance.ethiopianMonth,
  'ethiopianDay': instance.ethiopianDay,
  'gregorianDate': instance.gregorianDate,
  'title': instance.title,
  'content': instance.content,
  'hasReminder': instance.hasReminder,
  'reminderDateTime': instance.reminderDateTime,
};
