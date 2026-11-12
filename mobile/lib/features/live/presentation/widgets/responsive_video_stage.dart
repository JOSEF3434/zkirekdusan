// lib/features/live/presentation/widgets/responsive_video_stage.dart
//
// YouTube-style full-width live video surface: occupies 100% of available
// player width and fills the controlled landscape container cleanly via
// crop-to-fill (BoxFit.cover / CSS object-fit: cover) by default without
// stretching, black sidebars, or blurred backdrops.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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
    this.fitMode = VideoFitMode.fill,
    this.ambientThumbnailUrl,
    this.showAmbientBackdrop = false,
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
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: ClipRect(
          clipBehavior: Clip.hardEdge,
          child: fitMode == VideoFitMode.fill
              ? (kIsWeb
                    // WebHtmlVideo uses CSS width:100%; height:100%; object-fit:cover.
                    ? SizedBox.expand(child: child)
                    : SizedBox.expand(
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
                      ))
              // Optional user-toggled uncropped mode.
              : Center(
                  child: AspectRatio(
                    aspectRatio: aspect,
                    child: child,
                  ),
                ),
        ),
      ),
    );
  }
}
