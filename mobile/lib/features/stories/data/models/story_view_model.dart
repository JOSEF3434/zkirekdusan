// lib/features/stories/data/models/story_view_model.dart
import 'story_model.dart';

class StoryViewModel {
  final String storyId;
  final String viewerId;
  final StoryAuthorModel viewer;
  final DateTime viewedAt;

  const StoryViewModel({
    required this.storyId,
    required this.viewerId,
    required this.viewer,
    required this.viewedAt,
  });

  factory StoryViewModel.fromJson(Map<String, dynamic> json) {
    return StoryViewModel(
      storyId: json['storyId'] as String? ?? '',
      viewerId: json['viewerId'] as String? ?? '',
      viewer: StoryAuthorModel.fromJson(
        json['viewer'] as Map<String, dynamic>? ?? {},
      ),
      viewedAt:
          DateTime.tryParse(json['viewedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storyId': storyId,
      'viewerId': viewerId,
      'viewer': viewer.toJson(),
      'viewedAt': viewedAt.toIso8601String(),
    };
  }
}
