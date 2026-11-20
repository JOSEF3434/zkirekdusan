import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/presentation/widgets/manage_calendar_event_dialog.dart';
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

  const testHoliday = CalendarEventModel(
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
    primaryColor: '#DC2626',
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
    primaryColor: '#F59E0B',
    spiritualMeaning: 'Commemorating the prophecies of the Old Testament prophets',
    fastingRules: 'Abstinence from meat, poultry, dairy, and eggs',
    durationDays: 44,
    isMajor: true,
    isActive: true,
  );

  const testSpecial = CalendarEventModel(
    id: 'evt-test-3',
    name: 'ደብረ ምጥማቅ',
    nameEn: 'Debre Mitmaq',
    description: 'የእመቤታችን ቅድስት ድንግል ማርያም ዓመታዊ በዓል',
    type: CalendarEventType.specialEvent,
    category: CalendarEventCategory.annualFeast,
    startMonth: 9,
    startDay: 21,
    endMonth: 9,
    endDay: 21,
    isRecurring: true,
    primaryColor: '#16A34A',
    isMajor: false,
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
                event: testHoliday,
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

    testWidgets('renders all details for special event', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localizationServiceProvider.overrideWithValue(fakeLocalization),
            trProvider.overrideWith((ref) => fakeLocalization.translate),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CalendarEventDetailsDialog(
                event: testSpecial,
                selectedDay: 21,
                selectedMonth: 9,
                selectedYear: 2016,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ደብረ ምጥማቅ'), findsOneWidget);
      expect(find.text('የእመቤታችን ቅድስት ድንግል ማርያም ዓመታዊ በዓል'), findsOneWidget);
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

    testWidgets('renders multi-event switcher when multiple events occur on same day',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localizationServiceProvider.overrideWithValue(fakeLocalization),
            trProvider.overrideWith((ref) => fakeLocalization.translate),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CalendarEventDetailsDialog(
                events: [testHoliday, testFast],
                selectedDay: 28,
                selectedMonth: 4,
                selectedYear: 2016,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header for multiple events section
      expect(find.text('በዚህ ቀን ያሉ ሁነቶች'), findsOneWidget);

      // Check both chips are present
      expect(find.widgetWithText(ChoiceChip, 'ገና (ልደት)'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'ጾመ ነቢያት'), findsOneWidget);

      // Initially, first event (testHoliday) is active
      expect(find.text('Celebration of the Incarnation of the Word'), findsOneWidget);

      // Tap on second chip (testFast)
      await tester.tap(find.widgetWithText(ChoiceChip, 'ጾመ ነቢያት'));
      await tester.pumpAndSettle();

      // Now second event details should be visible
      expect(find.text('Abstinence from meat, poultry, dairy, and eggs'), findsOneWidget);
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
              (ref) => [testHoliday, testFast],
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

  group('ManageCalendarEventDialog Widget Tests', () {
    testWidgets('renders configuration mode selector and live preview', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localizationServiceProvider.overrideWithValue(fakeLocalization),
            trProvider.overrideWith((ref) => fakeLocalization.translate),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ManageCalendarEventDialog(
                prefillYear: 2016,
                prefillMonth: 4,
                prefillDay: 29,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check title
      expect(find.text('የቀን ማስተካከያ እና የቀለም ቅንብር'), findsOneWidget);

      // Check SegmentedButton options (Specific Day vs Date Range)
      expect(find.text('አንድ ቀን ብቻ'), findsOneWidget);
      expect(find.text('የቀናት ወሰን'), findsOneWidget);

      // Check Live Preview section is displayed
      expect(find.text('የቀን ገጽታ ቅድመ እይታ (Live Preview)'), findsOneWidget);

      // Check prefilled day number 29 is visible in the live preview
      expect(find.text('29'), findsWidgets);
    });

    testWidgets('switching between Specific Day and Date Range displays end-date selector',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localizationServiceProvider.overrideWithValue(fakeLocalization),
            trProvider.overrideWith((ref) => fakeLocalization.translate),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ManageCalendarEventDialog(
                initialEvent: testFast,
                prefillYear: 2016,
                prefillMonth: 3,
                prefillDay: 15,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // testFast is already Date Range -> "ማብቂያ ወር" is shown
      expect(find.text('ማብቂያ ወር'), findsOneWidget);

      // Fasting start/end markers checkboxes should appear for Date Range fast
      expect(find.text('የመግቢያ ምልክት (መግቢያ)'), findsOneWidget);
      expect(find.text('የማብቂያ ምልክት (ፍጻሜ)'), findsOneWidget);

      // Switch to Specific Day mode
      await tester.tap(find.text('አንድ ቀን ብቻ'));
      await tester.pumpAndSettle();

      // Now "ማብቂያ ወር" should disappear
      expect(find.text('ማብቂያ ወር'), findsNothing);
    });
  });
}
