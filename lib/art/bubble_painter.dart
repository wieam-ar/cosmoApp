import 'dart:math';

import 'package:flutter/material.dart';

import '../config/bubble_types.dart';

/// Glossy glass-sphere bubble painter (logo style): saturated body, bright
/// glass rim, curved specular window and an element emblem with depth.
class BubblePainter {
  /// Draws a bubble centered at [center].
  static void draw(
    Canvas canvas,
    Offset center,
    double radius,
    BubbleType type, {
    double t = 0.0,
    double squashX = 1.0,
    double squashY = 1.0,
    double glow = 0.0,
    double alpha = 1.0,
    bool colorblind = false,
    double hits = 2,
    double hintGlow = 0,
    bool fireSource = false,
  }) {
    if (alpha <= 0.01) return;

    final style = kBubbleStyles[type] ?? kBubbleStyles[BubbleType.red]!;
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(squashX, squashY);

    if (alpha < 0.99) {
      canvas.saveLayer(
        Rect.fromCircle(center: Offset.zero, radius: radius * 1.6),
        Paint()..color = Color.fromRGBO(0, 0, 0, alpha),
      );
    }

    // 1. Outer glow (held / hint)
    final totalGlow = max(glow, hintGlow);
    if (totalGlow > 0.0) {
      canvas.drawCircle(
        Offset.zero,
        radius * (1.0 + 0.18 * totalGlow),
        Paint()
          ..color = style.lightColor.withValues(
            alpha: (0.6 * totalGlow).clamp(0.0, 1.0),
          )
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            radius * 0.45 * totalGlow,
          ),
      );
    }

    // 2. Body
    if (type == BubbleType.rainbow) {
      canvas.drawCircle(
        Offset.zero,
        radius,
        Paint()
          ..shader = SweepGradient(
            colors: const [
              Color(0xFFFF5E7E),
              Color(0xFFFFB347),
              Color(0xFFFFE45E),
              Color(0xFF5EE87F),
              Color(0xFF4DB8FF),
              Color(0xFFB77CFF),
              Color(0xFFFF5E7E),
            ],
            transform: GradientRotation(t * 2.0),
          ).createShader(rect),
      );
      // soften into a glassy ball
      canvas.drawCircle(
        Offset.zero,
        radius,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0x66FFFFFF), Color(0x00FFFFFF), Color(0x33000000)],
            stops: [0.0, 0.6, 1.0],
            center: Alignment(-0.3, -0.4),
          ).createShader(rect),
      );
    } else {
      canvas.drawCircle(
        Offset.zero,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [style.lightColor, style.midColor, style.darkColor],
            stops: const [0.0, 0.55, 1.0],
            center: const Alignment(-0.3, -0.4),
            radius: 1.05,
          ).createShader(rect),
      );
    }

    // 3. Glass rim glow (brighter toward the edge = see-through feel)
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0x00FFFFFF),
            style.lightColor.withValues(alpha: 0.0),
            style.lightColor.withValues(alpha: 0.5),
          ],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(rect),
    );

    // 4. Emblem
    _drawEmblem(canvas, radius, type, t, colorblind, hits);

    // 5. Bottom bounce light
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius * 0.82),
      pi * 0.18,
      pi * 0.64,
      false,
      Paint()
        ..color = const Color(0x44FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.5, radius * 0.1)
        ..strokeCap = StrokeCap.round,
    );

    // 6. Soft top-left highlight blob
    canvas.save();
    canvas.translate(-radius * 0.34, -radius * 0.4);
    canvas.rotate(-0.7);
    final blob = Rect.fromCenter(
      center: Offset.zero,
      width: radius * 0.62,
      height: radius * 0.32,
    );
    canvas.drawOval(
      blob,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xCCFFFFFF), Color(0x00FFFFFF)],
        ).createShader(blob),
    );
    canvas.restore();

    // 7. Curved specular window + dot
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius * 0.76),
      pi * 1.08,
      pi * 0.44,
      false,
      Paint()
        ..color = const Color(0xE6FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2.0, radius * 0.11)
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(cos(pi * 1.62) * radius * 0.76, sin(pi * 1.62) * radius * 0.76),
      max(1.2, radius * 0.06),
      Paint()..color = const Color(0xE6FFFFFF),
    );

    if (fireSource) _drawFireSource(canvas, radius, t);

    // 8. Twinkle
    final tw = (sin(t * 3.0 + radius) + 1) / 2;
    _sparkle(
      canvas,
      Offset(radius * 0.52, radius * 0.38),
      radius * (0.08 + 0.07 * tw),
      Colors.white.withValues(alpha: 0.35 + 0.5 * tw),
    );

    // 9. Saturated outline
    canvas.drawCircle(
      Offset.zero,
      radius - 0.5,
      Paint()
        ..color = style.darkColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.6, radius * 0.07),
    );

    if (alpha < 0.99) canvas.restore();
    canvas.restore();
  }

  // ---------------------------------------------------------------------
  // helpers
  // ---------------------------------------------------------------------

  static void _sparkle(Canvas canvas, Offset c, double r, Color color) {
    final p = Path()
      ..moveTo(c.dx, c.dy - r * 2)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r * 2, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r * 2)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r * 2, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r * 2)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  static void _drawFireSource(Canvas canvas, double radius, double t) {
    final size = radius * 0.32;
    final center = Offset(radius * 0.55, -radius * 0.55);
    final pulse = 0.82 + (sin(t * 6) + 1) * 0.09;
    final flame = Path()
      ..moveTo(center.dx, center.dy + size)
      ..cubicTo(
        center.dx - size * 1.1,
        center.dy + size * 0.2,
        center.dx - size * 0.35,
        center.dy - size * 0.25,
        center.dx,
        center.dy - size,
      )
      ..cubicTo(
        center.dx + size * 1.0,
        center.dy - size * 0.1,
        center.dx + size * 0.85,
        center.dy + size * 0.55,
        center.dx,
        center.dy + size,
      )
      ..close();
    canvas.drawCircle(
      center,
      size * 1.35 * pulse,
      Paint()
        ..color = const Color(0xAAFF7A24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(flame, Paint()..color = const Color(0xFFFF8A24));
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, size * 0.2),
        width: size * 0.42,
        height: size * 0.68,
      ),
      Paint()..color = const Color(0xFFFFE5A3),
    );
  }

  /// Fills [path] with a vertical gradient, adds a drop shadow (emboss) and a
  /// thin outline. In colorblind mode a bright white outline is added.
  static void _emblem(
    Canvas canvas,
    Path path,
    Rect bounds,
    Color top,
    Color bottom,
    double u,
    bool colorblind,
  ) {
    canvas.save();
    canvas.translate(0, u * 0.1);
    canvas.drawPath(path, Paint()..color = const Color(0x55000000));
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [top, bottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = colorblind ? Colors.white : const Color(0x44000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = colorblind ? u * 0.12 : u * 0.06
        ..strokeJoin = StrokeJoin.round,
    );
  }

  static void _drawEmblem(
    Canvas canvas,
    double radius,
    BubbleType type,
    double t,
    bool colorblind,
    double hits,
  ) {
    final u = radius * 0.5; // emblem unit
    final bounds = Rect.fromCenter(
      center: Offset.zero,
      width: u * 2,
      height: u * 2,
    );

    switch (type) {
      case BubbleType.red:
        // Flame: outer orange + inner yellow, flickering
        final flick = 1 + sin(t * 9) * 0.05;
        canvas.save();
        canvas.translate(0, u * 0.05);
        canvas.scale(1, flick);
        final outer = _flame(u);
        _emblem(
          canvas,
          outer,
          bounds,
          const Color(0xFFFFB02E),
          const Color(0xFFE8321C),
          u,
          colorblind,
        );
        canvas.save();
        canvas.translate(0, u * 0.28);
        canvas.scale(0.55);
        canvas.drawPath(
          _flame(u),
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFFFF59D), Color(0xFFFFB300)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
        );
        canvas.restore();
        canvas.restore();
        break;

      case BubbleType.blue:
        // Water swirl + droplets
        final wave = Path()
          ..moveTo(-u * 0.85, u * 0.35)
          ..cubicTo(
            -u * 0.55,
            -u * 0.55,
            u * 0.35,
            -u * 0.7,
            u * 0.55,
            -u * 0.15,
          )
          ..cubicTo(u * 0.75, u * 0.35, u * 0.1, u * 0.6, -u * 0.05, u * 0.15);
        final w = u * 0.34;
        canvas.drawPath(
          wave.shift(Offset(0, u * 0.1)),
          Paint()
            ..color = const Color(0x661565C0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawPath(
          wave,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFF9DEBFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w
            ..strokeCap = StrokeCap.round,
        );
        final drop = Paint()..color = const Color(0xE6FFFFFF);
        canvas.drawCircle(Offset(-u * 0.6, -u * 0.6), u * 0.13, drop);
        canvas.drawCircle(
          Offset(u * 0.2 + sin(t * 3) * u * 0.03, -u * 0.95),
          u * 0.09,
          drop,
        );
        canvas.drawCircle(Offset(u * 0.78, u * 0.5), u * 0.1, drop);
        break;

      case BubbleType.green:
        // Leaf with veins, gentle sway
        canvas.save();
        canvas.rotate(sin(t * 2.0) * 0.06);
        final leaf = Path()
          ..moveTo(-u * 0.7, u * 0.8)
          ..cubicTo(-u * 1.0, -u * 0.2, -u * 0.1, -u * 0.95, u * 0.85, -u * 0.8)
          ..cubicTo(u * 0.95, u * 0.0, u * 0.35, u * 0.8, -u * 0.7, u * 0.8)
          ..close();
        _emblem(
          canvas,
          leaf,
          bounds,
          const Color(0xFFC6F68D),
          const Color(0xFF1E9E3A),
          u,
          colorblind,
        );
        final vein = Paint()
          ..color = const Color(0xAA0F6B28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.09
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(-u * 0.7, u * 0.8),
          Offset(u * 0.62, -u * 0.62),
          vein,
        );
        vein.strokeWidth = u * 0.06;
        canvas.drawLine(
          Offset(-u * 0.1, u * 0.2),
          Offset(-u * 0.5, -u * 0.12),
          vein,
        );
        canvas.drawLine(
          Offset(u * 0.15, -u * 0.1),
          Offset(u * 0.55, u * 0.22),
          vein,
        );
        canvas.restore();
        break;

      case BubbleType.yellow:
        // Mountain with snow cap
        final mountain = Path()
          ..moveTo(-u * 1.0, u * 0.7)
          ..lineTo(-u * 0.1, -u * 0.7)
          ..lineTo(u * 0.25, -u * 0.15)
          ..lineTo(u * 0.5, -u * 0.35)
          ..lineTo(u * 1.0, u * 0.7)
          ..close();
        _emblem(
          canvas,
          mountain,
          bounds,
          const Color(0xFFB98253),
          const Color(0xFF6B4223),
          u,
          colorblind,
        );
        final snow = Path()
          ..moveTo(-u * 0.1, -u * 0.7)
          ..lineTo(u * 0.06, -u * 0.45)
          ..lineTo(-u * 0.02, -u * 0.38)
          ..lineTo(-u * 0.1, -u * 0.3)
          ..lineTo(-u * 0.2, -u * 0.37)
          ..lineTo(-u * 0.36, -u * 0.29)
          ..close();
        canvas.drawPath(snow, Paint()..color = const Color(0xFFFFFFFF));
        canvas.drawLine(
          Offset(-u * 1.0, u * 0.7),
          Offset(u * 1.0, u * 0.7),
          Paint()
            ..color = const Color(0xFF58C84A)
            ..strokeWidth = u * 0.16
            ..strokeCap = StrokeCap.round,
        );
        break;

      case BubbleType.purple:
        // Cat face
        final blink = sin(t * 3.0) > 0.95;
        final ears = Path()
          ..moveTo(-u * 0.75, -u * 0.1)
          ..lineTo(-u * 0.7, -u * 0.85)
          ..lineTo(-u * 0.15, -u * 0.5)
          ..close()
          ..moveTo(u * 0.75, -u * 0.1)
          ..lineTo(u * 0.7, -u * 0.85)
          ..lineTo(u * 0.15, -u * 0.5)
          ..close();
        _emblem(
          canvas,
          ears,
          bounds,
          const Color(0xFFF1E1FF),
          const Color(0xFFD2B0F5),
          u,
          colorblind,
        );
        final face = Path()
          ..addOval(
            Rect.fromCenter(
              center: Offset(0, u * 0.1),
              width: u * 1.7,
              height: u * 1.4,
            ),
          );
        _emblem(
          canvas,
          face,
          bounds,
          const Color(0xFFFFFFFF),
          const Color(0xFFE4CCFF),
          u,
          colorblind,
        );
        final dark = Paint()..color = const Color(0xFF3B1A70);
        if (blink) {
          final lid = Paint()
            ..color = const Color(0xFF3B1A70)
            ..style = PaintingStyle.stroke
            ..strokeWidth = u * 0.1
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(Offset(-u * 0.5, 0), Offset(-u * 0.2, 0), lid);
          canvas.drawLine(Offset(u * 0.2, 0), Offset(u * 0.5, 0), lid);
        } else {
          canvas.drawCircle(Offset(-u * 0.35, 0), u * 0.18, dark);
          canvas.drawCircle(Offset(u * 0.35, 0), u * 0.18, dark);
          final hl = Paint()..color = Colors.white;
          canvas.drawCircle(Offset(-u * 0.4, -u * 0.06), u * 0.06, hl);
          canvas.drawCircle(Offset(u * 0.3, -u * 0.06), u * 0.06, hl);
        }
        canvas.drawCircle(
          Offset(0, u * 0.28),
          u * 0.08,
          Paint()..color = const Color(0xFFFF6F8E),
        );
        canvas.drawCircle(
          Offset(-u * 0.6, u * 0.3),
          u * 0.13,
          Paint()..color = const Color(0x66FF8FA8),
        );
        canvas.drawCircle(
          Offset(u * 0.6, u * 0.3),
          u * 0.13,
          Paint()..color = const Color(0x66FF8FA8),
        );
        break;

      case BubbleType.bomb:
        // Bomb with burning fuse
        canvas.drawCircle(
          Offset(0, u * 0.18),
          u * 0.78,
          Paint()
            ..shader =
                const RadialGradient(
                  colors: [Color(0xFF6B6F85), Color(0xFF1B1D2B)],
                  center: Alignment(-0.4, -0.4),
                ).createShader(
                  Rect.fromCircle(
                    center: Offset(0, u * 0.18),
                    radius: u * 0.78,
                  ),
                ),
        );
        canvas.drawCircle(
          Offset(-u * 0.28, -u * 0.12),
          u * 0.14,
          Paint()..color = const Color(0x99FFFFFF),
        );
        final fuse = Path()
          ..moveTo(u * 0.25, -u * 0.5)
          ..quadraticBezierTo(u * 0.55, -u * 0.8, u * 0.6, -u * 0.95);
        canvas.drawPath(
          fuse,
          Paint()
            ..color = const Color(0xFFE8D7B0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = u * 0.12
            ..strokeCap = StrokeCap.round,
        );
        final sp = (sin(t * 12.0) + 1) / 2;
        canvas.drawCircle(
          Offset(u * 0.62, -u * 0.98),
          u * (0.2 + sp * 0.12),
          Paint()
            ..color = const Color(0xAAFFA502)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 0.1),
        );
        _sparkle(
          canvas,
          Offset(u * 0.62, -u * 0.98),
          u * (0.1 + sp * 0.08),
          const Color(0xFFFFF59D),
        );
        break;

      case BubbleType.rainbow:
        canvas.save();
        canvas.rotate(t * 1.2);
        _sparkle(canvas, Offset.zero, u * 0.38, const Color(0xFFFFFFFF));
        canvas.restore();
        canvas.drawCircle(
          Offset.zero,
          u * 0.18,
          Paint()..color = const Color(0xFFFFFFFF),
        );
        break;

      case BubbleType.stone:
        // Facets + cracks
        final facet = Paint()..color = const Color(0x22FFFFFF);
        canvas.drawPath(
          Path()
            ..moveTo(-u * 0.9, -u * 0.1)
            ..lineTo(-u * 0.2, -u * 0.8)
            ..lineTo(u * 0.5, -u * 0.55)
            ..lineTo(u * 0.1, u * 0.0)
            ..close(),
          facet,
        );
        canvas.drawPath(
          Path()
            ..moveTo(u * 0.9, u * 0.1)
            ..lineTo(u * 0.3, u * 0.85)
            ..lineTo(-u * 0.4, u * 0.6)
            ..lineTo(u * 0.1, u * 0.0)
            ..close(),
          Paint()..color = const Color(0x22000000),
        );
        if (hits <= 1) {
          final crack = Path()
            ..moveTo(-u * 0.64, -u * 0.5)
            ..lineTo(-u * 0.1, 0)
            ..lineTo(u * 0.36, -u * 0.2)
            ..lineTo(u * 0.6, u * 0.5)
            ..moveTo(-u * 0.1, 0)
            ..lineTo(-u * 0.44, u * 0.64);
          canvas.drawPath(
            crack,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = max(2, radius * 0.07)
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..color = const Color(0xEE171A22),
          );
        }
        break;

      case BubbleType.locked:
        final body = Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(0, u * 0.25),
                width: u * 1.2,
                height: u * 0.95,
              ),
              Radius.circular(u * 0.18),
            ),
          );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(0, -u * 0.25),
            width: u * 0.8,
            height: u * 0.95,
          ),
          pi,
          pi,
          false,
          Paint()
            ..color = const Color(0xFFE6E9F5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = u * 0.17
            ..strokeCap = StrokeCap.round,
        );
        _emblem(
          canvas,
          body,
          bounds,
          const Color(0xFFFFE27A),
          const Color(0xFFE59B1A),
          u,
          colorblind,
        );
        canvas.drawCircle(
          Offset(0, u * 0.2),
          u * 0.12,
          Paint()..color = const Color(0xFF6B4223),
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(0, u * 0.38),
            width: u * 0.09,
            height: u * 0.26,
          ),
          Paint()..color = const Color(0xFF6B4223),
        );
        break;

      case BubbleType.key:
        canvas.save();
        canvas.rotate(-0.6);
        final key = Path()
          ..addOval(
            Rect.fromCenter(
              center: Offset(-u * 0.5, 0),
              width: u * 0.8,
              height: u * 0.8,
            ),
          )
          ..addRect(Rect.fromLTWH(-u * 0.15, -u * 0.1, u * 1.15, u * 0.2))
          ..addRect(Rect.fromLTWH(u * 0.6, u * 0.1, u * 0.14, u * 0.3))
          ..addRect(Rect.fromLTWH(u * 0.84, u * 0.1, u * 0.14, u * 0.22));
        _emblem(
          canvas,
          key,
          bounds,
          const Color(0xFFFFF08A),
          const Color(0xFFE59B1A),
          u,
          colorblind,
        );
        canvas.drawCircle(
          Offset(-u * 0.5, 0),
          u * 0.14,
          Paint()..color = const Color(0xAA6B4223),
        );
        canvas.restore();
        break;
    }
  }

  static Path _flame(double u) {
    return Path()
      ..moveTo(0, -u * 1.0)
      ..cubicTo(u * 0.15, -u * 0.5, u * 0.85, -u * 0.2, u * 0.8, u * 0.35)
      ..cubicTo(u * 0.75, u * 0.8, u * 0.3, u * 1.0, 0, u * 1.0)
      ..cubicTo(-u * 0.3, u * 1.0, -u * 0.75, u * 0.8, -u * 0.8, u * 0.35)
      ..cubicTo(-u * 0.85, -u * 0.05, -u * 0.5, -u * 0.2, -u * 0.4, -u * 0.55)
      ..cubicTo(-u * 0.2, -u * 0.4, -u * 0.1, -u * 0.6, 0, -u * 1.0)
      ..close();
  }
}
