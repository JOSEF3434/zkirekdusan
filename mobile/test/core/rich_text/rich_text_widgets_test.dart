// mobile/test/core/rich_text/rich_text_widgets_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';
import 'package:mobile/core/rich_text/mention_text_controller.dart';
import 'package:mobile/core/rich_text/rich_text_renderer.dart';
import 'package:mobile/core/rich_text/suggestion_overlay.dart';

void main() {
  const uuidUser = '4a7a8988-0deb-4c4d-9685-97577886df56';
  const uuidVideo = '78f7e836-21eb-4ed9-be89-854b46a37ffe';
  const uuidBook = '94be4fbf-b204-4370-af6c-203d866e63e3';
  const uuidChannel = 'dc2787cb-c11c-47b1-9868-7398f8eb1b37';
  const uuidGroup = '2dbac866-db60-43af-a305-da549cc70229';

  group('MentionSuggestionPanel UX states', () {
    testWidgets('shows compact loading row (not giant blank box)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MentionSuggestionPanel(
              query: 'f',
              suggestions: const [],
              isLoading: true,
              onSelect: (_) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Searching "@f"'), findsOneWidget);
      final panelBox = tester.getSize(find.byType(MentionSuggestionPanel));
      expect(panelBox.height, lessThan(80));
    });

    testWidgets('shows error state with Retry button and never silently disappears', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MentionSuggestionPanel(
              query: 'f',
              suggestions: const [],
              isLoading: false,
              error: 'Network error',
              onSelect: (_) {},
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, true);
    });

    testWidgets('shows explicit No matches state when backend returns empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MentionSuggestionPanel(
              query: 'f',
              suggestions: const [],
              isLoading: false,
              hasSearched: true,
              onSelect: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('No matches for "@f"'), findsOneWidget);
    });

    testWidgets('renders Users, Groups, and Channels with badges and fires onSelect', (tester) async {
      MentionSuggestion? chosen;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MentionSuggestionPanel(
              query: 'test',
              suggestions: const [
                MentionSuggestion(
                  id: uuidUser,
                  type: MentionEntityType.user,
                  username: 'jj',
                  displayName: 'jj',
                ),
                MentionSuggestion(
                  id: uuidGroup,
                  type: MentionEntityType.group,
                  username: 'tests',
                  displayName: 'tests',
                ),
                MentionSuggestion(
                  id: uuidChannel,
                  type: MentionEntityType.channel,
                  username: 'test',
                  displayName: 'test Channel',
                ),
              ],
              isLoading: false,
              hasSearched: true,
              onSelect: (s) => chosen = s,
            ),
          ),
        ),
      );

      expect(find.text('User'), findsOneWidget);
      expect(find.text('Group'), findsOneWidget);
      expect(find.text('Channel'), findsOneWidget);
      expect(find.text('test Channel'), findsOneWidget);

      await tester.tap(find.text('test Channel'));
      expect(chosen?.id, uuidChannel);
      expect(chosen?.type, MentionEntityType.channel);
    });
  });

  group('RichTextRenderer GoRouter UUID navigation', () {
    testWidgets('tapping @[user:id:jj], #[channel:...], #[video:...], #[book:...] opens exact UUID route', (tester) async {
      final navigated = <String>[];

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: Column(
                children: [
                  RichTextRenderer(
                    content: '@[user:$uuidUser:jj]',
                  ),
                  RichTextRenderer(
                    content: '@[channel:$uuidChannel:test]',
                  ),
                  RichTextRenderer(
                    content: '#[video:$uuidVideo:testVideo]',
                  ),
                  RichTextRenderer(
                    content: '#[book:$uuidBook:testBook]',
                  ),
                ],
              ),
            ),
          ),
          GoRoute(
            path: '/u/:id',
            builder: (_, state) {
              navigated.add('/u/${state.pathParameters['id']}');
              return const Scaffold(body: Text('user-page'));
            },
          ),
          GoRoute(
            path: '/channel/:id',
            builder: (_, state) {
              navigated.add('/channel/${state.pathParameters['id']}');
              return const Scaffold(body: Text('channel-page'));
            },
          ),
          GoRoute(
            path: '/video/:id',
            builder: (_, state) {
              navigated.add('/video/${state.pathParameters['id']}');
              return const Scaffold(body: Text('video-page'));
            },
          ),
          GoRoute(
            path: '/books/:id',
            builder: (_, state) {
              navigated.add('/books/${state.pathParameters['id']}');
              return const Scaffold(body: Text('book-page'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.tap(find.text('@jj'));
      await tester.pumpAndSettle();
      expect(navigated.last, '/u/$uuidUser');
      router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('@test'));
      await tester.pumpAndSettle();
      expect(navigated.last, '/channel/$uuidChannel');
      router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('#testVideo'));
      await tester.pumpAndSettle();
      expect(navigated.last, '/video/$uuidVideo');
      router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('#testBook'));
      await tester.pumpAndSettle();
      expect(navigated.last, '/books/$uuidBook');
    });
  });

  group('MentionTextController constructor initial text', () {
    test('preserves initial text without triggering', () {
      final ctrl = MentionTextController(text: 'Hello @world');
      addTearDown(ctrl.dispose);
      expect(ctrl.text, 'Hello @world');
      expect(ctrl.activeTrigger, MentionTrigger.none);
    });
  });
}
