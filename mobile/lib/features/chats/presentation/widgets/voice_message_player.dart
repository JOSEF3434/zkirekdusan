// lib/features/chats/presentation/widgets/voice_message_player.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
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
      await _audioPlayer.setUrl(widget.voiceNote.url);
      _duration = _audioPlayer.duration ?? Duration(seconds: widget.voiceNote.duration);

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
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 260),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause circular button (Matching Screenshot 2 green/cyan circle)
          GestureDetector(
            onTap: _isLoading ? null : _togglePlayPause,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isMe
                    ? const LinearGradient(
                        colors: [Colors.white, Color(0xFFE0F7FA)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF2DD4BF), Color(0xFF10B981)],
                      ),
                boxShadow: [
                  BoxShadow(
                    color: (isMe ? Colors.white : const Color(0xFF10B981))
                        .withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isLoading
                  ? Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isMe ? const Color(0xFF0072FF) : Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: isMe ? const Color(0xFF0072FF) : Colors.black87,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Duration & Equalizer bars
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform Bars (tap/drag to seek)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box != null && _duration.inMilliseconds > 0) {
                      final localPos = details.localPosition.dx;
                      final ratio = (localPos / 140).clamp(0.0, 1.0);
                      _audioPlayer.seek(
                        Duration(milliseconds: (ratio * _duration.inMilliseconds).toInt()),
                      );
                    }
                  },
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(
                        _waveformBars.length.clamp(0, 30),
                        (index) {
                          final barProgress = index / 30.0;
                          final isActive = barProgress <= progress;
                          final amplitude = _waveformBars[index % _waveformBars.length];

                          return Container(
                            width: 2.5,
                            height: (amplitude * 20).clamp(4.0, 22.0),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? (isMe
                                      ? Colors.white
                                      : const Color(0xFF2DD4BF))
                                  : (isMe
                                      ? Colors.white.withValues(alpha: 0.35)
                                      : Colors.grey.withValues(alpha: 0.4)),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),

                // Duration Label
                Text(
                  _formatDuration(_isPlaying ? _position : _duration),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.85)
                        : Colors.grey[400],
                  ),
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
