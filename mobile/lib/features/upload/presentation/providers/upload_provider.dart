// lib/features/upload/presentation/providers/upload_provider.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/upload/data/upload_repository.dart';
import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/features/upload/domain/group_channel_model.dart';
import 'package:mobile/features/upload/domain/upload_video_model.dart';
import 'package:mobile/features/library/data/repositories/playlist_repository.dart';
import 'package:image_picker/image_picker.dart';

enum UploadStep {
  selectVideo,
  selectChannel,
  fillDetails,
  uploading,
  processing,
  completed,
  failed,
}

class UploadState {
  final UploadStep step;
  final XFile? file;

  final GroupDto? selectedGroup;
  final VideoChannelDto? selectedChannel;

  final UploadVideoFormData? formData;
  final VideoResponseDto? video;

  final double uploadProgress;
  final String? error;

  const UploadState({
    this.step = UploadStep.selectVideo,
    this.file,
    this.selectedGroup,
    this.selectedChannel,
    this.formData,
    this.video,
    this.uploadProgress = 0,
    this.error,
  });

  UploadState copyWith({
    UploadStep? step,
    XFile? file,
    GroupDto? selectedGroup,
    VideoChannelDto? selectedChannel,
    UploadVideoFormData? formData,
    VideoResponseDto? video,
    double? uploadProgress,
    String? error,
    bool clearError = false,
  }) {
    return UploadState(
      step: step ?? this.step,
      file: file ?? this.file,
      selectedGroup: selectedGroup ?? this.selectedGroup,
      selectedChannel: selectedChannel ?? this.selectedChannel,
      formData: formData ?? this.formData,
      video: video ?? this.video,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final uploadProvider =
    StateNotifierProvider.autoDispose<UploadNotifier, UploadState>((ref) {
      return UploadNotifier(
        ref.watch(uploadRepositoryProvider),
        ref.watch(playlistRepositoryProvider),
      );
    });

class UploadNotifier extends StateNotifier<UploadState> {
  final UploadRepository _repository;
  final PlaylistRepository _playlistRepository;
  CancelToken? _cancelToken;
  Timer? _pollingTimer;

  UploadNotifier(this._repository, this._playlistRepository)
    : super(const UploadState());

  @override
  void dispose() {
    _cancelToken?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void selectVideo(XFile file) {
    final nextStep = state.selectedChannel != null
        ? UploadStep.fillDetails
        : UploadStep.selectChannel;

    state = state.copyWith(file: file, step: nextStep, clearError: true);
  }

  void selectChannel(GroupDto group, VideoChannelDto channel) {
    state = state.copyWith(
      selectedGroup: group,
      selectedChannel: channel,
      step: UploadStep.fillDetails,
      clearError: true,
    );
  }

  void preselectChannel(GroupDto group, VideoChannelDto channel) {
    state = const UploadState().copyWith(
      selectedGroup: group,
      selectedChannel: channel,
      step: UploadStep
          .selectVideo, // Still need to pick a video, but channel is preselected
      clearError: true,
    );
  }

  void submitDetails(UploadVideoFormData data) {
    state = state.copyWith(formData: data, clearError: true);
    _startUploadProcess();
  }

  void cancelUpload() {
    _cancelToken?.cancel();
    _pollingTimer?.cancel();
    state = const UploadState();
  }

  Future<void> _startUploadProcess() async {
    if (state.selectedChannel == null ||
        state.formData == null ||
        state.file == null) {
      state = state.copyWith(error: 'Missing required data');
      return;
    }

    state = state.copyWith(
      step: UploadStep.uploading,
      uploadProgress: 0,
      clearError: true,
    );
    _cancelToken = CancelToken();

    try {
      // 1. Initiate Upload
      final initRequest = UploadInitRequest(
        title: state.formData!.title,
        description: state.formData!.description,
        visibility: state.formData!.visibility,
        channelId: state.selectedChannel!.id,
        playlistId: state.formData!.playlistId,
        sizeBytes:
            0, // Get actual size if possible, otherwise backend handles it or defaults
      );
      final initRes = await _repository.initiateUpload(initRequest);
      state = state.copyWith(
        video: VideoResponseDto(
          id: initRes.videoId,
          title: state.formData!.title,
          status: VideoStatus.uploading,
          visibility: state.formData!.visibility,
          author: const PostAuthorDto(id: '', username: '', displayName: ''),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // 2. Attach File
      await _repository.uploadVideoFile(
        channelId: state.selectedChannel!.id,
        videoId: initRes.videoId,
        file: state.file!,
        cancelToken: _cancelToken!,
        onProgress: (count, total) {
          if (total != -1) {
            state = state.copyWith(uploadProgress: count / total);
          }
        },
      );

      // 3. Start Polling Status
      state = state.copyWith(step: UploadStep.processing, clearError: true);
      _startPolling();
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        // Cancelled explicitly
        return;
      }
      state = state.copyWith(
        step: UploadStep.failed,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (state.video == null || state.selectedChannel == null) {
        timer.cancel();
        return;
      }

      try {
        final video = await _repository.getStatus(
          state.video!.id,
          channelId: state.selectedChannel?.id,
        );
        state = state.copyWith(video: video);

        if (video.status == VideoStatus.ready) {
          timer.cancel();

          // If a playlist was selected, add the video to it now that it's ready.
          if (state.formData?.playlistId != null) {
            try {
              await _playlistRepository.addVideoToPlaylist(
                state.formData!.playlistId!,
                state.video!.id,
              );
            } catch (_) {
              // Non-fatal if playlist addition fails, but we could log it.
            }
          }

          state = state.copyWith(step: UploadStep.completed);
        } else if (video.status == VideoStatus.failed) {
          timer.cancel();
          state = state.copyWith(
            step: UploadStep.failed,
            error: 'Video processing failed on server',
          );
        }
      } catch (e) {
        // Log silently, keep polling unless it's a persistent hard error
      }
    });
  }
}
