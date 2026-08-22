// lib/features/stories/presentation/providers/story_feed_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/stories/data/datasources/stories_remote_datasource.dart';
import 'package:mobile/features/stories/data/models/story_feed_group_model.dart';
import 'package:mobile/features/stories/data/models/story_model.dart';

import 'package:mobile/features/profile/presentation/providers/profile_providers.dart';

final storyFeedProvider =
    AsyncNotifierProvider<StoryFeedNotifier, List<StoryFeedGroupModel>>(() {
      return StoryFeedNotifier();
    });

class StoryFeedNotifier extends AsyncNotifier<List<StoryFeedGroupModel>> {
  @override
  Future<List<StoryFeedGroupModel>> build() async {
    ref.watch(authProvider);
    final datasource = ref.watch(storiesRemoteDatasourceProvider);
    return _fetchAndSortFeed(datasource);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final datasource = ref.read(storiesRemoteDatasourceProvider);
      return _fetchAndSortFeed(datasource);
    });
  }

  Future<List<StoryFeedGroupModel>> _fetchAndSortFeed(
    StoriesRemoteDatasource datasource,
  ) async {
    final now = DateTime.now();
    final auth = ref.read(authProvider);
    final profile = ref.read(profileProvider).profile;
    final myId = auth.user?.id;

    List<StoryFeedGroupModel> rawGroups = [];
    try {
      rawGroups = await datasource.getFeed();
    } catch (_) {
      // Gracefully continue with local/empty feed so My Story with + badge is always displayed
      rawGroups = [];
    }

    // Filter active stories within 24-hour range for each group
    final filteredGroups = <StoryFeedGroupModel>[];
    for (final group in rawGroups) {
      final activeStories =
          group.stories.where((s) => s.expiresAt.isAfter(now)).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (activeStories.isNotEmpty ||
          (myId != null && group.owner.id == myId)) {
        filteredGroups.add(
          group.copyWith(
            stories: activeStories,
            totalStories: activeStories.length,
            hasUnseen: activeStories.any((s) => !s.hasViewedByMe),
          ),
        );
      }
    }

    // Find or synthesize current user's story group at position 0
    StoryFeedGroupModel myGroup;
    final existingMyIndex = myId != null
        ? filteredGroups.indexWhere((g) => g.owner.id == myId)
        : -1;

    if (existingMyIndex >= 0) {
      myGroup = filteredGroups.removeAt(existingMyIndex);
    } else {
      myGroup = StoryFeedGroupModel(
        owner: StoryAuthorModel(
          id: myId ?? 'me',
          displayName:
              profile?.displayName ??
              auth.user?.username ??
              (auth.status == AuthStatus.authenticated ? 'You' : 'Guest'),
          username: auth.user?.username,
          avatarUrl: profile?.avatarUrl,
        ),
        stories: const [],
        hasUnseen: false,
        latestStoryAt: now,
        totalStories: 0,
      );
    }

    // Sort other users' groups: unseen first by latestStoryAt DESC, then seen by latestStoryAt DESC
    final othersWithStories = filteredGroups
        .where((g) => g.stories.isNotEmpty)
        .toList();
    final unseen = othersWithStories.where((g) => g.hasUnseen).toList()
      ..sort((a, b) => b.latestStoryAt.compareTo(a.latestStoryAt));
    final seen = othersWithStories.where((g) => !g.hasUnseen).toList()
      ..sort((a, b) => b.latestStoryAt.compareTo(a.latestStoryAt));

    return [myGroup, ...unseen, ...seen];
  }

  /// Optimistically or definitively mark a story as seen, updating local state
  /// and moving the group toward the seen section if all its active stories are viewed.
  void markStorySeen(String storyId, String ownerId) {
    final currentList = state.valueOrNull;
    if (currentList == null || currentList.isEmpty) return;

    final updated = currentList.map((group) {
      if (group.owner.id != ownerId) return group;

      final updatedStories = group.stories.map((story) {
        if (story.id == storyId) {
          return story.copyWith(hasViewedByMe: true);
        }
        return story;
      }).toList();

      final allSeen = updatedStories.every((s) => s.hasViewedByMe);

      return group.copyWith(stories: updatedStories, hasUnseen: !allSeen);
    }).toList();

    // Deterministic re-sort:
    // 0: Logged in user (first item)
    // Then unseen groups
    // Then seen groups
    if (updated.isNotEmpty) {
      final myGroup = updated[0];
      final others = updated.sublist(1);

      final unseen = others.where((g) => g.hasUnseen).toList()
        ..sort((a, b) => b.latestStoryAt.compareTo(a.latestStoryAt));
      final seen = others.where((g) => !g.hasUnseen).toList()
        ..sort((a, b) => b.latestStoryAt.compareTo(a.latestStoryAt));

      state = AsyncData([myGroup, ...unseen, ...seen]);
    } else {
      state = AsyncData(updated);
    }
  }

  void addStoryToMyGroup(StoryModel story) {
    final currentList = state.valueOrNull;
    if (currentList == null || currentList.isEmpty) {
      refresh();
      return;
    }

    final myGroup = currentList[0];
    final updatedStories = [...myGroup.stories, story];
    final updatedMyGroup = myGroup.copyWith(
      stories: updatedStories,
      totalStories: updatedStories.length,
      latestStoryAt: story.createdAt,
    );

    state = AsyncData([updatedMyGroup, ...currentList.sublist(1)]);
  }

  void removeStoryFromMyGroup(String storyId) {
    final currentList = state.valueOrNull;
    if (currentList == null || currentList.isEmpty) return;

    final myGroup = currentList[0];
    final updatedStories = myGroup.stories
        .where((s) => s.id != storyId)
        .toList();
    final updatedMyGroup = myGroup.copyWith(
      stories: updatedStories,
      totalStories: updatedStories.length,
    );

    state = AsyncData([updatedMyGroup, ...currentList.sublist(1)]);
  }
}
