// lib/features/upload/presentation/upload_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/upload/presentation/providers/upload_provider.dart';
import 'package:mobile/features/upload/domain/group_channel_model.dart';
import 'package:mobile/features/upload/data/upload_repository.dart';
import 'package:mobile/features/upload/domain/upload_video_model.dart';
import 'package:mobile/features/library/presentation/playlists_screen.dart';

class UploadScreen extends ConsumerWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uploadProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Video'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (state.step == UploadStep.uploading ||
                state.step == UploadStep.processing) {
              ref.read(uploadProvider.notifier).cancelUpload();
            }
            context.pop();
          },
        ),
      ),
      body: _buildBody(context, ref, state, theme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    UploadState state,
    ThemeData theme,
  ) {
    switch (state.step) {
      case UploadStep.selectVideo:
        return _VideoPickerWidget();
      case UploadStep.selectChannel:
        return _ChannelSelectorWidget();
      case UploadStep.fillDetails:
        return _UploadFormWidget();
      case UploadStep.uploading:
        return _UploadProgressWidget(progress: state.uploadProgress);
      case UploadStep.processing:
        return _ProcessingStatusWidget();
      case UploadStep.completed:
        return _UploadCompletedWidget(videoId: state.video?.id);
      case UploadStep.failed:
        return _UploadFailedWidget(error: state.error);
    }
  }
}

class _VideoPickerWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library,
            size: 80,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text('Select a video to upload', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('MP4, MOV, or WebM', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () async {
              final picker = ImagePicker();
              final pickedFile = await picker.pickVideo(
                source: ImageSource.gallery,
              );

              if (pickedFile != null) {
                ref.read(uploadProvider.notifier).selectVideo(pickedFile);
              }
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Select File'),
          ),
        ],
      ),
    );
  }
}

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
        channels[g.id] = await repo.getGroupChannels(g.id);
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
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
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
              const Icon(Icons.group_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No Groups Found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'You need to be part of a group with a video channel to upload videos.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _groups!.length,
      itemBuilder: (context, index) {
        final group = _groups![index];
        final groupChannels = _channels[group.id] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                group.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (group.status == 'PENDING_APPROVAL')
              Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.pending_actions, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This group is pending admin approval. You cannot upload videos yet.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              )
            else if (groupChannels.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text('No upload channels available in this group.'),
              ),
            if (group.status != 'PENDING_APPROVAL')
              ...groupChannels.map(
                (channel) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.video_camera_front),
                    title: Text(channel.name),
                    subtitle: Text('Type: ${channel.type}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ref
                          .read(uploadProvider.notifier)
                          .selectChannel(group, channel);
                    },
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _UploadFormWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<_UploadFormWidget> createState() => _UploadFormWidgetState();
}

class _UploadFormWidgetState extends ConsumerState<_UploadFormWidget> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _visibility = 'PUBLIC';
  String? _playlistId;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Add a video title',
                ),
                maxLength: 300,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Title is required' : null,
                onSaved: (v) => _title = v ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Add a description',
                ),
                maxLines: 4,
                maxLength: 10000,
                onSaved: (v) => _description = v ?? '',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _visibility,
                decoration: const InputDecoration(labelText: 'Visibility'),
                items: const [
                  DropdownMenuItem(value: 'PUBLIC', child: Text('Public')),
                  DropdownMenuItem(value: 'PRIVATE', child: Text('Private')),
                  DropdownMenuItem(
                    value: 'GROUP_ONLY',
                    child: Text('Group Only'),
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
                      return InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Add to Playlist (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _playlistId,
                            isExpanded: true,
                            isDense: true,
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('None'),
                              ),
                              ...playlists.map(
                                (p) => DropdownMenuItem<String?>(
                                  value: p.id,
                                  child: Text(p.title),
                                ),
                              ),
                            ],
                            onChanged: (v) => setState(() => _playlistId = v),
                          ),
                        ),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final data = UploadVideoFormData(
                      title: _title,
                      description: _description,
                      visibility: _visibility,
                      playlistId: _playlistId,
                    );
                    ref.read(uploadProvider.notifier).submitDetails(data);
                  }
                },
                child: const Text('Start Upload'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadProgressWidget extends StatelessWidget {
  final double progress;

  const _UploadProgressWidget({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload, size: 64, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              'Uploading Video...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Text('${(progress * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }
}

class _ProcessingStatusWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Processing Video...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('This may take a few minutes depending on the file size.'),
        ],
      ),
    );
  }
}

class _UploadCompletedWidget extends StatelessWidget {
  final String? videoId;

  const _UploadCompletedWidget({this.videoId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 80, color: Colors.green),
          const SizedBox(height: 24),
          Text(
            'Upload Complete!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 32),
          if (videoId != null)
            FilledButton(
              onPressed: () {
                context.pushReplacement('/video/$videoId');
              },
              child: const Text('View Video'),
            )
          else
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Close'),
            ),
        ],
      ),
    );
  }
}

class _UploadFailedWidget extends ConsumerWidget {
  final String? error;

  const _UploadFailedWidget({this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            Text(
              'Upload Failed',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              error ?? 'An unknown error occurred.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Pop back to the beginning of the flow or allow retry
                // For a proper retry, we'd need the provider to support it.
                // For now, we cancel and let them start over.
                ref.read(uploadProvider.notifier).cancelUpload();
                context.pop();
              },
              icon: const Icon(Icons.close),
              label: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
