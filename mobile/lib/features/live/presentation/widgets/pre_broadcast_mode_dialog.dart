// lib/features/live/presentation/widgets/pre_broadcast_mode_dialog.dart
//
// Modal dialog displayed prior to Go-Live, allowing broadcasters to choose
// between "Stream Only" vs "Stream & Record Audio Locally (Backup)", and confirming
// external encoder credentials if streaming from an external hardware device.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/features/live/domain/camera_source.dart';

enum BroadcastRecordingMode {
  streamOnly,
  streamAndRecordLocally,
}

class PreBroadcastModeDialog extends StatefulWidget {
  final CameraSource cameraSource;
  final bool initialRecordLocally;
  final String? rtmpServerUrl;
  final String? streamKey;

  const PreBroadcastModeDialog({
    super.key,
    required this.cameraSource,
    required this.initialRecordLocally,
    this.rtmpServerUrl,
    this.streamKey,
  });

  static Future<BroadcastRecordingMode?> show(
    BuildContext context, {
    required CameraSource cameraSource,
    required bool initialRecordLocally,
    String? rtmpServerUrl,
    String? streamKey,
  }) {
    return showDialog<BroadcastRecordingMode>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PreBroadcastModeDialog(
        cameraSource: cameraSource,
        initialRecordLocally: initialRecordLocally,
        rtmpServerUrl: rtmpServerUrl,
        streamKey: streamKey,
      ),
    );
  }

  @override
  State<PreBroadcastModeDialog> createState() => _PreBroadcastModeDialogState();
}

class _PreBroadcastModeDialogState extends State<PreBroadcastModeDialog> {
  late BroadcastRecordingMode _mode;
  bool _copiedUrl = false;
  bool _copiedKey = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialRecordLocally
        ? BroadcastRecordingMode.streamAndRecordLocally
        : BroadcastRecordingMode.streamOnly;
  }

  void _copyToClipboard(String text, bool isUrl) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    setState(() {
      if (isUrl) {
        _copiedUrl = true;
      } else {
        _copiedKey = true;
      }
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          if (isUrl) {
            _copiedUrl = false;
          } else {
            _copiedKey = false;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExternalEncoder =
        widget.cameraSource.type == CameraSourceType.externalEncoder;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sensors_rounded, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Go Live Confirmation',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Camera source tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.cameraSource.icon, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Source: ${widget.cameraSource.label}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // If external encoder, show quick copy credentials
            if (isExternalEncoder && widget.rtmpServerUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'External Encoder Ingest',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'URL: ${widget.rtmpServerUrl}',
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () => _copyToClipboard(widget.rtmpServerUrl!, true),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              _copiedUrl ? Icons.check_circle : Icons.copy_rounded,
                              size: 16,
                              color: _copiedUrl ? Colors.green : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.streamKey != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Key: ••••••••••••',
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ),
                          InkWell(
                            onTap: () => _copyToClipboard(widget.streamKey!, false),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                _copiedKey ? Icons.check_circle : Icons.copy_rounded,
                                size: 16,
                                color: _copiedKey ? Colors.green : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            Text(
              'Select Broadcast & Recording Mode:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Option 1: Stream Only
            InkWell(
              onTap: () => setState(() => _mode = BroadcastRecordingMode.streamOnly),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _mode == BroadcastRecordingMode.streamOnly
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _mode == BroadcastRecordingMode.streamOnly
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Radio<BroadcastRecordingMode>(
                      value: BroadcastRecordingMode.streamOnly,
                      groupValue: _mode,
                      onChanged: (v) {
                        if (v != null) setState(() => _mode = v);
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Live Stream Only',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Broadcast live to viewers. Server-side VOD recording created if enabled on channel.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Option 2: Stream & Record Locally
            InkWell(
              onTap: () => setState(
                () => _mode = BroadcastRecordingMode.streamAndRecordLocally,
              ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _mode == BroadcastRecordingMode.streamAndRecordLocally
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _mode == BroadcastRecordingMode.streamAndRecordLocally
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Radio<BroadcastRecordingMode>(
                      value: BroadcastRecordingMode.streamAndRecordLocally,
                      groupValue: _mode,
                      onChanged: (v) {
                        if (v != null) setState(() => _mode = v);
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Stream & Record Audio Locally',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'M4A Backup',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Saves microphone audio directly to phone storage as an immediate backup alongside the live broadcast.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, _mode),
          icon: const Icon(Icons.sensors_rounded, size: 18),
          label: const Text('Go Live Now'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
