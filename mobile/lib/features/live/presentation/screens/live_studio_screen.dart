// lib/features/live/presentation/screens/live_studio_screen.dart
// Broadcaster dashboard: setup, stream key, go-live, health monitoring, end stream.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/live/data/live_streaming_repository.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';
import 'package:mobile/features/live/domain/stream_health_model.dart';
import 'package:mobile/features/live/presentation/providers/broadcaster_provider.dart';
import 'package:mobile/features/live/presentation/widgets/live_badge_widget.dart';
import 'package:mobile/app/env/env.dart';
import 'package:mobile/features/live/presentation/widgets/stream_health_indicator.dart';
import 'package:mobile/features/live/presentation/widgets/viewer_count_widget.dart';
import 'package:mobile/features/live/presentation/widgets/live_chat_widget.dart';
import 'package:mobile/features/upload/data/upload_repository.dart';
import 'package:mobile/features/upload/domain/group_channel_model.dart';

class LiveStudioScreen extends ConsumerStatefulWidget {
  /// Optional pre-selected channelId. If null, the user picks from a dropdown.
  final String? channelId;

  const LiveStudioScreen({super.key, this.channelId});

  @override
  ConsumerState<LiveStudioScreen> createState() => _LiveStudioScreenState();
}

class _LiveStudioScreenState extends ConsumerState<LiveStudioScreen> {
  // Setup form controllers (shown before stream exists)
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isChatEnabled = true;
  bool _isRecordingEnabled = true;
  bool _isVideoStream = true;
  bool _isMicMuted = false;
  bool _isFrontCamera = true;
  bool _isCreating = false;
  String? _createError;
  bool _keyVisible = false;

  // Camera & Streaming hardware state
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = true;
  bool _isTorchOn = false;
  bool _isInitializingCamera = false;

  // Group / Channel picker state
  List<GroupDto> _groups = [];
  final Map<String, List<VideoChannelDto>> _channelsByGroup = {};
  GroupDto? _selectedGroup;
  VideoChannelDto? _selectedChannel;
  bool _loadingChannels = false;
  String? _loadError;

  // Set after stream is created
  String? _streamId;

  @override
  void initState() {
    super.initState();
    if (widget.channelId == null) {
      _loadGroups();
    }
    _setupCamera(front: true);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _loadingChannels = true;
      _loadError = null;
    });
    try {
      final repo = ref.read(uploadRepositoryProvider);
      final groups = await repo.getMyGroups();
      final activeGroups = groups
          .where((g) => g.status == 'ACTIVE')
          .toList();
      setState(() {
        _groups = activeGroups;
        _loadingChannels = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Could not load your groups. Please check your connection.';
        _loadingChannels = false;
      });
    }
  }

  Future<void> _loadChannelsForGroup(GroupDto group) async {
    if (_channelsByGroup.containsKey(group.id)) {
      setState(() {
        _selectedGroup = group;
        _selectedChannel = _channelsByGroup[group.id]!.isNotEmpty
            ? _channelsByGroup[group.id]!.first
            : null;
      });
      return;
    }
    setState(() {
      _loadingChannels = true;
      _selectedGroup = group;
      _selectedChannel = null;
    });
    try {
      final repo = ref.read(uploadRepositoryProvider);
      final channels = await repo.getGroupChannels(group.id);
      setState(() {
        _channelsByGroup[group.id] = channels;
        _selectedChannel = channels.isNotEmpty ? channels.first : null;
        _loadingChannels = false;
      });
    } catch (e) {
      setState(() {
        _loadingChannels = false;
      });
    }
  }

  String get _effectiveChannelId =>
      widget.channelId ?? _selectedChannel?.id ?? '';

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_streamId == null) {
      return _buildSetupPage(context);
    }
    return _buildStudioPage(context, _streamId!);
  }

  // ─── Setup page (create stream) ────────────────────────────────────────────

  Widget _buildSetupPage(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Stream'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stream Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // ── Group / Channel Picker (only if no channelId pre-supplied) ──
            if (widget.channelId == null) ...[
              _buildGroupChannelPicker(theme),
              const SizedBox(height: 16),
            ],

            // Title
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'Give your stream a title',
                border: OutlineInputBorder(),
              ),
              maxLength: 300,
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Tell viewers what your stream is about',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            // Stream Type Selector (Video with Camera vs Audio-Only)
            const Text(
              'Stream Mode',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  icon: Icon(Icons.videocam_outlined),
                  label: Text('Video Stream'),
                ),
                ButtonSegment<bool>(
                  value: false,
                  icon: Icon(Icons.mic_outlined),
                  label: Text('Audio-Only'),
                ),
              ],
              selected: {_isVideoStream},
              onSelectionChanged: (set) {
                setState(() => _isVideoStream = set.first);
              },
            ),
            const SizedBox(height: 16),

            // Options
            SwitchListTile(
              title: const Text('Enable Chat'),
              subtitle: const Text('Allow viewers to send messages'),
              value: _isChatEnabled,
              onChanged: (v) => setState(() => _isChatEnabled = v),
            ),
            SwitchListTile(
              title: const Text('Enable Recording'),
              subtitle: const Text('Save stream as VOD after ending'),
              value: _isRecordingEnabled,
              onChanged: (v) => setState(() => _isRecordingEnabled = v),
            ),

            const SizedBox(height: 8),

            if (_createError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _createError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Create button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isCreating || _loadingChannels ? null : _createStream,
                icon: _isCreating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.live_tv),
                label: const Text('Create Stream'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupChannelPicker(ThemeData theme) {
    if (_loadingChannels && _groups.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_loadError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_loadError!, style: const TextStyle(color: Colors.red)),
            ),
            TextButton(onPressed: _loadGroups, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_groups.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: const Text(
          'You have no active groups with video channels. '
          'Create or join a group to start streaming.',
          style: TextStyle(color: Colors.orange),
        ),
      );
    }

    final List<VideoChannelDto> channelsForGroup =
        _selectedGroup != null ? (_channelsByGroup[_selectedGroup!.id] ?? <VideoChannelDto>[]) : <VideoChannelDto>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group Dropdown
        DropdownButtonFormField<GroupDto>(
          isExpanded: true,
          initialValue: _selectedGroup,
          decoration: const InputDecoration(
            labelText: 'Group *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.group),
          ),
          hint: const Text('Select a group'),
          items: _groups
              .map((g) => DropdownMenuItem(
                    value: g,
                    child: Text(g.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (group) {
            if (group != null) _loadChannelsForGroup(group);
          },
        ),
        const SizedBox(height: 12),

        // Channel Dropdown (shown once a group is selected)
        if (_selectedGroup != null)
          _loadingChannels
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(),
                  ),
                )
              : channelsForGroup.isEmpty
              ? const Text(
                  'This group has no video channels.',
                  style: TextStyle(color: Colors.orange),
                )
              : DropdownButtonFormField<VideoChannelDto>(
                  isExpanded: true,
                  initialValue: _selectedChannel,
                  decoration: const InputDecoration(
                    labelText: 'Channel *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.live_tv),
                  ),
                  hint: const Text('Select a channel'),
                  items: channelsForGroup
                      .map((c) => DropdownMenuItem<VideoChannelDto>(
                            value: c,
                            child: Text(c.name, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (ch) {
                    if (ch != null) setState(() => _selectedChannel = ch);
                  },
                ),
      ],
    );
  }

  Future<void> _createStream() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _createError = 'Title is required.');
      return;
    }

    // Validate channel selected
    if (_effectiveChannelId.isEmpty) {
      setState(() => _createError =
          'Please select a group and channel to stream to.');
      return;
    }

    setState(() {
      _isCreating = true;
      _createError = null;
    });

    try {
      final repo = ref.read(liveStreamingRepositoryProvider);
      final stream = await repo.createStream(
        _effectiveChannelId,
        CreateLiveStreamRequest(
          title: title,
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          isChatEnabled: _isChatEnabled,
          isRecordingEnabled: _isRecordingEnabled,
        ),
      );
      setState(() {
        _streamId = stream.id;
        _isCreating = false;
      });
    } catch (e) {
      String msg;
      if (e is AppException) {
        msg = e.message.isNotEmpty ? e.message : 'Failed to create stream.';
      } else {
        msg = e.toString().replaceFirst('Exception: ', '');
      }
      setState(() {
        _createError = msg;
        _isCreating = false;
      });
    }
  }

  // ─── Studio page (after stream created) ───────────────────────────────────

  Widget _buildStudioPage(BuildContext context, String streamId) {
    final bState = ref.watch(broadcasterProvider((streamId, _effectiveChannelId)));
    final theme = Theme.of(context);
    final stream = bState.stream;

    return Scaffold(
      appBar: AppBar(
        title: stream?.status == LiveStreamStatus.live
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LiveBadgeWidget(small: true),
                  const SizedBox(width: 8),
                  Text(_formatElapsed(bState.elapsed)),
                ],
              )
            : const Text('Live Studio'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmLeave(context, bState.stream),
        ),
        actions: [
          // Stream health
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: StreamHealthIndicator(health: bState.health, compact: true),
          ),
          // Viewer count
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: ViewerCountWidget(count: bState.viewerCount)),
          ),
        ],
      ),
      body: stream == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── YouTube Studio Live Monitor Banner / Camera Preview ──
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 180,
                  child: MediaQuery.of(context).viewInsets.bottom > 0
                      ? const SizedBox.shrink()
                      : _buildLiveMonitor(theme, stream, bState),
                ),

                Expanded(
                  child: stream.status == LiveStreamStatus.live && stream.isChatEnabled
                      ? Column(
                          children: [
                            // Collapsible stats summary when live
                            _buildLiveStatsRow(theme, stream, bState),
                            const Divider(height: 1),
                            // Live Chat takes full flexible space when live
                            Expanded(
                              child: LiveChatWidget(
                                streamId: streamId,
                                isModerator: true,
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status banner
                              _StatusBanner(status: stream.status),
                              const SizedBox(height: 16),

                              // RTMP key card
                              _StreamKeyCard(
                                streamKey: bState.streamKey,
                                isLoading: bState.isLoadingKey,
                                keyVisible: _keyVisible,
                                onToggleVisible: () =>
                                    setState(() => _keyVisible = !_keyVisible),
                                onRegenerate: () => ref
                                    .read(
                                      broadcasterProvider((
                                        streamId,
                                        _effectiveChannelId,
                                      )).notifier,
                                    )
                                    .regenerateStreamKey(),
                              ),
                              const SizedBox(height: 16),

                              // Recording & Live Settings Card
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Recording & Archive Settings',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text('Record Stream'),
                                        subtitle: const Text(
                                          'Save stream into group recordings for VOD',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        value: stream.isRecordingEnabled,
                                        onChanged: stream.status == LiveStreamStatus.live
                                            ? null
                                            : (v) {
                                                ref
                                                    .read(liveStreamingRepositoryProvider)
                                                    .updateStream(stream.id, {
                                                      'isRecordingEnabled': v,
                                                    })
                                                    .then((updated) {
                                                      ref
                                                          .read(
                                                            broadcasterProvider((
                                                              streamId,
                                                              _effectiveChannelId,
                                                            )).notifier,
                                                          )
                                                          .goLive();
                                                    })
                                                    .catchError((_) {});
                                              },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Health details (if available)
                              if (bState.health != null) ...[
                                StreamHealthIndicator(health: bState.health),
                                const SizedBox(height: 16),
                              ],

                              // Stream info
                              Text(
                                stream.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              if (stream.description != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  stream.description!,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),

                              // Error
                              if (bState.error != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    bState.error!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),

                // Action bar (hidden when keyboard is open to avoid taking vertical room)
                if (MediaQuery.of(context).viewInsets.bottom == 0)
                  _ActionBar(
                    status: stream.status,
                    isGoingLive: bState.isGoingLive,
                    isEndingStream: bState.isEndingStream,
                    onGoLive: () => ref
                        .read(
                          broadcasterProvider((
                            streamId,
                            _effectiveChannelId,
                          )).notifier,
                        )
                        .goLive(),
                    onEndStream: () => _confirmEndStream(context, streamId, bState),
                    onPublishVod: () => ref
                        .read(
                          broadcasterProvider((
                            streamId,
                            _effectiveChannelId,
                          )).notifier,
                        )
                        .publishVod(),
                  ),
              ],
            ),
    );
  }

  Widget _buildLiveStatsRow(
    ThemeData theme,
    LiveStreamDto stream,
    BroadcasterState bState,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline, size: 16),
          const SizedBox(width: 6),
          const Text(
            'Live Chat & Interactions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const Spacer(),
          const Icon(Icons.people_outline, size: 16),
          const SizedBox(width: 4),
          Text(
            '${bState.viewerCount} watching',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.15),
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 32),
            ),
            icon: const Icon(Icons.stop_circle, size: 16),
            label: const Text('End', style: TextStyle(fontSize: 12)),
            onPressed: () => _confirmEndStream(context, stream.id, bState),
          ),
        ],
      ),
    );
  }

  Future<void> _setupCamera({bool? front}) async {
    if (_isInitializingCamera) return;
    setState(() => _isInitializingCamera = true);

    try {
      final camStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      if (!camStatus.isGranted || !micStatus.isGranted) {
        if (mounted) {
          setState(() {
            _isCameraPermissionGranted = false;
            _isCameraInitialized = false;
            _isInitializingCamera = false;
          });
        }
        return;
      }

      final isFront = front ?? _isFrontCamera;
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isCameraInitialized = false;
            _isInitializingCamera = false;
          });
        }
        return;
      }

      final selectedCam = _availableCameras.firstWhere(
        (c) =>
            c.lensDirection ==
            (isFront ? CameraLensDirection.front : CameraLensDirection.back),
        orElse: () => _availableCameras.first,
      );

      final oldController = _cameraController;
      _cameraController = null;
      await oldController?.dispose();

      final controller = CameraController(
        selectedCam,
        ResolutionPreset.high,
        enableAudio: !_isMicMuted,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraInitialized = true;
        _isCameraPermissionGranted = true;
        _isFrontCamera =
            selectedCam.lensDirection == CameraLensDirection.front;
        _isInitializingCamera = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _isInitializingCamera = false;
        });
      }
    }
  }

  Future<void> _flipCamera() async {
    HapticFeedback.lightImpact();
    final nextIsFront = !_isFrontCamera;
    setState(() => _isFrontCamera = nextIsFront);
    await _setupCamera(front: nextIsFront);
  }

  Future<void> _toggleTorch() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    HapticFeedback.lightImpact();
    try {
      final nextMode = _isTorchOn ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(nextMode);
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (_) {}
  }

  Widget _buildLiveMonitor(
    ThemeData theme,
    LiveStreamDto stream,
    BroadcasterState bState,
  ) {
    final isLive = stream.status == LiveStreamStatus.live;

    return Container(
      width: double.infinity,
      height: 220,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Video Preview or Audio Waveform ──
          if (_isVideoStream)
            if (_isCameraInitialized &&
                _cameraController != null &&
                _cameraController!.value.isInitialized)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _cameraController!.value.previewSize?.height ?? 1920,
                    height: _cameraController!.value.previewSize?.width ?? 1080,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              )
            else if (!_isCameraPermissionGranted)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off, size: 36, color: Colors.white54),
                      const SizedBox(height: 8),
                      const Text(
                        'Camera Permission Required',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FilledButton.tonal(
                        onPressed: () => _setupCamera(),
                        child: const Text('Grant Camera Access', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.redAccent,
                      strokeWidth: 2.5,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isInitializingCamera ? 'Starting Camera...' : 'Camera Standby',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              )
          else
            // Audio Stream Mode Visualizer
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isMicMuted ? Icons.mic_off : Icons.graphic_eq,
                      size: 48,
                      color: _isMicMuted ? Colors.redAccent : Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isMicMuted ? 'MICROPHONE MUTED' : 'LIVE AUDIO BROADCAST',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isMicMuted ? 'Tap mic to unmute' : 'High Quality Audio • 128kbps AAC',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),

          // Gradient overlay for contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Live duration badge (top-left)
          Positioned(
            top: 10,
            left: 10,
            child: isLive
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                        const SizedBox(width: 5),
                        Text(
                          'LIVE ${_formatElapsed(bState.elapsed)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'STANDBY',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),

          // Top-right health & viewers badge
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (bState.health != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: bState.health!.health == StreamHealthLevel.good
                              ? Colors.greenAccent
                              : (bState.health!.health == StreamHealthLevel.fair
                                  ? Colors.amberAccent
                                  : Colors.redAccent),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          bState.health!.health.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility, color: Colors.white, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${bState.viewerCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Controls Toolbar (bottom overlay)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                // REC / Mode indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isLive ? Colors.red.withValues(alpha: 0.85) : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fiber_manual_record,
                        color: isLive ? Colors.white : Colors.white70,
                        size: 9,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isVideoStream ? '720p HD' : 'AUDIO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Toggle Video/Audio Mode
                IconButton.filledTonal(
                  icon: Icon(
                    _isVideoStream ? Icons.videocam : Icons.mic,
                    size: 17,
                    color: Colors.white,
                  ),
                  tooltip: _isVideoStream ? 'Switch to Audio Mode' : 'Switch to Camera Video',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  onPressed: () {
                    setState(() => _isVideoStream = !_isVideoStream);
                    if (_isVideoStream && !_isCameraInitialized) {
                      _setupCamera();
                    }
                  },
                ),
                const SizedBox(width: 6),
                // Flip Camera (only in video mode)
                if (_isVideoStream) ...[
                  IconButton.filledTonal(
                    icon: const Icon(Icons.cameraswitch, size: 17, color: Colors.white),
                    tooltip: 'Flip Camera',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    onPressed: _flipCamera,
                  ),
                  const SizedBox(width: 6),
                  // Flash/Torch button
                  IconButton.filledTonal(
                    icon: Icon(
                      _isTorchOn ? Icons.flash_on : Icons.flash_off,
                      size: 17,
                      color: _isTorchOn ? Colors.amberAccent : Colors.white,
                    ),
                    tooltip: 'Toggle Flashlight',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          _isTorchOn ? Colors.amber.withValues(alpha: 0.3) : Colors.black54,
                    ),
                    onPressed: _toggleTorch,
                  ),
                  const SizedBox(width: 6),
                ],
                // Mute/Unmute Mic Button
                IconButton.filledTonal(
                  icon: Icon(
                    _isMicMuted ? Icons.mic_off : Icons.mic,
                    size: 17,
                    color: _isMicMuted ? Colors.redAccent : Colors.white,
                  ),
                  tooltip: _isMicMuted ? 'Unmute Mic' : 'Mute Mic',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        _isMicMuted ? Colors.red.withValues(alpha: 0.35) : Colors.black54,
                  ),
                  onPressed: () {
                    setState(() => _isMicMuted = !_isMicMuted);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmEndStream(
    BuildContext context,
    String streamId,
    BroadcasterState bState,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End Live Broadcast?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your live stream will end for all viewers.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('Duration: ${_formatElapsed(bState.elapsed)}'),
                  const Spacer(),
                  const Icon(Icons.people_outline, size: 18),
                  const SizedBox(width: 4),
                  Text('Peak: ${bState.viewerCount}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Stream'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref
          .read(broadcasterProvider((streamId, _effectiveChannelId)).notifier)
          .endStream();

      if (mounted) {
        _showPostStreamSummaryDialog(this.context, streamId, bState);
      }
    }
  }

  Future<void> _showPostStreamSummaryDialog(
    BuildContext context,
    String streamId,
    BroadcasterState bState,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Broadcast Finished'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your stream recording is saved in group channel streams.'),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 6),
                Text('Total Duration: ${_formatElapsed(bState.elapsed)}'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.visibility, size: 16),
                const SizedBox(width: 6),
                Text('Viewers: ${bState.viewerCount}'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Close Studio'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(
                      broadcasterProvider((
                        streamId,
                        _effectiveChannelId,
                      )).notifier,
                    )
                    .publishVod();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stream published as Channel Video!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Publish VOD failed: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.video_library),
            label: const Text('Post as Video (VOD)'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave(
    BuildContext context,
    LiveStreamDto? stream,
  ) async {
    if (stream?.status == LiveStreamStatus.live) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Leave Studio?'),
          content: const Text(
            'Your stream is still live. '
            'It will continue running in the background.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      if (confirm == true && mounted) {
        // ignore: use_build_context_synchronously
        context.pop();
      }
    } else {
      context.pop();
    }
  }
}

// ─── Status banner ─────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final LiveStreamStatus status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (status) {
      LiveStreamStatus.draft => (
        Colors.grey,
        'Draft — Not live yet',
        Icons.edit_outlined,
      ),
      LiveStreamStatus.scheduled => (Colors.blue, 'Scheduled', Icons.schedule),
      LiveStreamStatus.live => (Colors.red, 'LIVE', Icons.live_tv),
      LiveStreamStatus.ended => (Colors.orange, 'Stream Ended', Icons.stop),
      LiveStreamStatus.processing => (
        Colors.purple,
        'Processing Recording...',
        Icons.autorenew,
      ),
      LiveStreamStatus.vodReady => (
        Colors.green,
        'VOD Ready',
        Icons.video_library,
      ),
      LiveStreamStatus.cancelled => (Colors.grey, 'Cancelled', Icons.cancel),
      LiveStreamStatus.failed => (Colors.red, 'Failed', Icons.error),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Stream key card ───────────────────────────────────────────────────────

class _StreamKeyCard extends StatelessWidget {
  final dynamic streamKey;
  final bool isLoading;
  final bool keyVisible;
  final VoidCallback onToggleVisible;
  final VoidCallback onRegenerate;

  const _StreamKeyCard({
    required this.streamKey,
    required this.isLoading,
    required this.keyVisible,
    required this.onToggleVisible,
    required this.onRegenerate,
  });

  String _resolveRtmpUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) {
      final baseUri = Uri.tryParse(Env.apiBaseUrl);
      final host = baseUri?.host.isNotEmpty == true ? baseUri!.host : 'localhost';
      return 'rtmp://$host:1935/live';
    }
    if (rawUrl.contains('localhost') || rawUrl.contains('127.0.0.1')) {
      final baseUri = Uri.tryParse(Env.apiBaseUrl);
      if (baseUri != null && baseUri.host.isNotEmpty && baseUri.host != 'localhost' && baseUri.host != '127.0.0.1') {
        return rawUrl.replaceAll('localhost', baseUri.host).replaceAll('127.0.0.1', baseUri.host);
      }
    }
    return rawUrl;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sk = streamKey;
    final rtmpDisplayUrl = _resolveRtmpUrl(sk?.rtmpUrl);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RTMP Stream Setup',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 12),

            const Text(
              'Server URL',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    rtmpDisplayUrl,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy server URL',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: rtmpDisplayUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Server URL copied')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            const Text(
              'Stream Key',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            isLoading
                ? const LinearProgressIndicator()
                : sk == null
                ? const Text(
                    'No key available',
                    style: TextStyle(color: Colors.grey),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          keyVisible
                              ? (sk.rawKey ?? sk.keyPrefix ?? '****')
                              : '••••••••••••••••',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          keyVisible ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        onPressed: onToggleVisible,
                      ),
                      if (sk.rawKey != null)
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: sk.rawKey!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Stream key copied'),
                              ),
                            );
                          },
                        ),
                    ],
                  ),

            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: isLoading ? null : onRegenerate,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(
                'Regenerate Key',
                style: TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action bar ────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final LiveStreamStatus status;
  final bool isGoingLive;
  final bool isEndingStream;
  final VoidCallback onGoLive;
  final VoidCallback onEndStream;
  final VoidCallback onPublishVod;

  const _ActionBar({
    required this.status,
    required this.isGoingLive,
    required this.isEndingStream,
    required this.onGoLive,
    required this.onEndStream,
    required this.onPublishVod,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: switch (status) {
        LiveStreamStatus.draft || LiveStreamStatus.scheduled => SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isGoingLive ? null : onGoLive,
            icon: isGoingLive
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.live_tv),
            label: const Text('Go Live'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        LiveStreamStatus.live => SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isEndingStream ? null : onEndStream,
            icon: isEndingStream
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.stop_circle_outlined),
            label: const Text('End Stream'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        LiveStreamStatus.ended || LiveStreamStatus.processing => Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Column(
            children: [
              if (status == LiveStreamStatus.processing)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Processing recording…'),
                  ],
                )
              else
                FilledButton.icon(
                  onPressed: onPublishVod,
                  icon: const Icon(Icons.video_library),
                  label: const Text('Publish VOD'),
                ),
            ],
          ),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
