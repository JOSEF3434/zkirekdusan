// lib/core/presentation/widgets/mini_player_overlay.dart
// Persistent floating mini-player — YouTube-style.
//
// Shows at the bottom of the AppShell when:
//   • A VOD video is minimised while still playing.
//   • A live stream is minimised without ending.
//
// Interaction:
//   • Tap   → re-navigate to the full player/room.
//   • ×     → dismiss (stop playback).
//   • Drag down → dismiss with velocity.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile/core/presentation/providers/mini_player_provider.dart';

class MiniPlayerOverlay extends ConsumerStatefulWidget {
  const MiniPlayerOverlay({super.key});

  @override
  ConsumerState<MiniPlayerOverlay> createState() => _MiniPlayerOverlayState();
}

class _MiniPlayerOverlayState extends ConsumerState<MiniPlayerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  // Internal video controller for live streams started inside the mini player.
  VideoPlayerController? _liveCtrl;
  bool _liveCtrlReady = false;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _liveCtrl?.dispose();
    super.dispose();
  }

  // ── Live HLS init ────────────────────────────────────────────────────────

  Future<void> _initLiveCtrl(String hlsUrl) async {
    if (_liveCtrl != null) return; // already initialising
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(hlsUrl));
    _liveCtrl = ctrl;
    try {
      await ctrl.initialize();
      await ctrl.setVolume(0); // muted in mini player
      await ctrl.play();
      if (mounted) {
        setState(() => _liveCtrlReady = true);
        ref.read(miniPlayerProvider.notifier).updateLiveController(ctrl);
      }
    } catch (_) {
      // show thumbnail fallback if stream fails
    }
  }


  // ── Open full player ─────────────────────────────────────────────────────

  void _openFull(BuildContext context, MiniPlayerState mp) {
    ref.read(miniPlayerProvider.notifier).hide();
    if (mp.type == MiniPlayerType.live) {
      context.push('/live/room/${mp.contentId}');
    } else {
      context.push('/video/${mp.contentId}');
    }
  }

  // ── Dismiss ──────────────────────────────────────────────────────────────

  void _dismiss() {
    _liveCtrl?.pause();
    _liveCtrl?.dispose();
    _liveCtrl = null;
    _liveCtrlReady = false;
    ref.read(miniPlayerProvider.notifier).dismiss();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Listen to state changes to drive animation and live controller.
    ref.listen<MiniPlayerState>(miniPlayerProvider, (prev, next) {
      if (!mounted) return;

      // Slide in / out.
      if (next.isVisible && !(prev?.isVisible ?? false)) {
        _slideCtrl.forward(from: 0);
      } else if (!next.isVisible && (prev?.isVisible ?? false)) {
        _slideCtrl.reverse();
      }

      // Start live mini-player controller when needed.
      if (next.isVisible &&
          next.type == MiniPlayerType.live &&
          next.hlsUrl != null &&
          _liveCtrl == null) {
        _initLiveCtrl(next.hlsUrl!);
      }

      // Clean up live ctrl when dismissed.
      if (!next.hasContent) {
        _liveCtrl?.dispose();
        _liveCtrl = null;
        if (mounted) setState(() => _liveCtrlReady = false);
      }
    });

    final mp = ref.watch(miniPlayerProvider);

    // If keyboard is open or no content, hide overlay to prevent layout collisions & overflows
    if (!mp.hasContent || MediaQuery.of(context).viewInsets.bottom > 0) {
      return const SizedBox.shrink();
    }

    final ctrl = mp.type == MiniPlayerType.live ? _liveCtrl : mp.controller;
    final isCtrlReady = mp.type == MiniPlayerType.live
        ? _liveCtrlReady
        : (mp.controller?.value.isInitialized ?? false);

    return SlideTransition(
      position: _slideAnim,
      child: _MiniPlayerCard(
        mp: mp,
        controller: ctrl,
        isCtrlReady: isCtrlReady,
        onTap: () => _openFull(context, mp),
        onDismiss: _dismiss,
      ),
    );
  }
}

// ─── Card widget ─────────────────────────────────────────────────────────────

class _MiniPlayerCard extends StatelessWidget {
  final MiniPlayerState mp;
  final VideoPlayerController? controller;
  final bool isCtrlReady;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _MiniPlayerCard({
    required this.mp,
    required this.controller,
    required this.isCtrlReady,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLive = mp.type == MiniPlayerType.live;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 400) {
          onDismiss();
        }
      },
      child: Material(
        elevation: 12,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        color: theme.colorScheme.surface,
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // ── Video preview ──────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 96,
                    height: 54,
                    child: isCtrlReady && controller != null
                        ? AspectRatio(
                            aspectRatio:
                                controller!.value.aspectRatio.clamp(1.0, 2.0),
                            child: VideoPlayer(controller!),
                          )
                        : _buildThumbnail(mp),
                  ),
                ),
                const SizedBox(width: 8),

                // ── Title / Channel ────────────────────────────────────
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isLive)
                        Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      Text(
                        mp.title ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (mp.channelName != null)
                        Text(
                          mp.channelName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Controls ───────────────────────────────────────────
                if (!isLive && controller != null && controller!.value.isInitialized)
                  ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: controller!,
                    builder: (context, value, _) {
                      return IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          value.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: () {
                          if (value.isPlaying) {
                            controller!.pause();
                          } else {
                            controller!.play();
                          }
                        },
                      );
                    },
                  ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onDismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(MiniPlayerState mp) {
    if (mp.thumbnailUrl != null && mp.thumbnailUrl!.isNotEmpty) {
      return Image.network(
        mp.thumbnailUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: Colors.black,
      child: const Icon(Icons.play_circle_outline,
          color: Colors.white54, size: 28),
    );
  }
}
