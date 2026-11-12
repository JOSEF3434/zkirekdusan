// lib/features/live/presentation/widgets/web_hls_player_stub.dart
import 'package:flutter/material.dart';
import 'package:mobile/features/live/domain/live_dvr_state.dart';
import 'package:mobile/features/live/presentation/widgets/web_hls_controller.dart';

/// No-op stub for non-web targets; Flutter Web routes to web_hls_player_web.dart.
class WebHlsPlayer extends StatelessWidget {
  final String url;
  final WebHlsController? controller;
  final VideoFitMode fitMode;
  final VoidCallback? onReady;
  final VoidCallback? onWaitingForStream;
  final VoidCallback? onDvrExpired;
  final void Function(String error)? onFatalError;
  final void Function(Size size)? onVideoSizeChanged;
  final bool showControls;

  const WebHlsPlayer({
    super.key,
    required this.url,
    this.controller,
    this.fitMode = VideoFitMode.fill,
    this.onReady,
    this.onWaitingForStream,
    this.onDvrExpired,
    this.onFatalError,
    this.onVideoSizeChanged,
    this.showControls = false,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
