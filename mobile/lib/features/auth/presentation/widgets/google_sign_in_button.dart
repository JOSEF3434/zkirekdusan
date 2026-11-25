// lib/features/auth/presentation/widgets/google_sign_in_button.dart
import 'package:flutter/material.dart';

/// Professional "Continue with Google" button conforming to Google Brand Guidelines.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;
  final double? width;
  final double? height;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Continue with Google',
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF131314) : Colors.white;
    final textColor = isDark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F);
    final borderColor = isDark ? const Color(0xFF8E918F) : const Color(0xFF747775);

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(color: borderColor.withValues(alpha: 0.35), width: 1),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isDark ? 0 : 0.5,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const GoogleIconWidget(size: 20),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Official Google "G" logo rendered using vector paths
class GoogleIconWidget extends StatelessWidget {
  final double size;

  const GoogleIconWidget({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleIconPainter(),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double s = w / 24.0; // Standard 24x24 Google G viewBox

    final paint = Paint()..style = PaintingStyle.fill;

    // Blue section (Right bar and bottom right arc)
    paint.color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(23.745 * s, 12.27 * s)
      ..cubicTo(23.745 * s, 11.48 * s, 23.675 * s, 10.73 * s, 23.55 * s, 10.0 * s)
      ..lineTo(12.0 * s, 10.0 * s)
      ..lineTo(12.0 * s, 14.51 * s)
      ..lineTo(18.59 * s, 14.51 * s)
      ..cubicTo(18.31 * s, 16.02 * s, 17.44 * s, 17.29 * s, 16.14 * s, 18.15 * s)
      ..lineTo(16.14 * s, 21.23 * s)
      ..lineTo(20.08 * s, 21.23 * s)
      ..cubicTo(22.39 * s, 19.1 * s, 23.745 * s, 15.98 * s, 23.745 * s, 12.27 * s)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Green section (Bottom arc)
    paint.color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(12.0 * s, 24.0 * s)
      ..cubicTo(15.24 * s, 24.0 * s, 17.96 * s, 22.92 * s, 20.08 * s, 20.98 * s)
      ..lineTo(16.14 * s, 17.9 * s)
      ..cubicTo(15.05 * s, 18.63 * s, 13.63 * s, 19.07 * s, 12.0 * s, 19.07 * s)
      ..cubicTo(8.87 * s, 19.07 * s, 6.22 * s, 16.96 * s, 5.27 * s, 14.12 * s)
      ..lineTo(1.2 * s, 14.12 * s)
      ..lineTo(1.2 * s, 17.27 * s)
      ..cubicTo(3.28 * s, 21.39 * s, 7.31 * s, 24.0 * s, 12.0 * s, 24.0 * s)
      ..close();
    canvas.drawPath(greenPath, paint);

    // Yellow section (Bottom left arc)
    paint.color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(5.27 * s, 14.12 * s)
      ..cubicTo(5.03 * s, 13.41 * s, 4.9 * s, 12.72 * s, 4.9 * s, 12.0 * s)
      ..cubicTo(4.9 * s, 11.28 * s, 5.03 * s, 10.59 * s, 5.27 * s, 9.88 * s)
      ..lineTo(5.27 * s, 6.73 * s)
      ..lineTo(1.2 * s, 6.73 * s)
      ..cubicTo(0.44 * s, 8.24 * s, 0.0 * s, 9.94 * s, 0.0 * s, 12.0 * s)
      ..cubicTo(0.0 * s, 14.06 * s, 0.44 * s, 15.76 * s, 1.2 * s, 17.27 * s)
      ..lineTo(5.27 * s, 14.12 * s)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Red section (Top arc)
    paint.color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(12.0 * s, 4.93 * s)
      ..cubicTo(13.76 * s, 4.93 * s, 15.34 * s, 5.54 * s, 16.59 * s, 6.72 * s)
      ..lineTo(20.17 * s, 3.14 * s)
      ..cubicTo(18.03 * s, 1.15 * s, 15.24 * s, 0.0 * s, 12.0 * s, 0.0 * s)
      ..cubicTo(7.31 * s, 0.0 * s, 3.28 * s, 2.61 * s, 1.2 * s, 6.73 * s)
      ..lineTo(5.27 * s, 9.88 * s)
      ..cubicTo(6.22 * s, 7.04 * s, 8.87 * s, 4.93 * s, 12.0 * s, 4.93 * s)
      ..close();
    canvas.drawPath(redPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
