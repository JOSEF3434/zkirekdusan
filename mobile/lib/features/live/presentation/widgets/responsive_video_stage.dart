// lib/features/live/presentation/widgets/responsive_video_stage.dart
//
// Adapts any live video surface (VideoPlayer, WebHlsPlayer, CameraPreview) to
// the source stream's real aspect ratio (9:16 portrait, 1:1 square, 16:9 wide)
// with uncropped Fit (default) or controlled Fill scaling and a subtle
// ambient blurred backdrop on desktop/wide stages when aspect ratios differ.

import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile/core/presentation/widgets/app_network_image.dart';
import 'package:mobile/features/live/domain/live_dvr_state.dart';

class ResponsiveVideoStage extends StatelessWidget {
  final Widget child;
  final Size? sourceVideoSize;
  final VideoFitMode fitMode;
  final String? ambientThumbnailUrl;
  final bool showAmbientBackdrop;

  const ResponsiveVideoStage({
    super.key,
    required this.child,
    this.sourceVideoSize,
    this.fitMode = VideoFitMode.fit,
    this.ambientThumbnailUrl,
    this.showAmbientBackdrop = true,
  });

  @override
  Widget build(BuildContext context) {
    final w = (sourceVideoSize != null && sourceVideoSize!.width > 0)
        ? sourceVideoSize!.width
        : 16.0;
    final h = (sourceVideoSize != null && sourceVideoSize!.height > 0)
        ? sourceVideoSize!.height
        : 9.0;
    final aspect = (w / h).clamp(0.25, 4.0);

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showAmbientBackdrop && fitMode == VideoFitMode.fit)
            _AmbientBackdrop(thumbnailUrl: ambientThumbnailUrl),
          if (fitMode == VideoFitMode.fit)
            // AspectRatio + Center avoids CSS transform scaling on Web HtmlElementView
            // while preserving exact uncropped natural video bounds across platforms.
            Center(
              child: AspectRatio(
                aspectRatio: aspect,
                child: child,
              ),
            )
          else if (kIsWeb)
            // WebHtmlVideo uses CSS object-fit: cover directly without transform artifacts.
            SizedBox.expand(child: child)
          else
            ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.center,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: w,
                  height: h,
                  child: child,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AmbientBackdrop extends StatelessWidget {
  final String? thumbnailUrl;
  const _AmbientBackdrop({this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.15,
              colors: [
                Color(0xFF1F232B),
                Color(0xFF0A0C10),
              ],
            ),
          ),
        ),
        if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
          Opacity(
            opacity: 0.28,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: AppNetworkImage(
                imageUrl: thumbnailUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ColoredBox(color: Colors.black.withValues(alpha: 0.42)),
      ],
    );
  }
}
