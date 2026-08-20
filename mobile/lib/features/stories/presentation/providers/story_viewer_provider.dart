// lib/features/stories/presentation/providers/story_viewer_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/stories/data/datasources/stories_remote_datasource.dart';
import 'package:mobile/features/stories/data/models/story_feed_group_model.dart';
import 'package:mobile/features/stories/data/models/story_model.dart';
import 'package:mobile/features/stories/presentation/providers/story_feed_provider.dart';

class StoryViewerState {
  final List<StoryFeedGroupModel> groups;
  final int currentGroupIndex;
  final int currentStoryIndex;
  final bool isPaused;
  final bool isOverlayOpen;
  final double progress; // 0.0 to 1.0 for active story segment
  final bool isCompleted;

  const StoryViewerState({
    this.groups = const [],
    this.currentGroupIndex = 0,
    this.currentStoryIndex = 0,
    this.isPaused = false,
    this.isOverlayOpen = false,
    this.progress = 0.0,
    this.isCompleted = false,
  });

  StoryFeedGroupModel? get currentGroup {
    if (currentGroupIndex >= 0 && currentGroupIndex < groups.length) {
      return groups[currentGroupIndex];
    }
    return null;
  }

  StoryModel? get currentStory {
    final group = currentGroup;
    if (group != null &&
        currentStoryIndex >= 0 &&
        currentStoryIndex < group.stories.length) {
      return group.stories[currentStoryIndex];
    }
    return null;
  }

  bool isOwner(String? myUserId) {
    if (myUserId == null) return false;
    return currentStory?.author.id == myUserId;
  }

  StoryViewerState copyWith({
    List<StoryFeedGroupModel>? groups,
    int? currentGroupIndex,
    int? currentStoryIndex,
    bool? isPaused,
    bool? isOverlayOpen,
    double? progress,
    bool? isCompleted,
  }) {
    return StoryViewerState(
      groups: groups ?? this.groups,
      currentGroupIndex: currentGroupIndex ?? this.currentGroupIndex,
      currentStoryIndex: currentStoryIndex ?? this.currentStoryIndex,
      isPaused: isPaused ?? this.isPaused,
      isOverlayOpen: isOverlayOpen ?? this.isOverlayOpen,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class StoryViewerNotifier extends StateNotifier<StoryViewerState> {
  final Ref _ref;
  Timer? _ticker;
  static const Duration _imageDuration = Duration(seconds: 10);
  static const Duration _tickInterval = Duration(milliseconds: 50);

  // Set of story IDs already viewed in this viewer session to prevent duplicate network calls
  final Set<String> _viewedStoryIds = {};

  StoryViewerNotifier(this._ref) : super(const StoryViewerState());

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void init({
    required List<StoryFeedGroupModel> groups,
    int initialGroupIndex = 0,
    int initialStoryIndex = 0,
  }) {
    _ticker?.cancel();

    // Filter out groups with 0 stories
    final validGroups = groups.where((g) => g.stories.isNotEmpty).toList();
    final clampedGroupIndex = validGroups.isEmpty
        ? 0
        : initialGroupIndex.clamp(0, validGroups.length - 1);
    final currentGroup = validGroups.isNotEmpty
        ? validGroups[clampedGroupIndex]
        : null;
    final clampedStoryIndex = currentGroup != null
        ? initialStoryIndex.clamp(0, currentGroup.stories.length - 1)
        : 0;

    state = StoryViewerState(
      groups: validGroups,
      currentGroupIndex: clampedGroupIndex,
      currentStoryIndex: clampedStoryIndex,
      progress: 0.0,
      isPaused: false,
      isOverlayOpen: false,
      isCompleted: validGroups.isEmpty,
    );

    if (validGroups.isNotEmpty) {
      _startPlayback();
      _recordViewForCurrentStory();
    }
  }

  void _startPlayback() {
    _ticker?.cancel();
    final story = state.currentStory;
    if (story == null) return;

    // For video stories, video controller manages advancement on completion
    if (story.isVideo) {
      return;
    }

    final totalTicks =
        _imageDuration.inMilliseconds / _tickInterval.inMilliseconds;
    final step = 1.0 / totalTicks;

    _ticker = Timer.periodic(_tickInterval, (timer) {
      if (state.isPaused || state.isOverlayOpen) return;

      final newProgress = state.progress + step;
      if (newProgress >= 1.0) {
        nextStory();
      } else {
        state = state.copyWith(progress: newProgress);
      }
    });
  }

  void pause() {
    state = state.copyWith(isPaused: true);
  }

  void resume() {
    state = state.copyWith(isPaused: false);
  }

  void setOverlayOpen(bool isOpen) {
    state = state.copyWith(isOverlayOpen: isOpen);
  }

  void updateVideoProgress(double progress) {
    if (!state.isPaused && !state.isOverlayOpen) {
      state = state.copyWith(progress: progress.clamp(0.0, 1.0));
    }
  }

  void onVideoFinished() {
    nextStory();
  }

  void nextStory() {
    final currentGroup = state.currentGroup;
    if (currentGroup == null) return;

    if (state.currentStoryIndex < currentGroup.stories.length - 1) {
      // Next story in current group
      state = state.copyWith(
        currentStoryIndex: state.currentStoryIndex + 1,
        progress: 0.0,
      );
      _startPlayback();
      _recordViewForCurrentStory();
    } else if (state.currentGroupIndex < state.groups.length - 1) {
      // Next group
      state = state.copyWith(
        currentGroupIndex: state.currentGroupIndex + 1,
        currentStoryIndex: 0,
        progress: 0.0,
      );
      _startPlayback();
      _recordViewForCurrentStory();
    } else {
      // End of all stories
      _ticker?.cancel();
      state = state.copyWith(isCompleted: true);
    }
  }

  void previousStory() {
    if (state.progress > 0.15) {
      // If we are already mid-way through current story, restart it
      state = state.copyWith(progress: 0.0);
      _startPlayback();
      return;
    }

    if (state.currentStoryIndex > 0) {
      // Previous story in same group
      state = state.copyWith(
        currentStoryIndex: state.currentStoryIndex - 1,
        progress: 0.0,
      );
      _startPlayback();
      _recordViewForCurrentStory();
    } else if (state.currentGroupIndex > 0) {
      // Previous group (last story of previous group)
      final prevGroup = state.groups[state.currentGroupIndex - 1];
      state = state.copyWith(
        currentGroupIndex: state.currentGroupIndex - 1,
        currentStoryIndex: prevGroup.stories.length - 1,
        progress: 0.0,
      );
      _startPlayback();
      _recordViewForCurrentStory();
    } else {
      // Restart current story
      state = state.copyWith(progress: 0.0);
      _startPlayback();
    }
  }

  void jumpToGroup(int groupIndex) {
    if (groupIndex < 0 || groupIndex >= state.groups.length) return;
    state = state.copyWith(
      currentGroupIndex: groupIndex,
      currentStoryIndex: 0,
      progress: 0.0,
    );
    _startPlayback();
    _recordViewForCurrentStory();
  }

  void _recordViewForCurrentStory() {
    final story = state.currentStory;
    final group = state.currentGroup;
    if (story == null || group == null) return;

    if (_viewedStoryIds.contains(story.id)) return;
    _viewedStoryIds.add(story.id);

    // Call backend view recording silently
    _ref.read(storiesRemoteDatasourceProvider).viewStory(story.id).catchError((
      e,
    ) {
      debugPrint('[StoryViewer] view tracking failed: $e');
      return story;
    });

    // Update local feed state so ring borders update smoothly
    _ref
        .read(storyFeedProvider.notifier)
        .markStorySeen(story.id, group.owner.id);
  }

  Future<void> addReaction(String reaction) async {
    final story = state.currentStory;
    if (story == null) return;

    try {
      await _ref
          .read(storiesRemoteDatasourceProvider)
          .addReaction(story.id, reaction);
      _updateCurrentStoryLocally(
        story.copyWith(
          myReaction: reaction,
          reactionsCount: story.myReaction == null
              ? story.reactionsCount + 1
              : story.reactionsCount,
        ),
      );
    } catch (e) {
      debugPrint('[StoryViewer] reaction error: $e');
    }
  }

  Future<void> removeReaction() async {
    final story = state.currentStory;
    if (story == null || story.myReaction == null) return;

    try {
      await _ref.read(storiesRemoteDatasourceProvider).removeReaction(story.id);
      _updateCurrentStoryLocally(
        story.copyWith(
          myReaction: null,
          reactionsCount: (story.reactionsCount - 1).clamp(0, 999999),
        ),
      );
    } catch (e) {
      debugPrint('[StoryViewer] remove reaction error: $e');
    }
  }

  Future<bool> deleteCurrentStory() async {
    final story = state.currentStory;
    if (story == null) return false;

    try {
      await _ref.read(storiesRemoteDatasourceProvider).deleteStory(story.id);
      _ref.read(storyFeedProvider.notifier).removeStoryFromMyGroup(story.id);

      // Remove from active groups list in viewer
      final currentGroup = state.currentGroup;
      if (currentGroup == null) return true;

      final updatedStories = currentGroup.stories
          .where((s) => s.id != story.id)
          .toList();

      if (updatedStories.isEmpty) {
        // Entire group is now empty, remove group
        final updatedGroups = state.groups
            .where((g) => g.owner.id != currentGroup.owner.id)
            .toList();
        if (updatedGroups.isEmpty) {
          state = state.copyWith(isCompleted: true);
        } else {
          final nextGroupIdx = state.currentGroupIndex.clamp(
            0,
            updatedGroups.length - 1,
          );
          state = state.copyWith(
            groups: updatedGroups,
            currentGroupIndex: nextGroupIdx,
            currentStoryIndex: 0,
            progress: 0.0,
          );
          _startPlayback();
          _recordViewForCurrentStory();
        }
      } else {
        final nextStoryIdx = state.currentStoryIndex.clamp(
          0,
          updatedStories.length - 1,
        );
        final updatedGroup = currentGroup.copyWith(stories: updatedStories);
        final updatedGroups = [...state.groups];
        updatedGroups[state.currentGroupIndex] = updatedGroup;

        state = state.copyWith(
          groups: updatedGroups,
          currentStoryIndex: nextStoryIdx,
          progress: 0.0,
        );
        _startPlayback();
        _recordViewForCurrentStory();
      }
      return true;
    } catch (e) {
      debugPrint('[StoryViewer] delete error: $e');
      return false;
    }
  }

  void _updateCurrentStoryLocally(StoryModel updatedStory) {
    final group = state.currentGroup;
    if (group == null) return;

    final updatedStories = [...group.stories];
    updatedStories[state.currentStoryIndex] = updatedStory;

    final updatedGroup = group.copyWith(stories: updatedStories);
    final updatedGroups = [...state.groups];
    updatedGroups[state.currentGroupIndex] = updatedGroup;

    state = state.copyWith(groups: updatedGroups);
  }
}

final storyViewerProvider =
    StateNotifierProvider.autoDispose<StoryViewerNotifier, StoryViewerState>((
      ref,
    ) {
      return StoryViewerNotifier(ref);
    });
