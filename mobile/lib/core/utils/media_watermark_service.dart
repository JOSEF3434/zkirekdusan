// lib/core/utils/media_watermark_service.dart
// Watermark service that brands media downloads with App Logo + 'ዝክረ ቅዱሳን'
// in a modern, platform-style (TikTok/Instagram) overlay.
// Cross-platform: Web triggers a browser Blob download;
// Android/iOS/Desktop saves to the local filesystem.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/utils/media_save_helper.dart';

class MediaWatermarkService {
  MediaWatermarkService._();
  static final MediaWatermarkService instance = MediaWatermarkService._();

  final Dio _dio = Dio();
  ui.Image? _cachedLogoImage;

  /// Loads and caches the app logo from assets/images/logo.jpg
  Future<ui.Image> _getLogoImage() async {
    if (_cachedLogoImage != null) return _cachedLogoImage!;

    try {
      final byteData = await rootBundle.load('assets/images/logo.jpg');
      final bytes = byteData.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _cachedLogoImage = frame.image;
      return _cachedLogoImage!;
    } catch (e) {
      debugPrint('[MediaWatermarkService] Failed to load logo asset: $e');
      rethrow;
    }
  }

  /// Downloads a media file from [url], stamps the watermark (images only),
  /// then saves to device storage or triggers a browser download on web.
  Future<void> downloadAndWatermark({
    required String url,
    String? customFileName,
    void Function(double progress)? onProgress,
  }) async {
    final cleanFileName =
        customFileName ?? url.split('/').last.split('?').first;
    final isImage = _isImageFile(cleanFileName);

    // ── Download bytes ────────────────────────────────────────────────────────
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(received / total * (isImage ? 0.6 : 1.0));
        }
      },
    );
    if (response.data == null) throw Exception('Failed to download: $url');

    Uint8List bytes = Uint8List.fromList(response.data!);

    // ── Apply watermark for images ────────────────────────────────────────────
    if (isImage) {
      bytes = await applyWatermark(bytes);
      if (onProgress != null) onProgress(1.0);
    }

    // ── Save / trigger download ───────────────────────────────────────────────
    await MediaSaveHelper.saveFile(bytes: bytes, fileName: cleanFileName);
  }

  /// Applies the 'Logo + ዝክረ ቅዱሳን' TikTok-style watermark onto image [imageBytes].
  Future<Uint8List> applyWatermark(Uint8List imageBytes) async {
    // 1. Decode original image
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final originalImage = frame.image;
    final imgWidth = originalImage.width.toDouble();
    final imgHeight = originalImage.height.toDouble();

    // 2. Load logo
    ui.Image? logoImage;
    try {
      logoImage = await _getLogoImage();
    } catch (_) {
      logoImage = null;
    }

    // 3. Set up canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, imgWidth, imgHeight));

    // 4. Draw original image
    canvas.drawImage(originalImage, Offset.zero, Paint());

    // 5. Calculate responsive scale based on image dimensions
    final minDim = math.min(imgWidth, imgHeight);
    final scale = (minDim / 800.0).clamp(0.7, 2.8);

    const watermarkText = 'ዝክረ ቅዱሳን';
    final fontSize = 16.0 * scale;
    final logoSize = 30.0 * scale;
    final paddingHorizontal = 12.0 * scale;
    final paddingVertical = 7.0 * scale;
    final spacing = 8.0 * scale;
    final cornerRadius = 14.0 * scale;
    final margin = 20.0 * scale;

    // 6. Measure text layout
    final paragraphBuilder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: TextAlign.start,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              maxLines: 1,
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: const Color(0xFFFFFFFF),
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              shadows: [
                ui.Shadow(
                  color: const Color(0x99000000),
                  offset: Offset(scale, scale),
                  blurRadius: 3.0 * scale,
                ),
              ],
            ),
          )
          ..addText(watermarkText);

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: imgWidth * 0.5));

    final textWidth = paragraph.maxIntrinsicWidth;
    final textHeight = paragraph.height;

    // Badge container dimensions
    final badgeWidth =
        paddingHorizontal * 2 +
        (logoImage != null ? logoSize + spacing : 0) +
        textWidth;
    final badgeHeight = math.max(logoSize, textHeight) + (paddingVertical * 2);

    // Position at bottom-right (TikTok style)
    final badgeLeft = imgWidth - badgeWidth - margin;
    final badgeTop = imgHeight - badgeHeight - margin;
    final badgeRect = Rect.fromLTWH(
      badgeLeft,
      badgeTop,
      badgeWidth,
      badgeHeight,
    );

    // 7. Draw frosted pill background with subtle shadow
    final pillRRect = RRect.fromRectAndRadius(
      badgeRect,
      Radius.circular(cornerRadius),
    );

    // Shadow
    final shadowPaint = Paint()
      ..color = const Color(0x66000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.0 * scale);
    canvas.drawRRect(pillRRect.shift(Offset(0, 2.0 * scale)), shadowPaint);

    // Semi-transparent dark pill background
    final backgroundPaint = Paint()
      ..color =
          const Color(0xB8121214) // ~72% dark
      ..style = PaintingStyle.fill;
    canvas.drawRRect(pillRRect, backgroundPaint);

    // Thin elegant border
    final borderPaint = Paint()
      ..color = const Color(0x40FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    canvas.drawRRect(pillRRect, borderPaint);

    // 8. Draw circular/rounded logo if available
    double currentX = badgeLeft + paddingHorizontal;
    if (logoImage != null) {
      final logoRect = Rect.fromLTWH(
        currentX,
        badgeTop + (badgeHeight - logoSize) / 2,
        logoSize,
        logoSize,
      );

      // Clip logo as circular badge
      canvas.save();
      final clipRRect = RRect.fromRectAndRadius(
        logoRect,
        Radius.circular(logoSize / 2),
      );
      canvas.clipRRect(clipRRect);

      final srcRect = Rect.fromLTWH(
        0,
        0,
        logoImage.width.toDouble(),
        logoImage.height.toDouble(),
      );
      canvas.drawImageRect(logoImage, srcRect, logoRect, Paint());
      canvas.restore();

      // Thin border around logo
      final logoBorderPaint = Paint()
        ..color = const Color(0x55FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8 * scale;
      canvas.drawRRect(clipRRect, logoBorderPaint);

      currentX += logoSize + spacing;
    }

    // 9. Draw text
    final textY = badgeTop + (badgeHeight - textHeight) / 2;
    canvas.drawParagraph(paragraph, Offset(currentX, textY));

    // 10. Finish rendering to image
    final picture = recorder.endRecording();
    final watermarkedImage = await picture.toImage(
      imgWidth.toInt(),
      imgHeight.toInt(),
    );

    final byteData = await watermarkedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) {
      throw Exception('Failed to encode watermarked image');
    }

    return byteData.buffer.asUint8List();
  }

  bool _isImageFile(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp');
  }
}
