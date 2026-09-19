// lib/features/chats/presentation/widgets/telegram_qr_sheet.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';

class TelegramQrSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? avatarUrl;
  final String qrData;

  const TelegramQrSheet({
    super.key,
    required this.title,
    required this.subtitle,
    this.avatarUrl,
    required this.qrData,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    String? avatarUrl,
    required String qrData,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TelegramQrSheet(
        title: title,
        subtitle: subtitle,
        avatarUrl: avatarUrl,
        qrData: qrData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF17212B) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1621) : Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Text(
              'QR Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // QR Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // QR Matrix Simulation
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0E1621)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(
                              0xFF00C6FF,
                            ).withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: CustomPaint(
                          painter: _QrPatternPainter(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      // Center Avatar
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: cardBg,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(
                            0xFF00C6FF,
                          ).withValues(alpha: 0.2),
                          backgroundImage:
                              avatarUrl != null && avatarUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(avatarUrl!)
                              : null,
                          child: avatarUrl == null || avatarUrl!.isEmpty
                              ? Text(
                                  title.isNotEmpty
                                      ? title[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Color(0xFF00C6FF),
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Name
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Subtitle / username
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons: Share QR Code & Copy Link
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: qrData));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard!'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Consumer(
                      builder: (_, ref, _) =>
                          Text(ref.watch(trProvider)('common.copy')),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.white
                          : const Color(0xFF00C6FF),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : const Color(0xFF00C6FF).withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('QR Code shared!'),
                          backgroundColor: Color(0xFF00C6FF),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Consumer(
                      builder: (_, ref, _) =>
                          Text(ref.watch(trProvider)('profile.qr_and_share')),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00C6FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Scan QR Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/qr-scan');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF232E3C)
                      : Colors.grey.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Color(0xFF00C6FF),
                  size: 20,
                ),
                label: Text(
                  'Scan another QR Code',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrPatternPainter extends CustomPainter {
  final Color color;

  const _QrPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final dotSize = size.width / 18;

    // Corner Markers
    _drawMarker(canvas, const Offset(12, 12), dotSize * 3.5, paint);
    _drawMarker(
      canvas,
      Offset(size.width - 12 - dotSize * 3.5, 12),
      dotSize * 3.5,
      paint,
    );
    _drawMarker(
      canvas,
      Offset(12, size.height - 12 - dotSize * 3.5),
      dotSize * 3.5,
      paint,
    );

    // Decorative grid dots
    for (int r = 3; r < 15; r++) {
      for (int c = 3; c < 15; c++) {
        if ((r >= 7 && r <= 11) && (c >= 7 && c <= 11)) {
          continue; // Center hole for avatar
        }
        if ((r * 7 + c * 13) % 3 == 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                c * dotSize + 6,
                r * dotSize + 6,
                dotSize * 0.8,
                dotSize * 0.8,
              ),
              const Radius.circular(2),
            ),
            paint,
          );
        }
      }
    }
  }

  void _drawMarker(Canvas canvas, Offset offset, double size, Paint paint) {
    // Outer square
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(offset.dx, offset.dy, size, size),
        const Radius.circular(6),
      ),
      paint,
    );

    // Inner filled square
    paint.style = PaintingStyle.fill;
    final innerOffset = offset + Offset(size * 0.28, size * 0.28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(innerOffset.dx, innerOffset.dy, size * 0.44, size * 0.44),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
