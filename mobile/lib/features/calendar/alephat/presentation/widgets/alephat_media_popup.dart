// lib/features/calendar/alephat/presentation/widgets/alephat_media_popup.dart
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile/core/presentation/widgets/app_network_image.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/calendar/alephat/domain/alephat_letter_model.dart';

enum AlephatMediaType { audio, video, image, other }

AlephatMediaType detectMediaType(String url) {
  final clean = url.toLowerCase().split('?').first;
  if (clean.endsWith('.mp3') ||
      clean.endsWith('.wav') ||
      clean.endsWith('.aac') ||
      clean.endsWith('.m4a') ||
      clean.endsWith('.ogg') ||
      clean.endsWith('.opus') ||
      clean.endsWith('.flac') ||
      url.contains('/audio/')) {
    return AlephatMediaType.audio;
  }
  if (clean.endsWith('.mp4') ||
      clean.endsWith('.webm') ||
      clean.endsWith('.mov') ||
      clean.endsWith('.mkv') ||
      clean.endsWith('.avi') ||
      clean.endsWith('.m3u8') ||
      url.contains('/video/')) {
    return AlephatMediaType.video;
  }
  if (clean.endsWith('.jpg') ||
      clean.endsWith('.jpeg') ||
      clean.endsWith('.png') ||
      clean.endsWith('.gif') ||
      clean.endsWith('.webp') ||
      clean.endsWith('.svg') ||
      clean.endsWith('.bmp') ||
      url.contains('/image/')) {
    return AlephatMediaType.image;
  }
  return AlephatMediaType.other;
}

String getMediaTypeName(AlephatMediaType type) {
  switch (type) {
    case AlephatMediaType.audio:
      return 'ድምጽ (Audio)';
    case AlephatMediaType.video:
      return 'ቪዲዮ (Video)';
    case AlephatMediaType.image:
      return 'ምስል (Image)';
    case AlephatMediaType.other:
      return 'ሚዲያ (Media)';
  }
}

IconData getMediaTypeIcon(AlephatMediaType type) {
  switch (type) {
    case AlephatMediaType.audio:
      return Icons.audiotrack_rounded;
    case AlephatMediaType.video:
      return Icons.videocam_rounded;
    case AlephatMediaType.image:
      return Icons.image_rounded;
    case AlephatMediaType.other:
      return Icons.link_rounded;
  }
}

class AlephatMediaPopup extends StatefulWidget {
  final AlephatLetterModel letter;
  final AlephatFamilyMemberModel? selectedMember;
  final String? pronunciation;

  const AlephatMediaPopup({
    super.key,
    required this.letter,
    this.selectedMember,
    this.pronunciation,
  });

  static Future<void> show(
    BuildContext context, {
    required AlephatLetterModel letter,
    AlephatFamilyMemberModel? selectedMember,
    String? pronunciation,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlephatMediaPopup(
        letter: letter,
        selectedMember: selectedMember,
        pronunciation: pronunciation,
      ),
    );
  }

  @override
  State<AlephatMediaPopup> createState() => _AlephatMediaPopupState();
}

class _AlephatMediaPopupState extends State<AlephatMediaPopup> {
  late final List<String> _mediaUrls;
  int _selectedIndex = 0;

  AudioPlayer? _audioPlayer;
  VideoPlayerController? _videoController;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Resolve media list: member's media if present, else letter's media
    final memberMedia = widget.selectedMember?.mediaUrls ?? const [];
    if (memberMedia.isNotEmpty) {
      _mediaUrls = List.from(memberMedia);
    } else {
      _mediaUrls = List.from(widget.letter.mediaUrls);
    }

    if (_mediaUrls.isNotEmpty) {
      _loadMedia(_selectedIndex);
    }
  }

  @override
  void dispose() {
    _cleanupPlayers();
    super.dispose();
  }

  void _cleanupPlayers() {
    try {
      _audioPlayer?.stop();
      _audioPlayer?.dispose();
    } catch (_) {}
    _audioPlayer = null;

    try {
      _videoController?.pause();
      _videoController?.dispose();
    } catch (_) {}
    _videoController = null;
  }

  Future<void> _loadMedia(int index) async {
    _cleanupPlayers();
    if (index < 0 || index >= _mediaUrls.length) return;

    final rawUrl = _mediaUrls[index];
    final resolvedUrl = MediaUrlResolver.resolve(rawUrl) ?? rawUrl;
    final type = detectMediaType(resolvedUrl);

    setState(() {
      _selectedIndex = index;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (type == AlephatMediaType.audio) {
        final player = AudioPlayer();
        _audioPlayer = player;
        await player.setUrl(resolvedUrl);
        if (!mounted) return;
        player.play().catchError((_) {});
      } else if (type == AlephatMediaType.video) {
        final controller =
            VideoPlayerController.networkUrl(Uri.parse(resolvedUrl));
        _videoController = controller;
        await controller.initialize();
        if (!mounted) return;
        controller.play().catchError((_) {});
      }
    } catch (e) {
      if (mounted) {
        _errorMessage = 'ይህንን ሚዲያ ማጫወት አልተቻለም';
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
  }

  String _cleanUrlName(String url, int index) {
    try {
      final uri = Uri.parse(url);
      final segment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (segment.isNotEmpty) {
        return Uri.decodeComponent(segment);
      }
    } catch (_) {}
    return 'ሚዲያ ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glyph = widget.selectedMember?.glyph ?? widget.letter.letter;
    final name = widget.selectedMember?.orderName ?? widget.letter.name ?? '';
    final pron = widget.pronunciation ??
        widget.selectedMember?.pronunciation ??
        widget.letter.pronunciationGuide;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Title & Close button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$glyph፡',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                        fontFamilyFallback: const [
                          'Noto Serif Ethiopic',
                          'Noto Sans Ethiopic',
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ፊደል "$glyph" ድምጽ እና ሚዲያ',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamilyFallback: const [
                              'Noto Serif Ethiopic',
                              'Noto Sans Ethiopic',
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (name.isNotEmpty || (pron != null && pron.isNotEmpty))
                          Text(
                            [
                              if (name.isNotEmpty) name,
                              if (pron != null && pron.isNotEmpty) pron,
                            ].join(' • '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Dedicated Close Button ('X')
                  IconButton(
                    key: const Key('alephat_media_popup_close_button'),
                    icon: const Icon(Icons.close),
                    tooltip: 'ዝጋ (Close)',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Content Area
              Flexible(
                child: _mediaUrls.isEmpty
                    ? _buildEmptyState(theme, pron)
                    : _buildMediaViewer(theme),
              ),

              const SizedBox(height: 16),

              // Bottom Actions (Close Button)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ዝጋ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String? pron) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.volume_off_rounded,
                size: 52,
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ምንም የተያያዘ የሚዲያ ፋይል የለም',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (pron != null && pron.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.record_voice_over_outlined,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'የአጠራር መመሪያ፡ $pron',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'የፊደል አጠራር ድምጽ፣ ቪዲዮ ወይም ምስል በአስተዳዳሪ ቅንብር (Manage Letter) ውስጥ ማያያዝ ይችላሉ።',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaViewer(ThemeData theme) {
    final currentUrl = _mediaUrls[_selectedIndex];
    final resolvedUrl = MediaUrlResolver.resolve(currentUrl) ?? currentUrl;
    final currentType = detectMediaType(resolvedUrl);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active Player Area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _errorMessage != null
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      )
                    : _buildPlayerForType(theme, resolvedUrl, currentType),
          ),

          // If more than one listed on popup messages
          if (_mediaUrls.length > 1) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.playlist_play_rounded,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'የተያያዙ ሚዲያዎች (${_mediaUrls.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mediaUrls.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final itemUrl = _mediaUrls[index];
                final itemResolved = MediaUrlResolver.resolve(itemUrl) ?? itemUrl;
                final itemType = detectMediaType(itemResolved);
                final isSelected = index == _selectedIndex;

                return InkWell(
                  onTap: () => _loadMedia(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            getMediaTypeIcon(itemType),
                            size: 16,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${index + 1}. ${_cleanUrlName(itemUrl, index)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight:
                                      isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                getMediaTypeName(itemType),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'በመጫወት ላይ',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.play_circle_outline_rounded),
                            onPressed: () => _loadMedia(index),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerForType(
    ThemeData theme,
    String url,
    AlephatMediaType type,
  ) {
    switch (type) {
      case AlephatMediaType.audio:
        return _buildAudioControls(theme);
      case AlephatMediaType.video:
        return _buildVideoPlayer(theme);
      case AlephatMediaType.image:
        return _buildImageViewer(url);
      case AlephatMediaType.other:
        return _buildOtherViewer(theme, url);
    }
  }

  Widget _buildAudioControls(ThemeData theme) {
    final player = _audioPlayer;
    if (player == null) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('ድምጹ እየተዘጋጀ ነው...')),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Icon(
          Icons.graphic_eq_rounded,
          size: 54,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),
        StreamBuilder<Duration?>(
          stream: player.durationStream,
          builder: (context, durSnapshot) {
            final totalDuration = durSnapshot.data ?? Duration.zero;
            return StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (context, posSnapshot) {
                final currentPos = posSnapshot.data ?? Duration.zero;
                final maxMs = totalDuration.inMilliseconds.toDouble();
                final currentMs = currentPos.inMilliseconds
                    .toDouble()
                    .clamp(0.0, maxMs > 0 ? maxMs : 1.0);

                return Column(
                  children: [
                    Slider(
                      value: currentMs,
                      max: maxMs > 0 ? maxMs : 1.0,
                      onChanged: (val) {
                        player.seek(Duration(milliseconds: val.toInt()));
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(currentPos),
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            _formatDuration(totalDuration),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 6),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data?.playing ?? false;
            final isCompleted =
                snapshot.data?.processingState == ProcessingState.completed;

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10_rounded),
                  tooltip: '10 ሰከንድ ወደ ኋላ',
                  onPressed: () {
                    final newPos = player.position - const Duration(seconds: 10);
                    player.seek(newPos < Duration.zero ? Duration.zero : newPos);
                  },
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  iconSize: 36,
                  icon: Icon(
                    isCompleted
                        ? Icons.replay_rounded
                        : isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                  ),
                  onPressed: () {
                    if (isCompleted) {
                      player.seek(Duration.zero);
                      player.play();
                    } else if (isPlaying) {
                      player.pause();
                    } else {
                      player.play();
                    }
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.forward_10_rounded),
                  tooltip: '10 ሰከንድ ወደ ፊት',
                  onPressed: () {
                    final max = player.duration ?? Duration.zero;
                    final newPos = player.position + const Duration(seconds: 10);
                    player.seek(newPos > max ? max : newPos);
                  },
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildVideoPlayer(ThemeData theme) {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio > 0
          ? controller.value.aspectRatio
          : 16 / 9,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(controller),
          IconButton.filled(
            iconSize: 42,
            icon: Icon(
              controller.value.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
            ),
            onPressed: () {
              setState(() {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer(String url) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InteractiveViewer(
          child: AppNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildOtherViewer(ThemeData theme, String url) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.file_present_rounded, size: 48),
          const SizedBox(height: 12),
          Text(
            url,
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
