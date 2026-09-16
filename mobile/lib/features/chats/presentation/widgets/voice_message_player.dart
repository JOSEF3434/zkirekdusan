// lib/features/chats/presentation/widgets/voice_message_player.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
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

class _VoiceMessagePlayerState extends ConsumerState<VoiceMessagePlayer> {
  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;

  // Default simulated waveform if backend didn't provide array
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
    _initAudioPlayer();
  }

  List<double> _generateWaveform(int seed) {
    final bars = <double>[];
    for (int i = 0; i < 32; i++) {
      final val = (((seed + i * 37) % 70) + 20) / 100.0;
      bars.add(val.clamp(0.2, 1.0));
    }
    return bars;
  }

  Future<void> _initAudioPlayer() async {
    try {
      setState(() => _isLoading = true);
      final rawUrl = widget.voiceNote.url;
      final resolvedUrl = MediaUrlResolver.resolve(rawUrl) ?? rawUrl;

      if (resolvedUrl.startsWith('http://') || resolvedUrl.startsWith('https://')) {
        await _audioPlayer.setUrl(resolvedUrl);
      } else if (resolvedUrl.startsWith('file://')) {
        await _audioPlayer.setFilePath(resolvedUrl.replaceFirst('file://', ''));
      } else {
        final localFile = File(resolvedUrl);
        if (await localFile.exists()) {
          await _audioPlayer.setFilePath(resolvedUrl);
        } else {
          await _audioPlayer.setUrl(resolvedUrl);
        }
      }

      if (_audioPlayer.duration != null && _audioPlayer.duration! > Duration.zero) {
        _duration = _audioPlayer.duration!;
      } else if (widget.voiceNote.duration > 0) {
        _duration = Duration(seconds: widget.voiceNote.duration);
      }

      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });

          if (state.processingState == ProcessingState.completed) {
            _audioPlayer.seek(Duration.zero);
            setState(() => _isPlaying = false);
          }
        }
      });

      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() => _position = position);
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

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  @override
  void dispose() {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 290),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Duration on the LEFT (Matching Screenshot 4)
          Text(
            _formatDuration(_isPlaying ? _position : _duration),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: isMe
                  ? Colors.black87
                  : Colors.grey[300],
            ),
          ),
          const SizedBox(width: 10),

          // 2. Waveform bars in the MIDDLE (Matching Screenshot 4)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final box = context.findRenderObject() as RenderBox?;
                if (box != null && _duration.inMilliseconds > 0) {
                  final localPos = details.localPosition.dx;
                  final totalWidth = box.size.width - 90;
                  final ratio = (localPos / (totalWidth > 0 ? totalWidth : 140)).clamp(0.0, 1.0);
                  _audioPlayer.seek(
                    Duration(milliseconds: (ratio * _duration.inMilliseconds).toInt()),
                  );
                }
              },
              child: SizedBox(
                height: 28,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(
                    _waveformBars.length.clamp(0, 28),
                    (index) {
                      final barProgress = index / 28.0;
                      final isActive = barProgress <= progress;
                      final amplitude = _waveformBars[index % _waveformBars.length];

                      return Container(
                        width: 2.8,
                        height: (amplitude * 24).clamp(5.0, 26.0),
                        decoration: BoxDecoration(
                          color: isActive
                              ? (isMe
                                  ? Colors.black87
                                  : const Color(0xFF2DD4BF))
                              : (isMe
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 3. Play/Pause circular green button on the RIGHT (Matching Screenshot 4)
          GestureDetector(
            onTap: _isLoading ? null : _togglePlayPause,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF34D399), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
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
