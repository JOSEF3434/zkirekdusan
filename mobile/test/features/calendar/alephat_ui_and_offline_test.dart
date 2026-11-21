// test/features/calendar/alephat_ui_and_offline_test.dart
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/core/presentation/providers/preferences_provider.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/presentation/providers/admin_permissions_provider.dart';
import 'package:mobile/features/calendar/alephat/data/alephat_repository.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_letter_model.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_22_model.dart';
import 'package:mobile/features/calendar/alephat/presentation/providers/alephat_providers.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/alephat_learning_view.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/alephat_22_view.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/letter_selection_bar.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/letter_keyboard_grid.dart';
import 'package:mobile/features/calendar/alephat/data/alephat_seed_data.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/letter_info_panel.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/letter_family_display.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/manage_letter_dialog.dart';
import 'package:mobile/features/calendar/presentation/calendar_screen.dart';

class FakeConnectivityNotifier extends StateNotifier<ConnectivityState>
    implements ConnectivityNotifier {
  FakeConnectivityNotifier([
    super.state = const ConnectivityState(
      status: ConnectivityStatus.online,
      isInitialized: true,
      isReachable: true,
    ),
  ]);

  @override
  void addOnlineStatusListener(void Function(bool isOnline) listener) {}

  @override
  void removeOnlineStatusListener(void Function(bool isOnline) listener) {}

  @override
  Future<bool> checkActualReachability() async => state.isOnline;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─────────────────────────────────────────────────────────
  // Authentic Ethiopian Test Data (ሀ through ፐ)
  // ─────────────────────────────────────────────────────────

  final sampleFamilyHa = [
    const AlephatFamilyMemberModel(
      id: 'm-1',
      baseLetterId: 'l-1',
      glyph: 'ሀ',
      orderIndex: 1,
      orderName: 'ግዕዝ',
      note: 'ሀ፡ የሆይ የመጀመሪያ ድምጽ።',
      pronunciation: 'hä',
    ),
    const AlephatFamilyMemberModel(
      id: 'm-2',
      baseLetterId: 'l-1',
      glyph: 'ሁ',
      orderIndex: 2,
      orderName: 'ካዕብ',
      note: 'ሁ፡ የሆይ ሁለተኛ ድምጽ።',
      pronunciation: 'hu',
    ),
    const AlephatFamilyMemberModel(
      id: 'm-3',
      baseLetterId: 'l-1',
      glyph: 'ሂ',
      orderIndex: 3,
      orderName: 'ሣልስ',
      note: 'ሂ፡ የሆይ ሦስተኛ ድምጽ።',
      pronunciation: 'hi',
    ),
    const AlephatFamilyMemberModel(
      id: 'm-4',
      baseLetterId: 'l-1',
      glyph: 'ሃ',
      orderIndex: 4,
      orderName: 'ራብዕ',
      note: 'ሃ፡ የሆይ አራተኛ ድምጽ።',
      pronunciation: 'ha',
    ),
    const AlephatFamilyMemberModel(
      id: 'm-5',
      baseLetterId: 'l-1',
      glyph: 'ሄ',
      orderIndex: 5,
      orderName: 'ኃምስ',
      note: 'ሄ፡ የሆይ አምስተኛ ድምጽ።',
      pronunciation: 'hé',
    ),
    const AlephatFamilyMemberModel(
      id: 'm-6',
      baseLetterId: 'l-1',
      glyph: 'ህ',
      orderIndex: 6,
      orderName: 'ሳድስ',
      note: 'ህ፡ የሆይ ስድስተኛ ድምጽ።',
      pronunciation: 'hə',
    ),
    const AlephatFamilyMemberModel(
      id: 'm-7',
      baseLetterId: 'l-1',
      glyph: 'ሆ',
      orderIndex: 7,
      orderName: 'ሳብዕ',
      note: 'ሆ፡ የሆይ ሰባተኛ ድምጽ።',
      pronunciation: 'ho',
    ),
  ];

  final sampleLetters = [
    AlephatLetterModel(
      id: 'l-1',
      letter: 'ሀ',
      name: 'ሆይ',
      order: 1,
      defaultNote: 'ሀ፡ ሆይ ይባላል። የመጀመሪያው የፊደል መገኛ ድምጽ ነው።',
      pronunciationGuide: 'Hä - Glottal fricative',
      familyMembers: sampleFamilyHa,
    ),
    const AlephatLetterModel(
      id: 'l-2',
      letter: 'ለ',
      name: 'ላዊ',
      order: 2,
      defaultNote: 'ለ፡ ላዊ ይባላል። በምላስና ድድ የሚነገር ፈሳሽ ድምጽ ነው።',
      pronunciationGuide: 'Lä - Lateral',
      familyMembers: [
        AlephatFamilyMemberModel(
          id: 'm-l1',
          baseLetterId: 'l-2',
          glyph: 'ለ',
          orderIndex: 1,
          orderName: 'ግዕዝ',
          note: 'ለ፡ የላዊ የመጀመሪያ ድምጽ።',
        ),
      ],
    ),
    const AlephatLetterModel(
      id: 'l-16',
      letter: 'አ',
      name: 'አልፍ',
      order: 16,
      defaultNote: 'አ፡ አልፍ ይባላል። ከጉሮሮ የሚወጣ የአናባቢ መክፈቻ ድምጽ ነው።',
      pronunciationGuide: '’ä - Glottal stop',
      familyMembers: [],
    ),
    const AlephatLetterModel(
      id: 'l-33',
      letter: 'ፐ',
      name: 'ፔ',
      order: 33,
      defaultNote: 'ፐ፡ ፔ ይባላል። በከንፈሮች ፍንዳታ የሚወጣ ድምጽ ነው።',
      pronunciationGuide: 'Pä - Bilabial stop',
      familyMembers: [],
    ),
  ];

  final sample22List = [
    const Alephat22Model(
      id: 'entry-1',
      letter: 'አ',
      title: 'አሌፍ (አ)',
      meaning: 'አምላክ፣ መጀመሪያ',
      order: 1,
      note: 'አሌፍ ማለት አምላክ ወይም መጀመሪያ ማለት ነው። አልፋና ኦሜጋ የሆነውን ያሳያል።',
      supplementaryInfo: 'መዝ. 119፥1-8',
    ),
    const Alephat22Model(
      id: 'entry-2',
      letter: 'በ',
      title: 'ቤት (በ)',
      meaning: 'ቤት፣ ማደሪያ',
      order: 2,
      note: 'ቤት ማለት ማደሪያ ወይም መኖሪያ ማለት ነው። ማኅደረ መለኮትን ያሳያል።',
      supplementaryInfo: 'መዝ. 119፥9-16',
    ),
    const Alephat22Model(
      id: 'entry-22',
      letter: 'ተ',
      title: 'ታው (ተ)',
      meaning: 'ምልክት፣ መስቀል',
      order: 22,
      note: 'ታው ማለት ምልክት፣ መስቀል ወይም ማኅተም ማለት ነው።',
      supplementaryInfo: 'መዝ. 119፥169-176',
    ),
  ];

  group('Alephat Repository & Offline Caching Tests', () {
    late SharedPreferences prefs;
    late Dio failingDio;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      failingDio = Dio(BaseOptions());
      failingDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                error: 'Network unreachable (Offline mode)',
              ),
            );
          },
        ),
      );
    });

    test('Saves and loads Amharic letters to/from local cache', () async {
      final repo = AlephatRepository(failingDio, prefs);

      expect(await repo.hasCachedLetters(), false);
      await repo.saveCachedLetters(sampleLetters);
      expect(await repo.hasCachedLetters(), true);

      final cached = await repo.getCachedLetters();
      expect(cached.length, sampleLetters.length);
      expect(cached.first.letter, 'ሀ');
      expect(cached.first.name, 'ሆይ');
      expect(cached.first.familyMembers.length, 7);
      expect(cached.first.familyMembers[1].glyph, 'ሁ');
      expect(cached.last.letter, 'ፐ');
    });

    test('Saves and loads 22 Alephats to/from local cache', () async {
      final repo = AlephatRepository(failingDio, prefs);

      expect(await repo.hasCached22(), false);
      await repo.saveCached22List(sample22List);
      expect(await repo.hasCached22(), true);

      final cached = await repo.getCached22List();
      expect(cached.length, sample22List.length);
      expect(cached.first.title, 'አሌፍ (አ)');
      expect(cached.first.meaning, 'አምላክ፣ መጀመሪያ');
      expect(cached.last.letter, 'ተ');
      expect(cached.last.order, 22);
    });

    test('getLetters falls back to cache without network connection', () async {
      final repo = AlephatRepository(failingDio, prefs);
      await repo.saveCachedLetters(sampleLetters);

      // Even with failingDio, getLetters must return cached data safely
      final letters = await repo.getLetters();
      expect(letters.length, sampleLetters.length);
      expect(letters[0].letter, 'ሀ');
      expect(letters[1].letter, 'ለ');
      expect(letters[2].letter, 'አ');
      expect(letters[3].letter, 'ፐ');
    });

    test('getLetters filters cached data offline by Amharic search query', () async {
      final repo = AlephatRepository(failingDio, prefs);
      await repo.saveCachedLetters(sampleLetters);

      final results = await repo.getLetters(search: 'ላዊ');
      expect(results.length, 1);
      expect(results.first.letter, 'ለ');

      final familyResults = await repo.getLetters(search: 'ሁ');
      expect(familyResults.length, 1);
      expect(familyResults.first.letter, 'ሀ');
    });

    test('get22List falls back to cache without network connection', () async {
      final repo = AlephatRepository(failingDio, prefs);
      await repo.saveCached22List(sample22List);

      final entries = await repo.get22List();
      expect(entries.length, sample22List.length);
      expect(entries.first.letter, 'አ');
      expect(entries.first.meaning, contains('አምላክ'));
    });

    test('get22List filters cached entries offline by Amharic search query', () async {
      final repo = AlephatRepository(failingDio, prefs);
      await repo.saveCached22List(sample22List);

      final results = await repo.get22List(search: 'መስቀል');
      expect(results.length, 1);
      expect(results.first.letter, 'ተ');
    });

    test('First-launch empty-cache falls back to seed data when offline', () async {
      final repo = AlephatRepository(failingDio, prefs);

      // When offline on first launch, bundled seed data is returned and saved locally!
      final letters = await repo.getLetters();
      expect(letters.length, 33);
      expect(letters.first.letter, 'ሀ');

      final list22 = await repo.get22List();
      expect(list22.length, 22);
      expect(list22.first.letter, 'አ');
    });

    test('Safe synchronization: network failure does not erase valid local cache', () async {
      final repo = AlephatRepository(failingDio, prefs);
      await repo.saveCachedLetters(sampleLetters);

      // Attempt fetch which fails
      final lettersAfterFailedSync = await repo.getLetters();
      expect(lettersAfterFailedSync.isNotEmpty, true);
      expect(lettersAfterFailedSync.length, sampleLetters.length);

      // Verify persistent cache remains intact
      final stillCached = await repo.getCachedLetters();
      expect(stillCached.length, sampleLetters.length);
    });

    test('Administrator mutations update local cache immediately', () async {
      final dioWithMockSuccess = Dio(BaseOptions());
      dioWithMockSuccess.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.method == 'DELETE') {
              handler.resolve(
                Response(requestOptions: options, statusCode: 200, data: {}),
              );
            } else {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'id': 'new-letter-1',
                    'letter': 'ሸ',
                    'name': 'ሻ',
                    'order': 8,
                    'defaultNote': 'ሸ፡ ሻ ይባላል።',
                    'familyMembers': [],
                  },
                ),
              );
            }
          },
        ),
      );

      final repo = AlephatRepository(dioWithMockSuccess, prefs);
      await repo.saveCachedLetters(sampleLetters);

      final created = await repo.createLetter({
        'letter': 'ሸ',
        'name': 'ሻ',
        'order': 8,
      });

      expect(created.letter, 'ሸ');
      final updatedCache = await repo.getCachedLetters();
      expect(updatedCache.any((l) => l.letter == 'ሸ'), true);

      // Test delete updates cache
      await repo.deleteLetter('l-1');
      final cacheAfterDelete = await repo.getCachedLetters();
      expect(cacheAfterDelete.any((l) => l.id == 'l-1'), false);
    });
  });

  group('Layout Preference & Persistence Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('AlephatLayoutNotifier defaults to grid mode', () {
      final notifier = AlephatLayoutNotifier(prefs);
      expect(notifier.state, AlephatLayoutMode.grid);
    });

    test('setLayoutMode updates state and persists to SharedPreferences', () async {
      final notifier = AlephatLayoutNotifier(prefs);
      await notifier.setLayoutMode(AlephatLayoutMode.horizontal);

      expect(notifier.state, AlephatLayoutMode.horizontal);
      expect(prefs.getString('alephat_layout_mode'), 'horizontal');

      // Reinitialize from SharedPreferences to simulate app restart
      final restoredNotifier = AlephatLayoutNotifier(prefs);
      expect(restoredNotifier.state, AlephatLayoutMode.horizontal);
    });

    test('toggleLayoutMode toggles between grid and horizontal', () async {
      final notifier = AlephatLayoutNotifier(prefs);
      expect(notifier.state, AlephatLayoutMode.grid);

      await notifier.toggleLayoutMode();
      expect(notifier.state, AlephatLayoutMode.horizontal);

      await notifier.toggleLayoutMode();
      expect(notifier.state, AlephatLayoutMode.grid);
    });
  });

  group('Widget & UI Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Widget createTestApp({
      required Widget child,
      List<Override> overrides = const [],
    }) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          trProvider.overrideWithValue(
            (String key, [Map<String, dynamic>? args]) =>
                args?['fallback'] as String? ?? key,
          ),
          connectivityProvider.overrideWith(
            (ref) => FakeConnectivityNotifier(),
          ),
          adminPermissionsProvider.overrideWithValue(
            const AdminPermissions(role: 'USER', isAuthenticated: false),
          ),
          ...overrides,
        ],
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('LetterSelectionBar renders with chevrons and scrollbar',
        (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: LetterSelectionBar(letters: sampleLetters),
        ),
      );
      await tester.pumpAndSettle();

      // Chevrons must be present for web/desktop discoverability
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      // Letter items are displayed
      expect(find.text('ሀ'), findsOneWidget);
      expect(find.text('ለ'), findsOneWidget);

      // Custom ScrollBehavior is applied
      final scrollConfigs = tester
          .widgetList<ScrollConfiguration>(find.byType(ScrollConfiguration));
      expect(
        scrollConfigs.any(
            (sc) => sc.behavior is AlephatHorizontalScrollBehavior),
        true,
      );
      final customConfig = scrollConfigs.firstWhere(
          (sc) => sc.behavior is AlephatHorizontalScrollBehavior);
      expect(
        customConfig.behavior.dragDevices,
        containsAll([
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        ]),
      );
    });

    testWidgets('LetterSelectionBar selects letter on tap', (tester) async {
      String? selectedId;

      await tester.pumpWidget(
        createTestApp(
          child: Consumer(
            builder: (context, ref, _) {
              selectedId = ref.watch(selectedBaseLetterIdProvider);
              return LetterSelectionBar(letters: sampleLetters);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on 'ለ'
      await tester.tap(find.text('ለ'));
      await tester.pumpAndSettle();

      expect(selectedId, 'l-2');
    });

    testWidgets('LetterKeyboardGrid renders responsive keys and selects letter',
        (tester) async {
      String? selectedId;

      await tester.pumpWidget(
        createTestApp(
          child: Consumer(
            builder: (context, ref, _) {
              selectedId = ref.watch(selectedBaseLetterIdProvider);
              return LetterKeyboardGrid(letters: sampleLetters);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All sample keys are visible
      expect(find.text('ሀ'), findsOneWidget);
      expect(find.text('ለ'), findsOneWidget);
      expect(find.text('አ'), findsOneWidget);
      expect(find.text('ፐ'), findsOneWidget);

      // Tap on 'አ'
      await tester.tap(find.text('አ'));
      await tester.pumpAndSettle();

      expect(selectedId, 'l-16');
    });

    testWidgets('AlephatLearningView renders content above bottom selector',
        (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            alephatLettersProvider.overrideWith((ref) async => sampleLetters),
          ],
          child: const AlephatLearningView(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Nested tabs present
      expect(find.text('ፊደላት'), findsOneWidget);
      expect(find.text('22 አሌፋት'), findsOneWidget);

      // 2. Information Panel present (Above)
      expect(find.byType(LetterInfoPanel), findsOneWidget);
      expect(find.text('ሀ፡'), findsOneWidget);

      // 3. Family display present (Above)
      expect(find.byType(LetterFamilyDisplay), findsOneWidget);

      // 4. Letter selector present at the bottom dock (default mode is Keyboard Grid)
      expect(find.byType(LetterKeyboardGrid), findsOneWidget);
      expect(find.text('ፊደል ይምረጡ'), findsOneWidget);

      // 5. Verify vertical ordering: LetterInfoPanel is above LetterKeyboardGrid
      final infoPanelCenter = tester.getCenter(find.byType(LetterInfoPanel));
      final keyboardGridCenter =
          tester.getCenter(find.byType(LetterKeyboardGrid));
      expect(infoPanelCenter.dy < keyboardGridCenter.dy, true,
          reason: 'Learning content must be placed above the letter selector');
    });

    testWidgets('Switching layout modes preserves selected letter',
        (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late WidgetRef refHandle;

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            alephatLettersProvider.overrideWith((ref) async => sampleLetters),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              refHandle = ref;
              return const AlephatLearningView();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial mode is keyboard grid
      expect(find.byType(LetterKeyboardGrid), findsOneWidget);
      expect(find.byType(LetterSelectionBar), findsNothing);

      // Select 'ለ'
      await tester.tap(find.text('ለ'));
      await tester.pumpAndSettle();
      expect(refHandle.read(selectedBaseLetterIdProvider), 'l-2');

      // Switch to horizontal scroll mode using toggle icon
      final horizontalToggleIcon = find.byIcon(Icons.view_carousel_outlined);
      expect(horizontalToggleIcon, findsOneWidget);
      await tester.tap(horizontalToggleIcon);
      await tester.pumpAndSettle();

      // Mode is now horizontal
      expect(find.byType(LetterSelectionBar), findsOneWidget);
      expect(find.byType(LetterKeyboardGrid), findsNothing);

      // Selected letter must NOT be lost!
      expect(refHandle.read(selectedBaseLetterIdProvider), 'l-2');
      // Info panel still shows 'ለ'
      expect(find.text('ለ፡'), findsOneWidget);
    });

    testWidgets('Offline with empty cache displays graceful initial-connection notice',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          overrides: [
            alephatLettersProvider.overrideWith((ref) async {
              throw DioException(
                requestOptions: RequestOptions(path: '/alephat/letters'),
                type: DioExceptionType.connectionError,
              );
            }),
          ],
          child: const AlephatLearningView(),
        ),
      );
      await tester.pumpAndSettle();

      // Graceful first-launch explanation must be shown
      expect(find.text('የመጀመሪያ ማመሳሰል ያስፈልጋል'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      expect(find.text('እንደገና ሞክር'), findsOneWidget);
    });

    testWidgets('Alephat22View renders entries and displays detail sheet on tap',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          overrides: [
            alephat22ListProvider.overrideWith((ref) async => sample22List),
          ],
          child: const Alephat22View(),
        ),
      );
      await tester.pumpAndSettle();

      // Entries rendered
      expect(find.text('አሌፍ (አ)'), findsOneWidget);
      expect(find.text('ቤት (በ)'), findsOneWidget);
      expect(find.text('ታው (ተ)'), findsOneWidget);

      // Tap on first entry to open detail sheet
      await tester.tap(find.text('አሌፍ (አ)'));
      await tester.pumpAndSettle();

      // Detail sheet opens with full note & scripture info
      expect(find.text('መዝ. 119፥1-8'), findsOneWidget);
    });

    testWidgets('LetterKeyboardGrid on Android lists all 33 letters without scrolling',
        (tester) async {
      // Simulate standard Android phone screen width
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final allLetters = AlephatSeedData.getInitialLetters();
      expect(allLetters.length, 33);

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: LetterKeyboardGrid(letters: allLetters),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify GridView has NeverScrollableScrollPhysics so no scrolling is needed
      final gridViewFinder = find.byType(GridView);
      expect(gridViewFinder, findsOneWidget);
      final gridView = tester.widget<GridView>(gridViewFinder);
      expect(gridView.physics, isA<NeverScrollableScrollPhysics>());

      // First letter 'ሀ' and last letter 'ፐ' must both be visible without scrolling
      expect(find.text('ሀ'), findsOneWidget);
      expect(find.text('ፐ'), findsOneWidget);

      // Verify all 33 letters are rendered simultaneously
      for (final l in allLetters) {
        expect(find.text(l.letter), findsOneWidget);
      }
    });

    testWidgets(
        'LetterKeyboardGrid on large screen web formats letters into 3 rows (11 columns per row)',
        (tester) async {
      // Simulate large web desktop screen
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final allLetters = AlephatSeedData.getInitialLetters();

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: LetterKeyboardGrid(letters: allLetters),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      // 33 letters divided into 11 columns = exactly 3 rows!
      expect(delegate.crossAxisCount, 11);
      final rowCount = (allLetters.length / delegate.crossAxisCount).ceil();
      expect(rowCount, 3);
    });

    testWidgets(
        'CalendarScreen top tabs have top and horizontal margins and centered constraint',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            alephatLettersProvider.overrideWith(
                (ref) async => AlephatSeedData.getInitialLetters()),
          ],
          child: const CalendarScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Top SegmentedButton exists
      final segmentedButtonFinder = find.byType(SegmentedButton<int>);
      expect(segmentedButtonFinder, findsOneWidget);

      // Verify parent container has top: 10, bottom: 6, horizontal: 20 margins
      final containerFinder = find.ancestor(
        of: segmentedButtonFinder,
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);
      final container = tester.widget<Container>(containerFinder.first);
      final margin = container.margin as EdgeInsets;
      expect(margin.top, 10.0);
      expect(margin.bottom, 6.0);
      expect(margin.left, 20.0);
      expect(margin.right, 20.0);
    });

    testWidgets(
        'AlephatLearningView center learning content has matching X margin and maxWidth on large screen',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            alephatLettersProvider.overrideWith(
                (ref) async => AlephatSeedData.getInitialLetters()),
          ],
          child: const AlephatLearningView(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the ConstrainedBox enclosing the center learning content Column
      final infoPanelFinder = find.byType(LetterInfoPanel);
      expect(infoPanelFinder, findsOneWidget);

      final centerConstrainedBoxFinder = find.ancestor(
        of: infoPanelFinder,
        matching: find.byType(ConstrainedBox),
      );
      expect(centerConstrainedBoxFinder, findsWidgets);

      final constrainedBox =
          tester.widget<ConstrainedBox>(centerConstrainedBoxFinder.first);
      expect(constrainedBox.constraints.maxWidth, 1100.0);

      // Verify container margin has left: 24, right: 24 matching bottom keyboard dock
      final centerContainerFinder = find.ancestor(
        of: infoPanelFinder,
        matching: find.byType(Container),
      );
      final centerContainer =
          tester.widget<Container>(centerContainerFinder.first);
      final margin = centerContainer.margin as EdgeInsets;
      expect(margin.left, 24.0);
      expect(margin.right, 24.0);
    });

    testWidgets(
        'ManageLetterDialog general tab has top padding to keep floating labels fully visible',
        (tester) async {
      final sampleLetter = AlephatSeedData.getInitialLetters().first;

      await tester.pumpWidget(
        createTestApp(
          child: ManageLetterDialog(letter: sampleLetter),
        ),
      );
      await tester.pumpAndSettle();

      // Verify general tab is rendered and floating labels exist
      expect(find.text('መሠረታዊ ፊደል (ምሳሌ፡ ሀ)*'), findsOneWidget);
      expect(find.text('የፊደል ስም (ምሳሌ፡ ሆይ)'), findsOneWidget);
      expect(find.text('ተራ*'), findsOneWidget);

      // Verify SingleChildScrollView has top padding >= 16 to avoid TabBarView clipping
      final scrollViewFinder = find.descendant(
        of: find.byType(TabBarView),
        matching: find.byType(SingleChildScrollView),
      );
      expect(scrollViewFinder, findsOneWidget);

      final scrollView = tester.widget<SingleChildScrollView>(scrollViewFinder);
      final padding = scrollView.padding as EdgeInsets;
      expect(padding.top, greaterThanOrEqualTo(16.0));
    });

    testWidgets(
        'Right-clicking (secondary click) on a letter opens letter management popup on web',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final letters = AlephatSeedData.getInitialLetters();
      const adminPerms = AdminPermissions(
        role: 'SUPER_ADMIN',
        isAuthenticated: true,
      );

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            adminPermissionsProvider.overrideWithValue(adminPerms),
          ],
          child: LetterKeyboardGrid(letters: letters),
        ),
      );
      await tester.pumpAndSettle();

      // Right-click on the first letter card (ሀ)
      final letterHa = find.text('ሀ').first;
      await tester.tap(letterHa, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      // Verify that the management popup opens as a Dialog with all 4 management actions
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('ፊደሉን አርትዕ'), findsOneWidget);
      expect(find.text('የፊደል ቤተሰብ አስተዳድር'), findsOneWidget);
      expect(find.text('አዲስ ፊደል ጨምር'), findsOneWidget);
      expect(find.text('ፊደሉን ሰርዝ'), findsOneWidget);
    });

    testWidgets(
        'Dynamic media fields display one field initially and dynamically add next field when fulfilled',
        (tester) async {
      final sampleLetter = AlephatSeedData.getInitialLetters().first.copyWith(
        mediaUrls: [],
      );

      await tester.pumpWidget(
        createTestApp(
          child: ManageLetterDialog(letter: sampleLetter),
        ),
      );
      await tester.pumpAndSettle();

      // Initially only 1 dynamic media field is shown
      expect(find.byKey(const Key('dynamic_media_field_0')), findsOneWidget);
      expect(find.byKey(const Key('dynamic_media_field_1')), findsNothing);

      // Enter media URL in field 0
      await tester.enterText(
        find.byKey(const Key('dynamic_media_field_0')),
        'https://example.com/audio1.mp3',
      );
      await tester.pumpAndSettle();

      // Now field 1 has dynamically appeared!
      expect(find.byKey(const Key('dynamic_media_field_1')), findsOneWidget);
      expect(find.byKey(const Key('dynamic_media_field_2')), findsNothing);

      // Enter media URL in field 1
      await tester.enterText(
        find.byKey(const Key('dynamic_media_field_1')),
        'https://example.com/video2.mp4',
      );
      await tester.pumpAndSettle();

      // Now field 2 has dynamically appeared!
      expect(find.byKey(const Key('dynamic_media_field_2')), findsOneWidget);
    });

    testWidgets(
        'Clicking speaker icon opens popup player with close button and closes properly',
        (tester) async {
      final sampleLetter = AlephatSeedData.getInitialLetters().first.copyWith(
        pronunciationGuide: 'Hä - Voiceless glottal fricative',
        mediaUrls: ['https://example.com/audio1.mp3'],
      );

      await tester.pumpWidget(
        createTestApp(
          child: LetterInfoPanel(letter: sampleLetter),
        ),
      );
      await tester.pumpAndSettle();

      // Verify speaker icon button exists
      final speakerBtn = find.byKey(const Key('alephat_speaker_button'));
      expect(speakerBtn, findsOneWidget);

      // Tap speaker button to open popup
      await tester.tap(speakerBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Verify popup opened with close button
      final closeBtn = find.byKey(const Key('alephat_media_popup_close_button'));
      expect(closeBtn, findsOneWidget);

      // Tap close button and verify it dismisses
      await tester.tap(closeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(closeBtn, findsNothing);
    });

    testWidgets(
        'Popup player lists multiple media files when more than one are attached',
        (tester) async {
      final sampleLetter = AlephatSeedData.getInitialLetters().first.copyWith(
        pronunciationGuide: 'Hä - Voiceless glottal fricative',
        mediaUrls: [
          'https://example.com/sound.mp3',
          'https://example.com/clip.mp4',
          'https://example.com/chart.png',
        ],
      );

      await tester.pumpWidget(
        createTestApp(
          child: LetterInfoPanel(letter: sampleLetter),
        ),
      );
      await tester.pumpAndSettle();

      // Tap speaker icon to open popup
      await tester.tap(find.byKey(const Key('alephat_speaker_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Verify all multiple media are listed
      expect(find.text('የተያያዙ ሚዲያዎች (3)'), findsOneWidget);
      expect(find.text('1. sound.mp3'), findsOneWidget);
      expect(find.text('2. clip.mp4'), findsOneWidget);
      expect(find.text('3. chart.png'), findsOneWidget);

      // Dismiss popup
      await tester.tap(find.byKey(const Key('alephat_media_popup_close_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
    });

    testWidgets(
        'LetterFamilyDisplay supports 12 and 13 letter family members and displays dynamic count',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final letters = AlephatSeedData.getInitialLetters();
      final qafLetter = letters.firstWhere((l) => l.letter == 'ቀ');
      final kafLetter = letters.firstWhere((l) => l.letter == 'ከ');

      expect(qafLetter.familyMembers.length, 13);
      expect(kafLetter.familyMembers.length, 12);

      // Render Qaf (13 members)
      await tester.pumpWidget(
        createTestApp(
          child: Column(
            children: [
              LetterInfoPanel(letter: qafLetter),
              LetterFamilyDisplay(letter: qafLetter),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header shows 13 sounds
      expect(find.text('የ"ቀ" ቤተሰብ (13 ድምጾች)'), findsOneWidget);

      // Tap 10th order member (ቋ)
      final quaFinder = find.text('ቋ');
      expect(quaFinder, findsOneWidget);
      await tester.tap(quaFinder);
      await tester.pumpAndSettle();

      // Verify LetterInfoPanel displays selected ቋ and its order name and pronunciation
      expect(find.text('ቋ፡'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(LetterInfoPanel),
          matching: find.text('ዲቃላ ራብዕ'),
        ),
        findsOneWidget,
      );
      expect(find.text('qʷa'), findsOneWidget);
    });

    test('getCachedLetters automatically backfills missing members when cache has older 7-member letters', () async {
      SharedPreferences.setMockInitialValues({
        'alephat_cached_letters': '''[
          {
            "id": "seed_let_9",
            "letter": "ቀ",
            "name": "ቃፍ",
            "order": 9,
            "defaultNote": "ቀ፡ ቃፍ ይባላል።",
            "familyMembers": [
              {"id": "m1", "baseLetterId": "seed_let_9", "glyph": "ቀ", "orderIndex": 1, "orderName": "ግዕዝ"},
              {"id": "m2", "baseLetterId": "seed_let_9", "glyph": "ቁ", "orderIndex": 2, "orderName": "ካዕብ"},
              {"id": "m3", "baseLetterId": "seed_let_9", "glyph": "ቂ", "orderIndex": 3, "orderName": "ሣልስ"},
              {"id": "m4", "baseLetterId": "seed_let_9", "glyph": "ቃ", "orderIndex": 4, "orderName": "ራብዕ"},
              {"id": "m5", "baseLetterId": "seed_let_9", "glyph": "ቄ", "orderIndex": 5, "orderName": "ኃምስ"},
              {"id": "m6", "baseLetterId": "seed_let_9", "glyph": "ቅ", "orderIndex": 6, "orderName": "ሳድስ"},
              {"id": "m7", "baseLetterId": "seed_let_9", "glyph": "ቆ", "orderIndex": 7, "orderName": "ሳብዕ"}
            ]
          }
        ]''',
      });

      final prefs = await SharedPreferences.getInstance();
      final repo = AlephatRepository(Dio(), prefs);
      final letters = await repo.getCachedLetters();

      final qaf = letters.firstWhere((l) => l.letter == 'ቀ');
      expect(qaf.familyMembers.length, 13);
      expect(qaf.familyMembers.any((m) => m.glyph == 'ቋ'), isTrue);
      expect(qaf.familyMembers.any((m) => m.glyph == 'ቇ'), isTrue);
    });
  });
}
