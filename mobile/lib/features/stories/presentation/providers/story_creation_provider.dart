// lib/features/stories/presentation/providers/story_creation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/stories/data/datasources/stories_remote_datasource.dart';
import 'package:mobile/features/stories/presentation/providers/story_feed_provider.dart';

class StoryCreationState {
  final XFile? selectedFile;
  final bool isVideo;
  final String? caption;
  final String? backgroundColor;
  final String? textColor;
  final bool isUploading;
  final double uploadProgress; // 0.0 to 1.0
  final String? error;
  final bool isSuccess;

  const StoryCreationState({
    this.selectedFile,
    this.isVideo = false,
    this.caption,
    this.backgroundColor,
    this.textColor,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.error,
    this.isSuccess = false,
  });

  StoryCreationState copyWith({
    XFile? selectedFile,
    bool? isVideo,
    String? caption,
    String? backgroundColor,
    String? textColor,
    bool? isUploading,
    double? uploadProgress,
    String? error,
    bool? isSuccess,
    bool clearFile = false,
    bool clearError = false,
  }) {
    return StoryCreationState(
      selectedFile: clearFile ? null : (selectedFile ?? this.selectedFile),
      isVideo: isVideo ?? this.isVideo,
      caption: caption ?? this.caption,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: clearError ? null : (error ?? this.error),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class StoryCreationNotifier extends StateNotifier<StoryCreationState> {
  final Ref _ref;
  final ImagePicker _picker = ImagePicker();

  StoryCreationNotifier(this._ref) : super(const StoryCreationState());

  Future<void> pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 88,
      );
      if (file != null) {
        state = state.copyWith(
          selectedFile: file,
          isVideo: false,
          clearError: true,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to pick image. Please try again.');
    }
  }

  Future<void> pickVideo(ImageSource source) async {
    try {
      final file = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 60),
      );
      if (file != null) {
        state = state.copyWith(
          selectedFile: file,
          isVideo: true,
          clearError: true,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to pick video. Please try again.');
    }
  }

  void setCaption(String caption) {
    state = state.copyWith(caption: caption);
  }

  void setColors({String? background, String? text}) {
    state = state.copyWith(backgroundColor: background, textColor: text);
  }

  void clearSelection() {
    state = const StoryCreationState();
  }

  Future<bool> uploadStory() async {
    final file = state.selectedFile;
    if (file == null) {
      state = state.copyWith(error: 'Please select an image or video first');
      return false;
    }

    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0.0,
      clearError: true,
    );

    try {
      final created = await _ref
          .read(storiesRemoteDatasourceProvider)
          .createStoryWithFile(
            file: file,
            content: state.caption,
            backgroundColor: state.backgroundColor,
            textColor: state.textColor,
            onProgress: (sent, total) {
              if (total > 0) {
                state = state.copyWith(uploadProgress: sent / total);
              }
            },
          );

      // Immediately add to My Story group in the feed
      _ref.read(storyFeedProvider.notifier).addStoryToMyGroup(created);

      state = state.copyWith(
        isUploading: false,
        uploadProgress: 1.0,
        isSuccess: true,
      );
      return true;
    } catch (e) {
      final message = e is AppException
          ? e.message
          : 'Your story could not be uploaded. Please try again.';
      state = state.copyWith(isUploading: false, error: message);
      return false;
    }
  }
}

final storyCreationProvider =
    StateNotifierProvider.autoDispose<
      StoryCreationNotifier,
      StoryCreationState
    >((ref) {
      return StoryCreationNotifier(ref);
    });
