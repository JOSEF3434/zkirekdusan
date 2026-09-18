// lib/features/profile/presentation/widgets/qr_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/localization_service.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  bool _isTorchOn = false;
  bool _isProcessing = false;
  final TextEditingController _manualInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.72;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? const Color(0xFFFFB300) : Colors.white70,
            ),
            tooltip: 'Flashlight',
            onPressed: () {
              setState(() => _isTorchOn = !_isTorchOn);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isTorchOn ? 'Flashlight enabled' : 'Flashlight disabled',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Darkened Camera Background Simulation
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Color(0xFF131D2A), Color(0xFF090D14), Colors.black],
              ),
            ),
          ),

          // Scanning Overlay with Cutout
          CustomPaint(
            size: size,
            painter: _ScannerOverlayPainter(scanAreaSize: scanAreaSize),
          ),

          // Central Scan Target Frame
          SizedBox(
            width: scanAreaSize,
            height: scanAreaSize,
            child: Stack(
              children: [
                // 4 Corner brackets
                _buildCornerBrackets(scanAreaSize),

                // Animated Laser Line
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Positioned(
                      top: _animation.value * (scanAreaSize - 4),
                      left: 10,
                      right: 10,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFF00C6FF),
                              Color(0xFF0072FF),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF00C6FF,
                              ).withValues(alpha: 0.8),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Instructional Text
          Positioned(
            top: (size.height / 2) + (scanAreaSize / 2) + 24,
            child: Column(
              children: [
                const Text(
                  'Point camera at a Zikre Kidusan QR code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Scan profile or group invite QR to open directly',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),

          // Bottom Action Buttons (Manual Input / Gallery)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Manual Username / Link Input Button
                FilledButton.tonalIcon(
                  onPressed: _showManualInputDialog,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2638),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(
                    Icons.keyboard_rounded,
                    color: Color(0xFF00C6FF),
                  ),
                  label: const Text(
                    'Enter Code / @user',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Demo Scanner Trigger (Simulate scan)
                FilledButton.icon(
                  onPressed: () => _handleScannedCode(
                    'https://app.zikrekidusan.com/u/sara_bi',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00C6FF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.black,
                  ),
                  label: const Text(
                    'Test QR',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerBrackets(double size) {
    const cornerSize = 24.0;
    const strokeWidth = 3.5;
    const color = Color(0xFF00C6FF);

    return Stack(
      children: [
        // Top-left
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: strokeWidth),
                left: BorderSide(color: color, width: strokeWidth),
              ),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
            ),
          ),
        ),
        // Top-right
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: strokeWidth),
                right: BorderSide(color: color, width: strokeWidth),
              ),
              borderRadius: BorderRadius.only(topRight: Radius.circular(12)),
            ),
          ),
        ),
        // Bottom-left
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color, width: strokeWidth),
                left: BorderSide(color: color, width: strokeWidth),
              ),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12)),
            ),
          ),
        ),
        // Bottom-right
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color, width: strokeWidth),
                right: BorderSide(color: color, width: strokeWidth),
              ),
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  void _showManualInputDialog() {
    _manualInputController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF17212B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Enter Profile / Link',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter a username (e.g. sara_bi) or a full Zikre Kidusan URL:',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _manualInputController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '@username or URL...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: const Color(0xFF0E1621),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.link_rounded,
                  color: Color(0xFF00C6FF),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              ref.read(trProvider)('common.cancel'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00C6FF),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final text = _manualInputController.text.trim();
              Navigator.pop(ctx);
              if (text.isNotEmpty) {
                _handleScannedCode(text);
              }
            },
            child: Consumer(
              builder: (_, ref, _) => Text(
                ref.watch(trProvider)('profile.go_to_profile'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleScannedCode(String rawCode) {
    if (_isProcessing) return;
    _isProcessing = true;

    final trimmed = rawCode.trim();

    // 1. Check if it's a canonical profile URL: https://app.zikrekidusan.com/u/<username>
    final profileRegex = RegExp(
      r'(?:https?:\/\/)?(?:app\.zikrekidusan\.com|zikrekidusan\.com)\/u\/([a-zA-Z0-9_\.\-]+)',
      caseSensitive: false,
    );
    final profileMatch = profileRegex.firstMatch(trimmed);

    // 2. Check if custom scheme: zikrekidusan://profile/user/<username>
    final schemeRegex = RegExp(
      r'zikrekidusan:\/\/profile\/user\/([a-zA-Z0-9_\.\-]+)',
      caseSensitive: false,
    );
    final schemeMatch = schemeRegex.firstMatch(trimmed);

    // 3. Check group canonical link: https://app.zikrekidusan.com/g/<id> or t.me/<slug>
    final groupRegex = RegExp(
      r'(?:https?:\/\/)?(?:app\.zikrekidusan\.com\/g|t\.me)\/([a-zA-Z0-9_\.\-]+)',
      caseSensitive: false,
    );
    final groupMatch = groupRegex.firstMatch(trimmed);

    if (profileMatch != null) {
      final username = profileMatch.group(1)!;
      _navigateToProfile(username);
    } else if (schemeMatch != null) {
      final username = schemeMatch.group(1)!;
      _navigateToProfile(username);
    } else if (groupMatch != null) {
      final groupId = groupMatch.group(1)!;
      _navigateToGroup(groupId);
    } else if (trimmed.startsWith('@')) {
      final username = trimmed.substring(1);
      _navigateToProfile(username);
    } else if (!trimmed.contains(' ') &&
        !trimmed.contains('/') &&
        trimmed.length >= 3) {
      // Plain username fallback
      _navigateToProfile(trimmed);
    } else {
      _showGenericResult(trimmed);
    }
  }

  void _navigateToProfile(String username) {
    HapticFeedback.mediumImpact();
    context.pushReplacement('/profile/user/$username');
  }

  void _navigateToGroup(String groupId) {
    HapticFeedback.mediumImpact();
    context.pushReplacement('/groups/$groupId');
  }

  void _showGenericResult(String result) {
    _isProcessing = false;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF17212B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scanned QR Code',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1621),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                result,
                style: const TextStyle(color: Color(0xFF00C6FF), fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: result));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: Consumer(
                      builder: (_, ref, _) =>
                          Text(ref.watch(trProvider)('common.copy')),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00C6FF),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Consumer(
                      builder: (_, ref, _) => Text(
                        ref.watch(trProvider)('common.done'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final double scanAreaSize;

  _ScannerOverlayPainter({required this.scanAreaSize});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65);
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final scanRect = Rect.fromCenter(
      center: center,
      width: scanAreaSize,
      height: scanAreaSize,
    );
    final rrect = RRect.fromRectAndRadius(scanRect, const Radius.circular(16));

    // Draw background mask with cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backgroundPaint);
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter oldDelegate) => false;
}
