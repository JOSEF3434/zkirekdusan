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

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
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

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          IconButton(
            icon: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isMe ? Colors.white : theme.colorScheme.primary,
                      ),
                    ),
                  )
                : Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: widget.isMe ? Colors.white : theme.colorScheme.primary,
                  ),
            onPressed: _isLoading ? null : _togglePlayPause,
          ),

          // Waveform or progress slider
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.voiceNote.waveform != null)
                  _buildWaveform()
                else
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: widget.isMe ? Colors.white : theme.colorScheme.primary,
                      inactiveTrackColor: widget.isMe
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey[400],
                      thumbColor: widget.isMe ? Colors.white : theme.colorScheme.primary,
                    ),
                    child: Slider(
                      value: _position.inMilliseconds.toDouble(),
                      max: _duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                      onChanged: (value) {
                        _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Text(
                    _formatDuration(_isPlaying ? _position : _duration),
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.isMe
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    final waveformData = widget.voiceNote.waveform!;
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;
    final theme = Theme.of(context);

    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(
          waveformData.length.clamp(0, 40),
          (index) {
            final normalizedIndex = index / 40;
            final isActive = normalizedIndex <= progress;
            final amplitude = waveformData[index * (waveformData.length ~/ 40)];
            
            return Container(
              width: 2,
              height: (amplitude * 28).clamp(4.0, 28.0),
              decoration: BoxDecoration(
                color: isActive
                    ? (widget.isMe ? Colors.white : theme.colorScheme.primary)
                    : (widget.isMe
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey[400]),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
