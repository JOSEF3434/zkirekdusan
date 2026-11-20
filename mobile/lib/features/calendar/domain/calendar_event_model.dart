// lib/features/calendar/domain/calendar_event_model.dart

enum CalendarEventType {
  fast,
  holiday,
  specialEvent;

  static CalendarEventType fromString(String val) {
    final v = val.toUpperCase();
    if (v == 'FAST') return CalendarEventType.fast;
    if (v == 'SPECIAL_EVENT') return CalendarEventType.specialEvent;
    return CalendarEventType.holiday;
  }

  String toJson() {
    switch (this) {
      case CalendarEventType.fast:
        return 'FAST';
      case CalendarEventType.specialEvent:
        return 'SPECIAL_EVENT';
      case CalendarEventType.holiday:
        return 'HOLIDAY';
    }
  }
}

enum CalendarEventCategory {
  majorFast,
  minorFast,
  majorHoliday,
  minorHoliday,
  monthlyFeast,
  annualFeast;

  static CalendarEventCategory fromString(String val) {
    switch (val.toUpperCase()) {
      case 'MAJOR_FAST':
        return CalendarEventCategory.majorFast;
      case 'MINOR_FAST':
        return CalendarEventCategory.minorFast;
      case 'MAJOR_HOLIDAY':
        return CalendarEventCategory.majorHoliday;
      case 'MINOR_HOLIDAY':
        return CalendarEventCategory.minorHoliday;
      case 'MONTHLY_FEAST':
        return CalendarEventCategory.monthlyFeast;
      case 'ANNUAL_FEAST':
        return CalendarEventCategory.annualFeast;
      default:
        return CalendarEventCategory.majorHoliday;
    }
  }

  String toJson() {
    switch (this) {
      case CalendarEventCategory.majorFast:
        return 'MAJOR_FAST';
      case CalendarEventCategory.minorFast:
        return 'MINOR_FAST';
      case CalendarEventCategory.majorHoliday:
        return 'MAJOR_HOLIDAY';
      case CalendarEventCategory.minorHoliday:
        return 'MINOR_HOLIDAY';
      case CalendarEventCategory.monthlyFeast:
        return 'MONTHLY_FEAST';
      case CalendarEventCategory.annualFeast:
        return 'ANNUAL_FEAST';
    }
  }
}

class CalendarEventCoverageModel {
  final bool overlaps;
  final List<int> days;
  final bool isStartMonth;
  final bool isEndMonth;
  final int? startDay;
  final int? endDay;
  final int durationDays;

  const CalendarEventCoverageModel({
    required this.overlaps,
    required this.days,
    required this.isStartMonth,
    required this.isEndMonth,
    this.startDay,
    this.endDay,
    required this.durationDays,
  });

  factory CalendarEventCoverageModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventCoverageModel(
      overlaps: json['overlaps'] as bool? ?? false,
      days: (json['days'] as List<dynamic>?)?.map((e) => e as int).toList() ??
          const [],
      isStartMonth: json['isStartMonth'] as bool? ?? false,
      isEndMonth: json['isEndMonth'] as bool? ?? false,
      startDay: json['startDay'] as int?,
      endDay: json['endDay'] as int?,
      durationDays: json['durationDays'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'overlaps': overlaps,
        'days': days,
        'isStartMonth': isStartMonth,
        'isEndMonth': isEndMonth,
        'startDay': startDay,
        'endDay': endDay,
        'durationDays': durationDays,
      };
}

class CalendarEventModel {
  final String id;
  final String name;
  final String? nameEn;
  final CalendarEventType type;
  final CalendarEventCategory category;
  final bool isRecurring;
  final int? ethiopianYear;
  final int startMonth;
  final int startDay;
  final int? startYear;
  final int endMonth;
  final int endDay;
  final int? endYear;
  final String? description;
  final String? spiritualMeaning;
  final String? fastingRules;
  final String? primaryColor;
  final String? icon;
  final bool isMajor;
  final String importance;
  final bool isActive;
  final int durationDays;
  final String? startEthiopianDateFormatted;
  final String? endEthiopianDateFormatted;
  final String? startGregorianDate;
  final String? endGregorianDate;
  final CalendarEventCoverageModel? coverage;
  final String? dayRole; // 'SINGLE_DAY', 'FAST_BEGINNING', 'FAST_ENDING', 'ONGOING'

  const CalendarEventModel({
    required this.id,
    required this.name,
    this.nameEn,
    required this.type,
    required this.category,
    this.isRecurring = true,
    this.ethiopianYear,
    required this.startMonth,
    required this.startDay,
    this.startYear,
    required this.endMonth,
    required this.endDay,
    this.endYear,
    this.description,
    this.spiritualMeaning,
    this.fastingRules,
    this.primaryColor,
    this.icon,
    this.isMajor = false,
    this.importance = 'NORMAL',
    this.isActive = true,
    this.durationDays = 1,
    this.startEthiopianDateFormatted,
    this.endEthiopianDateFormatted,
    this.startGregorianDate,
    this.endGregorianDate,
    this.coverage,
    this.dayRole,
  });

  bool get isFast => type == CalendarEventType.fast;
  bool get isHoliday => type == CalendarEventType.holiday;
  bool get isSpecialEvent => type == CalendarEventType.specialEvent;
  bool get isMajorHoliday => isHoliday && (isMajor || importance == 'MAJOR');
  bool get isSpecial => isSpecialEvent || importance == 'SPECIAL';
  bool get isSingleDay =>
      startMonth == endMonth &&
      startDay == endDay &&
      (startYear == endYear || startYear == null || endYear == null);

  /// Color rules:
  /// Orange (#F59E0B): Fasting period
  /// Red (#DC2626): Major holiday
  /// Green (#16A34A): Fast start/end or special event marker
  String get defaultColorHex {
    if (isFast) return '#F59E0B';
    if (isMajorHoliday) return '#DC2626';
    if (isSpecial) return '#16A34A';
    return '#10B981';
  }

  String get effectiveColorHex =>
      (primaryColor != null && primaryColor!.isNotEmpty)
          ? primaryColor!
          : defaultColorHex;

  bool isDayStart(int day) {
    if (coverage != null) {
      return coverage!.isStartMonth && coverage!.startDay == day;
    }
    return startMonth == endMonth ? startDay == day : startDay == day;
  }

  bool isDayEnd(int day) {
    if (coverage != null) {
      return coverage!.isEndMonth && coverage!.endDay == day;
    }
    return startMonth == endMonth ? endDay == day : endDay == day;
  }

  CalendarEventModel copyWith({
    String? id,
    String? name,
    String? nameEn,
    CalendarEventType? type,
    CalendarEventCategory? category,
    bool? isRecurring,
    int? ethiopianYear,
    int? startMonth,
    int? startDay,
    int? startYear,
    int? endMonth,
    int? endDay,
    int? endYear,
    String? description,
    String? spiritualMeaning,
    String? fastingRules,
    String? primaryColor,
    String? icon,
    bool? isMajor,
    String? importance,
    bool? isActive,
    int? durationDays,
    String? startEthiopianDateFormatted,
    String? endEthiopianDateFormatted,
    String? startGregorianDate,
    String? endGregorianDate,
    CalendarEventCoverageModel? coverage,
    String? dayRole,
  }) {
    return CalendarEventModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      type: type ?? this.type,
      category: category ?? this.category,
      isRecurring: isRecurring ?? this.isRecurring,
      ethiopianYear: ethiopianYear ?? this.ethiopianYear,
      startMonth: startMonth ?? this.startMonth,
      startDay: startDay ?? this.startDay,
      startYear: startYear ?? this.startYear,
      endMonth: endMonth ?? this.endMonth,
      endDay: endDay ?? this.endDay,
      endYear: endYear ?? this.endYear,
      description: description ?? this.description,
      spiritualMeaning: spiritualMeaning ?? this.spiritualMeaning,
      fastingRules: fastingRules ?? this.fastingRules,
      primaryColor: primaryColor ?? this.primaryColor,
      icon: icon ?? this.icon,
      isMajor: isMajor ?? this.isMajor,
      importance: importance ?? this.importance,
      isActive: isActive ?? this.isActive,
      durationDays: durationDays ?? this.durationDays,
      startEthiopianDateFormatted:
          startEthiopianDateFormatted ?? this.startEthiopianDateFormatted,
      endEthiopianDateFormatted:
          endEthiopianDateFormatted ?? this.endEthiopianDateFormatted,
      startGregorianDate: startGregorianDate ?? this.startGregorianDate,
      endGregorianDate: endGregorianDate ?? this.endGregorianDate,
      coverage: coverage ?? this.coverage,
      dayRole: dayRole ?? this.dayRole,
    );
  }

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameEn: json['nameEn']?.toString(),
      type: CalendarEventType.fromString(json['type']?.toString() ?? 'HOLIDAY'),
      category: CalendarEventCategory.fromString(
        json['category']?.toString() ?? 'MAJOR_HOLIDAY',
      ),
      isRecurring: json['isRecurring'] as bool? ?? true,
      ethiopianYear: json['ethiopianYear'] as int?,
      startMonth: json['startMonth'] as int? ?? 1,
      startDay: json['startDay'] as int? ?? 1,
      startYear: json['startYear'] as int?,
      endMonth: json['endMonth'] as int? ?? 1,
      endDay: json['endDay'] as int? ?? 1,
      endYear: json['endYear'] as int?,
      description: json['description']?.toString(),
      spiritualMeaning: json['spiritualMeaning']?.toString(),
      fastingRules: json['fastingRules']?.toString(),
      primaryColor: json['primaryColor']?.toString(),
      icon: json['icon']?.toString(),
      isMajor: (json['isMajor'] as bool?) ??
          (json['importance']?.toString() == 'MAJOR'),
      importance: json['importance']?.toString() ??
          ((json['isMajor'] as bool? ?? false) ? 'MAJOR' : 'NORMAL'),
      isActive: json['isActive'] as bool? ?? true,
      durationDays: json['durationDays'] as int? ?? 1,
      startEthiopianDateFormatted:
          json['startEthiopianDateFormatted']?.toString(),
      endEthiopianDateFormatted: json['endEthiopianDateFormatted']?.toString(),
      startGregorianDate: json['startGregorianDate']?.toString(),
      endGregorianDate: json['endGregorianDate']?.toString(),
      coverage: json['coverage'] != null
          ? CalendarEventCoverageModel.fromJson(
              json['coverage'] as Map<String, dynamic>,
            )
          : null,
      dayRole: json['dayRole']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameEn': nameEn,
        'type': type.toJson(),
        'category': category.toJson(),
        'isRecurring': isRecurring,
        'ethiopianYear': ethiopianYear,
        'startMonth': startMonth,
        'startDay': startDay,
        'startYear': startYear,
        'endMonth': endMonth,
        'endDay': endDay,
        'endYear': endYear,
        'description': description,
        'spiritualMeaning': spiritualMeaning,
        'fastingRules': fastingRules,
        'primaryColor': primaryColor,
        'icon': icon,
        'isMajor': isMajor,
        'importance': importance,
        'isActive': isActive,
        'durationDays': durationDays,
        'startEthiopianDateFormatted': startEthiopianDateFormatted,
        'endEthiopianDateFormatted': endEthiopianDateFormatted,
        'startGregorianDate': startGregorianDate,
        'endGregorianDate': endGregorianDate,
        if (coverage != null) 'coverage': coverage!.toJson(),
        if (dayRole != null) 'dayRole': dayRole,
      };
}
