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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// Floating TikTok-style animated watermark overlay for video playback.
/// Matches the exact red-circled screenshot presentation:
///   [ Circular Logo ]
///   ዝክረ ቅዱሳን
///   @publisher_username
/// Vertically stacked on a transparent background with soft drop-shadows.
/// Periodically shifts between corners (Lower-Left <-> Top-Right)
/// to maintain visibility while preventing obstruction of important content.
class TikTokWatermarkOverlay extends StatefulWidget {
  final String publisherUsername;
  final String brandName;
  final bool isVisible;

  const TikTokWatermarkOverlay({
    super.key,
    required this.publisherUsername,
    this.brandName = WatermarkService.defaultBrandAmharic,
    this.isVisible = true,
  });

  @override
  State<TikTokWatermarkOverlay> createState() => _TikTokWatermarkOverlayState();
}

class _TikTokWatermarkOverlayState extends State<TikTokWatermarkOverlay> {
  Timer? _shiftTimer;
  bool _isTopRight = false;

  @override
  void initState() {
    super.initState();
    // Shift watermark position every 5 seconds, similar to TikTok
    _shiftTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          _isTopRight = !_isTopRight;
        });
      }
    });
  }

  @override
  void dispose() {
    _shiftTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final cleanUsername = widget.publisherUsername.startsWith('@')
        ? widget.publisherUsername
        : '@${widget.publisherUsername}';

    // Shifting positions: Lower-Left (matching reference screenshot) <-> Top-Right
    final alignment = _isTopRight
        ? const Alignment(0.85, -0.75) // Top-Right
        : const Alignment(-0.85, 0.65); // Lower-Left (screenshot)

    return IgnorePointer(
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Zikire Kdusan Logo Icon (circular with white border & shadow)
              Container(
                width: 38,
                height: 38,
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
                  child: Image.asset(
                    WatermarkService.logoAssetPath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // 2. Brand Name: 'ዝክረ ቅዱሳን' / 'Zikire Kdusan'
              Text(
                widget.brandName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.9),
                      blurRadius: 4,
                      offset: const Offset(1.2, 1.2),
                    ),
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.65),
                      blurRadius: 2,
                      offset: const Offset(-0.6, -0.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 1),
              // 3. Original Publisher Username: '@username' (e.g. @yemariyam123)
              Text(
                cleanUsername,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.9),
                      blurRadius: 4,
                      offset: const Offset(1.2, 1.2),
                    ),
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.65),
                      blurRadius: 2,
                      offset: const Offset(-0.6, -0.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
