import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abushakir/abushakir.dart';
import 'package:mobile/core/presentation/widgets/app_network_image.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/domain/entities/auth_user.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/calendar/domain/calendar_note_model.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_download_settings_provider.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_notes_provider.dart';
import 'package:mobile/features/calendar/presentation/providers/calendar_sync_provider.dart';
import 'package:mobile/features/calendar/presentation/widgets/day_notes_sheet.dart';

void main() {
  const normalUser = AuthUser(
    id: 'user-normal-1',
    email: 'normal@example.com',
    username: 'normaluser',
    role: 'USER',
  );

  final sampleNoteWithMedia = CalendarNoteModel(
    id: 'note-media-1',
    userId: 'admin-user',
    ethiopianYear: 2019,
    ethiopianMonth: 1,
    ethiopianDay: 7,
    gregorianDate: DateTime(2026, 9, 17),
    title: 'Test Note with Media',
    content: 'This note has media attached',
    media: [
      CalendarNoteMedia(
        id: 'media-1',
        noteId: 'note-media-1',
        fileId: 'file-1',
        order: 0,
        createdAt: DateTime(2026, 9, 17),
        file: {
          'id': 'file-1',
          'url':
              'https://res.cloudinary.com/v6zdpkoh/image/upload/v1790666020/posts/4a7a8988-0deb-4c4d-9685-97577886df56/file_joosjv.jpg',
          'mimeType': 'image/jpeg',
          'fileType': 'IMAGE',
        },
      ),
    ],
    createdAt: DateTime(2026, 9, 17),
    updatedAt: DateTime(2026, 9, 17),
  );

  testWidgets('DayNotesSheet renders AppNetworkImage for attached media', (
    tester,
  ) async {
    final etDate = EtDatetime(year: 2019, month: 1, day: 7);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trProvider.overrideWithValue(
            (String key, [Map<String, dynamic>? args]) => key,
          ),
          pendingSyncCountStreamProvider.overrideWith((ref) => Stream.value(0)),
          authProvider.overrideWith(
            (ref) => _FakeAuthNotifier(
              AuthState(status: AuthStatus.authenticated, user: normalUser),
            ),
          ),
          calendarNotesForDateProvider.overrideWith(
            (ref, params) async => [sampleNoteWithMedia],
          ),
          calendarDownloadEnabledProvider.overrideWith(
            (ref) => _FakeDownloadSettingsNotifier(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: DayNotesSheet(selectedDate: etDate)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify the title is displayed
    expect(find.text('Test Note with Media'), findsOneWidget);

    // Verify AppNetworkImage is present for the media item
    expect(find.byType(AppNetworkImage), findsOneWidget);

    // Verify MediaUrlResolver resolves the valid URL
    final resolved = MediaUrlResolver.resolve(
      sampleNoteWithMedia.media.first.file!['url'] as String,
    );
    expect(
      resolved,
      'https://res.cloudinary.com/v6zdpkoh/image/upload/v1790666020/posts/4a7a8988-0deb-4c4d-9685-97577886df56/file_joosjv.jpg',
    );
  });
}

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDownloadSettingsNotifier extends CalendarDownloadSettingsNotifier {
  _FakeDownloadSettingsNotifier() : super() {
    state = true;
  }
}
