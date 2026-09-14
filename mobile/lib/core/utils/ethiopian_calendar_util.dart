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
}
