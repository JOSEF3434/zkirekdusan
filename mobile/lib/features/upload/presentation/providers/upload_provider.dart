import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:mobile/features/home/domain/video_model.dart';
import 'package:mobile/features/upload/data/upload_repository.dart';
import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/features/upload/domain/group_channel_model.dart';
import 'package:mobile/features/upload/domain/upload_video_model.dart';
import 'package:mobile/features/library/data/repositories/playlist_repository.dart';
import 'package:mobile/features/home/presentation/providers/video_feed_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/network/connectivity_service.dart';

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
  final XFile? thumbnailFile;

  final GroupDto? selectedGroup;
  final VideoChannelDto? selectedChannel;

  final UploadVideoFormData? formData;
  final VideoResponseDto? video;

  final double uploadProgress;
  final String? error;

  const UploadState({
    this.step = UploadStep.selectVideo,
    this.file,
    this.thumbnailFile,
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
    XFile? thumbnailFile,
    bool clearThumbnail = false,
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
      thumbnailFile: clearThumbnail
          ? null
          : (thumbnailFile ?? this.thumbnailFile),
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
    StateNotifierProvider<UploadNotifier, UploadState>((ref) {
      return UploadNotifier(
        ref.watch(uploadRepositoryProvider),
        ref.watch(playlistRepositoryProvider),
        ref,
      );
    });

class UploadNotifier extends StateNotifier<UploadState>
    with WidgetsBindingObserver {
  final UploadRepository _repository;
  final PlaylistRepository _playlistRepository;
  final Ref _ref;
  CancelToken? _cancelToken;
  Timer? _pollingTimer;

  UploadNotifier(this._repository, this._playlistRepository, this._ref)
    : super(const UploadState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelToken?.cancel();
    _pollingTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkServerStatusAndRecover();
    }
  }

  Future<void> _checkServerStatusAndRecover() async {
    final videoId = state.video?.id;
    final channelId = state.selectedChannel?.id;
    if (videoId == null) return;

    if (state.step != UploadStep.uploading &&
        state.step != UploadStep.processing &&
        state.step != UploadStep.failed) {
      return;
    }

    try {
      final video = await _repository.getStatus(
        videoId,
        channelId: channelId,
      );
      state = state.copyWith(video: video);

      if (video.status == VideoStatus.ready) {
        _pollingTimer?.cancel();
        if (state.formData?.playlistId != null) {
          try {
            await _playlistRepository.addVideoToPlaylist(
              state.formData!.playlistId!,
              video.id,
            );
          } catch (_) {}
        }
        _ref.invalidate(videoFeedProvider);
        state = state.copyWith(step: UploadStep.completed, clearError: true);
        await WakelockPlus.disable();
      } else if (video.status == VideoStatus.processing ||
          video.status == VideoStatus.queued) {
        state = state.copyWith(step: UploadStep.processing, clearError: true);
        if (_pollingTimer == null || !_pollingTimer!.isActive) {
          _startPolling();
        }
      }
    } catch (_) {
      // Still unreachable or transient error; will recheck on next lifecycle event or poll
    }
  }

  void selectVideo(XFile file) {
    state = state.copyWith(
      file: file,
      step: UploadStep.fillDetails,
      clearError: true,
    );
  }

  void selectThumbnail(XFile? file) {
    state = state.copyWith(thumbnailFile: file, clearThumbnail: file == null);
  }

  void selectChannel(GroupDto group, VideoChannelDto channel) {
    state = state.copyWith(
      selectedGroup: group,
      selectedChannel: channel,
      step: state.file != null ? UploadStep.fillDetails : UploadStep.selectVideo,
      clearError: true,
    );
  }

  void preselectChannel(GroupDto group, VideoChannelDto channel) {
    if (state.file != null) {
      state = state.copyWith(
        selectedGroup: group,
        selectedChannel: channel,
        step: UploadStep.fillDetails,
        clearError: true,
      );
    } else {
      state = const UploadState().copyWith(
        selectedGroup: group,
        selectedChannel: channel,
        step: UploadStep.selectVideo,
        clearError: true,
      );
    }
  }

  void submitDetails(UploadVideoFormData data) {
    state = state.copyWith(formData: data, clearError: true);
    _startUploadProcess();
  }

  void cancelUpload() {
    _cancelToken?.cancel();
    _pollingTimer?.cancel();
    try {
      WakelockPlus.disable();
    } catch (_) {}
    state = const UploadState();
  }

  Future<void> _startUploadProcess() async {
    final isOnline = _ref.read(connectivityProvider).isOnline;
    if (!isOnline) {
      state = state.copyWith(
        step: UploadStep.failed,
        error: 'An active internet connection is required to upload videos.',
      );
      return;
    }

    if (state.selectedChannel == null ||
        state.formData == null ||
        state.file == null) {
      state = state.copyWith(
        step: UploadStep.failed,
        error: 'Missing required video data or channel selection',
      );
      return;
    }

    try {
      await WakelockPlus.enable();
    } catch (_) {}

    state = state.copyWith(
      step: UploadStep.uploading,
      uploadProgress: 0,
      clearError: true,
    );
    _cancelToken = CancelToken();

    try {
      final fileLength = await state.file!.length();

      // 1. Initiate Upload on backend
      final initRequest = UploadInitRequest(
        title: state.formData!.title,
        description: state.formData!.description,
        visibility: state.formData!.visibility,
        channelId: state.selectedChannel!.id,
        playlistId: state.formData!.playlistId,
        sizeBytes: fileLength,
        downloadPermission: state.formData!.downloadPermission,
        isDownloadable: state.formData!.isDownloadable,
        categories: state.formData!.categories,
        tags: state.formData!.tags,
        hashtags: state.formData!.hashtags,
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

      // 2. Upload custom thumbnail if selected
      if (state.thumbnailFile != null) {
        try {
          await _repository.uploadThumbnail(
            channelId: state.selectedChannel!.id,
            videoId: initRes.videoId,
            file: state.thumbnailFile!,
          );
        } catch (_) {
          // Fallback to auto-generated thumbnail from transcode pipeline if custom thumbnail fails
        }
      }

      // 3. Attach Source Video File
      try {
        await _repository.uploadVideoFile(
          channelId: state.selectedChannel!.id,
          videoId: initRes.videoId,
          file: state.file!,
          cancelToken: _cancelToken!,
          onProgress: (count, total) {
            if (total > 0) {
              state = state.copyWith(uploadProgress: count / total);
            }
          },
        );
      } catch (uploadErr) {
        if (uploadErr is DioException && uploadErr.type == DioExceptionType.cancel) {
          try {
            await WakelockPlus.disable();
          } catch (_) {}
          return;
        }

        // The device might have gone to background or connection interrupted.
        // Check if server actually received and saved the video with retries before failing
        bool recovered = false;
        for (int attempt = 0; attempt < 3; attempt++) {
          try {
            await Future.delayed(Duration(seconds: 1 + attempt));
            final currentStatus = await _repository.getStatus(
              initRes.videoId,
              channelId: state.selectedChannel?.id,
            );
            if (currentStatus.status == VideoStatus.ready) {
              state = state.copyWith(
                video: currentStatus,
                step: UploadStep.completed,
                clearError: true,
              );
              _ref.invalidate(videoFeedProvider);
              try {
                await WakelockPlus.disable();
              } catch (_) {}
              recovered = true;
              return;
            } else if (currentStatus.status == VideoStatus.processing ||
                currentStatus.status == VideoStatus.queued) {
              state = state.copyWith(
                video: currentStatus,
                step: UploadStep.processing,
                clearError: true,
              );
              _startPolling();
              recovered = true;
              return;
            }
          } catch (_) {
            // Retry
          }
        }

        if (!recovered) {
          // Keep the video in state so that when user returns to app, lifecycle observer can recover!
          try {
            await WakelockPlus.disable();
          } catch (_) {}
          state = state.copyWith(
            step: UploadStep.failed,
            error: _mapErrorToMessage(uploadErr),
          );
          return;
        }
      }

      // 4. Start Polling Status
      state = state.copyWith(step: UploadStep.processing, clearError: true);
      _startPolling();
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        try {
          await WakelockPlus.disable();
        } catch (_) {}
        return;
      }
      try {
        await WakelockPlus.disable();
      } catch (_) {}
      state = state.copyWith(
        step: UploadStep.failed,
        error: _mapErrorToMessage(e),
      );
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    int pollCount = 0;
    const maxPolls = 150; // 150 × 2s = 5 minutes max
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      pollCount++;
      if (pollCount > maxPolls) {
        timer.cancel();
        // Timeout — treat as completed so user isn't stuck forever
        _ref.invalidate(videoFeedProvider);
        state = state.copyWith(step: UploadStep.completed);
        try {
          await WakelockPlus.disable();
        } catch (_) {}
        return;
      }

      if (state.video == null || state.selectedChannel == null) {
        timer.cancel();
        try {
          await WakelockPlus.disable();
        } catch (_) {}
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

          // If a playlist was selected, add the video to it
          if (state.formData?.playlistId != null) {
            try {
              await _playlistRepository.addVideoToPlaylist(
                state.formData!.playlistId!,
                state.video!.id,
              );
            } catch (_) {}
          }

          // Refresh the video feeds so the newly uploaded video shows up immediately
          _ref.invalidate(videoFeedProvider);

          state = state.copyWith(step: UploadStep.completed);
          try {
            await WakelockPlus.disable();
          } catch (_) {}
        } else if (video.status == VideoStatus.failed) {
          timer.cancel();
          state = state.copyWith(
            step: UploadStep.failed,
            error:
                'Video processing failed on server. Please try a different video format or smaller file.',
          );
          try {
            await WakelockPlus.disable();
          } catch (_) {}
        }
      } catch (e) {
        // Keep polling on transient errors (e.g. background suspension or brief connectivity drops)
      }
    });
  }

  String _mapErrorToMessage(dynamic e) {
    if (e is DioException) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      String? backendMsg;
      if (responseData is Map) {
        backendMsg =
            responseData['message'] as String? ??
            responseData['error'] as String?;
      }

      if (statusCode == 400) {
        return backendMsg ??
            'Invalid request. Please make sure the video title is at least 3 characters.';
      } else if (statusCode == 401) {
        return 'Your session has expired. Please sign in and try again.';
      } else if (statusCode == 403) {
        return backendMsg ??
            'You do not have permission to upload videos to this channel. If this group is pending approval, uploads are disabled until an Admin approves it.';
      } else if (statusCode == 404) {
        return 'The target channel or group was not found.';
      } else if (statusCode == 413) {
        return 'The selected video file is too large to upload.';
      } else if (statusCode != null && statusCode >= 500) {
        return 'A server error occurred during upload. Please try again shortly.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Network connection error. Please check your internet connection and try again.';
      }
    }
    return e.toString().replaceFirst('Exception: ', '');
  }
}
