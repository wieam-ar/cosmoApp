import 'dart:math';

import 'package:flutter/material.dart';

/// All icon identifiers supported by IconsPainter.
enum AppIcon {
  sound,
  mute,
  share,
  gear,
  cart,
  gift,
  play,
  back,
  plus,
  pause,
  home,
  replay,
  close,
  heart,
  coin,
  gem,
  padlock,
  check,
  swap,
  bomb,
  rocket,
  lightning,
  planet,
  star,
  flower,
}

/// High performance vector path painter for UI icons.
class IconsPainter {
  /// Draws a vector [icon] fitted inside [rect].
  static void draw(
    Canvas canvas,
    Rect rect,
    AppIcon icon, {
    Color color = Colors.white,
    Color? strokeColor,
    double strokeWidth = 2.5,
  }) {
    canvas.save();
    canvas.translate(rect.left, rect.top);

    final w = rect.width;
    final h = rect.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final path = Path();

    switch (icon) {
      case AppIcon.star:
        final center = Offset(w / 2, h / 2);
        final rOuter = w * 0.45;
        final rInner = w * 0.18;
        const points = 5;
        for (int i = 0; i < points * 2; i++) {
          final r = i.isEven ? rOuter : rInner;
          final a = (i * pi) / points - pi / 2;
          final p = center + Offset(cos(a), sin(a)) * r;
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        break;

      case AppIcon.flower:
        final center = Offset(w / 2, h / 2);
        final petalRadius = w * 0.16;
        for (var i = 0; i < 6; i++) {
          final angle = i * pi / 3;
          canvas.drawCircle(
            center + Offset(cos(angle), sin(angle)) * w * 0.23,
            petalRadius,
            paint,
          );
        }
        canvas.drawCircle(
          center,
          w * 0.14,
          Paint()..color = const Color(0xFFFFE58A),
        );
        break;

      case AppIcon.sound:
        path
          ..moveTo(w * 0.15, h * 0.35)
          ..lineTo(w * 0.32, h * 0.35)
          ..lineTo(w * 0.52, h * 0.18)
          ..lineTo(w * 0.52, h * 0.82)
          ..lineTo(w * 0.32, h * 0.65)
          ..lineTo(w * 0.15, h * 0.65)
          ..close();
        canvas.drawPath(path, paint);

        final wavePaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromLTWH(w * 0.45, h * 0.3, w * 0.25, h * 0.4),
          -pi / 3,
          (2 * pi) / 3,
          false,
          wavePaint,
        );
        canvas.drawArc(
          Rect.fromLTWH(w * 0.42, h * 0.18, w * 0.42, h * 0.64),
          -pi / 3,
          (2 * pi) / 3,
          false,
          wavePaint,
        );
        break;

      case AppIcon.mute:
        path
          ..moveTo(w * 0.15, h * 0.35)
          ..lineTo(w * 0.32, h * 0.35)
          ..lineTo(w * 0.52, h * 0.18)
          ..lineTo(w * 0.52, h * 0.82)
          ..lineTo(w * 0.32, h * 0.65)
          ..lineTo(w * 0.15, h * 0.65)
          ..close();
        canvas.drawPath(path, paint);

        final slashPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 0.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(w * 0.2, h * 0.2),
          Offset(w * 0.8, h * 0.8),
          slashPaint,
        );
        break;

      case AppIcon.share:
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(Offset(w * 0.25, h * 0.5), w * 0.12, paint);
        canvas.drawCircle(Offset(w * 0.75, h * 0.25), w * 0.12, paint);
        canvas.drawCircle(Offset(w * 0.75, h * 0.75), w * 0.12, paint);

        final linePaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;
        canvas.drawLine(
          Offset(w * 0.25, h * 0.5),
          Offset(w * 0.75, h * 0.25),
          linePaint,
        );
        canvas.drawLine(
          Offset(w * 0.25, h * 0.5),
          Offset(w * 0.75, h * 0.75),
          linePaint,
        );
        break;

      case AppIcon.gear:
        final center = Offset(w / 2, h / 2);
        final rOuter = w * 0.42;
        final rInner = w * 0.28;
        const teeth = 8;

        for (int i = 0; i < teeth; i++) {
          final a1 = (i * 2 * pi) / teeth;
          final a2 = a1 + (pi / teeth) * 0.5;
          final a3 = a1 + (pi / teeth) * 0.8;
          final a4 = ((i + 1) * 2 * pi) / teeth - (pi / teeth) * 0.2;

          final p1 = center + Offset(cos(a1), sin(a1)) * rInner;
          final p2 = center + Offset(cos(a2), sin(a2)) * rOuter;
          final p3 = center + Offset(cos(a3), sin(a3)) * rOuter;
          final p4 = center + Offset(cos(a4), sin(a4)) * rInner;

          if (i == 0) path.moveTo(p1.dx, p1.dy);
          path.lineTo(p2.dx, p2.dy);
          path.lineTo(p3.dx, p3.dy);
          path.lineTo(p4.dx, p4.dy);
        }
        path.close();
        canvas.drawPath(path, paint);

        final holePaint = Paint()..blendMode = BlendMode.clear;
        canvas.drawCircle(center, w * 0.15, holePaint);
        break;

      case AppIcon.cart:
        final cartPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;
        path
          ..moveTo(w * 0.1, h * 0.2)
          ..lineTo(w * 0.28, h * 0.2)
          ..lineTo(w * 0.4, h * 0.65)
          ..lineTo(w * 0.82, h * 0.65)
          ..lineTo(w * 0.9, h * 0.32)
          ..lineTo(w * 0.3, h * 0.32);
        canvas.drawPath(path, cartPaint);

        paint.style = PaintingStyle.fill;
        canvas.drawCircle(Offset(w * 0.45, h * 0.82), w * 0.08, paint);
        canvas.drawCircle(Offset(w * 0.78, h * 0.82), w * 0.08, paint);
        break;

      case AppIcon.gift:
        paint.style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.2, h * 0.4, w * 0.6, h * 0.48),
            const Radius.circular(4),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.15, h * 0.28, w * 0.7, h * 0.14),
            const Radius.circular(3),
          ),
          paint,
        );

        final bowPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;
        canvas.drawOval(
          Rect.fromLTWH(w * 0.25, h * 0.12, w * 0.22, h * 0.18),
          bowPaint,
        );
        canvas.drawOval(
          Rect.fromLTWH(w * 0.53, h * 0.12, w * 0.22, h * 0.18),
          bowPaint,
        );
        break;

      case AppIcon.play:
        path
          ..moveTo(w * 0.28, h * 0.18)
          ..lineTo(w * 0.82, h * 0.5)
          ..lineTo(w * 0.28, h * 0.82)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case AppIcon.back:
        final arrowPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 1.0;
        path
          ..moveTo(w * 0.65, h * 0.18)
          ..lineTo(w * 0.3, h * 0.5)
          ..lineTo(w * 0.65, h * 0.82);
        canvas.drawPath(path, arrowPaint);
        break;

      case AppIcon.plus:
        final plusPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 1.5;
        canvas.drawLine(
          Offset(w * 0.18, h * 0.5),
          Offset(w * 0.82, h * 0.5),
          plusPaint,
        );
        canvas.drawLine(
          Offset(w * 0.5, h * 0.18),
          Offset(w * 0.5, h * 0.82),
          plusPaint,
        );
        break;

      case AppIcon.pause:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.25, h * 0.2, w * 0.18, h * 0.6),
            const Radius.circular(3),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.57, h * 0.2, w * 0.18, h * 0.6),
            const Radius.circular(3),
          ),
          paint,
        );
        break;

      case AppIcon.home:
        path
          ..moveTo(w * 0.15, h * 0.5)
          ..lineTo(w * 0.5, h * 0.18)
          ..lineTo(w * 0.85, h * 0.5)
          ..lineTo(w * 0.78, h * 0.5)
          ..lineTo(w * 0.78, h * 0.82)
          ..lineTo(w * 0.22, h * 0.82)
          ..lineTo(w * 0.22, h * 0.5)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case AppIcon.replay:
        final replayPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;
        canvas.drawArc(
          Rect.fromLTWH(w * 0.18, h * 0.18, w * 0.64, h * 0.64),
          0.3,
          5.2,
          false,
          replayPaint,
        );
        paint.style = PaintingStyle.fill;
        path
          ..moveTo(w * 0.75, h * 0.3)
          ..lineTo(w * 0.92, h * 0.22)
          ..lineTo(w * 0.8, h * 0.45)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case AppIcon.close:
        final closePaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 1.0;
        canvas.drawLine(
          Offset(w * 0.22, h * 0.22),
          Offset(w * 0.78, h * 0.78),
          closePaint,
        );
        canvas.drawLine(
          Offset(w * 0.78, h * 0.22),
          Offset(w * 0.22, h * 0.78),
          closePaint,
        );
        break;

      case AppIcon.heart:
        path
          ..moveTo(w * 0.5, h * 0.8)
          ..cubicTo(w * 0.1, h * 0.55, w * 0.05, h * 0.22, w * 0.32, h * 0.22)
          ..cubicTo(w * 0.42, h * 0.22, w * 0.48, h * 0.3, w * 0.5, h * 0.36)
          ..cubicTo(w * 0.52, h * 0.3, w * 0.58, h * 0.22, w * 0.68, h * 0.22)
          ..cubicTo(w * 0.95, h * 0.22, w * 0.9, h * 0.55, w * 0.5, h * 0.8)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case AppIcon.coin:
        canvas.drawCircle(Offset(w / 2, h / 2), w * 0.42, paint);
        TextPainter(
            text: TextSpan(
              text: '\$',
              style: TextStyle(
                color: strokeColor ?? const Color(0xCC000000),
                fontSize: h * 0.52,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          )
          ..layout()
          ..paint(canvas, Offset(w * 0.32, h * 0.18));
        break;

      case AppIcon.gem:
        path
          ..moveTo(w * 0.3, h * 0.2)
          ..lineTo(w * 0.7, h * 0.2)
          ..lineTo(w * 0.88, h * 0.45)
          ..lineTo(w * 0.5, h * 0.85)
          ..lineTo(w * 0.12, h * 0.45)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case AppIcon.padlock:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.2, h * 0.42, w * 0.6, h * 0.44),
            const Radius.circular(6),
          ),
          paint,
        );

        final shacklePaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 1.0;
        canvas.drawArc(
          Rect.fromLTWH(w * 0.32, h * 0.18, w * 0.36, h * 0.45),
          pi,
          pi,
          false,
          shacklePaint,
        );
        break;

      case AppIcon.check:
        final checkPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 1.5;
        path
          ..moveTo(w * 0.2, h * 0.52)
          ..lineTo(w * 0.42, h * 0.75)
          ..lineTo(w * 0.82, h * 0.25);
        canvas.drawPath(path, checkPaint);
        break;

      case AppIcon.swap:
        final swapPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;
        path
          ..moveTo(w * 0.18, h * 0.35)
          ..lineTo(w * 0.72, h * 0.35);
        canvas.drawPath(path, swapPaint);

        paint.style = PaintingStyle.fill;
        final topArrow = Path()
          ..moveTo(w * 0.82, h * 0.35)
          ..lineTo(w * 0.65, h * 0.22)
          ..lineTo(w * 0.65, h * 0.48)
          ..close();
        canvas.drawPath(topArrow, paint);

        final bottomLine = Path()
          ..moveTo(w * 0.82, h * 0.65)
          ..lineTo(w * 0.28, h * 0.65);
        canvas.drawPath(bottomLine, swapPaint);

        final bottomArrow = Path()
          ..moveTo(w * 0.18, h * 0.65)
          ..lineTo(w * 0.35, h * 0.52)
          ..lineTo(w * 0.35, h * 0.78)
          ..close();
        canvas.drawPath(bottomArrow, paint);
        break;

      case AppIcon.bomb:
        canvas.drawCircle(Offset(w * 0.45, h * 0.55), w * 0.32, paint);
        final fusePaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;
        canvas.drawArc(
          Rect.fromLTWH(w * 0.42, h * 0.12, w * 0.3, h * 0.3),
          pi / 2,
          pi / 1.2,
          false,
          fusePaint,
        );
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(Offset(w * 0.72, h * 0.15), w * 0.07, paint);
        break;

      case AppIcon.rocket:
        path
          ..moveTo(w * 0.5, h * 0.12)
          ..cubicTo(w * 0.75, h * 0.3, w * 0.75, h * 0.65, w * 0.62, h * 0.8)
          ..lineTo(w * 0.38, h * 0.8)
          ..cubicTo(w * 0.25, h * 0.65, w * 0.25, h * 0.3, w * 0.5, h * 0.12)
          ..close();
        canvas.drawPath(path, paint);

        final leftFin = Path()
          ..moveTo(w * 0.32, h * 0.62)
          ..lineTo(w * 0.15, h * 0.82)
          ..lineTo(w * 0.35, h * 0.78)
          ..close();
        canvas.drawPath(leftFin, paint);

        final rightFin = Path()
          ..moveTo(w * 0.68, h * 0.62)
          ..lineTo(w * 0.85, h * 0.82)
          ..lineTo(w * 0.65, h * 0.78)
          ..close();
        canvas.drawPath(rightFin, paint);

        final winPaint = Paint()
          ..color = strokeColor ?? const Color(0xCC000000);
        canvas.drawCircle(Offset(w * 0.5, h * 0.42), w * 0.1, winPaint);
        break;

      case AppIcon.lightning:
        path
          ..moveTo(w * 0.55, h * 0.12)
          ..lineTo(w * 0.22, h * 0.52)
          ..lineTo(w * 0.48, h * 0.52)
          ..lineTo(w * 0.42, h * 0.88)
          ..lineTo(w * 0.78, h * 0.45)
          ..lineTo(w * 0.52, h * 0.45)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case AppIcon.planet:
        canvas.drawCircle(Offset(w / 2, h / 2), w * 0.3, paint);

        final ringPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;
        canvas.save();
        canvas.translate(w / 2, h / 2);
        canvas.rotate(-0.35);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: w * 0.88,
            height: h * 0.28,
          ),
          ringPaint,
        );
        canvas.restore();
        break;
    }

    canvas.restore();
  }
}
