// lib/features/stories/data/models/story_feed_group_model.dart
import 'story_model.dart';

class StoryFeedGroupModel {
  final StoryAuthorModel owner;
  final List<StoryModel> stories;
  final bool hasUnseen;
  final DateTime latestStoryAt;
  final int totalStories;

  const StoryFeedGroupModel({
    required this.owner,
    required this.stories,
    required this.hasUnseen,
    required this.latestStoryAt,
    required this.totalStories,
  });

  bool get isEmpty => stories.isEmpty;
  bool get isNotEmpty => stories.isNotEmpty;

  StoryFeedGroupModel copyWith({
    StoryAuthorModel? owner,
    List<StoryModel>? stories,
    bool? hasUnseen,
    DateTime? latestStoryAt,
    int? totalStories,
  }) {
    return StoryFeedGroupModel(
      owner: owner ?? this.owner,
      stories: stories ?? this.stories,
      hasUnseen: hasUnseen ?? this.hasUnseen,
      latestStoryAt: latestStoryAt ?? this.latestStoryAt,
      totalStories: totalStories ?? this.totalStories,
    );
  }

  factory StoryFeedGroupModel.fromJson(Map<String, dynamic> json) {
    final rawStories = json['stories'] as List<dynamic>? ?? [];
    final parsedStories = rawStories
        .map((e) => StoryModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return StoryFeedGroupModel(
      owner: StoryAuthorModel.fromJson(
        json['owner'] as Map<String, dynamic>? ?? {},
      ),
      stories: parsedStories,
      hasUnseen: json['hasUnseen'] as bool? ?? false,
      latestStoryAt:
          DateTime.tryParse(json['latestStoryAt'] as String? ?? '') ??
          DateTime.now(),
      totalStories:
          (json['totalStories'] as num?)?.toInt() ?? parsedStories.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'owner': owner.toJson(),
      'stories': stories.map((s) => s.toJson()).toList(),
      'hasUnseen': hasUnseen,
      'latestStoryAt': latestStoryAt.toIso8601String(),
      'totalStories': totalStories,
    };
  }
}
