// lib/features/live/presentation/widgets/live_player_controls_overlay.dart
//
// YouTube-style live stream HUD overlay:
// - Top bar: minimize, LIVE / Behind-Live status pill + viewer count, Cast
// - Center transport: -10s rewind, Play/Pause (or buffering), +10s fast-forward
// - Bottom bar: interactive DVR seek bar, timestamp/behind-live readout, Go Live
//   button, volume/mute, Fit/Fill mode toggle, Quality selector, Fullscreen.

import 'package:flutter/material.dart';
import 'package:mobile/features/live/domain/live_dvr_state.dart';
import 'package:mobile/features/live/presentation/widgets/dvr_seek_bar.dart';
import 'package:mobile/features/live/presentation/widgets/viewer_count_widget.dart';

class LivePlayerControlsOverlay extends StatelessWidget {
  final String streamTitle;
  final LivePlaybackState playbackState;
  final DvrWindowMath window;
  final bool visible;
  final bool isFullscreen;
  final bool dvrEnabled;
  final int viewerCount;
  final VideoFitMode fitMode;
  final double volume;
  final bool isMuted;
  final List<VideoQualityOption> qualities;
  final int currentQualityIndex;
  final bool showVolumeSlider;
  final VoidCallback onMinimize;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onRewind10;
  final VoidCallback onForward10;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onGoLive;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onToggleFitMode;
  final VoidCallback onToggleMute;
  final ValueChanged<double>? onVolumeChanged;
  final ValueChanged<int>? onQualitySelected;
  final VoidCallback? onOpenCast;
  final VoidCallback? onInteraction;

  const LivePlayerControlsOverlay({
    super.key,
    required this.streamTitle,
    required this.playbackState,
    required this.window,
    required this.visible,
    required this.isFullscreen,
    required this.dvrEnabled,
    required this.viewerCount,
    required this.fitMode,
    required this.volume,
    required this.isMuted,
    this.qualities = const [VideoQualityOption.auto],
    this.currentQualityIndex = -1,
    this.showVolumeSlider = false,
    required this.onMinimize,
    required this.onTogglePlayPause,
    required this.onRewind10,
    required this.onForward10,
    required this.onSeek,
    required this.onGoLive,
    required this.onToggleFullscreen,
    required this.onToggleFitMode,
    required this.onToggleMute,
    this.onVolumeChanged,
    this.onQualitySelected,
    this.onOpenCast,
    this.onInteraction,
  });

  @override
  Widget build(BuildContext context) {
    final isBehind = !window.isAtLiveEdge ||
        playbackState == LivePlaybackState.paused ||
        playbackState == LivePlaybackState.playing ||
        playbackState == LivePlaybackState.rewinding ||
        playbackState == LivePlaybackState.fastForwarding;
    final canGoLive = dvrEnabled && (!window.isAtLiveEdge || isBehind);
    final canRewind =
        dvrEnabled && window.currentPosition > window.windowStart + const Duration(seconds: 2);
    final canForward = dvrEnabled && !window.isAtLiveEdge;

    return IgnorePointer(
      ignoring: !visible && playbackState != LivePlaybackState.dvrExpired,
      child: AnimatedOpacity(
        opacity: visible || playbackState == LivePlaybackState.dvrExpired
            ? 1.0
            : 0.0,
        duration: const Duration(milliseconds: 220),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.28, 0.65, 1.0],
              colors: [
                Color(0xC8000000),
                Colors.transparent,
                Colors.transparent,
                Color(0xDB000000),
              ],
            ),
          ),
          child: SafeArea(
            top: isFullscreen,
            bottom: isFullscreen,
            left: isFullscreen,
            right: isFullscreen,
            child: Column(
              children: [
                // ── Top Bar ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Minimize',
                        onPressed: () {
                          onInteraction?.call();
                          onMinimize();
                        },
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          streamTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ViewerCountWidget(count: viewerCount, light: true),
                      if (qualities.length > 1 &&
                          onQualitySelected != null) ...[
                        const SizedBox(width: 6),
                        PopupMenuButton<int>(
                          tooltip: 'Video quality',
                          color: const Color(0xEE181A20),
                          initialValue: currentQualityIndex,
                          onSelected: (idx) {
                            onInteraction?.call();
                            onQualitySelected!(idx);
                          },
                          itemBuilder: (_) => qualities
                              .map(
                                (q) => PopupMenuItem<int>(
                                  value: q.index,
                                  child: Row(
                                    children: [
                                      Icon(
                                        q.index == currentQualityIndex
                                            ? Icons.check_rounded
                                            : Icons.circle_outlined,
                                        size: 16,
                                        color: q.index == currentQualityIndex
                                            ? const Color(0xFFE53935)
                                            : Colors.white54,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        q.label,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              qualities
                                      .where(
                                        (q) => q.index == currentQualityIndex,
                                      )
                                      .firstOrNull
                                      ?.label ??
                                  'Auto',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (onOpenCast != null)
                        IconButton(
                          tooltip: 'Cast to TV',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 34,
                            minHeight: 34,
                          ),
                          onPressed: () {
                            onInteraction?.call();
                            onOpenCast!();
                          },
                          icon: const Icon(
                            Icons.cast_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),

                if (playbackState == LivePlaybackState.dvrExpired)
                  _DvrExpiredBanner(onGoLive: onGoLive),

                const Spacer(),

                // ── Center YouTube-style Transport Buttons ──────────────────
                if (visible)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dvrEnabled)
                        _CircleTransportButton(
                          icon: Icons.replay_10_rounded,
                          tooltip: 'Rewind 10s',
                          enabled: canRewind,
                          onTap: () {
                            onInteraction?.call();
                            onRewind10();
                          },
                        ),
                      const SizedBox(width: 22),
                      _MainPlayPauseButton(
                        playbackState: playbackState,
                        onTap: () {
                          onInteraction?.call();
                          onTogglePlayPause();
                        },
                      ),
                      const SizedBox(width: 22),
                      if (dvrEnabled)
                        _CircleTransportButton(
                          icon: Icons.forward_10_rounded,
                          tooltip: 'Forward 10s',
                          enabled: canForward,
                          onTap: () {
                            onInteraction?.call();
                            onForward10();
                          },
                        ),
                    ],
                  ),

                const Spacer(),

                // ── Bottom DVR Timeline & Toolbar ───────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 8, 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dvrEnabled)
                        DvrSeekBar(
                          window: window,
                          enabled: dvrEnabled,
                          compact: !isFullscreen && !showVolumeSlider,
                          onSeek: (pos) {
                            onInteraction?.call();
                            onSeek(pos);
                          },
                          onGoLive: () {
                            onInteraction?.call();
                            onGoLive();
                          },
                          onScrubStart: onInteraction,
                        ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompactWidth = constraints.maxWidth < 380;
                          final iconStyle = IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(32, 32),
                          );
                          return Row(
                            children: [
                              IconButton(
                                style: iconStyle,
                                tooltip:
                                    playbackState == LivePlaybackState.paused
                                        ? 'Play'
                                        : 'Pause',
                                onPressed: () {
                                  onInteraction?.call();
                                  onTogglePlayPause();
                                },
                                icon: Icon(
                                  playbackState == LivePlaybackState.paused
                                      ? Icons.play_arrow_rounded
                                      : Icons.pause_rounded,
                                  color: Colors.white,
                                  size: 21,
                                ),
                              ),
                              IconButton(
                                style: iconStyle,
                                tooltip: isMuted ? 'Unmute' : 'Mute',
                                onPressed: () {
                                  onInteraction?.call();
                                  onToggleMute();
                                },
                                icon: Icon(
                                  isMuted || volume == 0
                                      ? Icons.volume_off_rounded
                                      : volume < 0.5
                                          ? Icons.volume_down_rounded
                                          : Icons.volume_up_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                              if (showVolumeSlider &&
                                  !isCompactWidth &&
                                  onVolumeChanged != null)
                                SizedBox(
                                  width: 72,
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2.5,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 5,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                        overlayRadius: 10,
                                      ),
                                    ),
                                    child: Slider(
                                      value:
                                          isMuted ? 0.0 : volume.clamp(0.0, 1.0),
                                      onChanged: (v) {
                                        onInteraction?.call();
                                        onVolumeChanged!(v);
                                      },
                                      activeColor: Colors.white,
                                      inactiveColor: Colors.white30,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: _LiveStatusPill(
                                          window: window,
                                          playbackState: playbackState,
                                          dvrEnabled: dvrEnabled,
                                          canGoLive: canGoLive,
                                          onGoLive: () {
                                            onInteraction?.call();
                                            onGoLive();
                                          },
                                        ),
                                      ),
                                      if (dvrEnabled && !isCompactWidth) ...[
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            window.isAtLiveEdge
                                                ? window.formattedTotal
                                                : '${window.formattedCurrent} / ${window.formattedTotal}',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                style: iconStyle,
                                tooltip: fitMode == VideoFitMode.fit
                                    ? 'Fill viewport'
                                    : 'Fit whole video (uncropped)',
                                onPressed: () {
                                  onInteraction?.call();
                                  onToggleFitMode();
                                },
                                icon: Icon(
                                  fitMode == VideoFitMode.fill
                                      ? Icons.fit_screen_rounded
                                      : Icons.crop_free_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                              IconButton(
                                style: iconStyle,
                                tooltip: isFullscreen
                                    ? 'Exit fullscreen'
                                    : 'Fullscreen',
                                onPressed: () {
                                  onInteraction?.call();
                                  onToggleFullscreen();
                                },
                                icon: Icon(
                                  isFullscreen
                                      ? Icons.fullscreen_exit_rounded
                                      : Icons.fullscreen_rounded,
                                  color: Colors.white,
                                  size: 21,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveStatusPill extends StatelessWidget {
  final DvrWindowMath window;
  final LivePlaybackState playbackState;
  final bool dvrEnabled;
  final bool canGoLive;
  final VoidCallback onGoLive;

  const _LiveStatusPill({
    required this.window,
    required this.playbackState,
    required this.dvrEnabled,
    required this.canGoLive,
    required this.onGoLive,
  });

  @override
  Widget build(BuildContext context) {
    final isAtEdge = window.isAtLiveEdge && !canGoLive;
    final label = isAtEdge
        ? 'LIVE'
        : playbackState == LivePlaybackState.paused
            ? 'PAUSED ${window.formattedBehindLive}'
            : 'GO LIVE ${window.formattedBehindLive}';

    return Material(
      color: isAtEdge
          ? const Color(0xFFE53935).withValues(alpha: 0.92)
          : Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: canGoLive ? onGoLive : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isAtEdge ? Colors.white : Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleTransportButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  const _CircleTransportButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              size: 28,
              color: enabled ? Colors.white : Colors.white38,
            ),
          ),
        ),
      ),
    );
  }
}

class _MainPlayPauseButton extends StatelessWidget {
  final LivePlaybackState playbackState;
  final VoidCallback onTap;

  const _MainPlayPauseButton({
    required this.playbackState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final busy = playbackState == LivePlaybackState.buffering ||
        playbackState == LivePlaybackState.seeking;
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: busy
              ? const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  playbackState == LivePlaybackState.paused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  size: 32,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}

class _DvrExpiredBanner extends StatelessWidget {
  final VoidCallback onGoLive;
  const _DvrExpiredBanner({required this.onGoLive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.deepOrange.shade900.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_toggle_off, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Paused segment aged out of the DVR buffer.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onGoLive,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white24,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: const Text(
              'Go Live',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
