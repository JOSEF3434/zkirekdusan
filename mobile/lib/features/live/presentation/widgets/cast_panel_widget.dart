// lib/features/live/presentation/widgets/cast_panel_widget.dart
//
// Professional Cast Panel for the Live Studio.
//
// Sections:
//   1. Remote Cameras  — other phones/tablets paired as wireless camera inputs
//   2. Cast to TV      — Chromecast, AirPlay, DLNA smart TVs / projectors
//   3. Screen Share    — broadcast phone screen or connected external display
//   4. USB / Wired     — UVC cameras, HDMI capture cards (where available)
//
// Integrates with CastService via castDevicesProvider and CastService methods.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/live/domain/cast_device.dart';
import 'package:mobile/features/live/presentation/providers/cast_provider.dart';
import 'package:mobile/features/live/presentation/widgets/cast_device_tile.dart';

class CastPanelWidget extends ConsumerStatefulWidget {
  /// The current live stream ID (used for WebRTC signaling).
  final String streamId;

  /// HLS playback URL for TV cast (cast to TV mode).
  final String? hlsUrl;

  /// Stream title (shown on TV cast screen).
  final String streamTitle;

  /// Thumbnail for TV cast screen.
  final String? thumbnailUrl;

  const CastPanelWidget({
    super.key,
    required this.streamId,
    this.hlsUrl,
    required this.streamTitle,
    this.thumbnailUrl,
  });

  @override
  ConsumerState<CastPanelWidget> createState() => _CastPanelWidgetState();
}

class _CastPanelWidgetState extends ConsumerState<CastPanelWidget>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl =
      TabController(length: 4, vsync: this);

  bool _isScreenSharing = false;

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final devicesAsync = ref.watch(castDevicesProvider);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.tertiary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cast_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cast & Connect',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Cameras, TVs, screens and more',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Discovery status indicator
                devicesAsync.when(
                  data: (d) => _DiscoveryBadge(count: d.length),
                  loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, _) => Icon(Icons.wifi_off_rounded,
                      color: cs.error, size: 18),
                ),
                const SizedBox(width: 8),
                // Refresh
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh devices',
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => ref
                      .read(castServiceProvider)
                      .startDiscovery(),
                ),
              ],
            ),
          ),

          // ── Tab Bar ──────────────────────────────────────────────────────
          TabBar(
            controller: _tabCtrl,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            tabs: const [
              Tab(
                icon: Icon(Icons.phone_android_rounded, size: 18),
                text: 'Cameras',
              ),
              Tab(
                icon: Icon(Icons.tv_rounded, size: 18),
                text: 'TV',
              ),
              Tab(
                icon: Icon(Icons.screen_share_rounded, size: 18),
                text: 'Screen',
              ),
              Tab(
                icon: Icon(Icons.usb_rounded, size: 18),
                text: 'Wired',
              ),
            ],
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),

          // ── Tab Views ────────────────────────────────────────────────────
          SizedBox(
            height: 360,
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _RemoteCamerasTab(streamId: widget.streamId),
                _TvCastTab(
                  streamId: widget.streamId,
                  hlsUrl: widget.hlsUrl,
                  streamTitle: widget.streamTitle,
                  thumbnailUrl: widget.thumbnailUrl,
                ),
                _ScreenShareTab(
                  isSharing: _isScreenSharing,
                  onToggle: _toggleScreenShare,
                ),
                const _WiredTab(),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _toggleScreenShare() async {
    final service = ref.read(castServiceProvider);
    if (_isScreenSharing) {
      final stream = ref.read(screenShareStreamProvider);
      if (stream != null) service.stopScreenShare(stream);
      ref.read(screenShareStreamProvider.notifier).state = null;
      setState(() => _isScreenSharing = false);
    } else {
      final stream = await service.startScreenShare();
      if (stream != null && mounted) {
        ref.read(screenShareStreamProvider.notifier).state = stream;
        setState(() => _isScreenSharing = true);
      }
    }
  }
}

// ─── Remote Cameras Tab ───────────────────────────────────────────────────────

class _RemoteCamerasTab extends ConsumerWidget {
  final String streamId;
  const _RemoteCamerasTab({required this.streamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(castDevicesProvider);
    final activeSourceId = ref.watch(activeCastSourceIdProvider);

    return devicesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (devices) {
        final cameras = devices
            .where((d) => d.type == CastDeviceType.remoteCamera)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── How to add a remote camera ────────────────────────────
              _InfoBanner(
                icon: Icons.qr_code_scanner_rounded,
                message:
                    'Open the app on another phone → tap Live → "Use as Camera". '
                    'Both devices must be on the same network or internet.',
                color: Colors.deepOrange,
              ),
              const SizedBox(height: 12),

              if (cameras.isEmpty)
                _EmptyState(
                  icon: Icons.phonelink_off_rounded,
                  title: 'No remote cameras found',
                  subtitle:
                      'Ask a collaborator to open the app and tap "Use as Camera"',
                )
              else
                ...cameras.map((d) {
                  final isActive = d.id == activeSourceId;
                  return CastDeviceTile(
                    device: d,
                    isActiveSource: isActive,
                    showSetActiveButton: true,
                    onConnect: d.status == CastSessionStatus.discovered
                        ? () => ref.read(castServiceProvider).connectRemoteCamera(
                              streamId: streamId,
                              device: d,
                            )
                        : null,
                    onDisconnect: () => ref
                        .read(castServiceProvider)
                        .disconnectRemoteCamera(d.id),
                    onSetActive: () => ref
                        .read(activeCastSourceIdProvider.notifier)
                        .state = d.id,
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

// ─── TV Cast Tab ──────────────────────────────────────────────────────────────

class _TvCastTab extends ConsumerWidget {
  final String streamId;
  final String? hlsUrl;
  final String streamTitle;
  final String? thumbnailUrl;

  const _TvCastTab({
    required this.streamId,
    this.hlsUrl,
    required this.streamTitle,
    this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(castDevicesProvider);
    final activeTvId = ref.watch(activeTvCastDeviceIdProvider);
    final service = ref.read(castServiceProvider);

    return devicesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (devices) {
        final tvDevices =
            devices.where((d) => d.type == CastDeviceType.smartTv).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              _InfoBanner(
                icon: Icons.cast_connected_rounded,
                message:
                    'Cast the live stream to any Chromecast, AirPlay-compatible TV, '
                    'or DLNA renderer on your network.',
                color: Colors.blue,
              ),
              const SizedBox(height: 12),

              // ── AirPlay native picker (iOS/macOS only) ────────────────
              _AirPlayButton(),
              const SizedBox(height: 8),

              if (tvDevices.isEmpty)
                _EmptyState(
                  icon: Icons.tv_off_rounded,
                  title: 'No TVs or displays found',
                  subtitle:
                      'Ensure your TV supports Chromecast or DLNA and is on the same Wi-Fi network',
                )
              else
                ...tvDevices.map((d) {
                  final isActive = d.id == activeTvId;
                  return CastDeviceTile(
                    device: d,
                    isActiveSource: isActive,
                    onConnect: hlsUrl != null &&
                            d.status == CastSessionStatus.discovered
                        ? () async {
                            await service.castToTv(
                              device: d,
                              hlsUrl: hlsUrl!,
                              streamTitle: streamTitle,
                              thumbnailUrl: thumbnailUrl,
                            );
                            ref
                                .read(activeTvCastDeviceIdProvider.notifier)
                                .state = d.id;
                          }
                        : null,
                    onDisconnect: () async {
                      await service.stopTvCast(d);
                      if (activeTvId == d.id) {
                        ref
                            .read(activeTvCastDeviceIdProvider.notifier)
                            .state = null;
                      }
                    },
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

// ─── Screen Share Tab ─────────────────────────────────────────────────────────

class _ScreenShareTab extends StatelessWidget {
  final bool isSharing;
  final VoidCallback onToggle;

  const _ScreenShareTab({required this.isSharing, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          // Animated share illustration
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSharing
                    ? [Colors.purple.shade700, Colors.deepPurple.shade900]
                    : [
                        cs.surfaceContainerHighest,
                        cs.surfaceContainerHighest.withValues(alpha: 0.6),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSharing
                      ? Icons.screen_share_rounded
                      : Icons.stop_screen_share_rounded,
                  size: 44,
                  color: isSharing ? Colors.white : cs.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  isSharing ? 'Screen is being shared' : 'Screen not shared',
                  style: TextStyle(
                    color: isSharing ? Colors.white : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (isSharing)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Your screen is now part of the broadcast mix',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: isSharing ? cs.error : Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onToggle,
              icon: Icon(
                isSharing
                    ? Icons.stop_screen_share_rounded
                    : Icons.screen_share_rounded,
              ),
              label: Text(
                isSharing ? 'Stop Sharing Screen' : 'Share My Screen',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _InfoBanner(
            icon: Icons.info_outline_rounded,
            message:
                'Share your full screen or a specific window. On Android this uses '
                'MediaProjection; on iOS it uses ReplayKit. Audio capture may require '
                'device-level permissions.',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}

// ─── Wired / USB Tab ──────────────────────────────────────────────────────────

class _WiredTab extends StatelessWidget {
  const _WiredTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          _InfoBanner(
            icon: Icons.usb_rounded,
            message:
                'Connect a UVC USB camera or HDMI capture card via a USB-C OTG '
                'adapter. Your device must support USB host mode.',
            color: Colors.brown,
          ),
          const SizedBox(height: 20),

          // Option cards
          _WiredOptionCard(
            icon: Icons.usb_rounded,
            title: 'USB Camera (UVC)',
            subtitle:
                'Plug a UVC-compatible webcam into your device via OTG adapter',
            color: Colors.brown,
            onTap: () => _showUvcDialog(context),
          ),
          const SizedBox(height: 10),
          _WiredOptionCard(
            icon: Icons.settings_input_hdmi_rounded,
            title: 'HDMI Capture Card',
            subtitle:
                'Connect an Elgato, AVerMedia or similar capture card for HDMI input',
            color: Colors.blueGrey,
            onTap: () => _showHdmiDialog(context),
          ),
          const SizedBox(height: 10),
          _WiredOptionCard(
            icon: Icons.cable_rounded,
            title: 'NDI® Source',
            subtitle: 'Receive an NDI video feed from a production switcher on LAN',
            color: Colors.deepPurple,
            onTap: () => _showNdiDialog(context),
          ),
        ],
      ),
    );
  }

  void _showUvcDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _ConfigDialog(
        title: 'USB Camera (UVC)',
        icon: Icons.usb_rounded,
        color: Colors.brown,
        content: const Text(
          'Ensure the camera is connected via a USB-C OTG adapter and your device '
          'reports USB host mode. The system will enumerate UVC-compatible devices '
          'automatically on next scan.',
        ),
      ),
    );
  }

  void _showHdmiDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _ConfigDialog(
        title: 'HDMI Capture Card',
        icon: Icons.settings_input_hdmi_rounded,
        color: Colors.blueGrey,
        content: const Text(
          'Connect your capture card via USB-C OTG. Supported cards include '
          'Elgato Cam Link, AVerMedia Live Gamer Portable and compatible UVC '
          'HDMI grabbers. The card will appear as a UVC camera device.',
        ),
      ),
    );
  }

  void _showNdiDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _ConfigDialog(
        title: 'NDI® Source',
        icon: Icons.cable_rounded,
        color: Colors.deepPurple,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'NDI® (Network Device Interface) allows zero-latency video over LAN. '
              'Ensure the NDI SDK plugin is enabled and both devices are on the same subnet.',
            ),
            SizedBox(height: 10),
            Text(
              '• Ensure NDI Tools is installed on the source device\n'
              '• Both devices must share the same Wi-Fi subnet\n'
              '• Firewall rules must allow UDP 5960-5970',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helper widgets ───────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _InfoBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DiscoveryBadge extends StatelessWidget {
  final int count;
  const _DiscoveryBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _WiredOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _WiredOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

class _AirPlayButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // On non-Apple platforms this is a no-op tile shown for discovery.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.airplay_rounded, color: Colors.indigo, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AirPlay',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.indigo,
                  ),
                ),
                Text(
                  'Mirror to Apple TV or AirPlay-compatible display',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.indigo.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            onPressed: () {
              const MethodChannel('com.zkirekdusan/cast_airplay')
                  .invokeMethod('presentRoutePickerWithUrl', {'url': ''})
                  .catchError((_) {});
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }
}

class _ConfigDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget content;

  const _ConfigDialog({
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(title),
        ],
      ),
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Static method to open the cast panel as a modal bottom sheet.
Future<void> showCastPanel(
  BuildContext context, {
  required String streamId,
  String? hlsUrl,
  required String streamTitle,
  String? thumbnailUrl,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollCtrl) => CastPanelWidget(
        streamId: streamId,
        hlsUrl: hlsUrl,
        streamTitle: streamTitle,
        thumbnailUrl: thumbnailUrl,
      ),
    ),
  );
}

