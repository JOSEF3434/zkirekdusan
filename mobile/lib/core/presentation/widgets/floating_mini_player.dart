// lib/core/presentation/widgets/floating_mini_player.dart
// Production-grade persistent floating MiniPlayer matching YouTube/Telegram UX & user visual reference.
// Features:
//   • Responsive 16:9 video preview with rounded corners and elevation
//   • Working Play/Pause, Fullscreen/Expand, and Close controls
//   • Draggable across screen with safe-area & viewport edge bounds
//   • Smooth magnetic snap-to-edge animation on drag release
//   • Seamless zero-buffering handoff to full-screen player
//   • Complete disposal and hardware decoder release on Close

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/core/navigation/navigation_service.dart';
import 'package:mobile/core/presentation/providers/mini_player_provider.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';
import 'package:mobile/features/live/presentation/providers/scheduled_live_sync_provider.dart';

class FloatingMiniPlayer extends ConsumerStatefulWidget {
  const FloatingMiniPlayer({super.key});

  @override
  ConsumerState<FloatingMiniPlayer> createState() => _FloatingMiniPlayerState();
}

class _FloatingMiniPlayerState extends ConsumerState<FloatingMiniPlayer>
    with SingleTickerProviderStateMixin {
  // Draggable position coordinates
  Offset? _position;
  Offset? _resizeStartPointer;
  Offset? _resizeStartPosition;
  double? _resizeStartWidth;
  bool _resizeFromLeft = false;
  bool _resizeFromTop = false;
  bool _resizeFromHorizontalEdge = false;
  bool _resizeFromVerticalEdge = false;

  // Snap animation controller
  late AnimationController _snapAnimCtrl;
  Animation<Offset>? _snapAnimation;

  // Internal live stream controller if initialized directly inside mini-player
  VideoPlayerController? _liveController;
  bool _isLiveCtrlInitializing = false;
  bool _isExpanding = false;

  @override
  void initState() {
    super.initState();
    _snapAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _snapAnimCtrl.addListener(() {
      if (_snapAnimation != null) {
        setState(() {
          _position = _snapAnimation!.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _snapAnimCtrl.dispose();
    _liveController?.dispose();
    super.dispose();
  }

  // ── Live Stream Fallback Controller Init ─────────────────────────────────

  Future<void> _initLiveControllerIfNeeded(String hlsUrl) async {
    final mp = ref.read(miniPlayerProvider);
    if (mp.isEnded ||
        _liveController != null ||
        _isLiveCtrlInitializing ||
        hlsUrl.trim().isEmpty) {
      return;
    }
    _isLiveCtrlInitializing = true;
    try {
      final resolved = MediaUrlResolver.resolve(hlsUrl.trim()) ?? hlsUrl.trim();
      if (resolved.isEmpty) {
        _isLiveCtrlInitializing = false;
        return;
      }
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(resolved));
      await ctrl.initialize();
      await ctrl.play();
      if (mounted) {
        setState(() {
          _liveController = ctrl;
          _isLiveCtrlInitializing = false;
        });
        ref.read(miniPlayerProvider.notifier).updateLiveController(ctrl);
      }
    } catch (e) {
      debugPrint('[FloatingMiniPlayer] Live fallback init error: $e');
      if (mounted) {
        setState(() => _isLiveCtrlInitializing = false);
      }
    }
  }

  // ── Open Full Player ──────────────────────────────────────────────────────

  void _restoreToFullPlayer(MiniPlayerState mp) {
    if (_isExpanding || !mp.hasContent) return;

    final contentId = mp.contentId?.trim();
    if (contentId == null || contentId.isEmpty) {
      debugPrint('[FloatingMiniPlayer] Fullscreen ignored: missing content id');
      return;
    }

    // If stream has ended, navigate directly to live room to view the ended state
    if (mp.isEnded) {
      final target = '/live/$contentId';
      _isExpanding = true;
      final navigated = NavigationService.instance.navigateTo(target);
      if (navigated) {
        ref.read(miniPlayerProvider.notifier).prepareExpand();
      } else {
        _isExpanding = false;
      }
      return;
    }

    final controller = mp.controller ?? _liveController;
    if (controller == null) {
      debugPrint(
        '[FloatingMiniPlayer] Fullscreen ignored: no active controller for $contentId',
      );
      return;
    }

    try {
      if (!controller.value.isInitialized) {
        debugPrint(
          '[FloatingMiniPlayer] Fullscreen ignored: controller not initialized for $contentId',
        );
        return;
      }
    } catch (error) {
      debugPrint(
        '[FloatingMiniPlayer] Fullscreen ignored: controller unavailable for $contentId: $error',
      );
      return;
    }

    final target = mp.isLive ? '/live/$contentId' : '/video/$contentId';
    debugPrint(
      '[FloatingMiniPlayer] Fullscreen requested: target=$target type=${mp.type} '
      'position=${controller.value.position} playing=${controller.value.isPlaying}',
    );
    _isExpanding = true;

    final navigated = NavigationService.instance.navigateTo(target);
    if (!navigated) {
      _isExpanding = false;
      debugPrint(
        '[FloatingMiniPlayer] Fullscreen navigation rejected: target=$target',
      );
      return;
    }

    // Transfer ownership without pausing, stopping, or disposing the session.
    ref.read(miniPlayerProvider.notifier).prepareExpand();
    debugPrint(
      '[FloatingMiniPlayer] Fullscreen navigation accepted; MiniPlayer hidden '
      'for controller handoff: target=$target',
    );
  }

  // ── Dismiss & Terminate ───────────────────────────────────────────────────

  void _dismissMiniPlayer() {
    final mp = ref.read(miniPlayerProvider);
    final wasEnded = mp.isEnded;
    _liveController?.pause();
    _liveController?.dispose();
    _liveController = null;
    _isLiveCtrlInitializing = false;
    ref.read(miniPlayerProvider.notifier).dismiss();
    if (wasEnded && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Live stream ended'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _beginResize({
    required DragStartDetails details,
    required bool fromLeft,
    required bool fromTop,
    required bool fromHorizontalEdge,
    required bool fromVerticalEdge,
  }) {
    _snapAnimCtrl.stop();
    _resizeStartPointer = details.globalPosition;
    _resizeStartPosition = _position;
    _resizeStartWidth = _currentCardWidth;
    _resizeFromLeft = fromLeft;
    _resizeFromTop = fromTop;
    _resizeFromHorizontalEdge = fromHorizontalEdge;
    _resizeFromVerticalEdge = fromVerticalEdge;
  }

  void _updateResize({
    required DragUpdateDetails details,
    required Size screenSize,
    required EdgeInsets padding,
    required double videoAspect,
  }) {
    final startPointer = _resizeStartPointer;
    final startPosition = _resizeStartPosition;
    final startWidth = _resizeStartWidth;
    if (startPointer == null || startPosition == null || startWidth == null) {
      return;
    }

    final delta = details.globalPosition - startPointer;
    final videoStartHeight = startWidth / videoAspect;
    final horizontalWidth = _resizeFromLeft
        ? startWidth - delta.dx
        : startWidth + delta.dx;
    final verticalWidth = _resizeFromTop
        ? startWidth - (delta.dy * videoAspect)
        : startWidth + (delta.dy * videoAspect);

    double nextWidth = startWidth;
    if (_resizeFromHorizontalEdge) nextWidth = horizontalWidth;
    if (_resizeFromVerticalEdge) {
      nextWidth = _resizeFromHorizontalEdge
          ? (horizontalWidth - startWidth).abs() >=
                    (verticalWidth - startWidth).abs()
                ? horizontalWidth
                : verticalWidth
          : verticalWidth;
    }

    final availableWidth = max(1.0, screenSize.width - padding.horizontal - 16);
    final availableHeight = max(
      1.0,
      screenSize.height - padding.vertical - 16 - bottomBarHeight,
    );
    final minWidth = min(
      180.0,
      min(availableWidth, availableHeight * videoAspect),
    );
    final maxWidthFromLeft =
        screenSize.width -
        padding.right -
        8 -
        (_resizeFromLeft ? padding.left + 8 : startPosition.dx);
    final maxWidthFromHeight =
        (screenSize.height - padding.vertical - 16 - bottomBarHeight) /
        videoAspect;
    final maxWidth =
        max(minWidth, min(420.0, min(maxWidthFromLeft, maxWidthFromHeight)))
            .clamp(
              minWidth,
              min(420.0, min(availableWidth, availableHeight * videoAspect)),
            )
            .toDouble();
    nextWidth = nextWidth.clamp(minWidth, maxWidth).toDouble();

    final nextHeight = nextWidth / videoAspect + bottomBarHeight;
    final nextLeft = _resizeFromLeft
        ? startPosition.dx + startWidth - nextWidth
        : startPosition.dx;
    final nextTop = _resizeFromTop
        ? startPosition.dy + videoStartHeight - nextWidth / videoAspect
        : startPosition.dy;
    final minLeft = padding.left + 8.0;
    final maxLeft = screenSize.width - padding.right - nextWidth - 8.0;
    final minTop = padding.top + 8.0;
    final maxTop = screenSize.height - padding.bottom - nextHeight - 8.0;

    setState(() {
      _position = Offset(
        nextLeft.clamp(minLeft, max(minLeft, maxLeft).toDouble()),
        nextTop.clamp(minTop, max(minTop, maxTop).toDouble()),
      );
      _currentCardWidth = nextWidth;
    });
  }

  void _endResize() {
    _resizeStartPointer = null;
    _resizeStartPosition = null;
    _resizeStartWidth = null;
  }

  // ── Drag & Safe Area Clamping ─────────────────────────────────────────────

  static const bottomBarHeight = 48.0;
  double _currentCardWidth = 0;

  void _clampPosition(
    Size screenSize,
    EdgeInsets padding,
    double cardWidth,
    double cardHeight,
  ) {
    if (_position == null) {
      // Default initial position: bottom-right above navigation bar
      final defaultX = screenSize.width - cardWidth - padding.right - 16;
      final defaultY = screenSize.height - cardHeight - padding.bottom - 16;
      _position = Offset(
        max(padding.left + 8, defaultX),
        max(padding.top + 8, defaultY),
      );
      return;
    }

    final minX = padding.left + 8.0;
    final maxX = screenSize.width - cardWidth - padding.right - 8.0;
    final minY = padding.top + 8.0;
    final maxY = screenSize.height - cardHeight - padding.bottom - 8.0;

    final clampedX = _position!.dx.clamp(minX, max(minX, maxX).toDouble());
    final clampedY = _position!.dy.clamp(minY, max(minY, maxY).toDouble());

    if (clampedX != _position!.dx || clampedY != _position!.dy) {
      _position = Offset(clampedX, clampedY);
    }
  }

  void _snapToEdge(
    Size screenSize,
    EdgeInsets padding,
    double cardWidth,
    double cardHeight,
  ) {
    if (_position == null) return;

    final minX = padding.left + 12.0;
    final maxX = screenSize.width - cardWidth - padding.right - 12.0;
    final midX = screenSize.width / 2;

    final targetX = (_position!.dx + (cardWidth / 2)) < midX ? minX : maxX;
    final targetY = _position!.dy;

    final startOffset = _position!;
    final endOffset = Offset(targetX, targetY);

    _snapAnimation = Tween<Offset>(begin: startOffset, end: endOffset).animate(
      CurvedAnimation(parent: _snapAnimCtrl, curve: Curves.easeOutCubic),
    );

    _snapAnimCtrl.forward(from: 0).then((_) {
      ref.read(miniPlayerProvider.notifier).updatePosition(endOffset);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mp = ref.watch(miniPlayerProvider);

    // Keep the player visible above the keyboard instead of allowing it to
    // extend into the keyboard/navigation-bar area.
    if (!mp.hasContent) {
      _isExpanding = false;
    }
    if (!mp.isVisible || !mp.hasContent) {
      return const SizedBox.shrink();
    }

    // Listen for real-time live stream transitions (such as stream ending)
    ref.listen<Map<String, LiveStreamStatus>>(scheduledLiveSyncProvider, (prev, next) {
      final currentMp = ref.read(miniPlayerProvider);
      if (currentMp.isLive && currentMp.contentId != null && !currentMp.isEnded) {
        if (next[currentMp.contentId] == LiveStreamStatus.ended) {
          ref.read(miniPlayerProvider.notifier).markEnded();
        }
      }
    });

    // Initialize live stream fallback if controller was null (only if not ended)
    if (mp.isLive && !mp.isEnded && mp.controller == null && mp.hlsUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initLiveControllerIfNeeded(mp.hlsUrl!);
      });
    }

    final media = MediaQuery.of(context);
    final screenSize = media.size;
    final padding =
        EdgeInsets.fromLTRB(
          max(media.padding.left, media.viewPadding.left),
          max(media.padding.top, media.viewPadding.top),
          max(media.padding.right, media.viewPadding.right),
          max(media.padding.bottom, media.viewPadding.bottom),
        ).copyWith(
          bottom: max(
            max(media.padding.bottom, media.viewPadding.bottom),
            media.viewInsets.bottom,
          ),
        );
    final activeCtrl = mp.controller ?? _liveController;
    final isInitialized = activeCtrl != null && activeCtrl.value.isInitialized;
    final videoAspect = isInitialized && activeCtrl.value.aspectRatio > 0
        ? activeCtrl.value.aspectRatio
        : 16 / 9;

    // Responsive dimensions
    final isTabletOrDesktop = screenSize.width >= 600;
    final defaultCardWidth = isTabletOrDesktop
        ? min(300.0, screenSize.width * 0.38)
        : min(220.0, screenSize.width * 0.58);
    if (_currentCardWidth <= 0) {
      _currentCardWidth = defaultCardWidth;
    }
    final availableWidth = max(1.0, screenSize.width - padding.horizontal - 16);
    final availableHeight = max(
      1.0,
      screenSize.height - padding.vertical - 16 - bottomBarHeight,
    );
    final maxWidth = min(
      420.0,
      min(availableWidth, availableHeight * videoAspect),
    );
    final minWidth = min(180.0, min(availableWidth, maxWidth));
    _currentCardWidth = _currentCardWidth.clamp(minWidth, maxWidth).toDouble();
    final cardWidth = _currentCardWidth;
    final videoHeight = cardWidth / videoAspect;
    final cardHeight = videoHeight + bottomBarHeight;

    // Position clamping
    _clampPosition(screenSize, padding, cardWidth, cardHeight);

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: GestureDetector(
        onPanStart: (_) {
          _snapAnimCtrl.stop();
        },
        onPanUpdate: (details) {
          setState(() {
            final minX = padding.left + 4.0;
            final maxX = screenSize.width - cardWidth - padding.right - 4.0;
            final minY = padding.top + 4.0;
            final maxY = screenSize.height - cardHeight - padding.bottom - 4.0;

            final nextX = (_position!.dx + details.delta.dx).clamp(
              minX,
              max(minX, maxX).toDouble(),
            );
            final nextY = (_position!.dy + details.delta.dy).clamp(
              minY,
              max(minY, maxY).toDouble(),
            );
            _position = Offset(nextX, nextY);
          });
        },
        onPanEnd: (_) {
          _snapToEdge(screenSize, padding, cardWidth, cardHeight);
        },
        child: Material(
          elevation: 16,
          shadowColor: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent,
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF14141E),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Column(
                    children: [
                      // ── 16:9 Video Player / Thumbnail Area ───────────────
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _restoreToFullPlayer(mp),
                        child: SizedBox(
                          width: cardWidth,
                          height: videoHeight,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(color: Colors.black),
                              if (mp.isEnded)
                                Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _buildThumbnail(mp),
                                    Container(color: Colors.black54),
                                  ],
                                )
                              else if (isInitialized)
                                FittedBox(
                                  fit: BoxFit.cover,
                                  clipBehavior: Clip.hardEdge,
                                  child: SizedBox(
                                    width: activeCtrl.value.size.width > 0
                                        ? activeCtrl.value.size.width
                                        : 16,
                                    height: activeCtrl.value.size.height > 0
                                        ? activeCtrl.value.size.height
                                        : 9,
                                    child: VideoPlayer(activeCtrl),
                                  ),
                                )
                              else
                                _buildThumbnail(mp),

                              // LIVE or ENDED Tag overlay
                              if (mp.isLive)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: mp.isEnded
                                          ? Colors.grey.shade800
                                          : Colors.redAccent,
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: mp.isEnded
                                              ? Colors.black.withValues(alpha: 0.5)
                                              : Colors.red.withValues(alpha: 0.4),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          mp.isEnded
                                              ? Icons.stop_circle_outlined
                                              : Icons.sensors_rounded,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          mp.isEnded ? 'ENDED' : 'LIVE',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // ── Bottom Metadata & Control Bar (Matching Reference) ─
                      Container(
                        height: bottomBarHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF181824),
                        ),
                        child: Row(
                          children: [
                            // Channel / Creator Avatar
                            GestureDetector(
                              onTap: () => _restoreToFullPlayer(mp),
                              child: _buildAvatar(mp),
                            ),
                            const SizedBox(width: 6),

                            // Title and Channel text
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _restoreToFullPlayer(mp),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: constraints.maxWidth,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mp.title ?? (mp.isLive ? 'Live Stream' : 'Video'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (mp.isEnded)
                                            Text(
                                              'Stream ended',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.redAccent.shade100,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )
                                          else if (mp.channelName != null &&
                                              mp.channelName!.isNotEmpty)
                                            Text(
                                              mp.channelName!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.65,
                                                ),
                                                fontSize: 9,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Play / Pause or Expand Button
                            if (!mp.isEnded)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                icon: Icon(
                                  mp.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  ref
                                      .read(miniPlayerProvider.notifier)
                                      .togglePlayPause();
                                },
                              )
                            else
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                icon: const Icon(
                                  Icons.open_in_full_rounded,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                onPressed: () => _restoreToFullPlayer(mp),
                              ),

                            // Close Button
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                              onPressed: _dismissMiniPlayer,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildResizeHandle(
                  alignment: Alignment.topLeft,
                  cursor: SystemMouseCursors.resizeUpLeft,
                  fromLeft: true,
                  fromTop: true,
                  fromHorizontalEdge: true,
                  fromVerticalEdge: true,
                  screenSize: screenSize,
                  padding: padding,
                  videoAspect: videoAspect,
                ),
                _buildResizeHandle(
                  alignment: Alignment.topRight,
                  cursor: SystemMouseCursors.resizeUpRight,
                  fromLeft: false,
                  fromTop: true,
                  fromHorizontalEdge: true,
                  fromVerticalEdge: true,
                  screenSize: screenSize,
                  padding: padding,
                  videoAspect: videoAspect,
                ),
                _buildResizeHandle(
                  alignment: Alignment.bottomLeft,
                  cursor: SystemMouseCursors.resizeDownLeft,
                  fromLeft: true,
                  fromTop: false,
                  fromHorizontalEdge: true,
                  fromVerticalEdge: true,
                  screenSize: screenSize,
                  padding: padding,
                  videoAspect: videoAspect,
                ),
                _buildResizeHandle(
                  alignment: Alignment.bottomRight,
                  cursor: SystemMouseCursors.resizeDownRight,
                  fromLeft: false,
                  fromTop: false,
                  fromHorizontalEdge: true,
                  fromVerticalEdge: true,
                  screenSize: screenSize,
                  padding: padding,
                  videoAspect: videoAspect,
                ),
                _buildResizeHandle(
                  alignment: Alignment.topCenter,
                  cursor: SystemMouseCursors.resizeUpDown,
                  fromLeft: false,
                  fromTop: true,
                  fromHorizontalEdge: false,
                  fromVerticalEdge: true,
                  screenSize: screenSize,
                  padding: padding,
                  videoAspect: videoAspect,
                ),
                _buildResizeHandle(
                  alignment: Alignment.bottomCenter,
                  cursor: SystemMouseCursors.resizeUpDown,
                  fromLeft: false,
                  fromTop: false,
                  fromHorizontalEdge: false,
                  fromVerticalEdge: true,
                  screenSize: screenSize,
                  padding: padding,
                  videoAspect: videoAspect,
                ),
                _buildResizeHandle(
                  alignment: Alignment.centerLeft,
                  cursor: SystemMouseCursors.resizeLeftRight,
                  fromLeft: true,
                  fromTop: false,
                  fromHorizontalEdge: true,
                  fromVerticalEdge: false,
                  screenSize: screenSize,
                  padding: padding,
                  videoAspect: videoAspect,
                ),
                _buildResizeHandle(
                  alignment: Alignment.centerRight,
                  cursor: SystemMouseCursors.resizeLeftRight,
                  fromLeft: false,
                  fromTop: false,
                  fromHorizontalEdge: true,
                  fromVerticalEdge: false,
                  screenSize: screenSize,
                  padding: padding,
                  videoAspect: videoAspect,
                ),
                // Keep fullscreen above the top-left resize hit target.
                Positioned(
                  top: 6,
                  left: 6,
                  child: Material(
                    color: Colors.black45,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => _restoreToFullPlayer(mp),
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.fullscreen_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResizeHandle({
    required Alignment alignment,
    required MouseCursor cursor,
    required bool fromLeft,
    required bool fromTop,
    required bool fromHorizontalEdge,
    required bool fromVerticalEdge,
    required Size screenSize,
    required EdgeInsets padding,
    required double videoAspect,
  }) {
    final isCorner = fromHorizontalEdge && fromVerticalEdge;
    final handleSize = isCorner ? 24.0 : 18.0;
    return Align(
      alignment: alignment,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) => _beginResize(
            details: details,
            fromLeft: fromLeft,
            fromTop: fromTop,
            fromHorizontalEdge: fromHorizontalEdge,
            fromVerticalEdge: fromVerticalEdge,
          ),
          onPanUpdate: (details) => _updateResize(
            details: details,
            screenSize: screenSize,
            padding: padding,
            videoAspect: videoAspect,
          ),
          onPanEnd: (_) => _endResize(),
          onPanCancel: _endResize,
          child: SizedBox(
            width: fromHorizontalEdge ? handleSize : 28,
            height: fromVerticalEdge ? handleSize : 28,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(MiniPlayerState mp) {
    if (mp.avatarUrl != null && mp.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 12,
        backgroundImage: CachedNetworkImageProvider(mp.avatarUrl!),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: mp.isLive
            ? Colors.redAccent.withValues(alpha: 0.25)
            : Colors.blueAccent.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      child: Icon(
        mp.isLive ? Icons.sensors_rounded : Icons.play_circle_filled_rounded,
        size: 14,
        color: mp.isLive ? Colors.redAccent : Colors.blueAccent,
      ),
    );
  }

  Widget _buildThumbnail(MiniPlayerState mp) {
    if (mp.thumbnailUrl != null && mp.thumbnailUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: mp.thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (c, u) => _fallbackPlaceholder(mp),
        errorWidget: (c, u, e) => _fallbackPlaceholder(mp),
      );
    }
    return _fallbackPlaceholder(mp);
  }

  Widget _fallbackPlaceholder(MiniPlayerState mp) {
    return Container(
      color: const Color(0xFF1A1A28),
      child: Center(
        child: Icon(
          mp.isLive ? Icons.sensors_rounded : Icons.video_library_rounded,
          color: Colors.white30,
          size: 32,
        ),
      ),
    );
  }
}
