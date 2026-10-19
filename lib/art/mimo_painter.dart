import 'dart:math';

import 'package:flutter/material.dart';

import '../config/bubble_types.dart';
import '../core/constants.dart';
import 'bubble_painter.dart';

/// Animation states for Mimo the astronaut kitten.
enum MimoState { idle, happy, sad, nervous, cheer, wave, aim }

/// Procedural painter for Mimo: big glossy eyes, striped forehead, sprout,
/// glass helmet — drawn to match the game logo.
class MimoPainter {
  static const _ink = Color(0xFF2B1160);

  /// Draws Mimo centered at [center]. [size] is the nominal width in px.
  static void draw(
    Canvas canvas,
    Offset center,
    double size, {
    required MimoState state,
    SkinId skin = SkinId.defaultMimo,
    double t = 0.0,
    double aimAngle = 0.0,
    BubbleType? heldBubble,
  }) {
    final isGolden = skin == SkinId.goldenMimo;
    final furTop = isGolden ? const Color(0xFFFFD86B) : const Color(0xFFB98BFF);
    final furBottom = isGolden
        ? const Color(0xFFE59B1A)
        : const Color(0xFF8656DC);
    final furLight = isGolden
        ? const Color(0xFFFFF1B8)
        : const Color(0xFFE2CBFF);
    final furDark = isGolden
        ? const Color(0xFFB8680E)
        : const Color(0xFF5E33B0);

    // ---- animation parameters ------------------------------------------
    final breath = sin(t * 3.0) * 0.025;
    final blink = (t % 3.4) > 3.28;
    final earTwitch = (sin(t * 7.0) > 0.85) ? sin(t * 28.0) * 0.1 : 0.0;
    final earDroop = state == MimoState.sad ? 0.45 : 0.0;
    final tailWiggle = sin(t * 4.0) * 0.25;
    final cheering = state == MimoState.cheer;
    final happy = state == MimoState.happy || cheering;

    final jumpY = happy
        ? -sin((t * (cheering ? 12.0 : 8.0)) % pi).abs() *
              (cheering ? 25.0 : 18.0)
        : 0.0;
    final sadY = state == MimoState.sad ? 6.0 : 0.0;
    final shake = state == MimoState.nervous
        ? Offset(sin(t * 30.0) * 3.0, cos(t * 25.0) * 2.0)
        : Offset.zero;

    final look = state == MimoState.aim
        ? sin(aimAngle) * 2.2
        : sin(t * 0.8) * 1.0;
    final lookY = state == MimoState.sad
        ? 1.6
        : (state == MimoState.aim ? -1.0 : 0.0);

    canvas.save();
    canvas.translate(center.dx + shake.dx, center.dy + jumpY + sadY + shake.dy);
    if (state == MimoState.aim) canvas.rotate(aimAngle * 0.2);
    final s = size / 100.0;
    canvas.scale(s * (1 - breath * 0.5), s * (1 + breath));

    // ---- floor glow -------------------------------------------------------
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 46), width: 74, height: 11),
      Paint()
        ..color = const Color(0x552DE3F2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // ---- tail ---------------------------------------------------------------
    final tail = Path()
      ..moveTo(-15, 30)
      ..cubicTo(-38, 34 + tailWiggle * 10, -44, 10 - tailWiggle * 15, -30, -2);
    canvas.drawPath(
      tail,
      Paint()
        ..color = furBottom
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      tail,
      Paint()
        ..color = furLight.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // ---- suit body ----------------------------------------------------------
    final suit = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-21, 12, 42, 32),
      const Radius.circular(15),
    );
    canvas.drawRRect(
      suit,
      Paint()
        ..shader = LinearGradient(
          colors: isGolden
              ? const [Color(0xFFFFFBE0), Color(0xFFFFD86B)]
              : const [Color(0xFFFFFFFF), Color(0xFFC9D2FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(suit.outerRect),
    );
    canvas.drawRRect(
      suit,
      Paint()
        ..color = _ink.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    // chest light
    final pulse = (sin(t * 4) + 1) / 2;
    canvas.drawCircle(
      const Offset(0, 32),
      4.5,
      Paint()
        ..color = const Color(0xFF31E8F4).withValues(alpha: 0.4 + pulse * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      const Offset(0, 32),
      2.6,
      Paint()..color = const Color(0xFF7CF6FF),
    );

    // ---- ears (behind head) ---------------------------------------------------
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.scale(side, 1);
      canvas.translate(-22, -18);
      canvas.rotate(-earDroop + earTwitch * side);
      canvas.translate(22, 18);
      final ear = Path()
        ..moveTo(-30, -14)
        ..quadraticBezierTo(-37, -34, -29, -48)
        ..quadraticBezierTo(-17, -44, -7, -33)
        ..close();
      canvas.drawPath(
        ear,
        Paint()
          ..shader = LinearGradient(
            colors: [furTop, furBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(ear.getBounds()),
      );
      canvas.drawPath(
        ear,
        Paint()
          ..color = furDark.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      final inner = Path()
        ..moveTo(-27, -19)
        ..quadraticBezierTo(-31, -32, -28, -40)
        ..quadraticBezierTo(-20, -37, -14, -31)
        ..close();
      canvas.drawPath(inner, Paint()..color = const Color(0xFFFF8FA8));
      canvas.restore();
    }

    // ---- head -----------------------------------------------------------------
    const headRect = Rect.fromLTWH(-30, -36, 60, 52);
    final head = RRect.fromRectAndRadius(headRect, const Radius.circular(26));
    canvas.drawRRect(
      head,
      Paint()
        ..shader = LinearGradient(
          colors: [furTop, furBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(headRect),
    );
    // cheek fluff
    for (final side in [-1.0, 1.0]) {
      final tuft = Path()
        ..moveTo(side * 29, -4)
        ..lineTo(side * 36, -1)
        ..lineTo(side * 29, 2)
        ..lineTo(side * 34, 6)
        ..lineTo(side * 27, 7)
        ..close();
      canvas.drawPath(tuft, Paint()..color = furBottom);
    }

    // forehead stripes
    final stripe = Paint()..color = furLight.withValues(alpha: 0.85);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3.5, -35, 7, 14),
        const Radius.circular(3.5),
      ),
      stripe,
    );
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side * 11, -31);
      canvas.rotate(side * 0.38);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -5, 6, 11),
          const Radius.circular(3),
        ),
        stripe,
      );
      canvas.restore();
    }

    // muzzle
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 4), width: 26, height: 15),
      Paint()..color = const Color(0xFFFFF3FF).withValues(alpha: 0.9),
    );

    // blush
    final blush = Paint()
      ..color = const Color(0xFFFF7AA2).withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-20, 2), width: 11, height: 7),
      blush,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(20, 2), width: 11, height: 7),
      blush,
    );

    // ---- eyes -----------------------------------------------------------------
    for (final side in [-1.0, 1.0]) {
      _eye(
        canvas,
        Offset(side * 11, -11),
        side,
        state,
        blink,
        happy,
        look,
        lookY,
      );
    }
    if (state == MimoState.sad) {
      final brow = Paint()
        ..color = furDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(-17, -24), const Offset(-7, -21), brow);
      canvas.drawLine(const Offset(17, -24), const Offset(7, -21), brow);
      final ty = (t * 18) % 16;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-16, -4 + ty), width: 3.6, height: 5.6),
        Paint()..color = const Color(0xCC7CD6FF),
      );
    }
    if (state == MimoState.nervous) {
      final sy = (sin(t * 6) + 1) * 1.5;
      final drop = Path()
        ..moveTo(28, -26 + sy)
        ..quadraticBezierTo(24, -19 + sy, 28, -17 + sy)
        ..quadraticBezierTo(32, -19 + sy, 28, -26 + sy);
      canvas.drawPath(drop, Paint()..color = const Color(0xCC7CD6FF));
    }

    // ---- nose + mouth ---------------------------------------------------------
    final nose = Path()
      ..moveTo(-3, -1.5)
      ..quadraticBezierTo(0, -3, 3, -1.5)
      ..quadraticBezierTo(2, 1.2, 0, 2.2)
      ..quadraticBezierTo(-2, 1.2, -3, -1.5);
    canvas.drawPath(nose, Paint()..color = const Color(0xFFFF6F8E));
    canvas.drawCircle(
      const Offset(-0.9, -1.1),
      0.7,
      Paint()..color = Colors.white,
    );
    _mouth(canvas, state, happy);

    // ---- sprout ---------------------------------------------------------------
    canvas.save();
    canvas.translate(0, -35);
    canvas.rotate(sin(t * 2.0) * 0.1);
    final stem = Path()
      ..moveTo(0, 2)
      ..quadraticBezierTo(1.5, -4, 0, -8);
    canvas.drawPath(
      stem,
      Paint()
        ..color = const Color(0xFF3CC15A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    for (final side in [-1.0, 1.0]) {
      final leaf = Path()
        ..moveTo(0, -8)
        ..cubicTo(side * 3, -15, side * 10, -16, side * 13, -11)
        ..cubicTo(side * 9, -6, side * 3, -5, 0, -8)
        ..close();
      canvas.drawPath(
        leaf,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFB8F27C), Color(0xFF24A84A)],
          ).createShader(leaf.getBounds()),
      );
      canvas.drawPath(
        leaf,
        Paint()
          ..color = const Color(0xFF166B2E).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
    canvas.restore();

    // ---- paws -----------------------------------------------------------------
    _paw(canvas, -1, state, t, furTop, furBottom, furDark);
    _paw(canvas, 1, state, t, furTop, furBottom, furDark);

    // ---- helmet -------------------------------------------------------------
    const hc = Offset(0, -10);
    const helmetRect = Rect.fromLTRB(-37, -47, 37, 27);
    canvas.drawCircle(
      hc,
      36,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x0070A1FF), Color(0x1A9DEBFF), Color(0x4D6FC8FF)],
          stops: [0.0, 0.7, 1.0],
          center: Alignment(-0.3, -0.4),
        ).createShader(helmetRect),
    );
    canvas.drawCircle(
      hc,
      36,
      Paint()
        ..color = const Color(0xFFB8E8FF).withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    // bottom cyan rim
    canvas.drawArc(
      Rect.fromCircle(center: hc, radius: 33),
      pi * 0.2,
      pi * 0.6,
      false,
      Paint()
        ..color = const Color(0xFF7CF6FF).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
    // big reflection
    canvas.drawArc(
      Rect.fromCircle(center: hc, radius: 31),
      pi * 1.08,
      pi * 0.42,
      false,
      Paint()
        ..color = const Color(0xE6FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      const Offset(17, -35),
      1.8,
      Paint()..color = const Color(0xE6FFFFFF),
    );
    // collar ring
    final collar = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-23, 14, 46, 9),
      const Radius.circular(4.5),
    );
    canvas.drawRRect(
      collar,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF7CF6FF), Color(0xFF2B7BFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(collar.outerRect),
    );
    canvas.drawRRect(
      collar,
      Paint()
        ..color = _ink.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // ---- skins ---------------------------------------------------------------
    _drawSkinAccessories(canvas, skin, t);

    // ---- held bubble ---------------------------------------------------------
    if (heldBubble != null) {
      BubblePainter.draw(canvas, const Offset(0, 28), 16.0, heldBubble, t: t);
    }

    canvas.restore();
  }

  // ----------------------------------------------------------------------
  static void _eye(
    Canvas canvas,
    Offset c,
    double side,
    MimoState state,
    bool blink,
    bool happy,
    double look,
    double lookY,
  ) {
    final line = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    if (happy) {
      canvas.drawArc(
        Rect.fromCenter(center: c + const Offset(0, 2), width: 12, height: 11),
        pi,
        pi,
        false,
        line,
      );
      return;
    }
    if (blink) {
      canvas.drawLine(c + const Offset(-6, 0), c + const Offset(6, 0), line);
      return;
    }
    final nervous = state == MimoState.nervous;
    final outerR = nervous ? 7.4 : 9.0;
    final irisR = nervous ? 5.4 : 7.2;

    canvas.drawCircle(c, outerR, Paint()..color = _ink);
    final iris = c + Offset(look, lookY);
    canvas.drawCircle(
      iris,
      irisR,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFA0604A), Color(0xFF5A2D6E), Color(0xFF2B1160)],
          center: Alignment(0, 0.4),
        ).createShader(Rect.fromCircle(center: iris, radius: irisR)),
    );
    canvas.drawCircle(
      iris,
      irisR * 0.45,
      Paint()..color = const Color(0xFF14082E),
    );
    canvas.drawCircle(
      iris + Offset(-irisR * 0.35, -irisR * 0.4),
      irisR * 0.36,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      iris + Offset(irisR * 0.38, irisR * 0.38),
      irisR * 0.17,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  static void _mouth(Canvas canvas, MimoState state, bool happy) {
    final line = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    if (happy) {
      final open = Path()
        ..moveTo(-6, 4)
        ..quadraticBezierTo(0, 15, 6, 4)
        ..close();
      canvas.drawPath(open, Paint()..color = const Color(0xFF7A1736));
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 9), width: 6.5, height: 4),
        Paint()..color = const Color(0xFFFF7A9E),
      );
      canvas.drawPath(open, line..strokeWidth = 1.4);
    } else if (state == MimoState.sad) {
      canvas.drawPath(
        Path()
          ..moveTo(-5, 9)
          ..quadraticBezierTo(0, 4.5, 5, 9),
        line,
      );
    } else if (state == MimoState.nervous) {
      canvas.drawPath(
        Path()
          ..moveTo(-6, 7)
          ..quadraticBezierTo(-3, 4, 0, 7)
          ..quadraticBezierTo(3, 10, 6, 7),
        line,
      );
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(0, 2.2)
          ..lineTo(0, 4)
          ..moveTo(-5.5, 4)
          ..quadraticBezierTo(-2.8, 8.5, 0, 4)
          ..quadraticBezierTo(2.8, 8.5, 5.5, 4),
        line,
      );
    }
  }

  static void _paw(
    Canvas canvas,
    double side,
    MimoState state,
    double t,
    Color top,
    Color bottom,
    Color dark,
  ) {
    var pos = Offset(side * 17, 20);
    var angle = 0.0;
    if (state == MimoState.cheer) {
      pos = Offset(side * 30, -2 + sin(t * 14 + side) * 3);
      angle = side * 0.5;
    } else if (state == MimoState.wave && side > 0) {
      pos = Offset(32, 4);
      angle = sin(t * 10) * 0.5;
    } else if (state == MimoState.nervous) {
      pos = Offset(side * 10, 16);
    }
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    final r = Rect.fromCenter(center: Offset.zero, width: 15, height: 12);
    canvas.drawOval(
      r,
      Paint()
        ..shader = LinearGradient(
          colors: [top, bottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(r),
    );
    canvas.drawOval(
      r,
      Paint()
        ..color = dark.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final toe = Paint()
      ..color = dark.withValues(alpha: 0.55)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-2.2, -5.5), const Offset(-2.2, -2.5), toe);
    canvas.drawLine(const Offset(2.2, -5.5), const Offset(2.2, -2.5), toe);
    canvas.restore();
  }

  static void _drawSkinAccessories(Canvas canvas, SkinId skin, double t) {
    switch (skin) {
      case SkinId.spaceMimo:
        // Pirate hat + eyepatch
        final hat = Path()
          ..moveTo(-30, -42)
          ..quadraticBezierTo(0, -68, 30, -42)
          ..quadraticBezierTo(0, -36, -30, -42)
          ..close();
        canvas.drawPath(
          hat,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFF4A4F5C), Color(0xFF1C1F27)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(hat.getBounds()),
        );
        canvas.drawPath(
          hat,
          Paint()
            ..color = const Color(0xFFFFD700)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
        canvas.drawCircle(
          const Offset(0, -50),
          3.6,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          const Offset(-1.3, -50.5),
          0.9,
          Paint()..color = Colors.black,
        );
        canvas.drawCircle(
          const Offset(1.3, -50.5),
          0.9,
          Paint()..color = Colors.black,
        );
        canvas.drawLine(
          const Offset(-28, -22),
          const Offset(8, -7),
          Paint()
            ..color = Colors.black
            ..strokeWidth = 1.6,
        );
        canvas.drawCircle(
          const Offset(-11, -11),
          8.6,
          Paint()..color = Colors.black,
        );
        break;

      case SkinId.neonMimo:
        // Wizard hat
        final hat = Path()
          ..moveTo(-24, -42)
          ..quadraticBezierTo(-4, -60, 6, -80)
          ..quadraticBezierTo(14, -58, 24, -42)
          ..quadraticBezierTo(0, -36, -24, -42)
          ..close();
        canvas.drawPath(
          hat,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFF1E3FBF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(hat.getBounds()),
        );
        canvas.drawPath(
          hat,
          Paint()
            ..color = const Color(0xFF9DEBFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
        final tw = (sin(t * 5) + 1) / 2;
        _star(canvas, const Offset(2, -56), 3.6 + tw, const Color(0xFFFFE45E));
        _star(canvas, const Offset(-9, -46), 2.4, const Color(0xFFFFE45E));
        break;

      case SkinId.goldenMimo:
        // Ninja headband with knot
        final band = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-30, -27, 60, 8),
          const Radius.circular(3),
        );
        canvas.drawRRect(
          band,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFFF5E6C), Color(0xFFC0182B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(band.outerRect),
        );
        canvas.drawCircle(
          const Offset(0, -23),
          4.4,
          Paint()..color = const Color(0xFFFFD700),
        );
        canvas.drawCircle(
          const Offset(0, -23),
          2,
          Paint()..color = const Color(0xFFC0182B),
        );
        break;

      case SkinId.defaultMimo:
        break;
    }
  }

  static void _star(Canvas canvas, Offset c, double r, Color color) {
    final p = Path()
      ..moveTo(c.dx, c.dy - r * 2)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r * 2, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r * 2)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r * 2, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r * 2)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }
}
