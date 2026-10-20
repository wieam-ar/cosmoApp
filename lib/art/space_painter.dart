import 'dart:math';

import 'package:flutter/material.dart';

/// Planet classification types.
enum PlanetKind { purpleMoon, lava, iceWorld, gasGiant }

class _StarData {
  final double xRatio; // 0..1
  final double yRatio; // 0..1
  final int layer; // 0: far, 1: mid, 2: near
  final double radius;
  final double phase;
  final int tint; // 0 white, 1 cyan, 2 gold, 3 pink

  const _StarData(
    this.xRatio,
    this.yRatio,
    this.layer,
    this.radius,
    this.phase,
    this.tint,
  );
}

/// Procedural space background: deep purple nebula, tinted starfield,
/// detailed planets, lava ground and shooting stars (logo mood).
class SpacePainter {
  static final List<_StarData> _stars = _generateStars();

  static const _tints = [
    Color(0xFFFFFFFF),
    Color(0xFFBDFBFF),
    Color(0xFFFFE9A6),
    Color(0xFFFFC2E2),
  ];

  static List<_StarData> _generateStars() {
    final rng = Random(42111);
    final list = <_StarData>[];
    for (int i = 0; i < 110; i++) {
      final layer = i < 60 ? 0 : (i < 92 ? 1 : 2);
      final radius = layer == 0 ? 1.0 : (layer == 1 ? 1.8 : 2.8);
      list.add(
        _StarData(
          rng.nextDouble(),
          rng.nextDouble(),
          layer,
          radius,
          rng.nextDouble() * pi * 2,
          rng.nextInt(4),
        ),
      );
    }
    return list;
  }

  /// Full-screen deep-space gradient with soft nebula clouds.
  static void nebula(Canvas canvas, Size size, {double t = 0.0}) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF0B0830), Color(0xFF2A1670), Color(0xFF3B1C8C)],
          stops: [0.0, 0.6, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
    );
    void cloud(double x, double y, double r, Color c, double phase) {
      final drift = sin(t * 0.25 + phase) * 14;
      canvas.drawCircle(
        Offset(size.width * x + drift, size.height * y),
        r,
        Paint()
          ..shader = RadialGradient(colors: [c, c.withValues(alpha: 0)])
              .createShader(
                Rect.fromCircle(
                  center: Offset(size.width * x + drift, size.height * y),
                  radius: r,
                ),
              ),
      );
    }

    cloud(0.15, 0.2, size.width * 0.7, const Color(0x558C4DFF), 0);
    cloud(0.9, 0.45, size.width * 0.6, const Color(0x3331E8F4), 2);
    cloud(0.35, 0.8, size.width * 0.8, const Color(0x44FF4FA3), 4);
  }

  /// 3-layer parallax starfield with twinkling animation.
  static void starfield(
    Canvas canvas,
    Size size, {
    double t = 0.0,
    double parallaxX = 0.0,
    double parallaxY = 0.0,
  }) {
    if (size.width <= 0 || size.height <= 0) return;

    for (final s in _stars) {
      final pFactor = (s.layer + 1) * 15.0;
      final x = (s.xRatio * size.width + parallaxX * pFactor) % size.width;
      final y = (s.yRatio * size.height + parallaxY * pFactor) % size.height;

      final twinkle = sin(t * 3.0 + s.phase) * 0.35 + 0.65;
      final alpha =
          (s.layer == 0 ? 0.45 : (s.layer == 1 ? 0.8 : 0.98)) * twinkle;
      final color = _tints[s.tint].withValues(alpha: alpha.clamp(0.0, 1.0));

      if (s.layer == 2) {
        final r = s.radius * (0.8 + 0.3 * twinkle);
        canvas.drawCircle(
          Offset(x, y),
          r * 3.2,
          Paint()
            ..color = color.withValues(alpha: 0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        final starPath = Path()
          ..moveTo(x, y - r * 2.4)
          ..quadraticBezierTo(x, y, x + r * 2.4, y)
          ..quadraticBezierTo(x, y, x, y + r * 2.4)
          ..quadraticBezierTo(x, y, x - r * 2.4, y)
          ..quadraticBezierTo(x, y, x, y - r * 2.4)
          ..close();
        canvas.drawPath(starPath, Paint()..color = color);
      } else {
        canvas.drawCircle(
          Offset(x, y),
          s.radius * twinkle,
          Paint()..color = color,
        );
      }
    }
  }

  /// Draws a detailed planet with atmosphere, shading and surface features.
  static void planet(
    Canvas canvas,
    Offset center,
    double radius,
    PlanetKind kind, {
    double t = 0.0,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    Color glowColor;
    List<Color> body;
    switch (kind) {
      case PlanetKind.purpleMoon:
        glowColor = const Color(0x779B6BFF);
        body = const [Color(0xFFD6B4FF), Color(0xFF8E5CE0), Color(0xFF2C1A66)];
        break;
      case PlanetKind.lava:
        glowColor = const Color(0x99FF5A3C);
        body = const [Color(0xFFFFB347), Color(0xFFE8321C), Color(0xFF5A0F10)];
        break;
      case PlanetKind.iceWorld:
        glowColor = const Color(0x7770C8FF);
        body = const [Color(0xFFF2FDFF), Color(0xFF70B8FF), Color(0xFF1B55C8)];
        break;
      case PlanetKind.gasGiant:
        glowColor = const Color(0x66FFB36B);
        body = const [Color(0xFFFFD79A), Color(0xFFE0704A), Color(0xFF4A1F3A)];
        break;
    }

    // ring (back half) for gas giant
    if (kind == PlanetKind.gasGiant) _ring(canvas, center, radius, back: true);

    // atmosphere
    canvas.drawCircle(
      center,
      radius * 1.18,
      Paint()
        ..color = glowColor
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.3),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: body,
          stops: const [0.0, 0.55, 1.0],
          center: const Alignment(-0.4, -0.4),
          radius: 0.95,
        ).createShader(rect),
    );

    // surface features clipped to the sphere
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    switch (kind) {
      case PlanetKind.purpleMoon:
        _crater(
          canvas,
          center + Offset(-radius * 0.3, -radius * 0.25),
          radius * 0.22,
        );
        _crater(
          canvas,
          center + Offset(radius * 0.32, radius * 0.1),
          radius * 0.16,
        );
        _crater(
          canvas,
          center + Offset(-radius * 0.05, radius * 0.5),
          radius * 0.2,
        );
        _crater(
          canvas,
          center + Offset(radius * 0.5, -radius * 0.4),
          radius * 0.1,
        );
        break;
      case PlanetKind.lava:
        final pulse = 0.65 + 0.35 * sin(t * 2.5);
        final crack = Paint()
          ..color = Color.fromRGBO(255, 215, 80, pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.06
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        final dark = Paint()..color = const Color(0x66300808);
        // dark rock plates
        canvas.drawOval(
          Rect.fromCenter(
            center: center + Offset(-radius * 0.3, -radius * 0.1),
            width: radius * 0.8,
            height: radius * 0.55,
          ),
          dark,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: center + Offset(radius * 0.35, radius * 0.4),
            width: radius * 0.7,
            height: radius * 0.45,
          ),
          dark,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: center + Offset(radius * 0.4, -radius * 0.4),
            width: radius * 0.45,
            height: radius * 0.3,
          ),
          dark,
        );
        final path = Path()
          ..moveTo(center.dx - radius * 0.9, center.dy + radius * 0.1)
          ..lineTo(center.dx - radius * 0.35, center.dy + radius * 0.25)
          ..lineTo(center.dx, center.dy - radius * 0.05)
          ..lineTo(center.dx + radius * 0.5, center.dy + radius * 0.05)
          ..lineTo(center.dx + radius * 0.9, center.dy - radius * 0.25)
          ..moveTo(center.dx, center.dy - radius * 0.05)
          ..lineTo(center.dx + radius * 0.1, center.dy - radius * 0.7);
        canvas.drawPath(path, crack);
        break;
      case PlanetKind.iceWorld:
        final band = Paint()..color = const Color(0x44FFFFFF);
        for (var i = -2; i <= 2; i++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: center + Offset(sin(t * 0.3 + i) * 3, i * radius * 0.3),
              width: radius * 2.2,
              height: radius * 0.14,
            ),
            band,
          );
        }
        _crater(
          canvas,
          center + Offset(radius * 0.3, -radius * 0.3),
          radius * 0.14,
        );
        break;
      case PlanetKind.gasGiant:
        const bands = [
          Color(0x55FFE3B0),
          Color(0x55A8442E),
          Color(0x44FFF1D0),
          Color(0x55702A32),
        ];
        for (var i = 0; i < 6; i++) {
          canvas.drawRect(
            Rect.fromLTWH(
              center.dx - radius,
              center.dy - radius + i * radius * 0.34 + sin(t * 0.5 + i) * 2,
              radius * 2,
              radius * 0.2,
            ),
            Paint()..color = bands[i % bands.length],
          );
        }
        break;
    }
    // terminator shadow (lower right)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x00000000), Color(0x00000000), Color(0x77000000)],
          stops: [0.0, 0.55, 1.0],
          center: Alignment(-0.45, -0.45),
          radius: 1.35,
        ).createShader(rect),
    );
    canvas.restore();

    // rim light
    canvas.drawArc(
      rect.deflate(radius * 0.04),
      pi * 1.05,
      pi * 0.5,
      false,
      Paint()
        ..color = const Color(0x77FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.5, radius * 0.04)
        ..strokeCap = StrokeCap.round,
    );

    if (kind == PlanetKind.gasGiant) _ring(canvas, center, radius, back: false);
  }

  static void _crater(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = const Color(0x33000000));
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      pi * 0.9,
      pi * 0.9,
      false,
      Paint()
        ..color = const Color(0x44FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, r * 0.18),
    );
  }

  static void _ring(
    Canvas canvas,
    Offset center,
    double radius, {
    required bool back,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.4);
    final oval = Rect.fromCenter(
      center: Offset.zero,
      width: radius * 2.9,
      height: radius * 0.7,
    );
    canvas.clipRect(
      back
          ? Rect.fromLTRB(-radius * 3, -radius * 3, radius * 3, 0)
          : Rect.fromLTRB(-radius * 3, 0, radius * 3, radius * 3),
    );
    canvas.drawOval(
      oval,
      Paint()
        ..color = const Color(0xCCFFE9B0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.16,
    );
    canvas.drawOval(
      oval.deflate(radius * 0.14),
      Paint()
        ..color = const Color(0x88FFB36B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.06,
    );
    canvas.restore();
  }

  /// Alias for planet.
  static void drawPlanet(
    Canvas canvas,
    Offset center,
    double radius,
    PlanetKind kind, {
    double t = 0.0,
  }) => planet(canvas, center, radius, kind, t: t);

  /// Alien planet surface at the bottom with glowing lava rivers and embers.
  static void lavaSurface(
    Canvas canvas,
    Size size, {
    double t = 0.0,
    double heightFactor = 0.25,
  }) {
    final surfaceHeight = size.height * heightFactor;
    final topY = size.height - surfaceHeight;

    canvas.drawRect(
      Rect.fromLTWH(0, topY - 14, size.width, 44),
      Paint()
        ..color = const Color(0x77FF4A2E)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    final wave1 = sin(t * 1.5) * 4;
    final wave2 = cos(t * 2.0) * 5;
    final terrain = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, topY + 20)
      ..quadraticBezierTo(
        size.width * 0.25,
        topY - 15 + wave1,
        size.width * 0.5,
        topY + 5 + wave2,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        topY + 25 - wave1,
        size.width,
        topY - 10 + wave2,
      )
      ..lineTo(size.width, size.height)
      ..close();

    final terrainRect = Rect.fromLTWH(
      0,
      topY - 20,
      size.width,
      surfaceHeight + 20,
    );
    canvas.drawPath(
      terrain,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF5A1F4A), Color(0xFF2A0F3E), Color(0xFF140A2C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(terrainRect),
    );
    // lit rim on the ridge
    canvas.drawPath(
      Path()
        ..moveTo(0, topY + 20)
        ..quadraticBezierTo(
          size.width * 0.25,
          topY - 15 + wave1,
          size.width * 0.5,
          topY + 5 + wave2,
        )
        ..quadraticBezierTo(
          size.width * 0.75,
          topY + 25 - wave1,
          size.width,
          topY - 10 + wave2,
        ),
      Paint()
        ..color = const Color(0xFFFF9A5C).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final glow = 0.6 + 0.3 * sin(t * 4.0);
    final crackPath = Path()
      ..moveTo(size.width * 0.15, topY + 25)
      ..lineTo(size.width * 0.22, topY + 45)
      ..lineTo(size.width * 0.35, topY + 55)
      ..lineTo(size.width * 0.42, topY + 80)
      ..moveTo(size.width * 0.6, topY + 30)
      ..lineTo(size.width * 0.72, topY + 50)
      ..lineTo(size.width * 0.85, topY + 60)
      ..moveTo(size.width * 0.72, topY + 50)
      ..lineTo(size.width * 0.7, topY + 82);
    canvas.drawPath(
      crackPath,
      Paint()
        ..color = Color.fromRGBO(255, 120, 60, glow * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      crackPath,
      Paint()
        ..color = Color.fromRGBO(255, 214, 102, 0.7 + 0.3 * sin(t * 4.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // floating embers
    for (var i = 0; i < 9; i++) {
      final life = (t * 0.35 + i * 0.113) % 1.0;
      final x = size.width * ((i * 0.137 + 0.05) % 1.0) + sin(t * 2 + i) * 10;
      final y = size.height - life * surfaceHeight * 1.6;
      canvas.drawCircle(
        Offset(x, y),
        1.6 + (i % 3) * 0.6,
        Paint()..color = Color.fromRGBO(255, 190, 90, (1 - life) * 0.9),
      );
    }
  }

  /// Fast shooting star streak with a glowing head.
  static void shootingStar(Canvas canvas, Size size, {double t = 0.0}) {
    final cycle = (t * 0.8) % 3.0;
    if (cycle > 0.8) return;

    final progress = cycle / 0.8;
    final startX = size.width * 0.9 - progress * (size.width * 0.7);
    final startY = size.height * 0.1 + progress * (size.height * 0.3);
    final endX = startX + 90.0;
    final endY = startY - 45.0;

    canvas.drawLine(
      Offset(endX, endY),
      Offset(startX, startY),
      Paint()
        ..shader =
            const LinearGradient(
              colors: [Color(0x00FFFFFF), Color(0x8870A1FF), Color(0xFFFFFFFF)],
            ).createShader(
              Rect.fromPoints(Offset(endX, endY), Offset(startX, startY)),
            )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(startX, startY),
      5,
      Paint()
        ..color = const Color(0xCCBDFBFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      Offset(startX, startY),
      2.2,
      Paint()..color = Colors.white,
    );
  }
}
