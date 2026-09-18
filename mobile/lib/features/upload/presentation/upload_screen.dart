// lib/features/upload/presentation/upload_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/upload/presentation/providers/upload_provider.dart';
import 'package:mobile/features/upload/domain/group_channel_model.dart';
import 'package:mobile/features/upload/data/upload_repository.dart';
import 'package:mobile/features/upload/domain/upload_video_model.dart';
import 'package:mobile/features/library/presentation/playlists_screen.dart';
import 'package:mobile/features/home/presentation/providers/video_feed_provider.dart';

class UploadScreen extends ConsumerWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uploadProvider);
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.step == UploadStep.fillDetails
              ? tr('video.details')
              : state.step == UploadStep.uploading
              ? tr('upload.uploading')
              : state.step == UploadStep.processing
              ? tr('upload.processing')
              : tr('shell.upload_video'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (state.step == UploadStep.uploading ||
                state.step == UploadStep.processing) {
              _confirmCancel(context, ref);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: _buildBody(context, ref, state),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    final tr = ref.read(trProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('upload.cancel_title')),
        content: Text(tr('upload.cancel_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr('upload.keep_uploading')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(uploadProvider.notifier).cancelUpload();
              context.pop();
            },
            child: Text(tr('upload.cancel_upload')),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, UploadState state) {
    switch (state.step) {
      case UploadStep.selectVideo:
        return const _VideoPickerWidget();
      case UploadStep.selectChannel:
        return _ChannelSelectorWidget();
      case UploadStep.fillDetails:
        return const _UploadFormWidget();
      case UploadStep.uploading:
        return _UploadProgressWidget(progress: state.uploadProgress);
      case UploadStep.processing:
        return const _ProcessingStatusWidget();
      case UploadStep.completed:
        return _UploadCompletedWidget(
          videoId: state.video?.id,
          title: state.formData?.title ?? state.video?.title ?? 'Video',
        );
      case UploadStep.failed:
        return _UploadFailedWidget(error: state.error);
    }
  }
}

// ─────────────────────────────────────────────
// STEP 1: VIDEO PICKER
// ─────────────────────────────────────────────

class _VideoPickerWidget extends ConsumerWidget {
  const _VideoPickerWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tr = ref.watch(trProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                tr('upload.select_video_title'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                tr('upload.select_video_desc'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickVideo(
                      source: ImageSource.gallery,
                    );
                    if (pickedFile != null) {
                      ref.read(uploadProvider.notifier).selectVideo(pickedFile);
                    }
                  },
                  icon: const Icon(Icons.video_library_rounded),
                  label: Text(
                    tr('upload.select_file_btn'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STEP 2: CHANNEL SELECTOR
// ─────────────────────────────────────────────

class _ChannelSelectorWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ChannelSelectorWidget> createState() =>
      _ChannelSelectorWidgetState();
}

class _ChannelSelectorWidgetState
    extends ConsumerState<_ChannelSelectorWidget> {
  List<GroupDto>? _groups;
  Map<String, List<VideoChannelDto>> _channels = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = ref.read(uploadRepositoryProvider);
      final groups = await repo.getMyGroups();

      final Map<String, List<VideoChannelDto>> channels = {};
      for (final g in groups) {
        if (g.status == 'ACTIVE') {
          try {
            channels[g.id] = await repo.getGroupChannels(g.id);
          } catch (_) {
            channels[g.id] = [];
          }
        }
      }

      if (mounted) {
        setState(() {
          _groups = groups;
          _channels = channels;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String message = 'Unable to connect to the server. Please try again.';
        if (e.toString().contains('500')) {
          message =
              'Server encountered an issue loading channels. Please retry.';
        } else if (e.toString().contains('401') ||
            e.toString().contains('403')) {
          message =
              'You do not have permission to view channels or your session has expired.';
        }
        setState(() {
          _error = message;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                tr('upload.load_channels_failed'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadData();
                },
                icon: const Icon(Icons.refresh),
                label: Text(tr('common.retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (_groups == null || _groups!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.tv_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                tr('upload.no_channels_title'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(tr('upload.no_channels_desc'), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.pop(),
                child: Text(tr('upload.go_back')),
              ),
            ],
          ),
        ),
      );
    }

    Future<void> handleSelectChannel(GroupDto group) async {
      final groupChannels = _channels[group.id] ?? [];
      VideoChannelDto channel;
      if (groupChannels.isNotEmpty) {
        channel = groupChannels.first;
      } else {
        try {
          final repo = ref.read(uploadRepositoryProvider);
          final fetched = await repo.getGroupChannels(group.id);
          if (fetched.isNotEmpty) {
            channel = fetched.first;
          } else {
            channel = VideoChannelDto(
              id: group.id,
              groupId: group.id,
              name: group.name,
              type: 'PUBLIC',
              uploadPermission: 'MEMBER',
            );
          }
        } catch (_) {
          channel = VideoChannelDto(
            id: group.id,
            groupId: group.id,
            name: group.name,
            type: 'PUBLIC',
            uploadPermission: 'MEMBER',
          );
        }
      }

      ref.read(uploadProvider.notifier).selectChannel(group, channel);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _groups!.length,
      itemBuilder: (context, index) {
        final group = _groups![index];
        final isPending = group.status == 'PENDING_APPROVAL';
        final theme = Theme.of(context);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 1,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: isPending ? null : () => handleSelectChannel(group),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isPending
                        ? Colors.orange.withValues(alpha: 0.15)
                        : theme.colorScheme.primaryContainer,
                    child: isPending
                        ? const Icon(
                            Icons.lock_outline,
                            color: Colors.orange,
                            size: 22,
                          )
                        : Text(
                            group.name.isNotEmpty
                                ? group.name.substring(0, 1).toUpperCase()
                                : 'C',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isPending) ...[
                          const SizedBox(height: 4),
                          Text(
                            tr('upload.pending_approval'),
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isPending)
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// STEP 3: YOUTUBE-STYLE DETAILS FORM
// ─────────────────────────────────────────────

class _UploadFormWidget extends ConsumerStatefulWidget {
  const _UploadFormWidget();

  @override
  ConsumerState<_UploadFormWidget> createState() => _UploadFormWidgetState();
}

class _UploadFormWidgetState extends ConsumerState<_UploadFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _visibility = 'PUBLIC';
  String? _playlistId;
  Uint8List? _thumbnailBytes;

  @override
  void initState() {
    super.initState();
    final uploadState = ref.read(uploadProvider);
    // Pre-fill title from filename if available
    if (uploadState.file != null && _titleController.text.isEmpty) {
      final name = uploadState.file!.name;
      final dotIndex = name.lastIndexOf('.');
      _titleController.text =
          (dotIndex > 0 ? name.substring(0, dotIndex) : name).replaceAll(
            RegExp(r'[_-]'),
            ' ',
          );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _thumbnailBytes = bytes;
      });
      ref.read(uploadProvider.notifier).selectThumbnail(image);
    }
  }

  void _removeThumbnail() {
    setState(() {
      _thumbnailBytes = null;
    });
    ref.read(uploadProvider.notifier).selectThumbnail(null);
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tr = ref.watch(trProvider);

    return Form(
      key: _formKey,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Target Channel Banner
              if (uploadState.selectedChannel != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primary,
                        child: const Icon(
                          Icons.video_camera_front,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              uploadState.selectedChannel!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (uploadState.selectedGroup != null)
                              Text(
                                uploadState.selectedGroup!.name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // Change channel
                          ref
                              .read(uploadProvider.notifier)
                              .selectVideo(uploadState.file!);
                        },
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text(
                          'Change',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              // Custom Thumbnail Section
              Text(
                tr('upload.thumbnail_label'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tr('upload.thumbnail_desc'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 10),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                      style: _thumbnailBytes == null
                          ? BorderStyle.solid
                          : BorderStyle.none,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _thumbnailBytes != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(_thumbnailBytes!, fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Row(
                                children: [
                                  IconButton.filledTonal(
                                    icon: const Icon(Icons.edit, size: 16),
                                    onPressed: _pickThumbnail,
                                    tooltip: 'Change thumbnail',
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton.filled(
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                    ),
                                    icon: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    onPressed: _removeThumbnail,
                                    tooltip: 'Remove thumbnail',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : InkWell(
                          onTap: _pickThumbnail,
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 40,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tr('upload.thumbnail_upload'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tr('upload.thumbnail_hint'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: tr('upload.title_required'),
                  hintText: tr('upload.title_hint'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
                maxLength: 300,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return tr('upload.title_validation');
                  }
                  if (v.trim().length < 3) {
                    return tr('upload.title_min_length');
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: tr('upload.description_label'),
                  hintText: tr('upload.description_hint'),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 5000,
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _visibility,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: tr('upload.visibility_label'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.visibility_rounded),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'PUBLIC',
                    child: Text(
                      tr('upload.visibility_public'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'GROUP_ONLY',
                    child: Text(
                      tr('upload.visibility_channel'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'PRIVATE',
                    child: Text(
                      tr('upload.visibility_private'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _visibility = v);
                },
              ),

              const SizedBox(height: 16),

              ref
                  .watch(myPlaylistsProvider)
                  .when(
                    data: (playlists) {
                      if (playlists.isEmpty) return const SizedBox.shrink();
                      return DropdownButtonFormField<String?>(
                        initialValue: _playlistId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: tr('upload.playlist_label'),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.playlist_add_rounded),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(tr('upload.none_playlist')),
                          ),
                          ...playlists.map(
                            (p) => DropdownMenuItem<String?>(
                              value: p.id,
                              child: Text(
                                p.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _playlistId = v),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (error, stackTrace) => const SizedBox.shrink(),
                  ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final data = UploadVideoFormData(
                        title: _titleController.text.trim(),
                        description: _descriptionController.text.trim(),
                        visibility: _visibility,
                        playlistId: _playlistId,
                      );
                      ref.read(uploadProvider.notifier).submitDetails(data);
                    }
                  },
                  icon: const Icon(Icons.cloud_upload_rounded),
                  label: Text(
                    _visibility == 'PUBLIC'
                        ? tr('upload.publish_btn')
                        : tr('upload.save_upload_btn'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STEP 4: UPLOAD PROGRESS
// ─────────────────────────────────────────────

class _UploadProgressWidget extends ConsumerWidget {
  final double progress;

  const _UploadProgressWidget({required this.progress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);
    final tr = ref.watch(trProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CircularProgressIndicator(
                      value: progress > 0 ? progress : null,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                tr('upload.uploading'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('common.loading'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(uploadProvider.notifier).cancelUpload();
                  context.pop();
                },
                icon: const Icon(Icons.close),
                label: Text(tr('upload.cancel_upload')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STEP 5: SERVER PROCESSING
// ─────────────────────────────────────────────

class _ProcessingStatusWidget extends StatelessWidget {
  const _ProcessingStatusWidget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(strokeWidth: 6),
              ),
              const SizedBox(height: 28),
              Text(
                'Processing Video...',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'We\'re transcoding resolutions (1080p, 720p, 480p) and generating HLS streams for smooth playback.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Optimizing for mobile playback',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STEP 6: COMPLETED
// ─────────────────────────────────────────────

class _UploadCompletedWidget extends ConsumerWidget {
  final String? videoId;
  final String title;

  const _UploadCompletedWidget({this.videoId, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                tr('upload.uploading'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"$title"',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 36),
              if (videoId != null && videoId!.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      ref.invalidate(videoFeedProvider);
                      context.pushReplacement('/video/$videoId');
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      tr('video.play'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(videoFeedProvider);
                    context.pop();
                  },
                  icon: const Icon(Icons.home_rounded),
                  label: Text(tr('upload.go_home')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STEP 7: ERROR STATE
// ─────────────────────────────────────────────

class _UploadFailedWidget extends ConsumerWidget {
  final String? error;

  const _UploadFailedWidget({this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                tr('state.error'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error ?? tr('upload.unknown_error'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    ref.read(uploadProvider.notifier).cancelUpload();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(tr('upload.try_again')),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(uploadProvider.notifier).cancelUpload();
                    context.pop();
                  },
                  child: Text(tr('common.cancel')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
