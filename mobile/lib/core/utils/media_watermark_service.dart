// lib/core/utils/media_watermark_service.dart
// Watermark service that brands media downloads with App Logo + 'ዝክረ ቅዱሳን'
// in a modern, platform-style (TikTok/Instagram) overlay.
// Cross-platform: Web triggers a browser Blob download;
// Android/iOS/Desktop saves to the local filesystem.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    Uint8List bytes;
    try {
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
      bytes = Uint8List.fromList(response.data!);
    } catch (e) {
      debugPrint('[MediaWatermarkService] Dio fetch failed: $e');
      if (kIsWeb) {
        // Fallback on web if CORS blocks binary fetching: trigger direct download/open
        await MediaSaveHelper.downloadUrl(url: url, fileName: cleanFileName);
        return;
      }
      rethrow;
    }

    // ── Apply watermark for images ────────────────────────────────────────────
    if (isImage) {
      try {
        bytes = await applyWatermark(bytes);
      } catch (e) {
        debugPrint('[MediaWatermarkService] Watermark failed, saving original: $e');
      }
      if (onProgress != null) onProgress(1.0);
    }

    // ── Save / trigger download ───────────────────────────────────────────────
    await MediaSaveHelper.saveFile(bytes: bytes, fileName: cleanFileName);
  }

  /// Applies the 'Logo + ዝክረ ቅዱሳን' TikTok-style watermark onto image [imageBytes].
  Future<Uint8List> applyWatermark(Uint8List imageBytes, {String? publisherUsername}) async {
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
    canvas.drawImage(originalImage, Offset.zero, Paint()..filterQuality = ui.FilterQuality.high);

    // 5. Calculate responsive scale based on image dimensions
    final minDim = math.min(imgWidth, imgHeight);
    final scale = (minDim / 750.0).clamp(0.6, 2.5);

    const brandName = 'ዝክረ ቅዱሳን';
    final fontSize = 16.0 * scale;
    final logoSize = 38.0 * scale;
    final margin = 26.0 * scale;

    final textShadows = [
      ui.Shadow(
        color: const Color(0xE6000000),
        offset: Offset(1.5 * scale, 1.5 * scale),
        blurRadius: 4.5 * scale,
      ),
      ui.Shadow(
        color: const Color(0x99000000),
        offset: Offset(-0.8 * scale, -0.8 * scale),
        blurRadius: 3.0 * scale,
      ),
    ];

    // 6. Measure text layout
    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.start,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        maxLines: 1,
      ),
    )
      ..pushStyle(
        ui.TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          shadows: textShadows,
        ),
      )
      ..addText(brandName);

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: imgWidth * 0.6));

    final textHeight = paragraph.height;

    // Optional username paragraph
    ui.Paragraph? userParagraph;
    if (publisherUsername != null && publisherUsername.isNotEmpty) {
      final cleanUser = publisherUsername.startsWith('@') ? publisherUsername : '@$publisherUsername';
      final userBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.start,
          fontSize: fontSize * 0.85,
          fontWeight: FontWeight.w600,
          maxLines: 1,
        ),
      )
        ..pushStyle(
          ui.TextStyle(
            color: const Color(0xFFFFFFFF),
            fontSize: fontSize * 0.85,
            fontWeight: FontWeight.w600,
            shadows: textShadows,
          ),
        )
        ..addText(cleanUser);

      userParagraph = userBuilder.build()
        ..layout(ui.ParagraphConstraints(width: imgWidth * 0.6));
    }

    final totalHeight = logoSize +
        (4.0 * scale) +
        textHeight +
        (userParagraph != null ? (2.0 * scale) + userParagraph.height : 0);

    // Position at bottom-left (TikTok style)
    final badgeLeft = margin;
    final badgeTop = imgHeight - totalHeight - margin;

    // 7. Draw circular logo with shadow and white ring (no dark box, exactly like TikTok)
    if (logoImage != null) {
      final logoCenter = Offset(badgeLeft + (logoSize / 2), badgeTop + (logoSize / 2));
      final shadowPaint = Paint()
        ..color = const Color(0x99000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5.0 * scale);
      canvas.drawCircle(logoCenter, (logoSize / 2) + (1.5 * scale), shadowPaint);

      canvas.save();
      final clipPath = Path()..addOval(Rect.fromLTWH(badgeLeft, badgeTop, logoSize, logoSize));
      canvas.clipPath(clipPath);

      final srcRect = Rect.fromLTWH(0, 0, logoImage.width.toDouble(), logoImage.height.toDouble());
      final dstRect = Rect.fromLTWH(badgeLeft, badgeTop, logoSize, logoSize);
      canvas.drawImageRect(logoImage, srcRect, dstRect, Paint()..filterQuality = FilterQuality.high);
      canvas.restore();

      final ringPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * scale;
      canvas.drawCircle(logoCenter, logoSize / 2, ringPaint);
    }

    // 8. Draw brand name directly below the logo
    final brandY = badgeTop + logoSize + (4.0 * scale);
    canvas.drawParagraph(paragraph, Offset(badgeLeft, brandY));

    // 9. Draw username if available
    if (userParagraph != null) {
      final userY = brandY + textHeight + (2.0 * scale);
      canvas.drawParagraph(userParagraph, Offset(badgeLeft, userY));
    }

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
