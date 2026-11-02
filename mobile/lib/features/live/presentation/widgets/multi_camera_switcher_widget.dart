// lib/features/live/presentation/widgets/multi_camera_switcher_widget.dart
//
// Director-mode multi-camera grid overlay for the Live Studio.
//
// Shows all connected camera sources (built-in + remote phones) as
// live preview thumbnails in a responsive grid.  The broadcaster taps
// one to switch the active on-air feed — identical to a professional
// production switcher (ATEM style).
//
// Layout:
//   • ≤ 2 cameras  → 1×2 split
//   • 3-4 cameras  → 2×2 grid
//   • 5+ cameras   → 3-column wrap grid
//
// "Program" (currently on-air) is always highlighted with a red border.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/live/domain/cast_device.dart';
import 'package:mobile/features/live/presentation/providers/cast_provider.dart';
import 'package:mobile/features/live/data/live_socket_service.dart';

// ─── Camera source entry for the switcher ────────────────────────────────────

class _SwitcherSource {
  final String id;
  final String label;
  final CastDevice? castDevice;
  final bool isBuiltIn;
  final bool isScreenShare;

  const _SwitcherSource({
    required this.id,
    required this.label,
    this.castDevice,
    this.isBuiltIn = false,
    this.isScreenShare = false,
  });
}

// ─── Main Widget ──────────────────────────────────────────────────────────────

class MultiCameraSwitcherWidget extends ConsumerWidget {
  /// Called when the broadcaster taps a source to go live.
  final ValueChanged<String> onSourceSelected;

  /// The stream ID (used to emit cast:switch-source via socket).
  final String streamId;

  const MultiCameraSwitcherWidget({
    super.key,
    required this.onSourceSelected,
    required this.streamId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(castDevicesProvider);
    final activeId = ref.watch(activeCastSourceIdProvider);
    final isScreenSharing =
        ref.watch(screenShareStreamProvider) != null;

    return devicesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (devices) {
        final connectedCameras = devices
            .where((d) =>
                d.type == CastDeviceType.remoteCamera &&
                d.status == CastSessionStatus.connected)
            .toList();

        // Build source list
        final sources = <_SwitcherSource>[
          const _SwitcherSource(
            id: '__builtin__',
            label: 'Built-in Camera',
            isBuiltIn: true,
          ),
          if (isScreenSharing)
            const _SwitcherSource(
              id: '__screen__',
              label: 'Screen Share',
              isScreenShare: true,
            ),
          ...connectedCameras.map(
            (d) => _SwitcherSource(
              id: d.id,
              label: d.name,
              castDevice: d,
            ),
          ),
        ];

        if (sources.length <= 1) return const SizedBox.shrink();

        return _SwitcherGrid(
          sources: sources,
          activeId: activeId ?? '__builtin__',
          onSourceSelected: (id) {
            ref.read(activeCastSourceIdProvider.notifier).state =
                id == '__builtin__' ? null : id;
            ref.read(liveSocketServiceProvider).emitCastSwitchSource(
                  streamId: streamId,
                  sourceId: id,
                  sourceType: id == '__builtin__'
                      ? 'BUILTIN'
                      : id == '__screen__'
                          ? 'SCREEN'
                          : 'REMOTE_CAMERA',
                );
            onSourceSelected(id);
          },
        );
      },
    );
  }
}

// ─── Switcher Grid ────────────────────────────────────────────────────────────

class _SwitcherGrid extends StatelessWidget {
  final List<_SwitcherSource> sources;
  final String activeId;
  final ValueChanged<String> onSourceSelected;

  const _SwitcherGrid({
    required this.sources,
    required this.activeId,
    required this.onSourceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final count = sources.length;
    final crossAxis = count <= 2
        ? count
        : count <= 4
            ? 2
            : 3;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'DIRECTOR — SELECT CAMERA',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxis,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 16 / 9,
            ),
            itemCount: sources.length,
            itemBuilder: (ctx, i) {
              final src = sources[i];
              final isActive = src.id == activeId;
              return _SourcePreview(
                source: src,
                isActive: isActive,
                onTap: () => onSourceSelected(src.id),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Individual Source Preview ────────────────────────────────────────────────

class _SourcePreview extends StatelessWidget {
  final _SwitcherSource source;
  final bool isActive;
  final VoidCallback onTap;

  const _SourcePreview({
    required this.source,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.red : Colors.white.withValues(alpha: 0.15),
            width: isActive ? 2.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Preview placeholder (actual camera preview would use RTCVideoRenderer
            // or CameraPreview; using icon+gradient for non-active sources)
            _buildPreviewContent(),

            // Bottom label
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(7)),
                ),
                child: Row(
                  children: [
                    if (isActive)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        source.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isActive)
                      const Text(
                        'PGM',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (source.isBuiltIn) {
      return Container(
        color: const Color(0xFF1A1A2E),
        child: const Center(
          child: Icon(
            Icons.camera_alt_rounded,
            color: Colors.white30,
            size: 24,
          ),
        ),
      );
    }
    if (source.isScreenShare) {
      return Container(
        color: const Color(0xFF1E0A3C),
        child: const Center(
          child: Icon(
            Icons.screen_share_rounded,
            color: Colors.purpleAccent,
            size: 24,
          ),
        ),
      );
    }
    // Remote camera — show device icon
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.phone_android_rounded,
              color: Colors.white30,
              size: 18,
            ),
            const SizedBox(height: 2),
            Text(
              source.castDevice?.protocolLabel ?? '',
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

