// lib/features/live/presentation/widgets/camera_source_picker_sheet.dart
//
// Interactive bottom sheet for selecting and configuring camera / encoder sources.
// Supports built-in cameras, USB UVC / HDMI / SDI capture hardware, wireless
// camera systems, RTSP IP cameras, external RTMP/SRT encoders, and screen share.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/live/data/external_device_manager.dart';
import 'package:mobile/features/live/domain/camera_source.dart';
import 'package:mobile/features/live/domain/external_device.dart';
import 'package:mobile/features/live/presentation/providers/external_device_provider.dart';
import 'package:mobile/features/live/presentation/widgets/external_device_connection_sheet.dart';

class CameraSourcePickerSheet extends ConsumerStatefulWidget {
  final CameraSource initialSource;
  final String? streamId;
  final ValueChanged<CameraSource> onSourceSelected;

  const CameraSourcePickerSheet({
    super.key,
    required this.initialSource,
    this.streamId,
    required this.onSourceSelected,
  });

  static Future<CameraSource?> show(
    BuildContext context, {
    required CameraSource initialSource,
    String? streamId,
  }) {
    return showModalBottomSheet<CameraSource>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CameraSourcePickerSheet(
        initialSource: initialSource,
        streamId: streamId,
        onSourceSelected: (source) => Navigator.pop(ctx, source),
      ),
    );
  }

  @override
  ConsumerState<CameraSourcePickerSheet> createState() =>
      _CameraSourcePickerSheetState();
}

class _CameraSourcePickerSheetState
    extends ConsumerState<CameraSourcePickerSheet> {
  late CameraSourceType _selectedType;

  // Built-in camera config
  late bool _isFrontCamera;
  late int _resolutionHeight;
  late int _targetFps;

  // Wired capture config (USB UVC / HDMI / SDI)
  late TextEditingController _wiredNameCtrl;
  String? _selectedWiredDeviceId;

  // External encoder config
  late TextEditingController _encoderNameCtrl;
  late TextEditingController _customRtmpUrlCtrl;
  late int _encoderBitrateKbps;

  // Network IP camera (RTSP) config
  late TextEditingController _rtspUrlCtrl;
  late RtspTransport _rtspTransport;
  late TextEditingController _rtspPortCtrl;
  late TextEditingController _rtspUserCtrl;
  late TextEditingController _rtspPassCtrl;

  // SRT encoder config
  late TextEditingController _srtHostCtrl;
  late TextEditingController _srtPortCtrl;
  late TextEditingController _srtLatencyCtrl;
  late SrtMode _srtMode;
  late TextEditingController _srtStreamIdCtrl;
  late TextEditingController _srtPassphraseCtrl;

  String? _validationError;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialSource.type;

    if (widget.initialSource is BuiltInCameraSource) {
      final s = widget.initialSource as BuiltInCameraSource;
      _isFrontCamera = s.isFront;
      _resolutionHeight = s.resolutionHeight;
      _targetFps = s.targetFps;
    } else if (widget.initialSource is WiredCaptureCameraSource) {
      final s = widget.initialSource as WiredCaptureCameraSource;
      _isFrontCamera = false;
      _resolutionHeight = s.resolutionHeight;
      _targetFps = s.targetFps;
    } else {
      _isFrontCamera = true;
      _resolutionHeight = 720;
      _targetFps = 30;
    }

    if (widget.initialSource is WiredCaptureCameraSource) {
      final s = widget.initialSource as WiredCaptureCameraSource;
      _wiredNameCtrl = TextEditingController(text: s.deviceName);
      _selectedWiredDeviceId = s.deviceId;
    } else {
      _wiredNameCtrl = TextEditingController();
    }

    if (widget.initialSource is ExternalEncoderSource) {
      final s = widget.initialSource as ExternalEncoderSource;
      _encoderNameCtrl = TextEditingController(text: s.encoderName);
      _customRtmpUrlCtrl = TextEditingController(text: s.customRtmpUrl ?? '');
      _encoderBitrateKbps = s.recommendedBitrateKbps;
    } else {
      _encoderNameCtrl = TextEditingController(text: 'OBS / ATEM Mini');
      _customRtmpUrlCtrl = TextEditingController();
      _encoderBitrateKbps = 3500;
    }

    if (widget.initialSource is NetworkCameraSource) {
      final s = widget.initialSource as NetworkCameraSource;
      _rtspUrlCtrl = TextEditingController(text: s.rtspUrl);
      _rtspTransport = s.transport;
      _rtspPortCtrl = TextEditingController(text: s.port.toString());
      _rtspUserCtrl = TextEditingController(text: s.username ?? '');
      _rtspPassCtrl = TextEditingController(text: s.password ?? '');
    } else {
      _rtspUrlCtrl = TextEditingController();
      _rtspTransport = RtspTransport.tcp;
      _rtspPortCtrl = TextEditingController(text: '554');
      _rtspUserCtrl = TextEditingController();
      _rtspPassCtrl = TextEditingController();
    }

    if (widget.initialSource is SrtEncoderSource) {
      final s = widget.initialSource as SrtEncoderSource;
      _srtHostCtrl = TextEditingController(text: s.host);
      _srtPortCtrl = TextEditingController(text: s.port.toString());
      _srtLatencyCtrl = TextEditingController(text: s.latencyMs.toString());
      _srtMode = s.mode;
      _srtStreamIdCtrl = TextEditingController(text: s.streamId ?? '');
      _srtPassphraseCtrl = TextEditingController(text: s.passphrase ?? '');
    } else {
      _srtHostCtrl = TextEditingController();
      _srtPortCtrl = TextEditingController(text: '9000');
      _srtLatencyCtrl = TextEditingController(text: '200');
      _srtMode = SrtMode.caller;
      _srtStreamIdCtrl = TextEditingController();
      _srtPassphraseCtrl = TextEditingController();
    }

    Future.microtask(() {
      if (mounted) {
        ref
            .read(externalDeviceManagerProvider.notifier)
            .discoverDevices(includeBleScan: false);
      }
    });
  }

  @override
  void dispose() {
    _wiredNameCtrl.dispose();
    _encoderNameCtrl.dispose();
    _customRtmpUrlCtrl.dispose();
    _rtspUrlCtrl.dispose();
    _rtspPortCtrl.dispose();
    _rtspUserCtrl.dispose();
    _rtspPassCtrl.dispose();
    _srtHostCtrl.dispose();
    _srtPortCtrl.dispose();
    _srtLatencyCtrl.dispose();
    _srtStreamIdCtrl.dispose();
    _srtPassphraseCtrl.dispose();
    super.dispose();
  }

  void _saveSelection() {
    setState(() => _validationError = null);
    final managerState = ref.read(externalDeviceManagerProvider);
    final audioId = managerState.selectedAudioInputId;

    CameraSource finalSource;
    switch (_selectedType) {
      case CameraSourceType.builtIn:
        finalSource = BuiltInCameraSource(
          isFront: _isFrontCamera,
          resolutionWidth: _resolutionHeight == 1080 ? 1920 : 1280,
          resolutionHeight: _resolutionHeight,
          targetFps: _targetFps,
          audioDeviceId: audioId,
        );
        break;

      case CameraSourceType.usbUvcCamera:
      case CameraSourceType.hdmiCapture:
      case CameraSourceType.sdiCapture:
        final defaultLabel = switch (_selectedType) {
          CameraSourceType.hdmiCapture => 'HDMI Capture Card',
          CameraSourceType.sdiCapture => 'SDI Capture Camera',
          _ => 'USB / UVC Camera',
        };
        finalSource = WiredCaptureCameraSource(
          type: _selectedType,
          deviceId: _selectedWiredDeviceId ?? '',
          deviceName: _wiredNameCtrl.text.trim().isEmpty
              ? defaultLabel
              : _wiredNameCtrl.text.trim(),
          resolutionWidth: _resolutionHeight == 1080 ? 1920 : 1280,
          resolutionHeight: _resolutionHeight,
          targetFps: _targetFps,
          audioDeviceId: audioId,
        );
        break;

      case CameraSourceType.wirelessCamera:
        finalSource = WirelessCameraSource(
          peerDeviceId: '',
          deviceName: 'Wireless Camera System',
          resolutionWidth: _resolutionHeight == 1080 ? 1920 : 1280,
          resolutionHeight: _resolutionHeight,
          targetFps: _targetFps,
          audioDeviceId: audioId,
        );
        break;

      case CameraSourceType.screenShare:
        finalSource = ScreenShareCameraSource(
          targetFps: _targetFps,
          audioDeviceId: audioId,
        );
        break;

      case CameraSourceType.externalEncoder:
        finalSource = ExternalEncoderSource(
          encoderName: _encoderNameCtrl.text.trim().isEmpty
              ? 'External Encoder'
              : _encoderNameCtrl.text.trim(),
          customRtmpUrl: _customRtmpUrlCtrl.text.trim().isEmpty
              ? null
              : _customRtmpUrlCtrl.text.trim(),
          recommendedBitrateKbps: _encoderBitrateKbps,
          audioDeviceId: audioId,
        );
        break;

      case CameraSourceType.networkCamera:
        final url = _rtspUrlCtrl.text.trim();
        if (url.isNotEmpty && !NetworkCameraSource.isValidRtspUrl(url)) {
          setState(() {
            _validationError =
                'Invalid RTSP URL. Format: rtsp://ip:554/path';
          });
          return;
        }
        final port = int.tryParse(_rtspPortCtrl.text.trim()) ?? 554;
        finalSource = NetworkCameraSource(
          rtspUrl: url,
          transport: _rtspTransport,
          port: port,
          username: _rtspUserCtrl.text.trim().isEmpty
              ? null
              : _rtspUserCtrl.text.trim(),
          password: _rtspPassCtrl.text.trim().isEmpty
              ? null
              : _rtspPassCtrl.text.trim(),
          audioDeviceId: audioId,
        );
        break;

      case CameraSourceType.srtEncoder:
        final host = _srtHostCtrl.text.trim();
        final port = int.tryParse(_srtPortCtrl.text.trim()) ?? 9000;
        final latency = int.tryParse(_srtLatencyCtrl.text.trim()) ?? 200;
        finalSource = SrtEncoderSource(
          host: host,
          port: port,
          mode: _srtMode,
          latencyMs: latency,
          streamId: _srtStreamIdCtrl.text.trim().isEmpty
              ? null
              : _srtStreamIdCtrl.text.trim(),
          passphrase: _srtPassphraseCtrl.text.trim().isEmpty
              ? null
              : _srtPassphraseCtrl.text.trim(),
          audioDeviceId: audioId,
        );
        break;
    }

    widget.onSourceSelected(finalSource);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final deviceState = ref.watch(externalDeviceManagerProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Row(
              children: [
                Icon(
                  Icons.video_camera_back_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Video & Camera Source',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final selected = await ExternalDeviceConnectionSheet.show(
                      context,
                      streamId: widget.streamId,
                      currentSource: widget.initialSource,
                    );
                    if (selected != null && context.mounted) {
                      widget.onSourceSelected(selected);
                    }
                  },
                  icon: const Icon(Icons.usb_rounded, size: 16),
                  label: const Text('Manage Devices'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Select built-in cameras, wired USB/HDMI/SDI capture hardware, '
              'wireless cameras, RTSP IP cameras, or RTMP/SRT encoders.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),

            RadioGroup<CameraSourceType>(
              groupValue: _selectedType,
              onChanged: (v) {
                if (v != null) setState(() => _selectedType = v);
              },
              child: Column(
                children: [
                  _buildSourceOption(
                    type: CameraSourceType.builtIn,
                    title: 'Device Camera (Front / Rear)',
                    subtitle: 'Built-in camera & microphone on this device',
                    icon: Icons.camera_alt_outlined,
                    theme: theme,
                  ),
                  _buildSourceOption(
                    type: CameraSourceType.usbUvcCamera,
                    title: 'USB / UVC Camera',
                    subtitle: 'Wired UVC webcam connected via USB-C / OTG',
                    icon: Icons.usb_rounded,
                    theme: theme,
                  ),
                  _buildSourceOption(
                    type: CameraSourceType.hdmiCapture,
                    title: 'HDMI Capture Camera',
                    subtitle: 'DSLR/mirrorless/camcorder via HDMI-to-USB UVC capture',
                    icon: Icons.settings_input_hdmi_rounded,
                    theme: theme,
                  ),
                  _buildSourceOption(
                    type: CameraSourceType.sdiCapture,
                    title: 'SDI Capture Camera',
                    subtitle: 'Broadcast SDI camera via SDI-to-HDMI/USB capture',
                    icon: Icons.settings_input_component_rounded,
                    theme: theme,
                  ),
                  _buildSourceOption(
                    type: CameraSourceType.wirelessCamera,
                    title: 'Wireless Camera System',
                    subtitle: 'Paired remote phone camera or wireless WebRTC link',
                    icon: Icons.wifi_tethering_rounded,
                    theme: theme,
                  ),
                  _buildSourceOption(
                    type: CameraSourceType.screenShare,
                    title: 'Screen Share',
                    subtitle: 'Broadcast device screen or presentation window',
                    icon: Icons.screen_share_rounded,
                    theme: theme,
                  ),
                  _buildSourceOption(
                    type: CameraSourceType.externalEncoder,
                    title: 'External RTMP Encoder',
                    subtitle: 'OBS Studio, ATEM Mini, vMix, Teradek, Yolobox',
                    icon: Icons.router_rounded,
                    theme: theme,
                  ),
                  _buildSourceOption(
                    type: CameraSourceType.networkCamera,
                    title: 'IP / Network Camera (RTSP)',
                    subtitle: 'LAN/WAN PTZ or network camera streaming RTSP',
                    icon: Icons.videocam_outlined,
                    theme: theme,
                  ),
                  _buildSourceOption(
                    type: CameraSourceType.srtEncoder,
                    title: 'External SRT Encoder',
                    subtitle: 'Low-latency Secure Reliable Transport (Caller / Listener)',
                    icon: Icons.speed_rounded,
                    theme: theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            _buildDetailConfigSection(theme, deviceState),

            if (_validationError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _saveSelection,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Video Source',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required CameraSourceType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeData theme,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Radio<CameraSourceType>(value: type),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailConfigSection(
    ThemeData theme,
    ExternalDeviceManagerState deviceState,
  ) {
    switch (_selectedType) {
      case CameraSourceType.builtIn:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Camera Position & Quality',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Front'),
                        icon: Icon(Icons.camera_front_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Rear'),
                        icon: Icon(Icons.camera_rear_rounded, size: 16),
                      ),
                    ],
                    selected: {_isFrontCamera},
                    onSelectionChanged: (s) =>
                        setState(() => _isFrontCamera = s.first),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 720, label: Text('720p HD')),
                      ButtonSegment(value: 1080, label: Text('1080p FHD')),
                    ],
                    selected: {_resolutionHeight == 1080 ? 1080 : 720},
                    onSelectionChanged: (s) =>
                        setState(() => _resolutionHeight = s.first),
                  ),
                ),
              ],
            ),
          ],
        );

      case CameraSourceType.usbUvcCamera:
      case CameraSourceType.hdmiCapture:
      case CameraSourceType.sdiCapture:
        final matchingDevices = deviceState.devices.where((d) {
          if (_selectedType == CameraSourceType.hdmiCapture) {
            return d.kind == ExternalDeviceKind.hdmiCapture ||
                d.kind == ExternalDeviceKind.usbUvcCamera;
          }
          if (_selectedType == CameraSourceType.sdiCapture) {
            return d.kind == ExternalDeviceKind.sdiCapture ||
                d.kind == ExternalDeviceKind.hdmiCapture ||
                d.kind == ExternalDeviceKind.usbUvcCamera;
          }
          return d.connectionMethod == ExternalConnectionMethod.usbOtg;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wired Capture Hardware Settings',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (matchingDevices.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: matchingDevices
                        .any((d) => d.endpoint == _selectedWiredDeviceId)
                    ? _selectedWiredDeviceId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Detected Capture Device',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: matchingDevices
                    .map(
                      (d) => DropdownMenuItem<String>(
                        value: d.endpoint ?? d.id,
                        child: Text(d.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  final match = matchingDevices
                      .where((d) => (d.endpoint ?? d.id) == val)
                      .firstOrNull;
                  setState(() {
                    _selectedWiredDeviceId = val;
                    if (match != null) _wiredNameCtrl.text = match.name;
                  });
                },
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _wiredNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Capture Device Label',
                hintText: 'e.g. Elgato Cam Link 4K / Blackmagic SDI-to-USB',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 720, label: Text('720p')),
                ButtonSegment(value: 1080, label: Text('1080p')),
              ],
              selected: {_resolutionHeight == 1080 ? 1080 : 720},
              onSelectionChanged: (s) =>
                  setState(() => _resolutionHeight = s.first),
            ),
            const SizedBox(height: 8),
            Text(
              'Note: A USB-C cable alone only captures video if the camera/adapter '
              'exposes standard UVC video or connects via an HDMI/SDI UVC capture card.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );

      case CameraSourceType.wirelessCamera:
        return Text(
          'Wireless Camera System pairs with a second phone/tablet in "Use as Camera" '
          'mode via WebRTC. Open Cast & Connect or External Device Manager to pair and switch feeds.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );

      case CameraSourceType.screenShare:
        return Text(
          'Captures this device screen or browser window/tab. '
          'Android uses MediaProjection; iOS uses ReplayKit.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );

      case CameraSourceType.externalEncoder:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'External Encoder Settings',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _encoderNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Encoder Device / Software Name',
                hintText: 'e.g. ATEM Mini, OBS Studio, Yolobox',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _customRtmpUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Custom RTMP Ingest URL (optional)',
                hintText: 'Leave blank to use Zekre Kedusan default RTMP URL',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended Encoder Settings:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('• Video Codec: H.264 (AVC) / AAC Audio'),
                  const Text('• Keyframe Interval: 2 seconds (strictly enforced)'),
                  const Text('• Bitrate: 3,500 – 6,000 Kbps (CBR recommended)'),
                  const Text('• Audio: 128 Kbps, 44.1 or 48 kHz stereo'),
                ],
              ),
            ),
          ],
        );

      case CameraSourceType.networkCamera:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IP Camera (RTSP) Configuration',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _rtspUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'RTSP Stream URL',
                hintText: 'rtsp://192.168.1.100:554/ch0',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rtspUserCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username (optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _rtspPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password (optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transport Protocol',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<RtspTransport>(
                        segments: const [
                          ButtonSegment(
                            value: RtspTransport.tcp,
                            label: Text('TCP (Reliable)'),
                          ),
                          ButtonSegment(
                            value: RtspTransport.udp,
                            label: Text('UDP'),
                          ),
                        ],
                        selected: {_rtspTransport},
                        onSelectionChanged: (s) =>
                            setState(() => _rtspTransport = s.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _rtspPortCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      hintText: '554',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case CameraSourceType.srtEncoder:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SRT Encoder Configuration',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _srtHostCtrl,
                    decoration: const InputDecoration(
                      labelText: 'SRT Host / IP',
                      hintText: 'e.g. 192.168.1.50',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _srtPortCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      hintText: '9000',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<SrtMode>(
                    segments: const [
                      ButtonSegment(
                        value: SrtMode.caller,
                        label: Text('Caller'),
                      ),
                      ButtonSegment(
                        value: SrtMode.listener,
                        label: Text('Listener'),
                      ),
                    ],
                    selected: {_srtMode},
                    onSelectionChanged: (s) =>
                        setState(() => _srtMode = s.first),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _srtLatencyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Latency (ms)',
                      hintText: '200',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _srtStreamIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Stream ID (optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _srtPassphraseCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Passphrase (optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}
