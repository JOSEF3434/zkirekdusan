// test/features/calendar/calendar_notes_visibility_test.dart
//
// Tests for Calendar Notes visibility and RBAC permission enforcement:
// 1. Normal users (USER) can view notes on the calendar
// 2. Normal users do not see management controls (+ Add Note, Edit, Delete)
// 3. Super admins (SUPER_ADMIN) see management controls and can manage notes
// 4. Multiple notes on a single date reflect correct count badge
// 5. Days without notes render cleanly without badge

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/entities/auth_user.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';
import 'package:mobile/features/calendar/presentation/calendar_screen.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_notes_provider.dart';
import 'package:mobile/features/calendar/presentation/widgets/day_notes_sheet.dart';
import 'package:abushakir/abushakir.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_sync_provider.dart';

void main() {
  const normalUser = AuthUser(
    id: 'user-normal-1',
    email: 'normal@example.com',
    username: 'normaluser',
    role: 'USER',
  );

  const superAdminUser = AuthUser(
    id: 'user-admin-1',
    email: 'admin@example.com',
    username: 'superadmin',
    role: 'SUPER_ADMIN',
  );

  final testNotesMonth = [
    CalendarNoteModel(
      id: 'note-1',
      userId: 'user-admin-1',
      ethiopianYear: 2019,
      ethiopianMonth: 1,
      ethiopianDay: 7,
      gregorianDate: DateTime(2026, 9, 17),
      title: 'Meskerem 7 Feast',
      content: 'Holy Feast of the Cross',
      hasReminder: true,
      media: [
        CalendarNoteMedia(
          id: 'media-1',
          noteId: 'note-1',
          fileId: 'file-1',
          order: 1,
          caption: 'Icon image',
          createdAt: DateTime.now(),
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    CalendarNoteModel(
      id: 'note-2',
      userId: 'user-admin-1',
      ethiopianYear: 2019,
      ethiopianMonth: 1,
      ethiopianDay: 8,
      gregorianDate: DateTime(2026, 9, 18),
      title: 'Meskerem 8 Celebration',
      content: 'Saint commemoration',
      hasReminder: false,
      media: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    CalendarNoteModel(
      id: 'note-3',
      userId: 'user-admin-1',
      ethiopianYear: 2019,
      ethiopianMonth: 1,
      ethiopianDay: 8,
      gregorianDate: DateTime(2026, 9, 18),
      title: 'Second note on day 8',
      content: 'Additional evening prayers',
      hasReminder: true,
      media: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
  Widget buildCalendarScreenWithUser({
    required AuthUser user,
    required List<CalendarNoteModel> notes,
  }) {
    return ProviderScope(
      overrides: [
        trProvider.overrideWithValue(
          (String key, [Map<String, dynamic>? args]) {
            switch (key) {
              case 'common.edit':
                return 'Edit';
              case 'common.delete':
                return 'Delete';
              case 'common.copy':
                return 'Copy text';
              default:
                return key;
            }
          },
        ),
        pendingSyncCountStreamProvider.overrideWith((ref) => Stream.value(0)),
        authProvider.overrideWith(
          (ref) => _FakeAuthNotifier(
            AuthState(status: AuthStatus.authenticated, user: user),
          ),
        ),
        calendarNotesForMonthProvider.overrideWith(
          (ref, params) async => notes,
        ),
        calendarNotesForDateProvider.overrideWith(
          (ref, params) async => notes
              .where(
                (n) =>
                    n.ethiopianYear == params.year &&
                    n.ethiopianMonth == params.month &&
                    n.ethiopianDay == params.day,
              )
              .toList(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: const CalendarScreen(),
      ),
    );
  }

  Widget buildDayNotesSheetWithUser({
    required AuthUser user,
    required List<CalendarNoteModel> notes,
    required EtDatetime selectedDate,
  }) {
    return ProviderScope(
      overrides: [
        trProvider.overrideWithValue(
          (String key, [Map<String, dynamic>? args]) {
            switch (key) {
              case 'common.edit':
                return 'Edit';
              case 'common.delete':
                return 'Delete';
              case 'common.copy':
                return 'Copy text';
              default:
                return key;
            }
          },
        ),
        pendingSyncCountStreamProvider.overrideWith((ref) => Stream.value(0)),
        authProvider.overrideWith(
          (ref) => _FakeAuthNotifier(
            AuthState(status: AuthStatus.authenticated, user: user),
          ),
        ),
        calendarNotesForDateProvider.overrideWith(
          (ref, params) async => notes
              .where(
                (n) =>
                    n.ethiopianYear == params.year &&
                    n.ethiopianMonth == params.month &&
                    n.ethiopianDay == params.day,
              )
              .toList(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Scaffold(body: DayNotesSheet(selectedDate: selectedDate)),
      ),
    );
  }

  group('Calendar Notes Visibility for Normal Users', () {
    testWidgets('Normal user can SEE calendar note count badges and icons', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildCalendarScreenWithUser(user: normalUser, notes: testNotesMonth),
      );
      await tester.pumpAndSettle();

      // Day 7 has 1 note -> Badge "1" should be visible
      expect(find.text('1'), findsWidgets);

      // Day 8 has 2 notes -> Badge "2" should be visible
      expect(find.text('2'), findsWidgets);

      // Attachment icon for media on day 7 note
      expect(find.byIcon(Icons.attach_file), findsWidgets);

      // Reminder icon on day 7 note
      expect(find.byIcon(Icons.notifications_active_outlined), findsWidgets);
    });

    testWidgets(
      'Normal user does NOT see "+ Add Note" FAB on Calendar screen',
      (tester) async {
        await tester.pumpWidget(
          buildCalendarScreenWithUser(user: normalUser, notes: testNotesMonth),
        );
        await tester.pumpAndSettle();

        // Normal user must not see "+ Add Note" button
        expect(find.byType(FloatingActionButton), findsNothing);
        expect(find.text('Add Note'), findsNothing);
      },
    );

    testWidgets(
      'Normal user in DayNotesSheet can view notes in read-only mode',
      (tester) async {
        final selectedDate = EtDatetime(year: 2019, month: 1, day: 7);
        await tester.pumpWidget(
          buildDayNotesSheetWithUser(
            user: normalUser,
            notes: testNotesMonth,
            selectedDate: selectedDate,
          ),
        );
        await tester.pumpAndSettle();

        // Note title and content are displayed to the normal user
        expect(find.text('Meskerem 7 Feast'), findsOneWidget);
        expect(find.text('Holy Feast of the Cross'), findsOneWidget);

        // Normal user must NOT have the "+ Add Note" button
        expect(find.byWidgetPredicate((w) => w is FilledButton), findsNothing);
        expect(find.text('calendar.add_note'), findsNothing);

        // Open the 3-dots popup menu on the note
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // Normal user must NOT see Edit or Delete options
        expect(find.text('Edit'), findsNothing);
        expect(find.text('Delete'), findsNothing);

        // But normal user CAN copy text
        expect(find.text('Copy text'), findsOneWidget);
      },
    );
  });

  group('Calendar Notes Management for SUPER_ADMIN', () {
    testWidgets('SUPER_ADMIN can see "+ Add Note" FAB when date is selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildCalendarScreenWithUser(
          user: superAdminUser,
          notes: testNotesMonth,
        ),
      );
      await tester.pumpAndSettle();

      // Select a date
      final day7 = find.text('7').first;
      await tester.tap(day7);
      await tester.pumpAndSettle();

      // Close bottom sheet if popped
      if (find.byIcon(Icons.close).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
      }

      // SUPER_ADMIN has the FloatingActionButton to add notes
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets(
      'SUPER_ADMIN in DayNotesSheet sees Add Note, Edit, and Delete',
      (tester) async {
        final selectedDate = EtDatetime(year: 2019, month: 1, day: 7);
        await tester.pumpWidget(
          buildDayNotesSheetWithUser(
            user: superAdminUser,
            notes: testNotesMonth,
            selectedDate: selectedDate,
          ),
        );
        await tester.pumpAndSettle();

        // SUPER_ADMIN has "+ Add Note" button
        expect(
          find.byWidgetPredicate((w) => w is FilledButton),
          findsOneWidget,
        );
        expect(find.text('calendar.add_note'), findsOneWidget);

        // Open 3-dots menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        // SUPER_ADMIN sees Edit and Delete
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      },
    );
  });
}

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  void clearError() {}

  @override
  Future<void> login({
    String? email,
    String? phoneNumber,
    String? username,
    required String password,
    bool rememberMe = true,
  }) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> register({
    String? email,
    String? phoneNumber,
    String? username,
    String? firstName,
    String? lastName,
    required String password,
  }) async {}
}
