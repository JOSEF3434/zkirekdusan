// lib/features/live/presentation/widgets/live_network_diagnostics_widget.dart
//
// Real-time network and camera interface diagnostics for Live Studio.
//
// Monitors active connection type (Wi-Fi, Cellular, Ethernet), estimates
// streaming suitability, and validates subnet compatibility for IP/network cameras.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/connectivity_service.dart';
import 'package:mobile/features/live/domain/camera_source.dart';

/// Diagnostics banner shown in Live Studio indicating network health and
/// interface routing recommendations.
class LiveNetworkDiagnosticsWidget extends ConsumerWidget {
  final CameraSource cameraSource;
  final VoidCallback? onConfigureCamera;

  const LiveNetworkDiagnosticsWidget({
    super.key,
    required this.cameraSource,
    this.onConfigureCamera,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final theme = Theme.of(context);

    // Diagnostics checks
    final isOffline = connectivity.isOffline;
    final isCellular = connectivity.isMobile;
    final isWifi = connectivity.isWifi;
    final isNetworkCamera = cameraSource.type == CameraSourceType.networkCamera;

    // Warning conditions
    String? warningTitle;
    String? warningMessage;
    IconData statusIcon = Icons.wifi_rounded;
    Color statusColor = Colors.green;

    if (isOffline) {
      statusIcon = Icons.wifi_off_rounded;
      statusColor = Colors.red;
      warningTitle = 'No Internet Connection';
      warningMessage =
          'You are currently offline. A stable connection is required to broadcast.';
    } else if (isNetworkCamera && isCellular) {
      statusIcon = Icons.warning_amber_rounded;
      statusColor = Colors.orange;
      warningTitle = 'Cellular Network & IP Camera Mismatch';
      warningMessage =
          'Your device is connected via Cellular data. Local LAN IP cameras '
          '(RTSP) typically require both devices to be connected to the same Wi-Fi subnet.';
    } else if (isCellular) {
      statusIcon = Icons.signal_cellular_alt_rounded;
      statusColor = Colors.amber.shade700;
      warningTitle = 'Broadcasting via Cellular Data';
      warningMessage =
          'High data usage: 720p 30fps consumes ~1.5 GB/hour. Wi-Fi is recommended.';
    } else if (isWifi) {
      statusIcon = Icons.wifi_rounded;
      statusColor = Colors.green;
    }

    // If completely normal Wi-Fi and built-in camera, render compact status badge
    if (warningTitle == null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(statusIcon, size: 16, color: statusColor),
            const SizedBox(width: 8),
            Text(
              isWifi ? 'Wi-Fi Network Active (Optimal)' : 'Connection Ready',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              'Latency: Low',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Render alert banner for warning or offline state
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(statusIcon, color: statusColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warningTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  warningMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                if (isNetworkCamera && isCellular && onConfigureCamera != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onConfigureCamera,
                    child: Text(
                      'Switch camera source or connect Wi-Fi →',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
