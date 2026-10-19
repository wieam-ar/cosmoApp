import 'dart:math';

import 'package:flutter/material.dart';

/// Procedural UFO space saucer painter with glass dome, pulsing lights & tractor beam.
class UfoPainter {
  /// Draws UFO centered at [center].
  static void draw(
    Canvas canvas,
    Offset center,
    double size, {
    double t = 0.0,
    double beamLength = 0.0,
    Color beamColor = const Color(0x6670A1FF),
  }) {
    final wobbleY = sin(t * 3.5) * 6.0;
    final wobbleAngle = sin(t * 2.5) * 0.06;
    final ufoCenter = center + Offset(0, wobbleY);

    canvas.save();
    canvas.translate(ufoCenter.dx, ufoCenter.dy);
    canvas.rotate(wobbleAngle);

    final rx = size * 0.5;
    final ry = size * 0.2;

    // 1. Translucent Tractor Beam Cone
    if (beamLength > 0.0) {
      final beamHeight = 220.0 * beamLength.clamp(0.0, 1.0);
      final topWidth = rx * 0.7;
      final bottomWidth = rx * 1.8 * (0.5 + 0.5 * beamLength);

      final beamPath = Path()
        ..moveTo(-topWidth / 2, ry * 0.2)
        ..lineTo(-bottomWidth / 2, beamHeight)
        ..lineTo(bottomWidth / 2, beamHeight)
        ..lineTo(topWidth / 2, ry * 0.2)
        ..close();

      final beamRect = Rect.fromLTWH(
        -bottomWidth / 2,
        0,
        bottomWidth,
        beamHeight,
      );

      final beamPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            beamColor.withValues(alpha: 0.65),
            beamColor.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(beamRect);

      canvas.drawPath(beamPath, beamPaint);
    }

    // 2. Glass Dome
    final domeRect = Rect.fromCenter(
      center: Offset(0, -ry * 0.4),
      width: rx * 0.9,
      height: ry * 1.6,
    );

    final domePaint = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xDD70A1FF), Color(0x881E90FF), Color(0x330984E3)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(domeRect);

    canvas.drawArc(domeRect, pi, pi, true, domePaint);

    // Glass Dome Highlight Arc
    final highlightPaint = Paint()
      ..color = const Color(0xAAFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawArc(domeRect.deflate(3.0), pi + 0.5, 1.2, false, highlightPaint);

    // 3. Main Saucer Metallic Body
    final saucerRect = Rect.fromCenter(
      center: Offset.zero,
      width: rx * 2,
      height: ry * 2,
    );

    final saucerPaint = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFFD6A2E8), Color(0xFF9B59B6), Color(0xFF4834D4)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(saucerRect);

    canvas.drawOval(saucerRect, saucerPaint);

    // Underside glow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, ry * 0.9),
        width: rx * 1.2,
        height: ry * 0.7,
      ),
      Paint()
        ..color = const Color(0x6631E8F4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Top gloss on the saucer
    canvas.drawArc(
      saucerRect.deflate(ry * 0.25),
      pi * 1.1,
      pi * 0.5,
      false,
      Paint()
        ..color = const Color(0x99FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Saucer Outer Rim Lip
    final rimPaint = Paint()
      ..color = const Color(0xFF8E7BFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawOval(saucerRect, rimPaint);

    // 4. Pulsing Lights around Saucer Rim
    const numLights = 5;
    final lightColors = [
      const Color(0xFFFF4757),
      const Color(0xFFFFA502),
      const Color(0xFF2ED573),
      const Color(0xFF1E90FF),
      const Color(0xFFFD79A8),
    ];

    for (int i = 0; i < numLights; i++) {
      final angle = pi * 0.15 + (i * pi * 0.7) / (numLights - 1);
      final lx = cos(angle) * (rx * 0.82);
      final ly = sin(angle) * (ry * 0.82);

      final pulse = (sin(t * 6.0 + i * 1.2) + 1.0) / 2.0;
      final lightColor = lightColors[i % lightColors.length];

      // Light Glow
      final glowPaint = Paint()
        ..color = lightColor.withValues(alpha: 0.4 + 0.6 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      canvas.drawCircle(Offset(lx, ly), 4.5 + pulse * 2.0, glowPaint);

      // Light Bulb
      final bulbPaint = Paint()
        ..color = Color.lerp(lightColor, Colors.white, pulse * 0.5)!;

      canvas.drawCircle(Offset(lx, ly), 3.0, bulbPaint);
    }

    canvas.restore();
  }
}
