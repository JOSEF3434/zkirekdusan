// lib/features/live/presentation/widgets/external_device_connection_sheet.dart
//
// Dedicated External Device Connection Manager UI for Zekre Kedusan Live Studio.
//
// Provides:
//  • Unified connection lifecycle banner (Disconnected → Discovering → Available →
//    Connecting → Connected → Stream Ready → Streaming → Error)
//  • Simple vs Pro Broadcaster view toggle
//  • Auto-discovery & "Scan Again" across USB/UVC/HDMI/SDI, Bluetooth/BLE,
//    Remote Wireless Cameras, LAN/DLNA receivers, and Saved devices
//  • Manual setup for RTSP IP Cameras, RTMP Encoders, and SRT Encoders
//  • Resolution, FPS, and Audio Input selector
//  • Real "Test Video Feed", "Test Audio", "Pair", "Reconnect", and "Forget" actions
//  • Honest platform capability, USB-C UVC vs non-UVC guidance, and 5-mode
//    recording equipment capability matrix

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:mobile/features/live/data/external_device_manager.dart';
import 'package:mobile/features/live/domain/camera_source.dart';
import 'package:mobile/features/live/domain/external_device.dart';
import 'package:mobile/features/live/presentation/providers/external_device_provider.dart';

class ExternalDeviceConnectionSheet extends ConsumerStatefulWidget {
  final String? streamId;
  final CameraSource currentSource;
  final ValueChanged<CameraSource> onSelectSource;

  const ExternalDeviceConnectionSheet({
    super.key,
    this.streamId,
    required this.currentSource,
    required this.onSelectSource,
  });

  static Future<CameraSource?> show(
    BuildContext context, {
    String? streamId,
    required CameraSource currentSource,
  }) {
    return showModalBottomSheet<CameraSource>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        expand: false,
        builder: (_, scrollCtrl) => ExternalDeviceConnectionSheet(
          streamId: streamId,
          currentSource: currentSource,
          onSelectSource: (src) => Navigator.pop(ctx, src),
        ),
      ),
    );
  }

  @override
  ConsumerState<ExternalDeviceConnectionSheet> createState() =>
      _ExternalDeviceConnectionSheetState();
}

class _ExternalDeviceConnectionSheetState
    extends ConsumerState<ExternalDeviceConnectionSheet> {
  bool _proMode = false;
  ExternalDeviceKind _manualKind = ExternalDeviceKind.ipCameraRtsp;

  final _nameCtrl = TextEditingController();
  final _endpointCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '554');
  final _userCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  final _srtStreamIdCtrl = TextEditingController();
  String _rtspTransport = 'tcp';
  String _srtMode = 'caller';
  final int _srtLatencyMs = 200;
  final int _rtmpBitrateKbps = 3500;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(externalDeviceManagerProvider.notifier).discoverDevices();
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _endpointCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _secretCtrl.dispose();
    _srtStreamIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(externalDeviceManagerProvider);
    final manager = ref.read(externalDeviceManagerProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.settings_input_component_rounded,
                      color: cs.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'External Device Manager',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: state.managerState.color(context),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            state.managerState.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: state.managerState.color(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                FilterChip(
                  label: Text(_proMode ? 'Pro' : 'Simple',
                      style: const TextStyle(fontSize: 11)),
                  selected: _proMode,
                  onSelected: (v) => setState(() => _proMode = v),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Scan Again',
                  onPressed: state.isScanning ? null : () => manager.scanAgain(),
                  icon: state.isScanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (state.permissionGuidance != null)
                  _AlertCard(
                    icon: Icons.lock_open_rounded,
                    color: Colors.orange,
                    title: 'Permission Needed',
                    message: state.permissionGuidance!,
                    actionLabel: 'Settings',
                    onAction: () => openAppSettings(),
                  ),

                if (_statusMessage != null)
                  _AlertCard(
                    icon: Icons.info_outline_rounded,
                    color: cs.primary,
                    title: 'Device Status',
                    message: _statusMessage!,
                    actionLabel: 'Dismiss',
                    onAction: () => setState(() => _statusMessage = null),
                  ),

                // Video Format & Audio Selection
                _FormatAndAudioCard(
                  state: state,
                  proMode: _proMode,
                  onResolutionChanged: (w, h) => manager.configureFormat(
                    width: w,
                    height: h,
                    fps: state.targetFps,
                  ),
                  onFpsChanged: (fps) => manager.configureFormat(
                    width: state.targetWidth,
                    height: state.targetHeight,
                    fps: fps,
                  ),
                  onAudioChanged: (id) => manager.selectAudioSource(id),
                ),

                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      'Detected & Saved Devices (${state.devices.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: state.isScanning
                          ? () => manager.cancelDiscovery()
                          : () => manager.scanAgain(),
                      icon: Icon(
                        state.isScanning
                            ? Icons.stop_circle_outlined
                            : Icons.radar_rounded,
                        size: 16,
                      ),
                      label: Text(state.isScanning ? 'Stop Scan' : 'Scan Again'),
                    ),
                  ],
                ),

                if (state.devices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No external devices detected yet. Connect a USB/HDMI/SDI '
                        'capture card, pair a Bluetooth device, or add one manually below.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...state.devices.map(
                    (dev) => _DeviceCard(
                      device: dev,
                      isSelected: state.selectedVideoDeviceId == dev.id,
                      proMode: _proMode,
                      onConnect: () async {
                        final ok = await manager.connectDevice(
                          dev.id,
                          streamId: widget.streamId,
                        );
                        if (mounted && !ok) {
                          setState(() => _statusMessage =
                              'Could not connect ${dev.name}. Check card details.');
                        }
                      },
                      onDisconnect: () => manager.disconnectDevice(
                        dev.id,
                        streamId: widget.streamId,
                      ),
                      onPair: () => manager.pairDevice(dev.id),
                      onTestVideo: () => manager.testVideoFeed(
                        dev.id,
                        streamId: widget.streamId,
                      ),
                      onTestAudio: () => manager.testAudio(dev.id),
                      onForget: () => manager.removeOrForgetDevice(dev.id),
                      onSelectAsSource: dev.capabilities.hasVideoInput &&
                              dev.kind != ExternalDeviceKind.nonUvcUsbDevice
                          ? () {
                              manager.selectVideoSource(dev.id);
                              final source = manager.toCameraSource(dev);
                              if (source != null) {
                                widget.onSelectSource(source);
                              }
                            }
                          : null,
                    ),
                  ),

                // Manual Network / Encoder Configuration (Pro Mode or Expandable)
                const SizedBox(height: 16),
                ExpansionTile(
                  initiallyExpanded: _proMode,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  leading: const Icon(Icons.add_link_rounded),
                  title: const Text(
                    'Add Network Camera or Encoder Manually',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'RTSP IP Camera, External RTMP Encoder, or SRT Encoder',
                    style: TextStyle(fontSize: 12),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                      child: _buildManualForm(theme, manager),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                _PlatformCompatibilitySection(caps: state.capabilities),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualForm(ThemeData theme, ExternalDeviceManager manager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<ExternalDeviceKind>(
          segments: const [
            ButtonSegment(
              value: ExternalDeviceKind.ipCameraRtsp,
              label: Text('RTSP'),
            ),
            ButtonSegment(
              value: ExternalDeviceKind.externalRtmpEncoder,
              label: Text('RTMP'),
            ),
            ButtonSegment(
              value: ExternalDeviceKind.externalSrtEncoder,
              label: Text('SRT'),
            ),
          ],
          selected: {_manualKind},
          onSelectionChanged: (s) {
            setState(() {
              _manualKind = s.first;
              _portCtrl.text = switch (_manualKind) {
                ExternalDeviceKind.ipCameraRtsp => '554',
                ExternalDeviceKind.externalSrtEncoder => '9000',
                _ => '1935',
              };
            });
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: 'Device / Camera Name',
            hintText: switch (_manualKind) {
              ExternalDeviceKind.ipCameraRtsp => 'Sanctuary PTZ Camera',
              ExternalDeviceKind.externalSrtEncoder => 'Field SRT Encoder',
              _ => 'ATEM Mini / OBS Studio',
            },
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _endpointCtrl,
          decoration: InputDecoration(
            labelText: switch (_manualKind) {
              ExternalDeviceKind.ipCameraRtsp => 'RTSP URL',
              ExternalDeviceKind.externalSrtEncoder => 'SRT Host / IP',
              _ => 'Custom RTMP Server URL (optional)',
            },
            hintText: switch (_manualKind) {
              ExternalDeviceKind.ipCameraRtsp => 'rtsp://192.168.1.50:554/live',
              ExternalDeviceKind.externalSrtEncoder => '192.168.1.80',
              _ => 'rtmp://live.cloudinary.com/streams',
            },
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _portCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_manualKind == ExternalDeviceKind.ipCameraRtsp)
              Expanded(
                flex: 2,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'tcp', label: Text('TCP')),
                    ButtonSegment(value: 'udp', label: Text('UDP')),
                  ],
                  selected: {_rtspTransport},
                  onSelectionChanged: (s) =>
                      setState(() => _rtspTransport = s.first),
                ),
              )
            else if (_manualKind == ExternalDeviceKind.externalSrtEncoder)
              Expanded(
                flex: 2,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'caller', label: Text('Caller')),
                    ButtonSegment(value: 'listener', label: Text('Listener')),
                  ],
                  selected: {_srtMode},
                  onSelectionChanged: (s) => setState(() => _srtMode = s.first),
                ),
              ),
          ],
        ),
        if (_manualKind == ExternalDeviceKind.ipCameraRtsp ||
            _manualKind == ExternalDeviceKind.externalSrtEncoder) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (_manualKind == ExternalDeviceKind.ipCameraRtsp) ...[
                Expanded(
                  child: TextField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username (optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextField(
                  controller: _secretCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _manualKind == ExternalDeviceKind.ipCameraRtsp
                        ? 'Password (memory only)'
                        : 'SRT Passphrase (memory only)',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (_manualKind == ExternalDeviceKind.externalSrtEncoder) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _srtStreamIdCtrl,
            decoration: const InputDecoration(
              labelText: 'SRT Stream ID (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () async {
              final ep = _endpointCtrl.text.trim();
              if (_manualKind == ExternalDeviceKind.ipCameraRtsp &&
                  !NetworkCameraSource.isValidRtspUrl(ep)) {
                setState(() => _statusMessage =
                    'Enter a valid rtsp:// or rtsps:// URL.');
                return;
              }
              final port = int.tryParse(_portCtrl.text.trim()) ?? 554;
              final dev = await manager.addOrUpdateManualDevice(
                kind: _manualKind,
                name: _nameCtrl.text.trim().isEmpty
                    ? _manualKind.name
                    : _nameCtrl.text.trim(),
                endpoint: ep,
                secret: _secretCtrl.text.trim(),
                metadata: {
                  'port': port,
                  if (_manualKind == ExternalDeviceKind.ipCameraRtsp)
                    'transport': _rtspTransport,
                  if (_userCtrl.text.trim().isNotEmpty)
                    'username': _userCtrl.text.trim(),
                  if (_manualKind == ExternalDeviceKind.externalSrtEncoder) ...{
                    'mode': _srtMode,
                    'latencyMs': _srtLatencyMs,
                    if (_srtStreamIdCtrl.text.trim().isNotEmpty)
                      'streamId': _srtStreamIdCtrl.text.trim(),
                  },
                  if (_manualKind == ExternalDeviceKind.externalRtmpEncoder)
                    'bitrateKbps': _rtmpBitrateKbps,
                },
              );
              await manager.connectDevice(dev.id, streamId: widget.streamId);
              if (mounted) {
                setState(() => _statusMessage =
                    'Saved "${dev.name}" and tested connection.');
              }
            },
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Save & Test Connection'),
          ),
        ),
      ],
    );
  }
}

class _FormatAndAudioCard extends StatelessWidget {
  final ExternalDeviceManagerState state;
  final bool proMode;
  final void Function(int w, int h) onResolutionChanged;
  final ValueChanged<int> onFpsChanged;
  final ValueChanged<String?> onAudioChanged;

  const _FormatAndAudioCard({
    required this.state,
    required this.proMode,
    required this.onResolutionChanged,
    required this.onFpsChanged,
    required this.onAudioChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stream Video & Audio Input Settings',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 720, label: Text('720p')),
                    ButtonSegment(value: 1080, label: Text('1080p')),
                  ],
                  selected: {state.targetHeight == 1080 ? 1080 : 720},
                  onSelectionChanged: (s) {
                    final h = s.first;
                    onResolutionChanged(h == 1080 ? 1920 : 1280, h);
                  },
                ),
              ),
              if (proMode) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 30, label: Text('30 fps')),
                      ButtonSegment(value: 60, label: Text('60 fps')),
                    ],
                    selected: {state.targetFps == 60 ? 60 : 30},
                    onSelectionChanged: (s) => onFpsChanged(s.first),
                  ),
                ),
              ],
            ],
          ),
          if (state.audioInputs.isNotEmpty) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<String?>(
              initialValue: state.audioInputs
                      .any((a) => a.id == state.selectedAudioInputId)
                  ? state.selectedAudioInputId
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Audio Input Source',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('System Default Microphone'),
                ),
                ...state.audioInputs.map(
                  (a) => DropdownMenuItem<String?>(
                    value: a.id,
                    child: Text('${a.name} (${a.kind.toUpperCase()})',
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: onAudioChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final ExternalDevice device;
  final bool isSelected;
  final bool proMode;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onPair;
  final VoidCallback onTestVideo;
  final VoidCallback onTestAudio;
  final VoidCallback onForget;
  final VoidCallback? onSelectAsSource;

  const _DeviceCard({
    required this.device,
    required this.isSelected,
    required this.proMode,
    required this.onConnect,
    required this.onDisconnect,
    required this.onPair,
    required this.onTestVideo,
    required this.onTestAudio,
    required this.onForget,
    this.onSelectAsSource,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusColor = device.connectionState.color(context);
    final isActive = device.connectionState.isActiveConnection;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected
              ? cs.primary
              : device.connectionState == ExternalConnectionState.error
                  ? cs.error.withValues(alpha: 0.6)
                  : cs.outlineVariant.withValues(alpha: 0.4),
          width: isSelected ? 1.6 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.14),
                  child: Icon(device.icon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${device.kindLabel} • ${device.connectionMethod.label}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    device.connectionState.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (proMode ||
                device.diagnostics.batteryPercent != null ||
                device.diagnostics.videoTestSummary != null ||
                device.lastError != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (device.capabilities.supportedVideoFormats.isNotEmpty)
                    _MiniSpec(device.capabilities.supportedVideoFormats.first),
                  if (device.capabilities.supportedResolutions.isNotEmpty)
                    _MiniSpec(device.capabilities.supportedResolutions.first),
                  if (device.capabilities.supportedFps.isNotEmpty)
                    _MiniSpec('${device.capabilities.supportedFps.join('/')} fps'),
                  _MiniSpec(device.capabilities.hasAudioInput
                      ? 'Audio: Yes'
                      : 'Audio: None'),
                  if (device.diagnostics.batteryPercent != null)
                    _MiniSpec('Battery: ${device.diagnostics.batteryPercent}%'),
                  if (device.diagnostics.latencyMs != null)
                    _MiniSpec('${device.diagnostics.latencyMs} ms'),
                ],
              ),
            ],
            if (device.diagnostics.videoTestSummary != null) ...[
              const SizedBox(height: 6),
              Text(
                device.diagnostics.videoTestSummary!,
                style: TextStyle(
                  fontSize: 11,
                  color: device.diagnostics.videoFeedVerified == true
                      ? Colors.green.shade700
                      : cs.onSurfaceVariant,
                ),
              ),
            ],
            if (device.diagnostics.audioTestSummary != null) ...[
              const SizedBox(height: 2),
              Text(
                device.diagnostics.audioTestSummary!,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
            if (device.lastError != null) ...[
              const SizedBox(height: 6),
              Text(
                device.lastError!,
                style: TextStyle(fontSize: 11, color: cs.error),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (!isActive)
                  FilledButton.tonal(
                    onPressed: onConnect,
                    child: Text(
                      device.isSaved ? 'Reconnect' : 'Connect',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )
                else
                  OutlinedButton(
                    onPressed: onDisconnect,
                    child: const Text('Disconnect', style: TextStyle(fontSize: 12)),
                  ),
                if (device.capabilities.requiresUsbPermission &&
                    !device.isUsbPermissionGranted)
                  OutlinedButton(
                    onPressed: onPair,
                    child: const Text('Grant USB', style: TextStyle(fontSize: 12)),
                  ),
                if (device.capabilities.hasVideoInput &&
                    device.kind != ExternalDeviceKind.nonUvcUsbDevice)
                  OutlinedButton(
                    onPressed: onTestVideo,
                    child: const Text('Test Video', style: TextStyle(fontSize: 12)),
                  ),
                if (proMode)
                  OutlinedButton(
                    onPressed: onTestAudio,
                    child: const Text('Test Audio', style: TextStyle(fontSize: 12)),
                  ),
                if (onSelectAsSource != null)
                  FilledButton(
                    onPressed: onSelectAsSource,
                    child: Text(
                      isSelected ? 'Active Source' : 'Use Video Source',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                if (device.isSaved)
                  TextButton(
                    onPressed: onForget,
                    child: Text(
                      'Forget',
                      style: TextStyle(fontSize: 12, color: cs.error),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniSpec extends StatelessWidget {
  final String text;
  const _MiniSpec(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10)),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _AlertCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: color, fontSize: 12)),
                Text(message, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _PlatformCompatibilitySection extends StatelessWidget {
  final PlatformConnectivityCapabilities caps;
  const _PlatformCompatibilitySection({required this.caps});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform Support (${caps.platform.toUpperCase()})',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 6),
          if (caps.usbNote != null)
            Text('• Wired / USB: ${caps.usbNote}', style: const TextStyle(fontSize: 11)),
          if (caps.bluetoothNote != null)
            Text('• Bluetooth: ${caps.bluetoothNote}', style: const TextStyle(fontSize: 11)),
          if (caps.networkNote != null)
            Text('• Network: ${caps.networkNote}', style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
