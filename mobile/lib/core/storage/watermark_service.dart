// lib/core/storage/watermark_service.dart
// TikTok-style watermark system for Zikire Kdusan media.
// Matches the official TikTok layout:
//   [Zikire Kdusan LOGO]
//   ዝክረ ቅዱሳን / Zikire Kdusan
//   @publisher_username
// Stacked vertically on a transparent backdrop with high-contrast drop-shadows.
// Embeds watermark directly into downloaded images and provides dynamic moving overlay for videos.

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile/features/home/domain/video_model.dart';

class WatermarkService {
  static const String defaultBrandAmharic = 'ዝክረ ቅዱሳን';
  static const String defaultBrandEnglish = 'Zikire Kdusan';
  static const String logoAssetPath = 'assets/images/logo.jpg';

  /// Applies TikTok-style vertical stacked watermark directly to a downloaded image file.
  /// Layout:
  ///   [ Circular Logo ]
  ///   ዝክረ ቅዱሳን
  ///   @publisher_username
  /// Pure white text & logo with high-contrast soft drop-shadows on transparent background (no box).
  /// Preserves resolution, aspect ratio, and quality.
  static Future<File> applyImageWatermark({
    required File sourceImageFile,
    required File destinationFile,
    required String publisherUsername,
    String? publisherDisplayName,
    String brandName = defaultBrandAmharic,
  }) async {
    final imageBytes = await sourceImageFile.readAsBytes();

    // 1. Decode original image
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final originalImage = frame.image;
    final width = originalImage.width;
    final height = originalImage.height;

    // 2. Load official Zikire Kdusan logo asset
    ui.Image? logoImage;
    try {
      final logoData = await rootBundle.load(logoAssetPath);
      final logoCodec =
          await ui.instantiateImageCodec(logoData.buffer.asUint8List());
      final logoFrame = await logoCodec.getNextFrame();
      logoImage = logoFrame.image;
    } catch (e) {
      debugPrint('[WatermarkService] Logo asset load note: $e');
    }

    // 3. Setup canvas & draw original image
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
        recorder, ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
    final basePaint = ui.Paint()..filterQuality = ui.FilterQuality.high;
    canvas.drawImage(originalImage, ui.Offset.zero, basePaint);

    // 4. Calculate responsive scaling relative to image dimensions
    final minDim = min(width, height).toDouble();
    final scale = (minDim / 750.0).clamp(0.6, 2.5);

    final cleanUsername = publisherUsername.startsWith('@')
        ? publisherUsername
        : '@$publisherUsername';

    final logoSize = 42.0 * scale;
    final brandFontSize = (17.0 * scale).clamp(11.0, 44.0);
    final userFontSize = (14.5 * scale).clamp(9.5, 38.0);
    final margin = 28.0 * scale;
    final spacingAfterLogo = 4.0 * scale;
    final spacingBetweenTexts = 2.0 * scale;

    // Dual-layer drop shadows for crystal-clear readability on light & dark media
    final textShadows = [
      Shadow(
        color: Colors.black.withValues(alpha: 0.9),
        offset: Offset(1.5 * scale, 1.5 * scale),
        blurRadius: 4.5 * scale,
      ),
      Shadow(
        color: Colors.black.withValues(alpha: 0.65),
        offset: Offset(-0.8 * scale, -0.8 * scale),
        blurRadius: 3.0 * scale,
      ),
      Shadow(
        color: Colors.black.withValues(alpha: 0.5),
        offset: Offset(0, 2.0 * scale),
        blurRadius: 6.0 * scale,
      ),
    ];

    // Measure brand text
    final brandPainter = TextPainter(
      text: TextSpan(
        text: brandName,
        style: TextStyle(
          color: Colors.white,
          fontSize: brandFontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          shadows: textShadows,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Measure publisher username text
    final userPainter = TextPainter(
      text: TextSpan(
        text: cleanUsername,
        style: TextStyle(
          color: Colors.white,
          fontSize: userFontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          shadows: textShadows,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final totalHeight = logoSize +
        spacingAfterLogo +
        brandPainter.height +
        spacingBetweenTexts +
        userPainter.height;

    // TikTok-style corner position: Lower-Left (as seen in reference screenshot)
    final badgeX = margin;
    final badgeY = height - totalHeight - margin;

    // Draw circular clipped logo on top with white border & shadow (NO dark bounding box)
    if (logoImage != null) {
      final logoCenter =
          ui.Offset(badgeX + (logoSize / 2), badgeY + (logoSize / 2));

      // Soft circular drop shadow behind logo
      final shadowPaint = ui.Paint()
        ..color = Colors.black.withValues(alpha: 0.65)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 5.0 * scale);
      canvas.drawCircle(
          logoCenter, (logoSize / 2) + (1.5 * scale), shadowPaint);

      // Clip logo as circle
      canvas.save();
      final logoRect = ui.Rect.fromLTWH(badgeX, badgeY, logoSize, logoSize);
      final clipPath = ui.Path()..addOval(logoRect);
      canvas.clipPath(clipPath);

      canvas.drawImageRect(
        logoImage,
        ui.Rect.fromLTWH(
            0, 0, logoImage.width.toDouble(), logoImage.height.toDouble()),
        logoRect,
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      canvas.restore();

      // Clean white ring border around circular logo
      final ringPaint = ui.Paint()
        ..color = Colors.white
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.4 * scale;
      canvas.drawCircle(logoCenter, logoSize / 2, ringPaint);
    }

    // Paint brand name directly below the logo
    final brandY = badgeY + logoSize + spacingAfterLogo;
    brandPainter.paint(canvas, ui.Offset(badgeX, brandY));

    // Paint publisher username directly below the brand name
    final userY = brandY + brandPainter.height + spacingBetweenTexts;
    userPainter.paint(canvas, ui.Offset(badgeX, userY));

    // 5. Finalize picture and save to destination file
    final picture = recorder.endRecording();
    final renderedImage = await picture.toImage(width, height);
    final byteData =
        await renderedImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to encode watermarked image to bytes');
    }

    await destinationFile.writeAsBytes(byteData.buffer.asUint8List(),
        flush: true);
    return destinationFile;
  }
}

/// Video branding watermark overlay for Zikre Kedusan media playback.
///
/// Displays the Zikre Kedusan / Publisher logo and identity in a single
/// horizontal layout:
///   - Logo on the LEFT (circular with white border and drop shadow)
///   - Publisher information on the RIGHT of the logo:
///       * Primary text: Publisher name (channel, group, or user display name)
///       * Secondary text: Identity handle (@channel, @group, @username) underneath
///   - Vertically center-aligned
///
/// Deterministic duration-based positioning:
///   - First half (0% - 49.99%): comfortably at the BOTTOM of the video frame.
///   - Second half (50% - 100%): smoothly transitions to the TOP of the video frame.
///   - Live streams / media without known duration: stable default position near bottom.
///
/// The watermark moves strictly as one cohesive component between intentional positions
/// without rapid bouncing, flickering, or continuous animations.
class TikTokWatermarkOverlay extends StatefulWidget {
  final String? publisherUsername;
  final String? publisherName;
  final String? publisherIdentity;
  final String? publisherLogoUrl;
  final String brandName;
  final bool isVisible;
  final VideoPlayerController? controller;
  final Duration? duration;
  final Duration? position;
  final bool isLive;
  final VideoResponseDto? video;
  final Alignment? bottomAlignment;
  final Alignment? topAlignment;
  final EdgeInsetsGeometry? padding;
  final Widget Function(BuildContext context)? logoBuilder;

  const TikTokWatermarkOverlay({
    super.key,
    this.publisherUsername,
    this.publisherName,
    this.publisherIdentity,
    this.publisherLogoUrl,
    this.brandName = WatermarkService.defaultBrandAmharic,
    this.isVisible = true,
    this.controller,
    this.duration,
    this.position,
    this.isLive = false,
    this.video,
    this.bottomAlignment,
    this.topAlignment,
    this.padding,
    this.logoBuilder,
  });

  @override
  State<TikTokWatermarkOverlay> createState() => _TikTokWatermarkOverlayState();
}

typedef VideoWatermarkOverlay = TikTokWatermarkOverlay;

class _TikTokWatermarkOverlayState extends State<TikTokWatermarkOverlay> {
  bool _isSecondHalf = false;

  static const List<Shadow> _kTextShadows = [
    Shadow(
      color: Color(0xF2000000), // 95% opacity black
      blurRadius: 4,
      offset: Offset(1.2, 1.2),
    ),
    Shadow(
      color: Color(0xBF000000), // 75% opacity black
      blurRadius: 2,
      offset: Offset(-0.8, -0.8),
    ),
    Shadow(
      color: Color(0x99000000), // 60% opacity black
      blurRadius: 6,
      offset: Offset(0, 1.5),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _isSecondHalf = _calculateIsSecondHalf();
    widget.controller?.addListener(_onControllerTick);
  }

  @override
  void didUpdateWidget(TikTokWatermarkOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerTick);
      widget.controller?.addListener(_onControllerTick);
    }
    _updatePositionState();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerTick);
    super.dispose();
  }

  void _onControllerTick() {
    if (!mounted) return;
    _updatePositionState();
  }

  void _updatePositionState() {
    final newIsSecondHalf = _calculateIsSecondHalf();
    if (newIsSecondHalf != _isSecondHalf) {
      setState(() {
        _isSecondHalf = newIsSecondHalf;
      });
    }
  }

  bool _calculateIsSecondHalf() {
    if (widget.isLive) return false;
    if (widget.video?.isStream == true) return false;

    Duration currentPos = Duration.zero;
    Duration totalDur = Duration.zero;

    final ctrl = widget.controller;
    if (ctrl != null && ctrl.value.isInitialized) {
      currentPos = ctrl.value.position;
      totalDur = ctrl.value.duration;
    }

    if (widget.position != null) {
      currentPos = widget.position!;
    }

    if (widget.duration != null && widget.duration! > Duration.zero) {
      totalDur = widget.duration!;
    } else if (totalDur <= Duration.zero &&
        widget.video != null &&
        widget.video!.duration > 0) {
      totalDur = Duration(seconds: widget.video!.duration);
    }

    if (totalDur <= Duration.zero || currentPos < Duration.zero) {
      return false; // Live stream or unknown duration -> default bottom
    }

    final progress = currentPos.inMicroseconds / totalDur.inMicroseconds;
    if (progress.isNaN || progress.isInfinite) return false;

    return progress >= 0.50;
  }

  String _cleanIdentity(String identity) {
    final trimmed = identity.trim();
    if (trimmed.isEmpty) return '@zikre_kdusan';
    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

  Widget _buildLogoWidget(String? logoUrl) {
    if (widget.logoBuilder != null) {
      return widget.logoBuilder!(context);
    }

    if (logoUrl != null &&
        logoUrl.trim().isNotEmpty &&
        (logoUrl.startsWith('http://') || logoUrl.startsWith('https://'))) {
      return CachedNetworkImage(
        imageUrl: logoUrl.trim(),
        fit: BoxFit.cover,
        placeholder: (context, url) => Image.asset(
          WatermarkService.logoAssetPath,
          fit: BoxFit.cover,
        ),
        errorWidget: (context, url, error) => Image.asset(
          WatermarkService.logoAssetPath,
          fit: BoxFit.cover,
        ),
      );
    }

    return Image.asset(
      WatermarkService.logoAssetPath,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Resolve publisher metadata dynamically
    String resolvedPrimaryText;
    String resolvedSecondaryText;
    String? resolvedLogoUrl;

    if (widget.publisherName != null &&
        widget.publisherName!.trim().isNotEmpty) {
      resolvedPrimaryText = widget.publisherName!.trim();
      resolvedSecondaryText = _cleanIdentity(
        widget.publisherIdentity ??
            widget.publisherUsername ??
            'zikre_kdusan',
      );
      resolvedLogoUrl = widget.publisherLogoUrl;
    } else if (widget.video != null) {
      final v = widget.video!;
      // Case 1: Channel
      if (v.channelName != null && v.channelName!.trim().isNotEmpty) {
        resolvedPrimaryText = v.channelName!.trim();
        final handle = v.channelHandle ?? v.author.username ?? v.channelName!;
        resolvedSecondaryText = _cleanIdentity(handle);
        resolvedLogoUrl = widget.publisherLogoUrl ??
            v.channelAvatarUrl ??
            v.author.avatarUrl;
      }
      // Case 2: Group
      else if (v.groupName != null && v.groupName!.trim().isNotEmpty) {
        resolvedPrimaryText = v.groupName!.trim();
        final groupIdentity = v.groupSlug ?? v.groupName!;
        resolvedSecondaryText = _cleanIdentity(groupIdentity);
        resolvedLogoUrl = widget.publisherLogoUrl ?? v.groupAvatarUrl;
      }
      // Case 3: Regular User
      else {
        final authorName = (v.author.displayName != null &&
                v.author.displayName!.trim().isNotEmpty)
            ? v.author.displayName!.trim()
            : ((v.author.username != null &&
                    v.author.username!.trim().isNotEmpty)
                ? v.author.username!.trim()
                : widget.brandName);
        resolvedPrimaryText = authorName;
        final userHandle = (v.author.username != null &&
                v.author.username!.trim().isNotEmpty)
            ? v.author.username!.trim()
            : 'zikre_kdusan';
        resolvedSecondaryText = _cleanIdentity(userHandle);
        resolvedLogoUrl = widget.publisherLogoUrl ?? v.author.avatarUrl;
      }
    } else {
      if (widget.publisherUsername != null &&
          widget.publisherUsername!.trim().isNotEmpty) {
        final rawUser = widget.publisherUsername!.trim();
        if (rawUser.startsWith('@')) {
          resolvedPrimaryText = widget.brandName;
          resolvedSecondaryText = rawUser;
        } else {
          resolvedPrimaryText = rawUser;
          resolvedSecondaryText = '@$rawUser';
        }
      } else {
        resolvedPrimaryText = widget.brandName;
        resolvedSecondaryText = '@zikre_kdusan';
      }
      resolvedLogoUrl = widget.publisherLogoUrl;
    }

    final alignment = _isSecondHalf
        ? (widget.topAlignment ?? Alignment.topLeft)
        : (widget.bottomAlignment ?? Alignment.bottomLeft);

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: widget.isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
          alignment: alignment,
          child: Padding(
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth.isFinite
                    ? (constraints.maxWidth * 0.70).clamp(160.0, 320.0)
                    : 280.0;
                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. Logo on LEFT
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.65),
                              blurRadius: 6,
                              offset: const Offset(1, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _buildLogoWidget(resolvedLogoUrl),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 2. Publisher information on RIGHT of logo
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resolvedPrimaryText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                shadows: _kTextShadows,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              resolvedSecondaryText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                                shadows: _kTextShadows,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
