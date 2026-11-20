// lib/features/calendar/domain/calendar_event_model.dart

enum CalendarEventType {
  fast,
  holiday;

  static CalendarEventType fromString(String val) {
    if (val.toUpperCase() == 'FAST') return CalendarEventType.fast;
    return CalendarEventType.holiday;
  }

  String toJson() => name.toUpperCase();
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
      isMajor: json['isMajor'] as bool? ?? false,
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
