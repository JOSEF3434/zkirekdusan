import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mobile/core/services/media_cache_service.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';

class VoiceMessagePlayer extends ConsumerStatefulWidget {
  final MessageVoiceNoteModel voiceNote;
  final bool isMe;

  const VoiceMessagePlayer({
    super.key,
    required this.voiceNote,
    required this.isMe,
  });

  @override
  ConsumerState<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoicePlaybackRegistration {
  final String id;
  final Future<void> Function() play;
  final Future<void> Function() pause;

  const _VoicePlaybackRegistration({
    required this.id,
    required this.play,
    required this.pause,
  });
}

class _VoicePlaybackCoordinator {
  static final List<_VoicePlaybackRegistration> _players = [];
  static String? _activeId;

  static void register(_VoicePlaybackRegistration registration) {
    _players.removeWhere((player) => player.id == registration.id);
    _players.add(registration);
  }

  static void unregister(String id) {
    _players.removeWhere((player) => player.id == id);
    if (_activeId == id) _activeId = null;
  }

  static Future<void> play(_VoicePlaybackRegistration registration) async {
    final active = _players
        .where((player) => player.id == _activeId)
        .firstOrNull;
    if (active != null && active.id != registration.id) {
      await active.pause();
    }
    _activeId = registration.id;
    await registration.play();
  }

  static Future<void> pause(String id) async {
    final player = _players.where((player) => player.id == id).firstOrNull;
    if (player != null) await player.pause();
    if (_activeId == id) _activeId = null;
  }

  static Future<void> playNext(String id) async {
    final index = _players.indexWhere((player) => player.id == id);
    if (index == -1) return;
    final next = index + 1 < _players.length ? _players[index + 1] : null;
    _activeId = null;
    if (next != null) await play(next);
  }
}

class _VoiceMessagePlayerState extends ConsumerState<VoiceMessagePlayer> {
  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  bool _isFinishing = false;
  double _playbackSpeed = 1.0;

  // Waveform bars
  late final List<double> _waveformBars;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _waveformBars = widget.voiceNote.waveform?.isNotEmpty == true
        ? widget.voiceNote.waveform!
        : _generateWaveform(widget.voiceNote.url.hashCode);

    if (widget.voiceNote.duration > 0) {
      _duration = Duration(seconds: widget.voiceNote.duration);
    }
    _registerForPlayback();
    _initAudioPlayer();
  }

  void _registerForPlayback() {
    _VoicePlaybackCoordinator.register(
      _VoicePlaybackRegistration(
        id: widget.voiceNote.fileId,
        play: () => _audioPlayer.play(),
        pause: () => _audioPlayer.pause(),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant VoiceMessagePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.voiceNote.duration > 0 &&
        widget.voiceNote.duration != oldWidget.voiceNote.duration) {
      setState(() {
        _duration = Duration(seconds: widget.voiceNote.duration);
      });
    }
    if (widget.voiceNote.url != oldWidget.voiceNote.url &&
        widget.voiceNote.url.isNotEmpty) {
      _VoicePlaybackCoordinator.unregister(oldWidget.voiceNote.fileId);
      _registerForPlayback();
      _initAudioPlayer();
    }
  }

  List<double> _generateWaveform(int seed) {
    final bars = <double>[];
    for (int i = 0; i < 30; i++) {
      final val = (((seed + i * 37) % 70) + 20) / 100.0;
      bars.add(val.clamp(0.2, 1.0));
    }
    return bars;
  }

  Future<void> _initAudioPlayer() async {
    final rawUrl = widget.voiceNote.url.trim();
    if (rawUrl.isEmpty) return;

    try {
      setState(() => _isLoading = true);
      final resolvedUrl = MediaUrlResolver.resolve(rawUrl) ?? rawUrl;

      // 1. Check local persistent disk cache first (offline-first & instant)
      final cachedFile = await ChatMediaCacheService.getLocalCachedFile(
        resolvedUrl,
      );
      if (cachedFile != null && await cachedFile.exists()) {
        await _audioPlayer.setFilePath(cachedFile.path);
      } else if (resolvedUrl.startsWith('file://')) {
        await _audioPlayer.setFilePath(resolvedUrl.replaceFirst('file://', ''));
      } else if (!kIsWeb && File(resolvedUrl).existsSync()) {
        await _audioPlayer.setFilePath(resolvedUrl);
      } else {
        // Stream from URL and download once in background into disk cache
        await _audioPlayer.setUrl(resolvedUrl);
        // Persist to local disk for subsequent plays & offline access
        ChatMediaCacheService.getOrDownloadMedia(resolvedUrl);
      }

      if (_audioPlayer.duration != null &&
          _audioPlayer.duration! > Duration.zero) {
        _duration = _audioPlayer.duration!;
      } else if (widget.voiceNote.duration > 0) {
        _duration = Duration(seconds: widget.voiceNote.duration);
      }

      _audioPlayer.durationStream.listen((d) {
        if (d != null && d > Duration.zero && mounted) {
          setState(() => _duration = d);
        }
      });

      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }

        if (state.processingState == ProcessingState.completed) {
          _finishAndAdvance();
        }
      });

      _audioPlayer.positionStream.listen((pos) {
        if (mounted) {
          setState(() => _position = pos);
        }
      });

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _finishAndAdvance() async {
    if (_isFinishing) return;
    _isFinishing = true;

    // Stop before seeking. Seeking a still-playing player can leave just_audio
    // reporting `playing: true`, which keeps the finished bubble's pause icon.
    try {
      await _audioPlayer.pause();
      await _audioPlayer.seek(Duration.zero);
    } catch (_) {}

    if (!mounted) {
      _isFinishing = false;
      return;
    }
    setState(() {
      _isPlaying = false;
      _position = Duration.zero;
    });
    await _VoicePlaybackCoordinator.playNext(widget.voiceNote.fileId);
    _isFinishing = false;
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _VoicePlaybackCoordinator.pause(widget.voiceNote.fileId);
    } else {
      if (_position >= _duration && _duration > Duration.zero) {
        await _audioPlayer.seek(Duration.zero);
      }
      await _VoicePlaybackCoordinator.play(
        _VoicePlaybackRegistration(
          id: widget.voiceNote.fileId,
          play: () => _audioPlayer.play(),
          pause: () => _audioPlayer.pause(),
        ),
      );
    }
  }

  void _cyclePlaybackSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
    });
    _audioPlayer.setSpeed(_playbackSpeed);
  }

  @override
  void dispose() {
    _VoicePlaybackCoordinator.unregister(widget.voiceNote.fileId);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 310),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Play / Pause Button on the LEFT ──────────────────────────────
          GestureDetector(
            onTap: _isLoading ? null : _togglePlayPause,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isMe
                    ? const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: (isMe ? Colors.black : const Color(0xFF00C6FF))
                        .withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 10),

          // ── Waveform & Info on the RIGHT ─────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Interactive Waveform
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box != null && _duration.inMilliseconds > 0) {
                      final localPos = details.localPosition.dx;
                      final totalWidth = box.size.width - 65;
                      final ratio =
                          (localPos / (totalWidth > 0 ? totalWidth : 140))
                              .clamp(0.0, 1.0);
                      _audioPlayer.seek(
                        Duration(
                          milliseconds: (ratio * _duration.inMilliseconds)
                              .toInt(),
                        ),
                      );
                    }
                  },
                  child: SizedBox(
                    height: 26,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(
                        _waveformBars.length.clamp(0, 30),
                        (index) {
                          final barProgress = index / 30.0;
                          final isActive = barProgress <= progress;
                          final amplitude =
                              _waveformBars[index % _waveformBars.length];

                          return Container(
                            width: 2.6,
                            height: (amplitude * 24).clamp(4.0, 24.0),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? (isMe
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFF00C6FF))
                                  : (isMe
                                        ? Colors.black.withValues(alpha: 0.25)
                                        : Colors.white.withValues(alpha: 0.28)),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Duration & Speed
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isPlaying
                          ? '${_formatDuration(_position)} / ${_formatDuration(_duration)}'
                          : _formatDuration(_duration),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isMe
                            ? Colors.black.withValues(alpha: 0.75)
                            : Colors.grey[300],
                      ),
                    ),
                    // Playback speed toggle
                    GestureDetector(
                      onTap: _cyclePlaybackSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: (isMe ? Colors.black : Colors.white)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _playbackSpeed == 1.0
                              ? '1x'
                              : _playbackSpeed == 1.5
                              ? '1.5x'
                              : '2x',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isMe ? Colors.black87 : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
