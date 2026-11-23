// test/features/explore/search_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/explore/presentation/providers/search_provider.dart';
import 'package:mobile/features/explore/presentation/search_screen.dart';

class _FakeRecentSearchesNotifier extends RecentSearchesNotifier {
  final List<String> initial;
  _FakeRecentSearchesNotifier(this.initial);

  @override
  Future<List<String>> build() async => initial;
}

void main() {
  Widget buildSearchScreen({
    List<String> recentSearches = const [],
  }) {
    return ProviderScope(
      overrides: [
        trProvider.overrideWithValue((key, [args]) => key),
        recentSearchesProvider.overrideWith(
          () => _FakeRecentSearchesNotifier(recentSearches),
        ),
      ],
      child: const MaterialApp(
        home: SearchScreen(),
      ),
    );
  }

  testWidgets('SearchScreen renders back icon and search input with responsive margins', (
    tester,
  ) async {
    await tester.pumpWidget(buildSearchScreen());
    await tester.pumpAndSettle();

    // Verify back icon is rendered
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    // Verify search input field is rendered with correct hint text
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search videos, people, groups…'), findsOneWidget);

    // When empty, the clear (x) button is not visible
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('Typing text displays clear (x) button and tapping it resets search bar', (
    tester,
  ) async {
    await tester.pumpWidget(buildSearchScreen());
    await tester.pumpAndSettle();

    // Type query into the search field
    await tester.enterText(find.byType(TextField), 'orthodox mezmur');
    await tester.pump();

    // The clear (x) button must now be visible
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Tap the clear (x) button
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    // Search bar is reset/cleared
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, isEmpty);

    // Close button disappears when cleared
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('SearchScreen renders properly on large displays (1920x1080) without collapsing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildSearchScreen(recentSearches: ['test search item']));
    await tester.pumpAndSettle();

    // Verify search bar has proper width on large displays
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);
    final textFieldSize = tester.getSize(textFieldFinder);
    expect(textFieldSize.width, greaterThan(800));

    // Verify recent search item renders with full width and isn't collapsed
    final recentSearchFinder = find.text('test search item');
    expect(recentSearchFinder, findsOneWidget);
    final recentSearchSize = tester.getSize(recentSearchFinder);
    expect(recentSearchSize.width, greaterThan(50));
  });
}
