// lib/features/live/presentation/screens/local_recordings_screen.dart
//
// Screen for browsing, playing, and managing local live-stream recordings.
//
// Recordings are audio-only (M4A/AAC) captured alongside RTMP broadcasts.
// Each card clearly states "Audio Recording" to avoid misrepresentation.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_filex/open_filex.dart';

import 'package:mobile/core/providers/database_provider.dart';
import 'package:mobile/core/database/app_database.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

/// Watches the full list of recordings from Drift, auto-refreshing on change.
final localRecordingsStreamProvider =
    StreamProvider<List<LocalLiveRecordingData>>((ref) {
  return ref.watch(liveRecordingsDaoProvider).watchAllRecordings();
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class LocalRecordingsScreen extends ConsumerStatefulWidget {
  const LocalRecordingsScreen({super.key});

  @override
  ConsumerState<LocalRecordingsScreen> createState() =>
      _LocalRecordingsScreenState();
}

class _LocalRecordingsScreenState
    extends ConsumerState<LocalRecordingsScreen> {
  AudioPlayer? _player;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;

  LocalLiveRecordingData? _activeRecording;
  bool _isPlaying = false;
  bool _isCompleted = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  bool _isScrubbing = false;
  double _scrubValue = 0.0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _posSub = _player!.positionStream.listen((pos) {
      if (mounted && !_isScrubbing) {
        setState(() => _position = pos);
      }
    });

    _durSub = _player!.durationStream.listen((dur) {
      if (dur != null && dur > Duration.zero && mounted) {
        setState(() => _duration = dur);
      }
    });

    _stateSub = _player!.playerStateStream.listen((state) {
      if (!mounted) return;
      final completed = state.processingState == ProcessingState.completed;
      setState(() {
        _isPlaying = state.playing && !completed;
        _isCompleted = completed;
      });
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  // ── Audio playback ────────────────────────────────────────────────────────

  Future<void> _togglePlayback(LocalLiveRecordingData row) async {
    final player = _player;
    if (player == null) return;

    if (_activeRecording?.id == row.id) {
      if (_isPlaying) {
        await player.pause();
      } else {
        final total = _duration > Duration.zero
            ? _duration
            : Duration(seconds: row.durationSeconds);
        if (_isCompleted || _position >= total) {
          await player.seek(Duration.zero);
        }
        await player.play();
      }
      return;
    }

    if (row.localFilePath == null) return;
    if (!kIsWeb) {
      final file = File(row.localFilePath!);
      if (!file.existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recording file not found on device.')),
          );
        }
        return;
      }
    }

    try {
      await player.stop();
      if (mounted) {
        setState(() {
          _activeRecording = row;
          _position = Duration.zero;
          _duration = Duration(seconds: row.durationSeconds);
          _isCompleted = false;
          _isScrubbing = false;
        });
      }
      await player.setFilePath(row.localFilePath!);
      await player.setSpeed(_playbackSpeed);
      await player.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playback error: $e')),
        );
      }
    }
  }

  Future<void> _skipBy(Duration offset) async {
    final player = _player;
    final rec = _activeRecording;
    if (player == null || rec == null) return;
    final total = _duration > Duration.zero
        ? _duration
        : Duration(seconds: rec.durationSeconds);
    final target = _position + offset;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > total ? total : target);
    await player.seek(clamped);
    if (_isCompleted && clamped < total) {
      await player.play();
    }
  }

  Future<void> _seekToProgress(double fraction) async {
    final player = _player;
    final rec = _activeRecording;
    if (player == null || rec == null) return;
    final total = _duration > Duration.zero
        ? _duration
        : Duration(seconds: rec.durationSeconds);
    if (total <= Duration.zero) return;
    final targetMs = (fraction * total.inMilliseconds).round();
    final clamped = Duration(
      milliseconds: targetMs.clamp(0, total.inMilliseconds),
    );
    await player.seek(clamped);
    if (_isCompleted && clamped < total) {
      await player.play();
    }
  }

  Future<void> _cycleSpeed() async {
    final speeds = [1.0, 1.25, 1.5, 2.0];
    final currentIndex = speeds.indexOf(_playbackSpeed);
    final nextSpeed = speeds[(currentIndex + 1) % speeds.length];
    await _player?.setSpeed(nextSpeed);
    if (mounted) {
      setState(() => _playbackSpeed = nextSpeed);
    }
  }

  Future<void> _stopPlayback() async {
    await _player?.stop();
    if (mounted) {
      setState(() {
        _activeRecording = null;
        _isPlaying = false;
        _isCompleted = false;
        _position = Duration.zero;
      });
    }
  }

  // ── Open with external app ────────────────────────────────────────────────

  Future<void> _openWithExternalApp(LocalLiveRecordingData row) async {
    if (row.localFilePath == null) return;
    final result = await OpenFilex.open(row.localFilePath!);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open file: ${result.message}')),
      );
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(LocalLiveRecordingData row) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recording?'),
        content: const Text(
          'This will permanently delete the audio recording file from your device. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Stop playback if this file is active.
    if (_activeRecording?.id == row.id) {
      await _player?.stop();
      if (mounted) {
        setState(() {
          _activeRecording = null;
          _isPlaying = false;
          _isCompleted = false;
          _position = Duration.zero;
        });
      }
    }

    // Delete file from disk.
    if (row.localFilePath != null && !kIsWeb) {
      try {
        final f = File(row.localFilePath!);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }

    // Remove DB row.
    await ref.read(liveRecordingsDaoProvider).deleteRecording(row.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording deleted.')),
      );
    }
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  String _formatDuration(int seconds) {
    if (seconds < 0) seconds = 0;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '--';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return DateFormat('MMM d, yyyy · HH:mm').format(local);
  }

  Widget _statusChip(String status) {
    final (label, color) = switch (status) {
      'recording'    => ('● Recording', Colors.redAccent),
      'complete'     => ('Complete', Colors.green),
      'incomplete'   => ('Incomplete', Colors.orange),
      'failed'       => ('Failed', Colors.red),
      'uploading'    => ('Uploading…', Colors.blue),
      'uploaded'     => ('Uploaded', Colors.teal),
      'uploadFailed' => ('Upload Failed', Colors.deepOrange),
      _              => (status, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRecordingCard(LocalLiveRecordingData row) {
    final isActive = _activeRecording?.id == row.id;
    final canPlay = row.localFilePath != null &&
        (kIsWeb || File(row.localFilePath!).existsSync()) &&
        (row.status == 'complete' || row.status == 'incomplete');
    final theme = Theme.of(context);

    final totalSec = _duration.inSeconds > 0
        ? _duration.inSeconds
        : row.durationSeconds;
    final curSec = _position.inSeconds.clamp(0, totalSec > 0 ? totalSec : 0);
    final sliderProgress = _isScrubbing
        ? _scrubValue
        : (totalSec > 0
            ? (_position.inMilliseconds / (totalSec * 1000)).clamp(0.0, 1.0)
            : 0.0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isActive ? 2 : 0,
      color: isActive
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.6)
              : theme.dividerColor.withValues(alpha: 0.3),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mic icon / animated indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.primary.withValues(alpha: 0.16)
                        : Colors.deepOrange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive && _isPlaying
                        ? Icons.graphic_eq_rounded
                        : Icons.mic,
                    color: isActive
                        ? theme.colorScheme.primary
                        : Colors.deepOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.streamTitle.isNotEmpty
                            ? row.streamTitle
                            : 'Live Stream Recording',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Audio Recording (microphone only)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(row.startedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _statusChip(row.status),
              ],
            ),
            const SizedBox(height: 10),
            // ── Metadata row ─────────────────────────────────────────────
            Row(
              children: [
                if (row.durationSeconds > 0) ...[
                  Icon(
                    Icons.timer_outlined,
                    size: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(row.durationSeconds),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                if (row.fileSizeBytes > 0) ...[
                  Icon(
                    Icons.storage_outlined,
                    size: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatFileSize(row.fileSizeBytes),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
            // ── Error message ─────────────────────────────────────────────
            if (row.errorMessage != null && row.errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  row.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                ),
              ),
            ],

            // ── Active playback controller (Expanded for active recording) ─────
            if (isActive && canPlay) ...[
              const SizedBox(height: 8),
              Divider(
                height: 16,
                thickness: 0.6,
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
              // Scrubber slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3.5,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 13),
                  activeTrackColor: theme.colorScheme.primary,
                  inactiveTrackColor:
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                  thumbColor: theme.colorScheme.primary,
                ),
                child: Slider(
                  value: sliderProgress,
                  onChanged: (val) {
                    setState(() {
                      _isScrubbing = true;
                      _scrubValue = val;
                    });
                  },
                  onChangeEnd: (val) {
                    setState(() => _isScrubbing = false);
                    _seekToProgress(val);
                  },
                ),
              ),
              // Elapsed & total timestamps
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(
                        _isScrubbing
                            ? ((_scrubValue * (totalSec > 0 ? totalSec : 0))).round()
                            : curSec,
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      _formatDuration(totalSec),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Full playback manager row
              Row(
                children: [
                  // Playback speed toggle
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _cycleSpeed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${_playbackSpeed == 1.0 ? '1' : _playbackSpeed}x speed',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Rewind 10s
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded, size: 22),
                    tooltip: 'Rewind 10s',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _skipBy(const Duration(seconds: -10)),
                  ),
                  const SizedBox(width: 2),
                  // Play / Pause / Replay toggle
                  IconButton.filled(
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : (_isCompleted
                              ? Icons.replay_rounded
                              : Icons.play_arrow_rounded),
                      size: 22,
                    ),
                    tooltip: _isPlaying
                        ? 'Pause'
                        : (_isCompleted ? 'Replay' : 'Play'),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(40, 40),
                    ),
                    onPressed: () => _togglePlayback(row),
                  ),
                  const SizedBox(width: 2),
                  // Forward 10s
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded, size: 22),
                    tooltip: 'Forward 10s',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _skipBy(const Duration(seconds: 10)),
                  ),
                  const Spacer(),
                  // Open external
                  IconButton.outlined(
                    tooltip: 'Open with…',
                    icon: const Icon(Icons.open_in_new, size: 16),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _openWithExternalApp(row),
                  ),
                  const SizedBox(width: 4),
                  // Delete
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _confirmDelete(row),
                  ),
                ],
              ),
            ] else ...[
              // ── Inactive compact action buttons ─────────────────────────
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canPlay)
                    IconButton.filledTonal(
                      tooltip: 'Play Audio',
                      icon: const Icon(Icons.play_arrow, size: 18),
                      onPressed: () => _togglePlayback(row),
                    ),
                  if (canPlay) ...[
                    const SizedBox(width: 4),
                    IconButton.outlined(
                      tooltip: 'Open with…',
                      icon: const Icon(Icons.open_in_new, size: 16),
                      onPressed: () => _openWithExternalApp(row),
                    ),
                  ],
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _confirmDelete(row),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Bottom Mini-Player Bar ───────────────────────────────────────────────

  Widget _buildBottomPlayerBar(BuildContext context) {
    final rec = _activeRecording;
    if (rec == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    final totalSec = _duration.inSeconds > 0
        ? _duration.inSeconds
        : rec.durationSeconds;
    final posSec = _position.inSeconds.clamp(0, totalSec > 0 ? totalSec : 0);
    final progress = totalSec > 0
        ? (_position.inMilliseconds / (totalSec * 1000)).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress track
            LinearProgressIndicator(
              value: progress,
              minHeight: 2.5,
              backgroundColor:
                  theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 8, 8),
              child: Row(
                children: [
                  // Indicator
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying
                          ? Icons.graphic_eq_rounded
                          : Icons.mic_rounded,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Title + elapsed time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          rec.streamTitle.isNotEmpty
                              ? rec.streamTitle
                              : 'Live Stream Recording',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${_formatDuration(posSec)} / ${_formatDuration(totalSec)} · ${_playbackSpeed == 1.0 ? '1' : _playbackSpeed}x',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Rewind 10s
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded, size: 20),
                    tooltip: 'Rewind 10s',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _skipBy(const Duration(seconds: -10)),
                  ),
                  // Play / Pause
                  IconButton.filled(
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : (_isCompleted
                              ? Icons.replay_rounded
                              : Icons.play_arrow_rounded),
                      size: 20,
                    ),
                    tooltip: _isPlaying
                        ? 'Pause'
                        : (_isCompleted ? 'Replay' : 'Play'),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(7),
                      minimumSize: const Size(36, 36),
                    ),
                    onPressed: () => _togglePlayback(rec),
                  ),
                  // Forward 10s
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded, size: 20),
                    tooltip: 'Forward 10s',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _skipBy(const Duration(seconds: 10)),
                  ),
                  // Speed button
                  TextButton(
                    onPressed: _cycleSpeed,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      minimumSize: const Size(30, 26),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '${_playbackSpeed == 1.0 ? '1' : _playbackSpeed}x',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  // Close / Stop button
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: 'Stop & close',
                    visualDensity: VisualDensity.compact,
                    onPressed: _stopPlayback,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final recordingsAsync = ref.watch(localRecordingsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Recordings'),
        actions: [
          IconButton(
            tooltip: 'About local recordings',
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      bottomNavigationBar: _activeRecording != null
          ? _buildBottomPlayerBar(context)
          : null,
      body: recordingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error loading recordings: $err'),
          ),
        ),
        data: (recordings) {
          if (recordings.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              0,
              8,
              0,
              _activeRecording != null ? 16 : 8,
            ),
            itemCount: recordings.length,
            itemBuilder: (_, i) => _buildRecordingCard(recordings[i]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic_none,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Local Recordings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'When you go live with "Record and Stream" enabled on mobile, '
              'an audio recording of your microphone will be saved here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInfoDialog() {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.mic, color: Colors.deepOrange),
        title: const Text('About Local Recordings'),
        content: const SingleChildScrollView(
          child: Text(
            'Local recordings are audio-only files (M4A/AAC) captured from '
            'your device microphone during a live broadcast.\n\n'
            '• Video is NOT captured locally — your video broadcast goes '
            'directly to the streaming server (Cloudinary) and is available '
            'as a VOD on the server after you end the stream.\n\n'
            '• Audio-only recording captures your microphone input in parallel '
            'with the RTMP broadcast.\n\n'
            '• Recording is not available on web browsers (the browser '
            'only allows one app to access the microphone at a time).\n\n'
            'Full audio + video local recording requires a future native '
            'plugin update.',
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
