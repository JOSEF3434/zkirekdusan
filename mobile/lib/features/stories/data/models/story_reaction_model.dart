// lib/features/stories/data/models/story_reaction_model.dart
import 'story_model.dart';

class StoryReactionModel {
  final String storyId;
  final String userId;
  final String reaction;
  final StoryAuthorModel user;
  final DateTime createdAt;

  const StoryReactionModel({
    required this.storyId,
    required this.userId,
    required this.reaction,
    required this.user,
    required this.createdAt,
  });

  factory StoryReactionModel.fromJson(Map<String, dynamic> json) {
    return StoryReactionModel(
      storyId: json['storyId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      reaction: json['reaction'] as String? ?? 'LIKE',
      user: StoryAuthorModel.fromJson(
        json['user'] as Map<String, dynamic>? ?? {},
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storyId': storyId,
      'userId': userId,
      'reaction': reaction,
      'user': user.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
