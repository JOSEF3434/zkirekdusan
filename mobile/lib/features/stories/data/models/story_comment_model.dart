// lib/features/stories/data/models/story_comment_model.dart
import 'story_model.dart';

class StoryCommentModel {
  final String id;
  final String storyId;
  final String content;
  final StoryAuthorModel author;
  final DateTime createdAt;

  const StoryCommentModel({
    required this.id,
    required this.storyId,
    required this.content,
    required this.author,
    required this.createdAt,
  });

  factory StoryCommentModel.fromJson(Map<String, dynamic> json) {
    return StoryCommentModel(
      id: json['id'] as String? ?? '',
      storyId: json['storyId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      author: StoryAuthorModel.fromJson(
        json['author'] as Map<String, dynamic>? ?? {},
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storyId': storyId,
      'content': content,
      'author': author.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
