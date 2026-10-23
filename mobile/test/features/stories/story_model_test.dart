// test/features/stories/story_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/stories/data/models/story_feed_group_model.dart';
import 'package:mobile/features/stories/data/models/story_model.dart';

void main() {
  group('StoryModel', () {
    test('correctly parses JSON and computes expiration and media type', () {
      final now = DateTime.now();
      final inFuture = now.add(const Duration(hours: 12));
      final inPast = now.subtract(const Duration(hours: 1));

      final activeStoryJson = {
        'id': 'story-1',
        'type': 'IMAGE',
        'mediaUrl': 'https://example.com/image.jpg',
        'content': 'Check out this photo',
        'viewsCount': 10,
        'reactionsCount': 3,
        'commentsCount': 1,
        'hasViewedByMe': false,
        'myReaction': null,
        'author': {
          'id': 'user-1',
          'username': 'john_doe',
          'displayName': 'John Doe',
          'avatarUrl': 'https://example.com/avatar.jpg',
        },
        'expiresAt': inFuture.toIso8601String(),
        'createdAt': now.toIso8601String(),
      };

      final story = StoryModel.fromJson(activeStoryJson);

      expect(story.id, 'story-1');
      expect(story.isImage, isTrue);
      expect(story.isVideo, isFalse);
      expect(story.isText, isFalse);
      expect(story.isExpired, isFalse);
      expect(story.author.effectiveName, 'John Doe');
      expect(story.viewsCount, 10);
      expect(story.reactionsCount, 3);
      expect(story.hasViewedByMe, isFalse);

      final expiredStory = story.copyWith(expiresAt: inPast);
      expect(expiredStory.isExpired, isTrue);
    });

    test('correctly serializes StoryFeedGroupModel to and from JSON', () {
      final now = DateTime.now();
      final group = StoryFeedGroupModel(
        owner: const StoryAuthorModel(
          id: 'user-2',
          username: 'sarah',
          displayName: 'Sarah Connor',
        ),
        stories: [
          StoryModel(
            id: 's-1',
            type: 'VIDEO',
            mediaUrl: 'https://example.com/video.mp4',
            author: const StoryAuthorModel(id: 'user-2'),
            expiresAt: now.add(const Duration(hours: 24)),
            createdAt: now,
            hasViewedByMe: false,
          ),
        ],
        hasUnseen: true,
        latestStoryAt: now,
        totalStories: 1,
      );

      final json = group.toJson();
      final parsed = StoryFeedGroupModel.fromJson(json);

      expect(parsed.owner.id, 'user-2');
      expect(parsed.stories.length, 1);
      expect(parsed.stories.first.isVideo, isTrue);
      expect(parsed.hasUnseen, isTrue);
      expect(parsed.totalStories, 1);
    });
  });
}
