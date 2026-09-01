// lib/features/splash/presentation/splash_screen.dart
// Startup splash screen; routing is handled deterministically by RouterNotifier.

import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// Ethiopic-compatible font family fallbacks across Android, iOS, Web, and Desktop
  static const List<String> _amharicFontFallback = [
    'Noto Serif Ethiopic',
    'Noto Sans Ethiopic',
    'Abyssinica SIL',
    'Nyala',
    'Geez Pro',
    'sans-serif',
  ];

  late final AnimationController _entranceController;
  late final AnimationController _ambientController;

  // Staggered Entrance Animations
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;

  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;

  late final Animation<double> _quoteOpacity;
  late final Animation<Offset> _quoteSlide;
  late final Animation<double> _goldenGlowOpacity;

  late final Animation<double> _authorOpacity;
  late final Animation<Offset> _authorSlide;

  late final Animation<double> _spinnerOpacity;

  // Ambient Candlelight Pulse
  late final Animation<double> _candlePulse;

  // Pre-calculated particles for deterministic, performant rendering
  late final List<_LightParticle> _particles;

  @override
  void initState() {
    super.initState();

    // 1. Entrance Choreography (2400ms smooth reverent reveal)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // 2. Ambient Candlelight Breathing Animation (4000ms loop)
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // Logo reveal (0.0 -> 0.35)
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0.0, -0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
      ),
    );

    // Title reveal (0.15 -> 0.45)
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.45, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    // Golden light/glow illumination (0.30 -> 0.70)
    _goldenGlowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.30, 0.70, curve: Curves.easeOut),
      ),
    );

    // Quote reveal: Gentle fade-in + upward motion (0.35 -> 0.75)
    _quoteOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
      ),
    );
    _quoteSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // Author reveal: Slow elegant fade + slight upward motion (0.65 -> 1.0)
    _authorOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );
    _authorSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Spinner reveal (0.75 -> 1.0)
    _spinnerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
      ),
    );

    // Continuous subtle candlelight pulse
    _candlePulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _ambientController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Initialize sacred light particles with fixed random seeds for smooth performance
    final rand = math.Random(42);
    _particles = List.generate(14, (index) {
      return _LightParticle(
        relativeX: rand.nextDouble(),
        speed: 0.15 + rand.nextDouble() * 0.25,
        size: 2.0 + rand.nextDouble() * 2.8,
        baseAlpha: 0.12 + rand.nextDouble() * 0.18,
        seed: rand.nextDouble() * 100,
      );
    });

    _entranceController.forward();
    _ambientController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    // Responsive scaling for different Android screen sizes and orientations
    final isCompact = size.height < 650 || size.width < 360;
    final logoSize = isCompact ? 100.0 : 120.0;
    final titleFontSize = isCompact ? 24.0 : 28.0;
    final quoteFontSize = isCompact ? 15.0 : 16.5;
    final authorFontSize = isCompact ? 12.5 : 14.0;
    final spacing = isCompact ? 16.0 : 22.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Subtle Orthodox Sacred Light Particles ───────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _SacredParticlesPainter(
                    particles: _particles,
                    progress: _ambientController.value,
                    glowOpacity: _goldenGlowOpacity.value,
                  ),
                );
              },
            ),
          ),

          // ── Main Splash Content ──────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. Logo with gentle entrance
                      FadeTransition(
                        opacity: _logoOpacity,
                        child: SlideTransition(
                          position: _logoSlide,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              'assets/images/logo.jpg',
                              width: logoSize,
                              height: logoSize,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.stream_rounded,
                                  size: logoSize * 0.6,
                                  color: theme.colorScheme.primary,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: spacing),

                      // 2. App Title with subtle slide-in
                      FadeTransition(
                        opacity: _titleOpacity,
                        child: SlideTransition(
                          position: _titleSlide,
                          child: Text(
                            'ዝክረ ክዱሳን',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  fontFamilyFallback: _amharicFontFallback,
                                  letterSpacing: 0.3,
                                ) ??
                                TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  fontFamilyFallback: _amharicFontFallback,
                                ),
                          ),
                        ),
                      ),
                      SizedBox(height: spacing * 1.1),

                      // 3. Church-Inspired Illuminated Amharic Quote & Attribution
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _entranceController,
                          _ambientController,
                        ]),
                        builder: (context, child) {
                          final glowVal =
                              _goldenGlowOpacity.value * _candlePulse.value;

                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              // Soft golden candlelight halo behind the sacred quote
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 1.1,
                                colors: [
                                  const Color(0xFFF5A623).withValues(
                                    alpha: 0.10 * glowVal.clamp(0.0, 1.0),
                                  ),
                                  const Color(0xFF006B5E).withValues(
                                    alpha: 0.03 * glowVal.clamp(0.0, 1.0),
                                  ),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.6, 1.0],
                              ),
                              border: Border.all(
                                color: const Color(0xFFF5A623).withValues(
                                  alpha: 0.16 * glowVal.clamp(0.0, 1.0),
                                ),
                                width: 1.0,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18.0,
                              vertical: 16.0,
                            ),
                            child: child,
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Main Quote with upward motion + golden glow
                            FadeTransition(
                              opacity: _quoteOpacity,
                              child: SlideTransition(
                                position: _quoteSlide,
                                child: Text(
                                  '✝️ፍቅር ያጌብረኒ ከመ እንግር ዜናሆሙ ለቅዱሳን!🌿',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: quoteFontSize,
                                    fontWeight: FontWeight.w600,
                                    height: 1.6,
                                    color: const Color(0xFF1E293B),
                                    fontFamilyFallback: _amharicFontFallback,
                                    letterSpacing: 0.15,
                                    shadows: [
                                      Shadow(
                                        color: const Color(0xFFF5A623)
                                            .withValues(alpha: 0.25),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10.0),

                            // Subtle Orthodox Gold Divider
                            FadeTransition(
                              opacity: _authorOpacity,
                              child: Container(
                                width: 40,
                                height: 1.5,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(1),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Color(0xFFD4AF37),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10.0),

                            // Author / Source with slow elegant fade
                            FadeTransition(
                              opacity: _authorOpacity,
                              child: SlideTransition(
                                position: _authorSlide,
                                child: Text(
                                  'አባ ጊዮርጊስ ዘጋስጫ (መጽሐፈ ምሥጢር)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: authorFontSize,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                    color: const Color(0xFF5A6E6A),
                                    fontFamilyFallback: _amharicFontFallback,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: spacing * 1.5),

                      // 4. Loading Indicator with gentle fade
                      FadeTransition(
                        opacity: _spinnerOpacity,
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A lightweight, calm particle for floating candlelight/ambient motes
class _LightParticle {
  final double relativeX;
  final double speed;
  final double size;
  final double baseAlpha;
  final double seed;

  const _LightParticle({
    required this.relativeX,
    required this.speed,
    required this.size,
    required this.baseAlpha,
    required this.seed,
  });
}

/// Custom painter rendering subtle, calm golden candlelight particles
class _SacredParticlesPainter extends CustomPainter {
  final List<_LightParticle> particles;
  final double progress;
  final double glowOpacity;

  _SacredParticlesPainter({
    required this.particles,
    required this.progress,
    required this.glowOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (glowOpacity <= 0.01) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      // Smooth continuous vertical ascent
      final yOffset = ((progress * p.speed + p.seed * 0.01) % 1.0);
      final y = size.height * (1.0 - yOffset);
      // Gentle horizontal sway
      final sway = math.sin(progress * 2 * math.pi + p.seed) * 8.0;
      final x = (p.relativeX * size.width) + sway;

      // Soft flicker
      final flicker = 0.7 + 0.3 * math.sin(progress * 4 * math.pi + p.seed);
      final alpha = (p.baseAlpha * glowOpacity * flicker).clamp(0.0, 1.0);

      paint.color = const Color(0xFFF5A623).withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SacredParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glowOpacity != glowOpacity;
  }
}
