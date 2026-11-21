// lib/features/calendar/domain/calendar_theme_colors.dart
// Domain model and presets for customizable Ethiopian calendar fasting and holiday colors.

import 'package:flutter/material.dart';

class CalendarColorPreset {
  final String id;
  final String name;
  final String nameEn;
  final String fastColorHex;
  final String holidayColorHex;
  final String feastColorHex;

  const CalendarColorPreset({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.fastColorHex,
    required this.holidayColorHex,
    required this.feastColorHex,
  });

  Color get fastColor =>
      CalendarThemeColors.parseHex(fastColorHex, const Color(0xFFF59E0B));
  Color get holidayColor =>
      CalendarThemeColors.parseHex(holidayColorHex, const Color(0xFFDC2626));
  Color get feastColor =>
      CalendarThemeColors.parseHex(feastColorHex, const Color(0xFF16A34A));
}

class CalendarThemeColors {
  static const String defaultFastHex = '#F59E0B'; // Amber Gold
  static const String defaultHolidayHex = '#DC2626'; // Crimson Red
  static const String defaultFeastHex = '#16A34A'; // Emerald Green

  final String fastColorHex;
  final String holidayColorHex;
  final String feastColorHex;

  const CalendarThemeColors({
    this.fastColorHex = defaultFastHex,
    this.holidayColorHex = defaultHolidayHex,
    this.feastColorHex = defaultFeastHex,
  });

  static Color parseHex(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  Color get fastColor => parseHex(fastColorHex, const Color(0xFFF59E0B));
  Color get holidayColor => parseHex(holidayColorHex, const Color(0xFFDC2626));
  Color get feastColor => parseHex(feastColorHex, const Color(0xFF16A34A));

  /// Adaptive text color for fasting cells depending on theme brightness.
  Color getFastTextColor(bool isDark) {
    final c = fastColor;
    final hsl = HSLColor.fromColor(c);
    if (isDark) {
      return hsl
          .withLightness((hsl.lightness + 0.32).clamp(0.4, 0.95))
          .toColor();
    } else {
      return hsl
          .withLightness((hsl.lightness - 0.22).clamp(0.1, 0.65))
          .toColor();
    }
  }

  /// Adaptive text color for feast cells.
  Color getFeastTextColor(bool isDark) {
    final c = feastColor;
    if (isDark) {
      final hsl = HSLColor.fromColor(c);
      return hsl
          .withLightness((hsl.lightness + 0.28).clamp(0.4, 0.92))
          .toColor();
    } else {
      return c;
    }
  }

  bool get isDefault =>
      fastColorHex.toUpperCase() == defaultFastHex.toUpperCase() &&
      holidayColorHex.toUpperCase() == defaultHolidayHex.toUpperCase() &&
      feastColorHex.toUpperCase() == defaultFeastHex.toUpperCase();

  CalendarThemeColors copyWith({
    String? fastColorHex,
    String? holidayColorHex,
    String? feastColorHex,
  }) {
    return CalendarThemeColors(
      fastColorHex: fastColorHex ?? this.fastColorHex,
      holidayColorHex: holidayColorHex ?? this.holidayColorHex,
      feastColorHex: feastColorHex ?? this.feastColorHex,
    );
  }

  // Curated theme presets
  static const List<CalendarColorPreset> presets = [
    CalendarColorPreset(
      id: 'classic',
      name: 'ቀኖናዊ (Canonical Default)',
      nameEn: 'Canonical Liturgical',
      fastColorHex: '#F59E0B', // Amber Gold
      holidayColorHex: '#DC2626', // Crimson Red
      feastColorHex: '#16A34A', // Emerald Green
    ),
    CalendarColorPreset(
      id: 'royal',
      name: 'ንጉሣዊ (Royal Monastic)',
      nameEn: 'Royal Monastic',
      fastColorHex: '#8B5CF6', // Royal Purple
      holidayColorHex: '#E11D48', // Ruby Rose
      feastColorHex: '#0D9488', // Deep Teal
    ),
    CalendarColorPreset(
      id: 'monastery',
      name: 'የገዳማት ጥበብ (Monastery Gold)',
      nameEn: 'Monastery Gold',
      fastColorHex: '#D97706', // Ochre Gold
      holidayColorHex: '#991B1B', // Deep Burgundy
      feastColorHex: '#65A30D', // Olive Green
    ),
    CalendarColorPreset(
      id: 'celestial',
      name: 'ሰማያዊ ንጋት (Celestial Azure)',
      nameEn: 'Celestial Azure',
      fastColorHex: '#0284C7', // Azure Blue
      holidayColorHex: '#F43F5E', // Coral Rose
      feastColorHex: '#059669', // Jade Green
    ),
    CalendarColorPreset(
      id: 'sunrise',
      name: 'ሞቅ ያለ ፀሐይ (Warm Sunrise)',
      nameEn: 'Warm Sunrise',
      fastColorHex: '#EA580C', // Tangerine
      holidayColorHex: '#BE123C', // Deep Crimson
      feastColorHex: '#15803D', // Forest Green
    ),
    CalendarColorPreset(
      id: 'high_contrast',
      name: 'ከፍተኛ ንጽጽር (High Contrast)',
      nameEn: 'High Contrast',
      fastColorHex: '#FF6D00', // Neon Orange
      holidayColorHex: '#D50000', // Vivid Red
      feastColorHex: '#00C853', // Vivid Green
    ),
  ];

  static const List<String> availableFastColors = [
    '#F59E0B', // Amber Gold (Default)
    '#D97706', // Ochre Deep Gold
    '#EA580C', // Tangerine Orange
    '#F97316', // Coral Orange
    '#8B5CF6', // Royal Purple
    '#6366F1', // Indigo Fast
    '#3B82F6', // Lenten Blue
    '#0284C7', // Deep Azure
    '#10B981', // Sage Fast
    '#78716C', // Monastic Earth Ash
    '#A855F7', // Violet
    '#EAB308', // Pure Gold
  ];

  static const List<String> availableHolidayColors = [
    '#DC2626', // Crimson Red (Default)
    '#EF4444', // Bright Red
    '#B91C1C', // Dark Crimson
    '#E11D48', // Rose Ruby
    '#BE123C', // Deep Rose
    '#991B1B', // Burgundy
    '#F43F5E', // Coral Crimson
    '#C026D3', // Fuchsia Feast
    '#D946EF', // Bright Orchid
    '#7C3AED', // Royal Violet
    '#EA580C', // Orange Flame
    '#DB2777', // Magenta Red
  ];

  static const List<String> availableFeastColors = [
    '#16A34A', // Emerald Green (Default)
    '#22C55E', // Bright Green
    '#15803D', // Forest Green
    '#059669', // Jade
    '#0D9488', // Teal
    '#14B8A6', // Aqua Teal
    '#06B6D4', // Cyan
    '#0284C7', // Sky Azure
    '#65A30D', // Olive Lime
    '#84CC16', // Bright Lime
    '#10B981', // Mint Green
    '#047857', // Deep Pine
  ];
}
