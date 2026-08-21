import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/utils/time_phase_helper.dart';

/// Interactive & dynamically animated celestial body (Sun / Moon / Stars)
/// that morphs and animates in 60fps based on the current [TimePhase].
class AnimatedCelestialHero extends StatefulWidget {
  final TimePhase phase;
  final double size;

  const AnimatedCelestialHero({
    super.key,
    required this.phase,
    this.size = 100,
  });

  @override
  State<AnimatedCelestialHero> createState() => _AnimatedCelestialHeroState();
}

class _AnimatedCelestialHeroState extends State<AnimatedCelestialHero>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Continuous smooth rotation for sunrays / celestial corona
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Gentle breathing pulse animation for glowing aura
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = TimePhaseHelper.getPrimaryAccent(widget.phase);
    final secondaryColor = TimePhaseHelper.getSecondaryAccent(widget.phase);
    final isDay = TimePhaseHelper.isDaytime(widget.phase);

    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _CelestialPainter(
              phase: widget.phase,
              isDay: isDay,
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
              rotationAngle: _rotationController.value * 2 * math.pi,
              pulseScale: _pulseAnimation.value,
              twinkleProgress: _pulseController.value,
            ),
          ),
        );
      },
    );
  }
}

class _CelestialPainter extends CustomPainter {
  final TimePhase phase;
  final bool isDay;
  final Color primaryColor;
  final Color secondaryColor;
  final double rotationAngle;
  final double pulseScale;
  final double twinkleProgress;

  const _CelestialPainter({
    required this.phase,
    required this.isDay,
    required this.primaryColor,
    required this.secondaryColor,
    required this.rotationAngle,
    required this.pulseScale,
    required this.twinkleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * 0.42;

    // 1. Ambient Background Halo Aura
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: 0.35 * pulseScale),
          secondaryColor.withValues(alpha: 0.15 * pulseScale),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 2.2 * pulseScale));

    canvas.drawCircle(center, radius * 2.2 * pulseScale, haloPaint);

    if (isDay) {
      _paintSun(canvas, center, radius);
    } else {
      _paintMoonAndStars(canvas, center, radius, size);
    }
  }

  void _paintSun(Canvas canvas, Offset center, double radius) {
    // 2. Rotating Sunrays
    final rayPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor.withValues(alpha: 0.9),
          secondaryColor.withValues(alpha: 0.3),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.7))
      ..style = PaintingStyle.fill;

    const numRays = 8;
    for (int i = 0; i < numRays; i++) {
      final angle = rotationAngle + (i * 2 * math.pi / numRays);
      final rayStartDist = radius * 1.08;
      final rayEndDist = radius * (1.52 + 0.12 * math.sin(angle + pulseScale * 3));
      final rayWidthAngle = 0.12; // Ray thickness in radians

      final path = Path();
      final p1 = Offset(
        center.dx + rayStartDist * math.cos(angle - rayWidthAngle),
        center.dy + rayStartDist * math.sin(angle - rayWidthAngle),
      );
      final tip = Offset(
        center.dx + rayEndDist * math.cos(angle),
        center.dy + rayEndDist * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + rayStartDist * math.cos(angle + rayWidthAngle),
        center.dy + rayStartDist * math.sin(angle + rayWidthAngle),
      );

      path.moveTo(p1.dx, p1.dy);
      path.lineTo(tip.dx, tip.dy);
      path.lineTo(p2.dx, p2.dy);
      path.close();

      canvas.drawPath(path, rayPaint);
    }

    // 3. Inner Pulsing Solar Flare Corona
    final coronaPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 1.15 * pulseScale, coronaPaint);

    // 4. Main Sun Disc with Radiant Gradient
    final sunDiscPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(Colors.white, primaryColor, 0.2)!,
          primaryColor,
          secondaryColor,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, sunDiscPaint);

    // 5. Specular highlight for a rich 3D appearance
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.32, center.dy - radius * 0.32),
      radius * 0.28,
      highlightPaint,
    );
  }

  void _paintMoonAndStars(Canvas canvas, Offset center, double radius, Size size) {
    // 1. Draw Twinkling Starlight Particles
    final starOffsets = [
      Offset(center.dx - radius * 1.4, center.dy - radius * 1.1),
      Offset(center.dx + radius * 1.3, center.dy - radius * 1.2),
      Offset(center.dx + radius * 1.5, center.dy + radius * 0.8),
      Offset(center.dx - radius * 1.2, center.dy + radius * 1.2),
    ];

    final starOpacities = [
      (0.3 + 0.7 * twinkleProgress).clamp(0.0, 1.0),
      (0.9 - 0.6 * twinkleProgress).clamp(0.0, 1.0),
      (0.4 + 0.6 * (1 - twinkleProgress)).clamp(0.0, 1.0),
      (0.7 + 0.3 * math.sin(twinkleProgress * math.pi)).clamp(0.0, 1.0),
    ];

    final starPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < starOffsets.length; i++) {
      starPaint.color = Colors.white.withValues(alpha: starOpacities[i]);
      _drawSparkle(canvas, starOffsets[i], 4.0 * (0.8 + 0.4 * starOpacities[i]), starPaint);
    }

    // 2. Outer Moon Glow
    final moonGlowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.25 * pulseScale)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 1.18 * pulseScale, moonGlowPaint);

    // 3. Crescent Moon Path
    final moonRadius = radius * 0.95;
    final mainCircle = Path()..addOval(Rect.fromCircle(center: center, radius: moonRadius));
    final cutoutCircle = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(center.dx + moonRadius * 0.55, center.dy - moonRadius * 0.35),
        radius: moonRadius * 0.85,
      ));

    final crescentPath = Path.combine(PathOperation.difference, mainCircle, cutoutCircle);

    final moonPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white,
          primaryColor,
          secondaryColor,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: moonRadius))
      ..style = PaintingStyle.fill;

    canvas.drawPath(crescentPath, moonPaint);

    // 4. Moon Surface Highlight Arc
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final arcRect = Rect.fromCircle(center: center, radius: moonRadius - 1.5);
    canvas.drawArc(arcRect, math.pi * 0.7, math.pi * 0.8, false, highlightPaint);
  }

  void _drawSparkle(Canvas canvas, Offset pos, double size, Paint paint) {
    final path = Path();
    path.moveTo(pos.dx, pos.dy - size);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx + size, pos.dy);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy + size);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx - size, pos.dy);
    path.quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy - size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CelestialPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.pulseScale != pulseScale ||
        oldDelegate.twinkleProgress != twinkleProgress ||
        oldDelegate.phase != phase;
  }
}
