// lib/core/presentation/widgets/app_network_image.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A unified network image widget that intelligently adapts across platforms:
/// - On Web: Uses standard [Image.network] which delegates to the browser's
///   native HTTP caching pipeline and prevents broken image / canvas corruption
///   when navigating between IndexedStack / Offstage branches (e.g. Chrome).
/// - On Mobile: Uses [CachedNetworkImage] with local disk cache for fast offline access.
class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final Widget Function(BuildContext, ImageProvider)? imageBuilder;
  final BorderRadius? borderRadius;
  final Color? color;
  final BlendMode? colorBlendMode;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
    this.imageBuilder,
    this.borderRadius,
    this.color,
    this.colorBlendMode,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  /// Provides an [ImageProvider] suitable for [CircleAvatar.backgroundImage] or [DecorationImage].
  /// Returns [NetworkImage] on Web and [CachedNetworkImageProvider] on native mobile platforms.
  static ImageProvider provider(String url) {
    if (kIsWeb) {
      return NetworkImage(url, headers: const {});
    }
    return CachedNetworkImageProvider(url);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget defaultPlaceholder(BuildContext ctx, String url) => Container(
          width: width,
          height: height,
          color: theme.colorScheme.surfaceContainerHighest,
        );

    Widget defaultErrorWidget(BuildContext ctx, String url, dynamic err) =>
        Container(
          width: width,
          height: height,
          color: theme.colorScheme.surfaceContainerHighest,
          child: const Icon(
            Icons.broken_image,
            color: Colors.grey,
          ),
        );

    final trimmed = imageUrl.trim();
    if (trimmed.isEmpty) {
      final errW = errorWidget ?? defaultErrorWidget;
      return errW(context, imageUrl, 'Empty image URL');
    }

    // Safeguard: If a local file path was accidentally passed to AppNetworkImage on native mobile
    if (!kIsWeb &&
        !imageUrl.startsWith('http://') &&
        !imageUrl.startsWith('https://') &&
        !imageUrl.startsWith('blob:') &&
        !imageUrl.startsWith('data:')) {
      final clean = imageUrl.replaceFirst('file://', '');
      try {
        final f = File(clean);
        if (f.existsSync()) {
          final localWidget = Image.file(
            f,
            fit: fit,
            width: width,
            height: height,
            alignment: alignment,
            color: color,
            colorBlendMode: colorBlendMode,
            errorBuilder: (ctx, err, stack) {
              final errW = errorWidget ?? defaultErrorWidget;
              return errW(ctx, imageUrl, err);
            },
          );
          if (borderRadius != null) {
            return ClipRRect(borderRadius: borderRadius!, child: localWidget);
          }
          return localWidget;
        }
      } catch (_) {}
    }

    Widget imageContent;

    if (kIsWeb) {
      if (imageBuilder != null) {
        imageContent = imageBuilder!(context, NetworkImage(imageUrl, headers: const {}));
      } else {
        imageContent = Image.network(
          imageUrl,
          fit: fit,
          width: width,
          height: height,
          alignment: alignment,
          color: color,
          colorBlendMode: colorBlendMode,
          cacheWidth: memCacheWidth,
          cacheHeight: memCacheHeight,
          // Setting headers forces crossOrigin="anonymous" on the underlying
          // <img> element in Flutter Web, which is required for Cloudinary and
          // other external CDN images that would otherwise fail with a CORS
          // canvas taint error.
          headers: const {},
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            final ph = placeholder ?? defaultPlaceholder;
            return ph(context, imageUrl);
          },
          errorBuilder: (context, error, stackTrace) {
            final errW = errorWidget ?? defaultErrorWidget;
            return errW(context, imageUrl, error);
          },
        );
      }
    } else {
      imageContent = CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        color: color,
        colorBlendMode: colorBlendMode,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        placeholder: placeholder != null
            ? (ctx, url) => placeholder!(ctx, url)
            : defaultPlaceholder,
        errorWidget: (ctx, url, err) {
          // If CachedNetworkImage encounters a caching or storage issue on mobile,
          // gracefully fallback to standard Image.network before showing error widget
          return Image.network(
            imageUrl,
            fit: fit,
            width: width,
            height: height,
            alignment: alignment,
            color: color,
            colorBlendMode: colorBlendMode,
            errorBuilder: (c, e, s) {
              final errW = errorWidget ?? defaultErrorWidget;
              return errW(c, imageUrl, e);
            },
          );
        },
        imageBuilder: imageBuilder != null
            ? (ctx, prov) => imageBuilder!(ctx, prov)
            : null,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageContent,
      );
    }

    return imageContent;
  }
}
