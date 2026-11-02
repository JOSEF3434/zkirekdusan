// lib/features/live/presentation/widgets/cast_device_tile.dart
//
// A single cast-device row used inside CastPanelWidget and the director grid.
// Shows icon, name, protocol badge, signal strength, status dot, and actions.

import 'package:flutter/material.dart';
import 'package:mobile/features/live/domain/cast_device.dart';

class CastDeviceTile extends StatelessWidget {
  final CastDevice device;
  final bool isActiveSource;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;
  final VoidCallback? onSetActive;
  final bool showSetActiveButton;

  const CastDeviceTile({
    super.key,
    required this.device,
    this.isActiveSource = false,
    this.onConnect,
    this.onDisconnect,
    this.onSetActive,
    this.showSetActiveButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isConnected = device.status == CastSessionStatus.connected;
    final isPairing = device.status == CastSessionStatus.pairing;
    final isError = device.status == CastSessionStatus.error;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isActiveSource
            ? cs.primaryContainer.withValues(alpha: 0.4)
            : cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActiveSource
              ? cs.primary
              : isConnected
                  ? Colors.green.withValues(alpha: 0.5)
                  : cs.outlineVariant.withValues(alpha: 0.4),
          width: isActiveSource ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // ── Device icon with status ring ──────────────────────────────
            Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isActiveSource
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    device.icon,
                    color: isActiveSource ? cs.primary : cs.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                // Status dot
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: device.statusColor(context),
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.surface, width: 2),
                    ),
                    child: isPairing
                        ? const _PulsingDot()
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // ── Name, model, protocol badge ───────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          device.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isActiveSource ? cs.primary : cs.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isActiveSource) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ON AIR',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: cs.onPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      // Protocol badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _protocolColor(device.protocol)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          device.protocolLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _protocolColor(device.protocol),
                          ),
                        ),
                      ),
                      if (device.model != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '· ${device.model}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                      // Signal strength
                      if (device.signalStrength != null) ...[
                        const SizedBox(width: 6),
                        _SignalBars(strength: device.signalStrength!),
                      ],
                    ],
                  ),
                  if (device.status != CastSessionStatus.discovered) ...[
                    const SizedBox(height: 2),
                    Text(
                      device.statusLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: device.statusColor(context),
                      ),
                    ),
                  ],
                  if (isError && device.lastError != null)
                    Text(
                      device.lastError!,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: cs.error),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // ── Action buttons ────────────────────────────────────────────
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isConnected && !isPairing)
                  _ActionChip(
                    label: 'Connect',
                    color: cs.primary,
                    onTap: onConnect,
                  ),
                if (isConnected) ...[
                  if (showSetActiveButton && !isActiveSource)
                    _ActionChip(
                      label: 'Go Live',
                      color: Colors.green,
                      onTap: onSetActive,
                    ),
                  const SizedBox(height: 4),
                  _ActionChip(
                    label: 'Disconnect',
                    color: cs.error,
                    onTap: onDisconnect,
                  ),
                ],
                if (isPairing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _protocolColor(CastProtocol p) {
    switch (p) {
      case CastProtocol.chromecast:
        return Colors.blue;
      case CastProtocol.airplay:
        return Colors.indigo;
      case CastProtocol.dlna:
        return Colors.teal;
      case CastProtocol.remotePeerCamera:
        return Colors.deepOrange;
      case CastProtocol.screenCapture:
        return Colors.purple;
      case CastProtocol.uvcUsb:
        return Colors.brown;
      case CastProtocol.hdmiCapture:
        return Colors.blueGrey;
    }
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  final int strength; // 0-100

  const _SignalBars({required this.strength});

  @override
  Widget build(BuildContext context) {
    final bars = (strength / 25).ceil().clamp(0, 4);
    final color = strength > 60
        ? Colors.green
        : strength > 30
            ? Colors.orange
            : Colors.red;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = i < bars;
        return Container(
          width: 3,
          height: 4.0 + i * 2.5,
          margin: const EdgeInsets.only(right: 1.5),
          decoration: BoxDecoration(
            color: active
                ? color
                : Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

