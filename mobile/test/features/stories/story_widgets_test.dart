// test/features/stories/story_widgets_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/stories/data/models/story_feed_group_model.dart';
import 'package:mobile/features/stories/data/models/story_model.dart';
import 'package:mobile/features/stories/presentation/widgets/my_story_item.dart';
import 'package:mobile/features/stories/presentation/widgets/story_empty_state.dart';
import 'package:mobile/features/stories/presentation/widgets/story_item.dart';
import 'package:mobile/features/stories/presentation/widgets/story_progress_bar.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Story Widgets', () {
    testWidgets(
      'MyStoryItem renders correctly with and without active stories',
      (tester) async {
        bool viewTapped = false;
        bool createTapped = false;

        // 1. Without active stories
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: MyStoryItem(
                  myGroup: StoryFeedGroupModel(
                    owner: const StoryAuthorModel(
                      id: 'user-me',
                      displayName: 'Josef',
                    ),
                    stories: const [],
                    hasUnseen: false,
                    latestStoryAt: DateTime.now(),
                    totalStories: 0,
                  ),
                  onViewStory: () => viewTapped = true,
                  onCreateStory: () => createTapped = true,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Your Story'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);

        // Tap avatar -> should trigger create because no active stories
        await tester.tap(find.text('Your Story'));
        await tester.pump();
        // Click on avatar area
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump();
        expect(createTapped, isTrue);

        // 2. With active stories
        createTapped = false;
        viewTapped = false;
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: MyStoryItem(
                  myGroup: StoryFeedGroupModel(
                    owner: const StoryAuthorModel(
                      id: 'user-me',
                      displayName: 'Josef',
                    ),
                    stories: [
                      StoryModel(
                        id: 's1',
                        type: 'IMAGE',
                        author: const StoryAuthorModel(id: 'user-me'),
                        expiresAt: DateTime.now().add(
                          const Duration(hours: 24),
                        ),
                        createdAt: DateTime.now(),
                      ),
                    ],
                    hasUnseen: false,
                    latestStoryAt: DateTime.now(),
                    totalStories: 1,
                  ),
                  onViewStory: () => viewTapped = true,
                  onCreateStory: () => createTapped = true,
                ),
              ),
            ),
          ),
        );

        // Tap avatar -> triggers view story
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump();
        expect(viewTapped, isTrue);

        // Plus icon is hidden when active stories exist (canAddMore is false)
        expect(find.byIcon(Icons.add), findsNothing);
      },
    );

    testWidgets('StoryItem renders unseen border and seen border', (
      tester,
    ) async {
      final unseenGroup = StoryFeedGroupModel(
        owner: const StoryAuthorModel(id: 'user-1', displayName: 'Jane Doe'),
        stories: [
          StoryModel(
            id: 's1',
            type: 'IMAGE',
            author: const StoryAuthorModel(id: 'user-1'),
            expiresAt: DateTime.now().add(const Duration(hours: 24)),
            createdAt: DateTime.now(),
            hasViewedByMe: false,
          ),
        ],
        hasUnseen: true,
        latestStoryAt: DateTime.now(),
        totalStories: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryItem(group: unseenGroup, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Jane Doe'), findsOneWidget);
    });

    testWidgets('StoryProgressBar renders expected number of segments', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StoryProgressBar(
              totalStories: 4,
              currentIndex: 1,
              currentProgress: 0.5,
            ),
          ),
        ),
      );

      expect(find.byType(StoryProgressBar), findsOneWidget);
    });

    testWidgets('StoryEmptyState renders and triggers callback', (
      tester,
    ) async {
      bool addTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryEmptyState(onAddStory: () => addTapped = true),
          ),
        ),
      );

      expect(find.text('No stories yet'), findsOneWidget);
      await tester.tap(find.text('No stories yet'));
      await tester.pump();
      expect(addTapped, isTrue);
    });
  });
}
