// lib/features/calendar/domain/calendar_note_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_note_model.freezed.dart';
part 'calendar_note_model.g.dart';

enum ReminderRepeat {
  @JsonValue('NONE')
  none,
  @JsonValue('MONTHLY')
  monthly,
  @JsonValue('YEARLY')
  yearly,
}

@freezed
abstract class CalendarNoteModel with _$CalendarNoteModel {
  const factory CalendarNoteModel({
    required String id,
    required String userId,
    required int ethiopianYear,
    required int ethiopianMonth,
    required int ethiopianDay,
    required DateTime gregorianDate,
    String? title,
    String? content,
    @Default(false) bool hasReminder,
    DateTime? reminderDateTime,
    @Default(false) bool reminderNotified,
    @Default(ReminderRepeat.none) ReminderRepeat reminderRepeat,
    int? reminderEthiopianMonth,
    int? reminderEthiopianDay,
    int? reminderHour,
    int? reminderMinute,
    @Default('Africa/Addis_Ababa') String reminderTimezone,
    DateTime? reminderNextOccurrence,
    @Default([]) List<CalendarNoteMedia> media,
    @Default(false) bool allowDownload,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _CalendarNoteModel;

  factory CalendarNoteModel.fromJson(Map<String, dynamic> json) =>
      _$CalendarNoteModelFromJson(json);
}

@freezed
abstract class CalendarNoteMedia with _$CalendarNoteMedia {
  const factory CalendarNoteMedia({
    required String id,
    required String noteId,
    required String fileId,
    required int order,
    String? caption,
    Map<String, dynamic>? file,
    required DateTime createdAt,
  }) = _CalendarNoteMedia;

  factory CalendarNoteMedia.fromJson(Map<String, dynamic> json) =>
      _$CalendarNoteMediaFromJson(json);
}

@freezed
abstract class CreateCalendarNoteDto with _$CreateCalendarNoteDto {
  const CreateCalendarNoteDto._();

  const factory CreateCalendarNoteDto({
    required int ethiopianYear,
    required int ethiopianMonth,
    required int ethiopianDay,
    required String gregorianDate,
    String? title,
    String? content,
    @Default(false) bool hasReminder,
    String? reminderDateTime,
    @Default(ReminderRepeat.none) ReminderRepeat reminderRepeat,
    int? reminderEthiopianMonth,
    int? reminderEthiopianDay,
    int? reminderHour,
    int? reminderMinute,
    @Default('Africa/Addis_Ababa') String reminderTimezone,
    @Default(false) bool allowDownload,
  }) = _CreateCalendarNoteDto;

  factory CreateCalendarNoteDto.fromJson(Map<String, dynamic> json) =>
      _$CreateCalendarNoteDtoFromJson(json);

  @override
  Map<String, dynamic> toJson() => {
    'ethiopianYear': ethiopianYear,
    'ethiopianMonth': ethiopianMonth,
    'ethiopianDay': ethiopianDay,
    'gregorianDate': gregorianDate,
    if (title != null) 'title': title,
    if (content != null) 'content': content,
    'hasReminder': hasReminder,
    if (reminderDateTime != null) 'reminderDateTime': reminderDateTime,
    'reminderRepeat': _$ReminderRepeatEnumMap[reminderRepeat],
    if (reminderEthiopianMonth != null)
      'reminderEthiopianMonth': reminderEthiopianMonth,
    if (reminderEthiopianDay != null)
      'reminderEthiopianDay': reminderEthiopianDay,
    if (reminderHour != null) 'reminderHour': reminderHour,
    if (reminderMinute != null) 'reminderMinute': reminderMinute,
    'reminderTimezone': reminderTimezone,
    'allowDownload': allowDownload,
  };
}

@freezed
abstract class UpdateCalendarNoteDto with _$UpdateCalendarNoteDto {
  const UpdateCalendarNoteDto._();

  const factory UpdateCalendarNoteDto({
    int? ethiopianYear,
    int? ethiopianMonth,
    int? ethiopianDay,
    String? gregorianDate,
    String? title,
    String? content,
    bool? hasReminder,
    String? reminderDateTime,
    ReminderRepeat? reminderRepeat,
    int? reminderEthiopianMonth,
    int? reminderEthiopianDay,
    int? reminderHour,
    int? reminderMinute,
    String? reminderTimezone,
    bool? allowDownload,
  }) = _UpdateCalendarNoteDto;

  factory UpdateCalendarNoteDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateCalendarNoteDtoFromJson(json);

  @override
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (ethiopianYear != null) map['ethiopianYear'] = ethiopianYear;
    if (ethiopianMonth != null) {
      map['ethiopianMonth'] = ethiopianMonth;
    }
    if (ethiopianDay != null) map['ethiopianDay'] = ethiopianDay;
    if (gregorianDate != null) map['gregorianDate'] = gregorianDate;
    if (title != null) map['title'] = title;
    if (content != null) map['content'] = content;
    if (hasReminder != null) map['hasReminder'] = hasReminder;
    if (reminderDateTime != null) {
      map['reminderDateTime'] = reminderDateTime;
    }
    if (reminderRepeat != null) {
      map['reminderRepeat'] = _$ReminderRepeatEnumMap[reminderRepeat];
    }
    if (reminderEthiopianMonth != null) {
      map['reminderEthiopianMonth'] = reminderEthiopianMonth;
    }
    if (reminderEthiopianDay != null) {
      map['reminderEthiopianDay'] = reminderEthiopianDay;
    }
    if (reminderHour != null) map['reminderHour'] = reminderHour;
    if (reminderMinute != null) map['reminderMinute'] = reminderMinute;
    if (reminderTimezone != null) map['reminderTimezone'] = reminderTimezone;
    if (allowDownload != null) map['allowDownload'] = allowDownload;
    return map;
  }
}
