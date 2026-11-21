// lib/core/utils/ethiopian_calendar_util.dart
// Ethiopian calendar utilities using the abushakir package

import 'package:abushakir/abushakir.dart';

/// Helper class for Ethiopian calendar operations
class EthiopianCalendarUtil {
  /// Ethiopian month names in Amharic
  static const List<String> ethiopianMonthNames = [
    'መስከረም', // Meskerem - 1
    'ጥቅምት', // Tikimt - 2
    'ኅዳር', // Hidar - 3
    'ታኅሣሥ', // Tahsas - 4
    'ጥር', // Tir - 5
    'የካቲት', // Yekatit - 6
    'መጋቢት', // Megabit - 7
    'ሚያዝያ', // Miazia - 8
    'ግንቦት', // Ginbot - 9
    'ሰኔ', // Sene - 10
    'ሐምሌ', // Hamle - 11
    'ነሐሴ', // Nehase - 12
    'ጳጉሜን', // Pagumen - 13
  ];

  /// Ethiopian weekday names in Amharic
  static const List<String> ethiopianWeekdayNames = [
    'ሰኞ', // Monday (Segno)
    'ማክሰኞ', // Tuesday (Maksegno)
    'ረቡዕ', // Wednesday (Rebu)
    'ሐሙስ', // Thursday (Hamus)
    'ዓርብ', // Friday (Arb)
    'ቅዳሜ', // Saturday (Kidame)
    'እሁድ', // Sunday (Ehud)
  ];

  /// Get current Ethiopian date
  static EtDatetime now() {
    return EtDatetime.now();
  }

  /// Get Ethiopian date from Gregorian DateTime
  static EtDatetime fromGregorian(DateTime gregorian) {
    return EtDatetime.fromMillisecondsSinceEpoch(
      gregorian.millisecondsSinceEpoch,
    );
  }

  /// Convert Ethiopian date to Gregorian DateTime
  static DateTime toGregorian(EtDatetime ethiopian) {
    return DateTime.fromMillisecondsSinceEpoch(ethiopian.moment);
  }

  /// Get month name in Amharic
  static String getMonthName(int month) {
    if (month < 1 || month > 13) return '';
    return ethiopianMonthNames[month - 1];
  }

  /// Get weekday name in Amharic (1-based, Monday = 1)
  static String getWeekdayName(int weekday) {
    if (weekday < 1 || weekday > 7) return '';
    return ethiopianWeekdayNames[weekday - 1];
  }

  /// Get number of days in an Ethiopian month
  static int getDaysInMonth(int year, int month) {
    if (month < 1 || month > 13) return 0;
    if (month == 13) {
      // Pagumen has 5 or 6 days depending on leap year
      return isLeapYear(year) ? 6 : 5;
    }
    return 30; // All other months have 30 days
  }

  /// Check if an Ethiopian year is a leap year
  static bool isLeapYear(int year) {
    // Ethiopian leap year: year % 4 == 3
    return (year % 4) == 3;
  }

  /// Get the first day of the month (returns weekday 1-7, Monday = 1)
  static int getFirstWeekdayOfMonth(int year, int month) {
    final etc = ETC(year: year, month: month, day: 1);
    final firstDay = etc.monthDays().first;
    // firstDay format: [year, month, day, weekdayIndex]
    // weekdayIndex: 0=Monday, 1=Tuesday, ..., 6=Sunday
    // Convert to 1-based (1=Monday, 7=Sunday)
    final weekdayIndex = firstDay[3] as int;
    return (weekdayIndex % 7) + 1;
  }

  /// Create EtDatetime for a specific Ethiopian date
  static EtDatetime create(int year, int month, int day) {
    return EtDatetime(year: year, month: month, day: day);
  }

  /// Check if two Ethiopian dates are the same day
  static bool isSameDay(EtDatetime date1, EtDatetime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Format Ethiopian date as "DD መስከረም YYYY"
  static String formatEthiopianDate(EtDatetime date) {
    return '${date.day} ${getMonthName(date.month)} ${date.year}';
  }

  /// Format Gregorian date as "Month DD, YYYY"
  static String formatGregorianDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Monotonic chronological date score: year * 10000 + month * 100 + day
  static int getDateScore(int year, int month, int day) {
    return year * 10000 + month * 100 + day;
  }

  /// Calculates the active rolling one-Ethiopian-year calendar window.
  /// START: Same Ethiopian month/day in the previous Ethiopian year.
  /// Clamped to max days of that month (e.g. Pagumen).
  /// END: Current Ethiopian date.
  /// Covers all 13 Ethiopian months inclusively.
  static ({EtDatetime start, EtDatetime end}) getRollingOneYearWindow([
    EtDatetime? referenceDate,
  ]) {
    final now = referenceDate ?? EthiopianCalendarUtil.now();
    final prevYear = now.year - 1;
    final maxPrevDays = getDaysInMonth(prevYear, now.month);
    final startDay = now.day > maxPrevDays ? maxPrevDays : now.day;

    final start = EtDatetime(year: prevYear, month: now.month, day: startDay);
    final end = EtDatetime(year: now.year, month: now.month, day: now.day);
    return (start: start, end: end);
  }

  /// Checks if an Ethiopian date falls within the inclusive rolling window.
  static bool isDateInRollingWindow({
    required int year,
    required int month,
    required int day,
    required EtDatetime start,
    required EtDatetime end,
  }) {
    final score = getDateScore(year, month, day);
    final startScore = getDateScore(start.year, start.month, start.day);
    final endScore = getDateScore(end.year, end.month, end.day);
    return score >= startScore && score <= endScore;
  }

  /// Format Ethiopian date as standard ISO-like string "YYYY-MM-DD"
  static String formatIsoDate(dynamic yearOrDate, [int? month, int? day]) {
    if (yearOrDate is EtDatetime) {
      final m = yearOrDate.month.toString().padLeft(2, '0');
      final d = yearOrDate.day.toString().padLeft(2, '0');
      return '${yearOrDate.year}-$m-$d';
    }
    final y = yearOrDate as int;
    final m = (month ?? 1).toString().padLeft(2, '0');
    final d = (day ?? 1).toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // ─────────────────────────────────────────────
  // BAHIRE HASAB (ባሕረ ሐሳብ) & MOVABLE FEASTS / FASTS
  // ─────────────────────────────────────────────

  /// Calculates authoritative Bahire Hasab movable fasts and feasts for an Ethiopian year.
  static ({
    int year,
    String evangelist,
    bool isLeapYear,
    int meskerem1Weekday,
    ({int month, int day}) nenewe,
    ({int startMonth, int startDay, int endMonth, int endDay, int durationDays}) abiyTsom,
    ({int month, int day}) debreZeyt,
    ({int month, int day}) hosanna,
    ({int month, int day}) tseloteHamus,
    ({int month, int day}) siklet,
    ({int month, int day}) kedamSeur,
    ({int month, int day}) fasika,
    ({int month, int day}) rikbeKahnat,
    ({int month, int day}) erget,
    ({int month, int day}) peraklitos,
    ({int startMonth, int startDay, int endMonth, int endDay, int durationDays}) apostlesFast,
    ({int startMonth, int startDay, int endMonth, int endDay}) bealeHamsa,
  }) calculateBahireHasab(int year) {
    final ameteAlem = 5500 + year;
    const evangelists = ['ዮሐንስ', 'ማቴዎስ', 'ማርቆስ', 'ሉቃስ'];
    final evangelist = evangelists[ameteAlem % 4];
    final isLeap = isLeapYear(year);

    final rabeet = ameteAlem ~/ 4;
    final meskerem1Weekday0 = (ameteAlem + rabeet) % 7; // 0=Mon ... 6=Sun
    final meskerem1Weekday = meskerem1Weekday0 + 1;

    int wenber = (ameteAlem % 19) - 1;
    if (wenber < 0) wenber = 0;
    final metqe = wenber == 0 ? 30 : (wenber * 19) % 30;
    final metqeMonth = metqe > 14 ? 1 : 2;

    int metqeWeekday0;
    if (metqeMonth == 1) {
      metqeWeekday0 = (meskerem1Weekday0 + metqe - 1) % 7;
    } else {
      final tikimt1Weekday0 = (meskerem1Weekday0 + 2) % 7;
      metqeWeekday0 = (tikimt1Weekday0 + metqe - 1) % 7;
    }

    const tewsakMap = {4: 2, 3: 3, 2: 4, 1: 5, 0: 6, 6: 7, 5: 8};
    final dayTewsak = tewsakMap[metqeWeekday0] ?? 4;

    int neneweMonth;
    int neneweDay;
    final total = metqe + dayTewsak;
    if (metqeMonth == 1) {
      if (total > 30) {
        neneweMonth = 6; // Yekatit
        neneweDay = total % 30 == 0 ? 30 : total % 30;
      } else {
        neneweMonth = 5; // Tir
        neneweDay = total;
      }
    } else {
      neneweMonth = 6; // Yekatit
      neneweDay = total % 30 == 0 ? 30 : total % 30;
    }

    ({int month, int day}) addDaysToNenewe(int offset) {
      int m = neneweMonth;
      int d = neneweDay + offset;
      while (d > 30) {
        d -= 30;
        m += 1;
      }
      return (month: m, day: d);
    }

    final abiyTsomStart = addDaysToNenewe(14);
    final abiyTsomEnd = addDaysToNenewe(68);
    final debreZeyt = addDaysToNenewe(41);
    final hosanna = addDaysToNenewe(62);
    final tseloteHamus = addDaysToNenewe(66);
    final siklet = addDaysToNenewe(67);
    final kedamSeur = addDaysToNenewe(68);
    final fasika = addDaysToNenewe(69);
    final rikbeKahnat = addDaysToNenewe(93);
    final erget = addDaysToNenewe(108);
    final peraklitos = addDaysToNenewe(118);
    final apostlesFastStart = addDaysToNenewe(119);
    const apostlesFastEnd = (month: 11, day: 5); // Hamle 5

    final apostlesDuration = (11 - apostlesFastStart.month) * 30 +
        (5 - apostlesFastStart.day) +
        1;

    return (
      year: year,
      evangelist: evangelist,
      isLeapYear: isLeap,
      meskerem1Weekday: meskerem1Weekday,
      nenewe: (month: neneweMonth, day: neneweDay),
      abiyTsom: (
        startMonth: abiyTsomStart.month,
        startDay: abiyTsomStart.day,
        endMonth: abiyTsomEnd.month,
        endDay: abiyTsomEnd.day,
        durationDays: 55,
      ),
      debreZeyt: debreZeyt,
      hosanna: hosanna,
      tseloteHamus: tseloteHamus,
      siklet: siklet,
      kedamSeur: kedamSeur,
      fasika: fasika,
      rikbeKahnat: rikbeKahnat,
      erget: erget,
      peraklitos: peraklitos,
      apostlesFast: (
        startMonth: apostlesFastStart.month,
        startDay: apostlesFastStart.day,
        endMonth: apostlesFastEnd.month,
        endDay: apostlesFastEnd.day,
        durationDays: apostlesDuration > 0 ? apostlesDuration : 1,
      ),
      bealeHamsa: (
        startMonth: fasika.month,
        startDay: fasika.day,
        endMonth: peraklitos.month,
        endDay: peraklitos.day,
      ),
    );
  }

  /// Returns weekday 1-7 (1=Monday ... 7=Sunday) for any Ethiopian date.
  static int getWeekday(int year, int month, int day) {
    final ameteAlem = 5500 + year;
    final rabeet = ameteAlem ~/ 4;
    final meskerem1Weekday0 = (ameteAlem + rabeet) % 7;
    final daysSince = (month - 1) * 30 + (day - 1);
    return ((meskerem1Weekday0 + daysSince) % 7) + 1;
  }

  /// Checks if an Ethiopian date is a fasting Wednesday or Friday (ጾመ ድኅነት).
  /// Excludes:
  /// 1. 50 joyful days of Beale Hamsa (Fasika to Pentecost).
  /// 2. Christmas / Genna (Tahsas 29, or 28 on leap year).
  /// 3. Epiphany / Timket (Tir 11).
  static bool isWednesdayFridayFastingDay(int year, int month, int day) {
    final w = getWeekday(year, month, day);
    if (w != 3 && w != 5) return false;

    final bh = calculateBahireHasab(year);
    final score = month * 100 + day;
    final hamsaStart = bh.bealeHamsa.startMonth * 100 + bh.bealeHamsa.startDay;
    final hamsaEnd = bh.bealeHamsa.endMonth * 100 + bh.bealeHamsa.endDay;

    if (score >= hamsaStart && score <= hamsaEnd) {
      return false;
    }

    final gennaDay = bh.isLeapYear ? 28 : 29;
    if (month == 4 && day == gennaDay) return false;
    if (month == 5 && day == 11) return false;

    return true;
  }

  /// Returns all day numbers in a given Ethiopian month that are fasting Wednesdays and Fridays.
  static List<int> getWednesdayFridayFastDaysForMonth(int year, int month) {
    final maxDays = getDaysInMonth(year, month);
    final fastDays = <int>[];
    for (int d = 1; d <= maxDays; d++) {
      if (isWednesdayFridayFastingDay(year, month, d)) {
        fastDays.add(d);
      }
    }
    return fastDays;
  }

  /// Converts a Gregorian hour and minute (0-23, 0-59) to an Ethiopian time representation.
  static EthiopianTime toEthiopianTime(int gregorianHour, int gregorianMinute) {
    int ethHour;
    String periodAmharic;
    String periodEnglish;

    if (gregorianHour >= 6 && gregorianHour < 12) {
      // 06:00 - 11:59 -> ጧት (Morning)
      ethHour = (gregorianHour == 6) ? 12 : (gregorianHour - 6);
      periodAmharic = 'ጧት';
      periodEnglish = 'Morning';
    } else if (gregorianHour >= 12 && gregorianHour < 18) {
      // 12:00 - 17:59 -> ከሰዓት / ቀትር (Afternoon)
      ethHour = (gregorianHour == 12) ? 6 : (gregorianHour - 6);
      periodAmharic = (gregorianHour == 12) ? 'ቀትር' : 'ከሰዓት';
      periodEnglish = (gregorianHour == 12) ? 'Noon' : 'Afternoon';
    } else if (gregorianHour >= 18 && gregorianHour < 24) {
      // 18:00 - 23:59 -> ምሽት (Evening)
      ethHour = (gregorianHour == 18) ? 12 : (gregorianHour - 18);
      periodAmharic = 'ምሽት';
      periodEnglish = 'Evening';
    } else {
      // 00:00 - 05:59 -> ሌሊት / እኩለ ሌሊት (Night / Midnight)
      ethHour = (gregorianHour == 0) ? 6 : (gregorianHour + 6);
      periodAmharic = (gregorianHour == 0) ? 'እኩለ ሌሊት' : 'ሌሊት';
      periodEnglish = (gregorianHour == 0) ? 'Midnight' : 'Night';
    }

    return EthiopianTime(
      hour: ethHour,
      minute: gregorianMinute,
      periodAmharic: periodAmharic,
      periodEnglish: periodEnglish,
      gregorianHour: gregorianHour,
      gregorianMinute: gregorianMinute,
    );
  }

  /// Converts Ethiopian time back to Gregorian hour (0-23) and minute (0-59).
  static ({int hour, int minute}) toGregorianTime({
    required int ethiopianHour,
    required int ethiopianMinute,
    required String period,
  }) {
    final p = period.toLowerCase();
    int gregHour;

    if (p.contains('ጧት') || p.contains('ጠዋት') || p.contains('morning')) {
      gregHour = (ethiopianHour == 12) ? 6 : (ethiopianHour + 6) % 24;
    } else if (p.contains('ቀትር') || p.contains('noon')) {
      gregHour = 12;
    } else if (p.contains('ከሰዓት') || p.contains('afternoon')) {
      gregHour = (ethiopianHour == 12) ? 18 : (ethiopianHour + 6) % 24;
    } else if (p.contains('ምሽት') || p.contains('evening')) {
      gregHour = (ethiopianHour == 12) ? 18 : (ethiopianHour + 18) % 24;
    } else if (p.contains('እኩለ') || p.contains('midnight')) {
      gregHour = 0;
    } else {
      // ሌሊት / night
      if (ethiopianHour == 6) {
        gregHour = 0;
      } else if (ethiopianHour == 12) {
        gregHour = 6;
      } else if (ethiopianHour >= 7 && ethiopianHour <= 11) {
        gregHour = ethiopianHour - 6;
      } else {
        gregHour = (ethiopianHour + 6) % 24;
      }
    }

    return (hour: gregHour, minute: ethiopianMinute);
  }

  /// Formatted string showing both Ethiopian and Gregorian times: e.g. "ጧት 2:00 (8:00 AM)"
  static String formatDualTime(int gregorianHour, int gregorianMinute) {
    final et = toEthiopianTime(gregorianHour, gregorianMinute);
    return et.formatDual();
  }
}

/// Class representing Ethiopian time with hour (1-12), minute (0-59), and period.
class EthiopianTime {
  final int hour; // 1-12
  final int minute; // 0-59
  final String periodAmharic; // 'ጧት', 'ቀትር', 'ከሰዓት', 'ምሽት', 'እኩለ ሌሊት', 'ሌሊት'
  final String periodEnglish; // 'Morning', 'Noon', 'Afternoon', 'Evening', 'Midnight', 'Night'
  final int gregorianHour; // 0-23
  final int gregorianMinute; // 0-59

  const EthiopianTime({
    required this.hour,
    required this.minute,
    required this.periodAmharic,
    required this.periodEnglish,
    required this.gregorianHour,
    required this.gregorianMinute,
  });

  /// Formatted Amharic time string, e.g. "ጧት 2:00" or "ጧት 5:30"
  String formatAmharic() {
    final m = minute.toString().padLeft(2, '0');
    return '$periodAmharic $hour:$m';
  }

  /// Formatted Gregorian time string, e.g. "08:00 AM" or "11:30 AM"
  String formatGregorian() {
    final h = gregorianHour % 12 == 0 ? 12 : gregorianHour % 12;
    final m = gregorianMinute.toString().padLeft(2, '0');
    final p = gregorianHour < 12 ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  /// Formatted dual time string, e.g. "ጧት 2:00 (8:00 AM)"
  String formatDual() {
    return '${formatAmharic()} (${formatGregorian()})';
  }

  @override
  String toString() => formatDual();
}
