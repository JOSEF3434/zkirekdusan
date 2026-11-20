import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calendar/domain/calendar_event_model.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_events_provider.dart';
import 'package:mobile/features/calendar/presentation/widgets/calendar_event_details_dialog.dart';
import 'package:mobile/features/calendar/presentation/widgets/monthly_fasts_holidays_summary.dart';

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

  const testEvent = CalendarEventModel(
    id: 'evt-test-1',
    name: 'ገና (ልደት)',
    nameEn: 'Nativity of Christ (Genna)',
    description: 'የጌታችን የመድኃኒታችን የኢየሱስ ክርስቶስ የልደት በዓል',
    type: CalendarEventType.holiday,
    category: CalendarEventCategory.majorHoliday,
    startMonth: 4,
    startDay: 29,
    endMonth: 4,
    endDay: 29,
    isRecurring: true,
    primaryColor: '#10B981',
    spiritualMeaning: 'Celebration of the Incarnation of the Word',
    fastingRules: null,
    durationDays: 1,
    isMajor: true,
    isActive: true,
  );

  const testFast = CalendarEventModel(
    id: 'evt-test-2',
    name: 'ጾመ ነቢያት',
    nameEn: 'Fast of the Prophets',
    description: 'ከጌታችን ልደት በፊት የሚጾም የ44 ቀን ጾም',
    type: CalendarEventType.fast,
    category: CalendarEventCategory.majorFast,
    startMonth: 3,
    startDay: 15,
    endMonth: 4,
    endDay: 28,
    isRecurring: true,
    primaryColor: '#3B82F6',
    spiritualMeaning: 'Commemorating the prophecies of the Old Testament prophets',
    fastingRules: 'Abstinence from meat, poultry, dairy, and eggs',
    durationDays: 44,
    isMajor: true,
    isActive: true,
  );

  final fakeLocalization = FakeLocalizationService();

  group('CalendarEventDetailsDialog Widget Tests', () {
    testWidgets('renders all details for holiday', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localizationServiceProvider.overrideWithValue(fakeLocalization),
            trProvider.overrideWith((ref) => fakeLocalization.translate),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CalendarEventDetailsDialog(
                event: testEvent,
                selectedDay: 29,
                selectedMonth: 4,
                selectedYear: 2016,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ገና (ልደት)'), findsOneWidget);
      expect(find.text('የጌታችን የመድኃኒታችን የኢየሱስ ክርስቶስ የልደት በዓል'), findsOneWidget);
      expect(find.text('Celebration of the Incarnation of the Word'), findsOneWidget);
    });

    testWidgets('renders fasting rules and duration for fast', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localizationServiceProvider.overrideWithValue(fakeLocalization),
            trProvider.overrideWith((ref) => fakeLocalization.translate),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CalendarEventDetailsDialog(
                event: testFast,
                selectedDay: 15,
                selectedMonth: 3,
                selectedYear: 2016,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ጾመ ነቢያት'), findsWidgets);
      expect(find.text('ከጌታችን ልደት በፊት የሚጾም የ44 ቀን ጾም'), findsOneWidget);
      expect(find.text('Abstinence from meat, poultry, dairy, and eggs'), findsOneWidget);
      expect(find.text('44 ቀናት'), findsOneWidget);
    });
  });

  group('MonthlyFastsHolidaysSummary Widget Tests', () {
    testWidgets('renders summary with events list', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localizationServiceProvider.overrideWithValue(fakeLocalization),
            trProvider.overrideWith((ref) => fakeLocalization.translate),
            calendarEventsForMonthProvider((year: 2016, month: 4)).overrideWith(
              (ref) => [testEvent, testFast],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MonthlyFastsHolidaysSummary(
                  year: 2016,
                  month: 4,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show the section title
      expect(find.text('የዚህ ወር አጽዋማት እና በዓላት'), findsOneWidget);
      // Should show both events
      expect(find.text('ገና (ልደት)'), findsOneWidget);
      expect(find.text('ጾመ ነቢያት'), findsOneWidget);
      // Should show "View All Fasts & Holidays of the Year" button
      expect(find.text('የዓመቱ አጽዋማትና በዓላት በሙሉ'), findsOneWidget);
    });

    testWidgets('renders empty state when no events in month', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localizationServiceProvider.overrideWithValue(fakeLocalization),
            trProvider.overrideWith((ref) => fakeLocalization.translate),
            calendarEventsForMonthProvider((year: 2016, month: 13)).overrideWith(
              (ref) => <CalendarEventModel>[],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MonthlyFastsHolidaysSummary(
                  year: 2016,
                  month: 13,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('በዚህ ወር የተመዘገበ ጾም ወይም በዓል የለም'), findsOneWidget);
    });
  });
}
