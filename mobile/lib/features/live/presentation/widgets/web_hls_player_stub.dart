// lib/features/live/presentation/widgets/web_hls_player_stub.dart
import 'package:flutter/material.dart';

/// No-op stub for non-web targets; Flutter Web routes to web_hls_player_web.dart.
class WebHlsPlayer extends StatelessWidget {
  final String url;
  final VoidCallback? onReady;
  final VoidCallback? onWaitingForStream;
  final void Function(String error)? onFatalError;
  final bool showControls;

  const WebHlsPlayer({
    super.key,
    required this.url,
    this.onReady,
    this.onWaitingForStream,
    this.onFatalError,
    this.showControls = false,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
