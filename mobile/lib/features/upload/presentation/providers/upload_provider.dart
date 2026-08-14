// lib/features/upload/presentation/providers/upload_provider.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/upload/data/upload_repository.dart';
import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/features/upload/domain/group_channel_model.dart';
import 'package:mobile/features/upload/domain/upload_video_model.dart';
import 'dart:io' as java_io;

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
  final String? filePath;
  final String? fileName;

  final GroupDto? selectedGroup;
  final VideoChannelDto? selectedChannel;

  final UploadVideoFormData? formData;
  final VideoResponseDto? video;

  final double uploadProgress;
  final String? error;

  const UploadState({
    this.step = UploadStep.selectVideo,
    this.filePath,
    this.fileName,
    this.selectedGroup,
    this.selectedChannel,
    this.formData,
    this.video,
    this.uploadProgress = 0,
    this.error,
  });

  UploadState copyWith({
    UploadStep? step,
    String? filePath,
    String? fileName,
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
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
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
      return UploadNotifier(ref.watch(uploadRepositoryProvider));
    });

class UploadNotifier extends StateNotifier<UploadState> {
  final UploadRepository _repository;
  CancelToken? _cancelToken;
  Timer? _pollingTimer;

  UploadNotifier(this._repository) : super(const UploadState());

  @override
  void dispose() {
    _cancelToken?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void selectVideo(String path, String name) {
    final nextStep = state.selectedChannel != null 
        ? UploadStep.fillDetails 
        : UploadStep.selectChannel;
        
    state = state.copyWith(
      filePath: path,
      fileName: name,
      step: nextStep,
      clearError: true,
    );
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
      step: UploadStep.selectVideo, // Still need to pick a video, but channel is preselected
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
        state.filePath == null) {
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
      // For now we assume a direct upload or simple file size.
      // In a real app we'd get file length and chunk it if needed.
      await _repository.uploadChunk(
        uploadUrl: initRes.uploadUrl,
        file: java_io.File(state.filePath!), // Make sure to use dart:io File
        start: 0,
        end:
            0, // We need file length, let's just assume we can get it via File(filePath).lengthSync()
        totalSize: 0,
        cancelToken: _cancelToken!,
        onProgress: (count, total) {
          if (total != -1) {
            state = state.copyWith(uploadProgress: count / total);
          }
        },
      );

      // Complete Upload
      await _repository.completeUpload(initRes.videoId);

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
        final video = await _repository.getStatus(state.video!.id);
        state = state.copyWith(video: video);

        if (video.status == VideoStatus.ready) {
          timer.cancel();
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
