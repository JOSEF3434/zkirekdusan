// lib/core/presentation/widgets/video_thumbnail_widget.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/presentation/widgets/app_network_image.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';

/// A robust, reusable thumbnail widget that guarantees consistent rendering and fallbacks:
/// 1. If [thumbnailUrl] (or resolved stream snapshot) is valid, displays it via [AppNetworkImage] or local file.
/// 2. If thumbnail is missing, null, empty, or fails to load, displays the exact Home page gradient fallback
///    with a circular play icon instead of an empty or black rectangle.
class VideoThumbnailWidget extends StatelessWidget {
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? hlsUrl;
  final List<String>? renditionUrls;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final double aspectRatio;
  final double playIconSize;
  final Widget? overlay;

  const VideoThumbnailWidget({
    super.key,
    this.thumbnailUrl,
    this.videoUrl,
    this.hlsUrl,
    this.renditionUrls,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.aspectRatio = 16 / 9,
    this.playIconSize = 36.0,
    this.overlay,
  });

  /// The standard video thumbnail fallback matching the Home page video cards.
  static Widget buildFallback(BuildContext context, {double playIconSize = 36.0}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceContainerHighest,
            Color.alphaBlend(
              theme.colorScheme.primary.withValues(alpha: 0.12),
              theme.colorScheme.surfaceContainerHigh,
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(playIconSize * 0.33),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            color: Colors.white.withValues(alpha: 0.8),
            size: playIconSize,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final resolvedThumb = MediaUrlResolver.resolveThumbnail(
      thumbnailUrl: thumbnailUrl,
      videoUrl: videoUrl,
      hlsUrl: hlsUrl,
      renditionUrls: renditionUrls,
    );

    Widget imageWidget;
    if (resolvedThumb == null || resolvedThumb.trim().isEmpty) {
      imageWidget = buildFallback(context, playIconSize: playIconSize);
    } else {
      final isLocalFile = !kIsWeb &&
          (resolvedThumb.startsWith('/') || resolvedThumb.startsWith('file://'));

      if (isLocalFile) {
        final filePath = resolvedThumb.replaceFirst('file://', '');
        imageWidget = Image.file(
          File(filePath),
          fit: fit,
          errorBuilder: (_, _, _) =>
              buildFallback(context, playIconSize: playIconSize),
        );
      } else if (kIsWeb &&
          !resolvedThumb.startsWith('http://') &&
          !resolvedThumb.startsWith('https://') &&
          !resolvedThumb.startsWith('blob:') &&
          !resolvedThumb.startsWith('data:')) {
        imageWidget = buildFallback(context, playIconSize: playIconSize);
      } else {
        imageWidget = AppNetworkImage(
          imageUrl: resolvedThumb,
          fit: fit,
          placeholder: (ctx, url) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          errorWidget: (ctx, url, error) =>
              buildFallback(context, playIconSize: playIconSize),
        );
      }
    }

    final content = Stack(
      fit: StackFit.expand,
      children: [
        imageWidget,
        ?overlay,
      ],
    );

    final clipped = borderRadius != null
        ? ClipRRect(
            borderRadius: borderRadius!,
            child: content,
          )
        : content;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: clipped,
    );
  }
}
