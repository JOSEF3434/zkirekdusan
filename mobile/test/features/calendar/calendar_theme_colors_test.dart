// test/features/calendar/calendar_theme_colors_test.dart
// Unit and Widget tests for user-customizable calendar fasting and holiday colors.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/features/calendar/domain/calendar_theme_colors.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_theme_colors_provider.dart';
import 'package:mobile/features/calendar/presentation/widgets/calendar_color_settings_sheet.dart';

class FakeLocalizationService extends LocalizationService {
  @override
  String translate(String key, [Map<String, dynamic>? args]) {
    if (args != null && args.containsKey('fallback')) {
      return args['fallback'].toString();
    }
    return key;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CalendarThemeColors Domain Model', () {
    test('defaults to canonical liturgical colors', () {
      const colors = CalendarThemeColors();
      expect(colors.fastColorHex, '#F59E0B');
      expect(colors.holidayColorHex, '#DC2626');
      expect(colors.feastColorHex, '#16A34A');
      expect(colors.isDefault, isTrue);

      expect(colors.fastColor, const Color(0xFFF59E0B));
      expect(colors.holidayColor, const Color(0xFFDC2626));
      expect(colors.feastColor, const Color(0xFF16A34A));
    });

    test('isDefault correctly identifies customized colors', () {
      const defaultColors = CalendarThemeColors();
      expect(defaultColors.isDefault, isTrue);

      final customFast = defaultColors.copyWith(fastColorHex: '#8B5CF6');
      expect(customFast.isDefault, isFalse);

      final customHoliday = defaultColors.copyWith(holidayColorHex: '#E11D48');
      expect(customHoliday.isDefault, isFalse);

      final customFeast = defaultColors.copyWith(feastColorHex: '#0D9488');
      expect(customFeast.isDefault, isFalse);
    });

    test('parseHex handles valid 6 and 8 digit hexes and fallbacks', () {
      expect(
        CalendarThemeColors.parseHex('#FF8800', Colors.black),
        const Color(0xFFFF8800),
      );
      expect(
        CalendarThemeColors.parseHex('8800FF', Colors.black),
        const Color(0xFF8800FF),
      );
      expect(
        CalendarThemeColors.parseHex('invalid', Colors.black),
        Colors.black,
      );
    });

    test('adaptive text colors return readable contrast in dark and light mode', () {
      const colors = CalendarThemeColors();
      final darkText = colors.getFastTextColor(true);
      final lightText = colors.getFastTextColor(false);

      expect(darkText, isNotNull);
      expect(lightText, isNotNull);
      // Dark mode text should have higher lightness than light mode text
      expect(
        HSLColor.fromColor(darkText).lightness,
        greaterThan(HSLColor.fromColor(lightText).lightness),
      );
    });

    test('all presets have valid colors and names', () {
      expect(CalendarThemeColors.presets.length, greaterThanOrEqualTo(5));
      for (final p in CalendarThemeColors.presets) {
        expect(p.id, isNotEmpty);
        expect(p.name, isNotEmpty);
        expect(p.fastColorHex, startsWith('#'));
        expect(p.holidayColorHex, startsWith('#'));
        expect(p.feastColorHex, startsWith('#'));
        expect(p.fastColor, isA<Color>());
        expect(p.holidayColor, isA<Color>());
        expect(p.feastColor, isA<Color>());
      }
    });
  });

  group('CalendarThemeColorsNotifier Persistence', () {
    test('loads from SharedPreferences if previously saved', () async {
      SharedPreferences.setMockInitialValues({
        CalendarThemeColorsNotifier.prefFastColor: '#8B5CF6',
        CalendarThemeColorsNotifier.prefHolidayColor: '#E11D48',
        CalendarThemeColorsNotifier.prefFeastColor: '#0D9488',
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = CalendarThemeColorsNotifier(prefs);

      expect(notifier.state.fastColorHex, '#8B5CF6');
      expect(notifier.state.holidayColorHex, '#E11D48');
      expect(notifier.state.feastColorHex, '#0D9488');
      expect(notifier.state.isDefault, isFalse);
    });

    test('updating colors updates state and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = CalendarThemeColorsNotifier(prefs);

      await notifier.setFastColor('#0284C7');
      expect(notifier.state.fastColorHex, '#0284C7');
      expect(prefs.getString(CalendarThemeColorsNotifier.prefFastColor), '#0284C7');

      await notifier.setHolidayColor('#BE123C');
      expect(notifier.state.holidayColorHex, '#BE123C');
      expect(prefs.getString(CalendarThemeColorsNotifier.prefHolidayColor), '#BE123C');

      await notifier.setFeastColor('#059669');
      expect(notifier.state.feastColorHex, '#059669');
      expect(prefs.getString(CalendarThemeColorsNotifier.prefFeastColor), '#059669');
    });

    test('applyPreset updates all 3 colors and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = CalendarThemeColorsNotifier(prefs);

      final royalPreset = CalendarThemeColors.presets.firstWhere((p) => p.id == 'royal');
      await notifier.applyPreset(royalPreset);

      expect(notifier.state.fastColorHex, royalPreset.fastColorHex);
      expect(notifier.state.holidayColorHex, royalPreset.holidayColorHex);
      expect(notifier.state.feastColorHex, royalPreset.feastColorHex);

      expect(
        prefs.getString(CalendarThemeColorsNotifier.prefFastColor),
        royalPreset.fastColorHex,
      );
    });

    test('resetToDefault clears preferences and resets to canonical defaults', () async {
      SharedPreferences.setMockInitialValues({
        CalendarThemeColorsNotifier.prefFastColor: '#8B5CF6',
        CalendarThemeColorsNotifier.prefHolidayColor: '#E11D48',
        CalendarThemeColorsNotifier.prefFeastColor: '#0D9488',
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = CalendarThemeColorsNotifier(prefs);

      expect(notifier.state.isDefault, isFalse);

      await notifier.resetToDefault();

      expect(notifier.state.isDefault, isTrue);
      expect(notifier.state.fastColorHex, CalendarThemeColors.defaultFastHex);
      expect(notifier.state.holidayColorHex, CalendarThemeColors.defaultHolidayHex);
      expect(notifier.state.feastColorHex, CalendarThemeColors.defaultFeastHex);

      expect(prefs.containsKey(CalendarThemeColorsNotifier.prefFastColor), isFalse);
    });
  });

  group('CalendarColorSettingsSheet Widget Tests', () {
    testWidgets('renders live preview, presets, and category selector', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localizationServiceProvider.overrideWithValue(FakeLocalizationService()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CalendarColorSettingsSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header title
      expect(find.text('የቀን መቁጠሪያ ቀለሞች'), findsOneWidget);

      // Live Preview day cells (15, 3, 28)
      expect(find.text('15'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
      expect(find.text('የጾም ዕለት'), findsOneWidget);
      expect(find.text('ዓቢይ በዓል'), findsNWidgets(2));
      expect(find.text('ጾም መጨረሻ'), findsOneWidget);

      // Preset list should show canonical preset
      expect(find.text('ቀኖናዊ (Canonical Default)'), findsOneWidget);

      // Category selector buttons
      expect(find.widgetWithText(SegmentedButton<int>, 'ጾም'), findsOneWidget);

      // Reset button exists
      expect(find.text('ወደ ነባሪ'), findsOneWidget);

      // Done button
      expect(find.text('ተከናውኗል'), findsOneWidget);
    });

    testWidgets('tapping a preset updates theme colors in real-time', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localizationServiceProvider.overrideWithValue(FakeLocalizationService()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return const CalendarColorSettingsSheet();
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially default
      expect(capturedRef.read(calendarThemeColorsProvider).isDefault, isTrue);

      // Find and tap "ንጉሣዊ (Royal Monastic)" preset
      final royalFinder = find.text('ንጉሣዊ (Royal Monastic)');
      expect(royalFinder, findsOneWidget);
      await tester.tap(royalFinder);
      await tester.pumpAndSettle();

      // Colors should now match Royal preset
      expect(capturedRef.read(calendarThemeColorsProvider).fastColorHex, '#8B5CF6');
      expect(capturedRef.read(calendarThemeColorsProvider).isDefault, isFalse);

      // Tap Reset to Default button
      await tester.tap(find.text('ወደ ነባሪ'));
      await tester.pumpAndSettle();

      // Colors should be back to default
      expect(capturedRef.read(calendarThemeColorsProvider).isDefault, isTrue);
      expect(capturedRef.read(calendarThemeColorsProvider).fastColorHex, '#F59E0B');
    });
  });
}
