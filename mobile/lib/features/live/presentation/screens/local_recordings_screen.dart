// lib/features/live/presentation/screens/local_recordings_screen.dart
//
// Screen for browsing, playing, and managing local live-stream recordings.
//
// Recordings are audio-only (M4A/AAC) captured alongside RTMP broadcasts.
// Each card clearly states "Audio Recording" to avoid misrepresentation.

import 'dart:io';

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
  String? _playingId;
  bool _isPlaying = false;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  // ── Audio playback ────────────────────────────────────────────────────────

  Future<void> _togglePlayback(LocalLiveRecordingData row) async {
    if (_playingId == row.id && _isPlaying) {
      await _player?.pause();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    // Stop any currently playing file first.
    if (_player != null) {
      await _player!.stop();
      _player!.dispose();
      _player = null;
    }

    if (row.localFilePath == null) return;
    final file = File(row.localFilePath!);
    if (!file.existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording file not found on device.')),
        );
      }
      return;
    }

    final player = AudioPlayer();
    try {
      await player.setFilePath(row.localFilePath!);
      player.playerStateStream.listen((s) {
        if (s.processingState == ProcessingState.completed && mounted) {
          setState(() {
            _isPlaying = false;
            _playingId = null;
          });
        }
      });
      await player.play();
      if (mounted) {
        setState(() {
          _player = player;
          _playingId = row.id;
          _isPlaying = true;
        });
      }
    } catch (e) {
      player.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playback error: $e')),
        );
      }
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

    // Stop playback if this file is playing.
    if (_playingId == row.id) {
      await _player?.stop();
      _player?.dispose();
      _player = null;
      setState(() {
        _playingId = null;
        _isPlaying = false;
      });
    }

    // Delete file from disk.
    if (row.localFilePath != null) {
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
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
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
      'recording'   => ('● Recording', Colors.redAccent),
      'complete'    => ('Complete', Colors.green),
      'incomplete'  => ('Incomplete', Colors.orange),
      'failed'      => ('Failed', Colors.red),
      'uploading'   => ('Uploading…', Colors.blue),
      'uploaded'    => ('Uploaded', Colors.teal),
      'uploadFailed'=> ('Upload Failed', Colors.deepOrange),
      _             => (status, Colors.grey),
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
    final isThisPlaying = _playingId == row.id && _isPlaying;
    final canPlay = row.localFilePath != null &&
        File(row.localFilePath!).existsSync() &&
        (row.status == 'complete' || row.status == 'incomplete');
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.3),
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
                // Mic icon — audio-only indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Colors.deepOrange,
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
                      // Clearly labeled "Audio Recording" — not "Full Recording"
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
            const SizedBox(height: 12),
            // ── Metadata row ─────────────────────────────────────────────
            Row(
              children: [
                if (row.durationSeconds > 0) ...[
                  Icon(Icons.timer_outlined,
                      size: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
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
                  Icon(Icons.storage_outlined,
                      size: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
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
            const SizedBox(height: 12),
            // ── Action buttons ────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canPlay)
                  IconButton.filledTonal(
                    tooltip: isThisPlaying ? 'Pause' : 'Play Audio',
                    icon: Icon(
                      isThisPlaying ? Icons.pause : Icons.play_arrow,
                      size: 18,
                    ),
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
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(row),
                ),
              ],
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
            padding: const EdgeInsets.symmetric(vertical: 8),
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
