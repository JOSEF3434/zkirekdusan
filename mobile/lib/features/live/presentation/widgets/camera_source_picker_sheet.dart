// lib/features/live/presentation/widgets/camera_source_picker_sheet.dart
//
// Interactive bottom sheet for selecting and configuring camera / encoder sources.
//
// Sources supported:
// 1. Device Camera (Built-in front/back)
// 2. External Hardware/Software Encoder (ATEM Mini, OBS Studio, vMix, Yolobox)
// 3. IP Camera (RTSP over TCP/UDP)
// 4. SRT Encoder (Secure Reliable Transport)

import 'package:flutter/material.dart';
import 'package:mobile/features/live/domain/camera_source.dart';

class CameraSourcePickerSheet extends StatefulWidget {
  final CameraSource initialSource;
  final ValueChanged<CameraSource> onSourceSelected;

  const CameraSourcePickerSheet({
    super.key,
    required this.initialSource,
    required this.onSourceSelected,
  });

  static Future<CameraSource?> show(
    BuildContext context, {
    required CameraSource initialSource,
  }) {
    return showModalBottomSheet<CameraSource>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CameraSourcePickerSheet(
        initialSource: initialSource,
        onSourceSelected: (source) => Navigator.pop(ctx, source),
      ),
    );
  }

  @override
  State<CameraSourcePickerSheet> createState() =>
      _CameraSourcePickerSheetState();
}

class _CameraSourcePickerSheetState extends State<CameraSourcePickerSheet> {
  late CameraSourceType _selectedType;

  // Built-in camera config
  late bool _isFrontCamera;
  late int _resolutionHeight;

  // External encoder config
  late TextEditingController _encoderNameCtrl;
  late int _encoderBitrateKbps;

  // Network IP camera (RTSP) config
  late TextEditingController _rtspUrlCtrl;
  late RtspTransport _rtspTransport;
  late TextEditingController _rtspPortCtrl;

  // SRT encoder config
  late TextEditingController _srtHostCtrl;
  late TextEditingController _srtPortCtrl;
  late TextEditingController _srtLatencyCtrl;
  late SrtMode _srtMode;
  late TextEditingController _srtStreamIdCtrl;

  String? _validationError;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialSource.type;

    if (widget.initialSource is BuiltInCameraSource) {
      final s = widget.initialSource as BuiltInCameraSource;
      _isFrontCamera = s.isFront;
      _resolutionHeight = s.resolutionHeight;
    } else {
      _isFrontCamera = true;
      _resolutionHeight = 720;
    }

    if (widget.initialSource is ExternalEncoderSource) {
      final s = widget.initialSource as ExternalEncoderSource;
      _encoderNameCtrl = TextEditingController(text: s.encoderName);
      _encoderBitrateKbps = s.recommendedBitrateKbps;
    } else {
      _encoderNameCtrl = TextEditingController(text: 'OBS / ATEM Mini');
      _encoderBitrateKbps = 3500;
    }

    if (widget.initialSource is NetworkCameraSource) {
      final s = widget.initialSource as NetworkCameraSource;
      _rtspUrlCtrl = TextEditingController(text: s.rtspUrl);
      _rtspTransport = s.transport;
      _rtspPortCtrl = TextEditingController(text: s.port.toString());
    } else {
      _rtspUrlCtrl = TextEditingController();
      _rtspTransport = RtspTransport.tcp;
      _rtspPortCtrl = TextEditingController(text: '554');
    }

    if (widget.initialSource is SrtEncoderSource) {
      final s = widget.initialSource as SrtEncoderSource;
      _srtHostCtrl = TextEditingController(text: s.host);
      _srtPortCtrl = TextEditingController(text: s.port.toString());
      _srtLatencyCtrl = TextEditingController(text: s.latencyMs.toString());
      _srtMode = s.mode;
      _srtStreamIdCtrl = TextEditingController(text: s.streamId ?? '');
    } else {
      _srtHostCtrl = TextEditingController();
      _srtPortCtrl = TextEditingController(text: '9000');
      _srtLatencyCtrl = TextEditingController(text: '200');
      _srtMode = SrtMode.caller;
      _srtStreamIdCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _encoderNameCtrl.dispose();
    _rtspUrlCtrl.dispose();
    _rtspPortCtrl.dispose();
    _srtHostCtrl.dispose();
    _srtPortCtrl.dispose();
    _srtLatencyCtrl.dispose();
    _srtStreamIdCtrl.dispose();
    super.dispose();
  }

  void _saveSelection() {
    setState(() => _validationError = null);

    CameraSource finalSource;
    switch (_selectedType) {
      case CameraSourceType.builtIn:
        finalSource = BuiltInCameraSource(
          isFront: _isFrontCamera,
          resolutionWidth: _resolutionHeight == 1080 ? 1920 : 1280,
          resolutionHeight: _resolutionHeight,
        );
        break;

      case CameraSourceType.externalEncoder:
        finalSource = ExternalEncoderSource(
          encoderName: _encoderNameCtrl.text.trim().isEmpty
              ? 'External Encoder'
              : _encoderNameCtrl.text.trim(),
          recommendedBitrateKbps: _encoderBitrateKbps,
        );
        break;

      case CameraSourceType.networkCamera:
        final url = _rtspUrlCtrl.text.trim();
        if (url.isNotEmpty && !NetworkCameraSource.isValidRtspUrl(url)) {
          setState(() {
            _validationError =
                'Invalid RTSP URL. Format: rtsp://username:password@ip:554/path';
          });
          return;
        }
        final port = int.tryParse(_rtspPortCtrl.text.trim()) ?? 554;
        finalSource = NetworkCameraSource(
          rtspUrl: url,
          transport: _rtspTransport,
          port: port,
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
        );
        break;
    }

    widget.onSourceSelected(finalSource);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
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
            // Handle bar
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

            // Header
            Row(
              children: [
                Icon(
                  Icons.video_camera_back_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Video & Camera Source',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Select whether you are streaming from this phone, a hardware encoder, an RTSP IP camera, or SRT.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Source Radio List
            _buildSourceOption(
              type: CameraSourceType.builtIn,
              title: 'Device Camera',
              subtitle: 'Front / back camera on this phone',
              icon: Icons.camera_alt_outlined,
              theme: theme,
            ),
            _buildSourceOption(
              type: CameraSourceType.externalEncoder,
              title: 'Hardware / Software Encoder',
              subtitle: 'OBS Studio, ATEM Mini, vMix, Teradek, Yolobox',
              icon: Icons.settings_input_hdmi_rounded,
              theme: theme,
            ),
            _buildSourceOption(
              type: CameraSourceType.networkCamera,
              title: 'IP Camera (RTSP)',
              subtitle: 'Local/LAN PTZ camera streaming RTSP over TCP/UDP',
              icon: Icons.videocam_outlined,
              theme: theme,
            ),
            _buildSourceOption(
              type: CameraSourceType.srtEncoder,
              title: 'SRT Encoder',
              subtitle: 'Ultra-low latency Secure Reliable Transport',
              icon: Icons.speed_rounded,
              theme: theme,
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Detailed Config Section per source
            _buildDetailConfigSection(theme),

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

            // Save / Apply Button
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
            Radio<CameraSourceType>(
              value: type,
              groupValue: _selectedType,
              onChanged: (v) {
                if (v != null) setState(() => _selectedType = v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailConfigSection(ThemeData theme) {
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
                    selected: {_resolutionHeight},
                    onSelectionChanged: (s) =>
                        setState(() => _resolutionHeight = s.first),
                  ),
                ),
              ],
            ),
          ],
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
                hintText: 'rtsp://user:pass@192.168.1.100:554/ch0',
                border: OutlineInputBorder(),
                isDense: true,
              ),
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
            const SizedBox(height: 8),
            Text(
              'Note: RTSP and SRT are separate protocols. Use RTSP for standard LAN IP cameras.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
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
          ],
        );
    }
  }
}
