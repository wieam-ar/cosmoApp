import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants.dart';

/// Animation parameters per letter for individual dropping/bouncing effects.
class LetterAnim {
  final double offsetY;
  final double scale;
  final double rotation; // in radians
  final double opacity;

  const LetterAnim({
    this.offsetY = 0.0,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.opacity = 1.0,
  });
}

/// 3D extruded comic title painter with gradient fill & diagonal shine sweep.
class Title3D {
  /// Draws extruded 3D title text centered at [center].
  static void draw(
    Canvas canvas,
    String text,
    Offset center, {
    double fontSize = 42.0,
    double shine = -1.0,
    Color fillTop = AppColors.accent,
    Color fillBottom = AppColors.secondary,
    Color strokeColor = Colors.black,
    Color extrusionColor = const Color(0xFF181340),
  }) {
    final textStyleBase = _getBaseStyle(fontSize);

    // 1. Extrusion Shadow Layers (Offset downwards)
    for (int i = 8; i >= 1; i--) {
      final styleExtrusion = textStyleBase.copyWith(color: extrusionColor);
      final tp = _getTextPainter(text, styleExtrusion);
      tp.layout();
      tp.paint(
        canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2 + i * 1.2),
      );
    }

    // 2. Thick Outer Outline
    final styleOutline = textStyleBase.copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..strokeJoin = StrokeJoin.round
        ..color = strokeColor,
    );
    final tpOutline = _getTextPainter(text, styleOutline);
    tpOutline.layout();
    tpOutline.paint(
      canvas,
      Offset(center.dx - tpOutline.width / 2, center.dy - tpOutline.height / 2),
    );

    // 3. Main Gradient Face Fill
    final textBounds = Rect.fromCenter(
      center: center,
      width: tpOutline.width,
      height: tpOutline.height,
    );

    final styleFill = textStyleBase.copyWith(
      foreground: Paint()
        ..shader = LinearGradient(
          colors: [fillTop, fillBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(textBounds),
    );

    final tpFill = _getTextPainter(text, styleFill);
    tpFill.layout();
    tpFill.paint(
      canvas,
      Offset(center.dx - tpFill.width / 2, center.dy - tpFill.height / 2),
    );

    // 4. Moving Diagonal Shine Sweep Overlay
    if (shine >= 0.0 && shine <= 1.0) {
      canvas.save();
      canvas.clipRect(textBounds);

      final shineX = textBounds.left + (textBounds.width + 100) * shine - 50;
      final shineRect = Rect.fromLTWH(
        shineX,
        textBounds.top - 20,
        40,
        textBounds.height + 40,
      );

      final shinePaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x00FFFFFF), Color(0xCCFFFFFF), Color(0x00FFFFFF)],
        ).createShader(shineRect)
        ..blendMode = BlendMode.srcATop;

      canvas.save();
      canvas.translate(shineRect.center.dx, shineRect.center.dy);
      canvas.rotate(-0.35); // Diagonal slant
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: 35,
          height: textBounds.height * 2,
        ),
        shinePaint,
      );
      canvas.restore();

      canvas.restore();
    }
  }

  /// Draws 3D title with individual per-letter animations (offset, scale, rotation, opacity).
  static void drawLetters(
    Canvas canvas,
    String text,
    Offset center, {
    double fontSize = 42.0,
    List<LetterAnim>? anims,
    double shine = -1.0,
    Color fillTop = AppColors.accent,
    Color fillBottom = AppColors.secondary,
    required bool sweep,
  }) {
    final textStyleBase = _getBaseStyle(fontSize);

    final tpFull = _getTextPainter(text, textStyleBase);
    tpFull.layout();

    double currentX = center.dx - tpFull.width / 2;
    final startY = center.dy - tpFull.height / 2;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final anim = (anims != null && i < anims.length)
          ? anims[i]
          : const LetterAnim();

      final tpChar = _getTextPainter(char, textStyleBase);
      tpChar.layout();
      final charWidth = tpChar.width;

      if (char.trim().isEmpty) {
        currentX += charWidth;
        continue;
      }

      final charCenter = Offset(
        currentX + charWidth / 2,
        startY + tpChar.height / 2,
      );

      canvas.save();
      if (anim.opacity < 1.0) {
        canvas.saveLayer(
          Rect.fromCircle(center: charCenter, radius: fontSize * 2),
          Paint()..color = Color.fromRGBO(0, 0, 0, anim.opacity),
        );
      }

      canvas.translate(charCenter.dx, charCenter.dy + anim.offsetY);
      canvas.rotate(anim.rotation);
      canvas.scale(anim.scale);

      draw(
        canvas,
        char,
        Offset.zero,
        fontSize: fontSize,
        shine: shine,
        fillTop: fillTop,
        fillBottom: fillBottom,
      );

      if (anim.opacity < 1.0) {
        canvas.restore();
      }
      canvas.restore();

      currentX += charWidth;
    }
  }

  static TextStyle _getBaseStyle(double fontSize) {
    try {
      return GoogleFonts.lilitaOne(fontSize: fontSize, letterSpacing: 1.0);
    } catch (_) {
      return TextStyle(
        fontFamily: 'sans-serif',
        fontWeight: FontWeight.w900,
        fontSize: fontSize,
        letterSpacing: 1.0,
      );
    }
  }

  static TextPainter _getTextPainter(String text, TextStyle style) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
  }
}
