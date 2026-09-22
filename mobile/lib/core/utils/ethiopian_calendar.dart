// lib/core/utils/ethiopian_calendar.dart
// Ethiopian (Ge'ez) calendar utilities for date/time formatting.
//
// The Ethiopian calendar has 13 months (12 × 30 days + Pagume 5–6 days).
// The year starts on ~September 11–12 Gregorian (Enkutatash / Ethiopian New Year).
// Ethiopian time is offset 6 hours from Western time: 1:00 EtClock = 07:00 Gregorian AM.

class EthiopianCalendar {
  // ─── Month names (Amharic / Ge'ez) ─────────────────────────────────────────
  static const List<String> monthNamesAm = [
    'መስከረም', // 1  Sep 11–Oct 10
    'ጥቅምት',   // 2  Oct 11–Nov 9
    'ህዳር',    // 3  Nov 10–Dec 9
    'ታህሳስ',   // 4  Dec 10–Jan 8
    'ጥር',     // 5  Jan 9–Feb 7
    'የካቲት',   // 6  Feb 8–Mar 9
    'መጋቢት',   // 7  Mar 10–Apr 8
    'ሚያዚያ',   // 8  Apr 9–May 8
    'ግንቦት',   // 9  May 9–Jun 7
    'ሰኔ',     // 10 Jun 8–Jul 7
    'ሐምሌ',    // 11 Jul 8–Aug 6
    'ነሐሴ',    // 12 Aug 7–Sep 5
    'ጳጉሜ',   // 13 Sep 6–Sep 10/11 (intercalary)
  ];

  static const List<String> monthNamesEn = [
    'Meskerem', 'Tikimt', 'Hidar', 'Tahsas', 'Tir', 'Yekatit',
    'Megabit', 'Miazia', 'Ginbot', 'Sene', 'Hamle', 'Nehase', 'Pagume',
  ];

  static const List<String> dayNamesAm = [
    'እሑድ',   // Sunday
    'ሰኞ',    // Monday
    'ማክሰኞ',  // Tuesday
    'ረቡዕ',   // Wednesday
    'ሐሙስ',   // Thursday
    'ዓርብ',   // Friday
    'ቅዳሜ',   // Saturday
  ];

  // ─── Gregorian → Ethiopian ──────────────────────────────────────────────────

  /// Returns an [EthDateTime] representing the Ethiopian equivalent of [gregorian].
  static EthDateTime fromGregorian(DateTime gregorian) {
    final jdn = _gregorianToJDN(gregorian.year, gregorian.month, gregorian.day);
    return _jdnToEthiopian(jdn);
  }

  // Julian Day Number from Gregorian date.
  static int _gregorianToJDN(int y, int m, int d) {
    final a = (14 - m) ~/ 12;
    final yr = y + 4800 - a;
    final mo = m + 12 * a - 3;
    return d +
        (153 * mo + 2) ~/ 5 +
        365 * yr +
        yr ~/ 4 -
        yr ~/ 100 +
        yr ~/ 400 -
        32045;
  }

  // Ethiopian epoch in JDN = 1724221 (Meskerem 1, 1 AM = August 29, 8 AD Gregorian).
  static const int _ethEpoch = 1724221;

  static EthDateTime _jdnToEthiopian(int jdn) {
    final r = (jdn - _ethEpoch) % 1461;
    final n = r % 365 + 365 * (r ~/ 1460);
    final year = 4 * ((jdn - _ethEpoch) ~/ 1461) + r ~/ 365 - r ~/ 1460;
    final month = n ~/ 30 + 1;
    final day = n % 30 + 1;
    return EthDateTime(year: year, month: month, day: day);
  }

  // ─── Formatting helpers ─────────────────────────────────────────────────────

  /// Full date in Amharic: "12 መስከረም 2019"
  static String formatDateAm(DateTime gregorian) {
    final eth = fromGregorian(gregorian);
    final monthName = eth.month >= 1 && eth.month <= 13
        ? monthNamesAm[eth.month - 1]
        : '?';
    return '${eth.day} $monthName ${eth.year}';
  }

  /// Short date with English month name: "12 Meskerem 2019 (Ethiopian)"
  static String formatDateEn(DateTime gregorian) {
    final eth = fromGregorian(gregorian);
    final monthName = eth.month >= 1 && eth.month <= 13
        ? monthNamesEn[eth.month - 1]
        : '?';
    return '${eth.day} $monthName ${eth.year} (ET)';
  }

  /// Day name in Amharic.
  static String dayNameAm(DateTime gregorian) => dayNamesAm[gregorian.weekday % 7];

  /// Full readable date + day name:  "ሰኞ, 12 መስከረም 2019"
  static String formatFullDateAm(DateTime gregorian) {
    return '${dayNameAm(gregorian)}, ${formatDateAm(gregorian)}';
  }

  /// Ethiopian clock time.
  ///
  /// Ethiopian time starts at 1:00 when Gregorian is 07:00.
  /// So Ethiopian hour = (Gregorian hour + 18) % 12, minimum 1 (never 0).
  ///   Gregorian 00:00 → 6:00 ሌሊት (night)
  ///   Gregorian 06:00 → 12:00 ጧት (morning)
  ///   Gregorian 07:00 → 1:00 ጧት
  ///   Gregorian 12:00 → 6:00 ቀትር (noon)
  ///   Gregorian 18:00 → 12:00 ምሽት (evening)
  static String formatTimeAm(DateTime gregorian) {
    return formatTimeOfDayAm(gregorian.hour, gregorian.minute);
  }

  static String formatTimeOfDayAm(int hour24, int minute) {
    final ethHour = (hour24 + 18) % 12 == 0 ? 12 : (hour24 + 18) % 12;
    final period = _timePeriod(hour24);
    final min = minute.toString().padLeft(2, '0');
    return '$ethHour:$min $period';
  }

  static String _timePeriod(int hour24) {
    if (hour24 >= 0 && hour24 < 6) return 'ሌሊት';   // night  (midnight–6AM)
    if (hour24 >= 6 && hour24 < 12) return 'ጧት';    // morning(6AM–noon)
    if (hour24 >= 12 && hour24 < 18) return 'ቀትር';  // noon   (noon–6PM)
    return 'ምሽት';                                     // evening(6PM–midnight)
  }

  /// Combined date + time in Amharic Ethiopian format.
  /// Example: "ሰኞ, 12 መስከረም 2019 · 1:30 ጧት"
  static String formatDateTimeAm(DateTime gregorian) {
    return '${formatFullDateAm(gregorian)} · ${formatTimeAm(gregorian)}';
  }

  /// Returns a two-line display: line1 = Gregorian, line2 = Ethiopian.
  static ({String gregorian, String ethiopian}) formatBoth(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final greg =
        '${dt.day} ${months[dt.month - 1]} ${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final eth = formatDateTimeAm(dt);
    return (gregorian: greg, ethiopian: eth);
  }

  /// Whether [year] is an Ethiopian leap year (every 4th year, year % 4 == 3).
  static bool isLeapYear(int ethYear) => ethYear % 4 == 3;
}

/// A lightweight value object representing an Ethiopian calendar date.
class EthDateTime {
  final int year;
  final int month; // 1–13
  final int day;   // 1–30

  const EthDateTime({
    required this.year,
    required this.month,
    required this.day,
  });

  @override
  String toString() => '$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}';
}
