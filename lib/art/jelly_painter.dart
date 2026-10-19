import 'package:flutter/material.dart';

/// Available candy color themes for Jelly UI elements.
enum JellyColor { orange, blue, pink, green, purple, red }

/// Single source of truth for jelly colours: used by JellyPainter here and by
/// JellyButton / RoundButton / Popup through `JellyColorX` in core/ui_theme.dart.
class JellyPalette {
  final Color top;
  final Color bottom;
  final Color lip;
  final Color glow;

  const JellyPalette({
    required this.top,
    required this.bottom,
    required this.lip,
    required this.glow,
  });
}

const Map<JellyColor, JellyPalette> kJellyPalettes = {
  // Tuned to the launcher icon: flame orange, steam cyan, blush pink,
  // sprout green, fur violet. Every lip is darker than its body.
  JellyColor.orange: JellyPalette(
    top: Color(0xFFFFB82E),
    bottom: Color(0xFFFF7A2E),
    lip: Color(0xFFC2500F),
    glow: Color(0xFFFFB82E),
  ),
  JellyColor.blue: JellyPalette(
    top: Color(0xFF5ED3FF),
    bottom: Color(0xFF2B8CF1),
    lip: Color(0xFF1565C0),
    glow: Color(0xFF2B9BF1),
  ),
  JellyColor.pink: JellyPalette(
    top: Color(0xFFFF8FB8),
    bottom: Color(0xFFFF5FA2),
    lip: Color(0xFFC73A7B),
    glow: Color(0xFFFF5FA2),
  ),
  JellyColor.green: JellyPalette(
    top: Color(0xFF8BE85A),
    bottom: Color(0xFF3CBF2A),
    lip: Color(0xFF1F7A12),
    glow: Color(0xFF4CC23A),
  ),
  JellyColor.purple: JellyPalette(
    top: Color(0xFFE2B8FF),
    bottom: Color(0xFF9B5BE0),
    lip: Color(0xFF6B35B0),
    glow: Color(0xFF9B5BE0),
  ),
  JellyColor.red: JellyPalette(
    top: Color(0xFFFF6B7A),
    bottom: Color(0xFFE8324A),
    lip: Color(0xFFA81E30),
    glow: Color(0xFFE8324A),
  ),
};

/// High-performance procedural jelly button, panel, and pill painter.
class JellyPainter {
  /// Draws a glossy, 3D candy jelly button inside [rect].
  static void button(
    Canvas canvas,
    Rect rect, {
    required JellyColor color,
    bool pressed = false,
    double pulse = 0.0,
    double borderRadius = 20.0,
  }) {
    final palette = kJellyPalettes[color]!;
    final lipHeight = pressed ? 3.0 : 8.0;
    final dyOffset = pressed ? 5.0 : 0.0;

    final drawRect = Rect.fromLTWH(
      rect.left,
      rect.top + dyOffset,
      rect.width,
      rect.height - 8.0,
    );

    // 1. Breathing Outer Glow
    if (pulse > 0.0) {
      final glowRadius = borderRadius + 4.0;
      final glowRect = drawRect.inflate(4.0 + pulse * 6.0);
      final glowPaint = Paint()
        ..color = palette.glow.withValues(alpha: 0.3 + 0.3 * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 + pulse * 6.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(glowRect, Radius.circular(glowRadius)),
        glowPaint,
      );
    }

    // 2. Darker Bottom Lip (Extrusion Shadow)
    final lipRect = Rect.fromLTWH(
      drawRect.left,
      drawRect.top + lipHeight,
      drawRect.width,
      drawRect.height,
    );
    final lipPaint = Paint()
      ..color = palette.lip
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(lipRect, Radius.circular(borderRadius)),
      lipPaint,
    );

    // 3. Main Gradient Body
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [palette.top, palette.bottom],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(drawRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(drawRect, Radius.circular(borderRadius)),
      bodyPaint,
    );

    // 4. Inner Top Highlight Stripe
    final highlightRect = Rect.fromLTWH(
      drawRect.left + 2,
      drawRect.top + 2,
      drawRect.width - 4,
      drawRect.height * 0.45,
    );
    final highlightPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x99FFFFFF), Color(0x00FFFFFF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(highlightRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, Radius.circular(borderRadius - 2)),
      highlightPaint,
    );

    // 5. Glossy Top-Left Reflection Blob
    final blobWidth = drawRect.width * 0.25;
    final blobHeight = drawRect.height * 0.22;
    final blobRect = Rect.fromLTWH(
      drawRect.left + 10,
      drawRect.top + 6,
      blobWidth,
      blobHeight,
    );
    final blobPaint = Paint()..color = const Color(0xAAFFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(blobRect, Radius.circular(blobHeight / 2)),
      blobPaint,
    );

    // 5b. Soft inner bottom shade + inner white rim (candy depth)
    final shadeRect = Rect.fromLTWH(
      drawRect.left,
      drawRect.top + drawRect.height * 0.6,
      drawRect.width,
      drawRect.height * 0.4,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        shadeRect,
        bottomLeft: Radius.circular(borderRadius),
        bottomRight: Radius.circular(borderRadius),
      ),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x00000000), Color(0x33000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(shadeRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        drawRect.deflate(2.5),
        Radius.circular(borderRadius - 2.5),
      ),
      Paint()
        ..color = const Color(0x44FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 6. Crisp Outer Border
    final borderPaint = Paint()
      ..color = palette.lip.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(drawRect, Radius.circular(borderRadius)),
      borderPaint,
    );
  }

  /// Draws a glossy round circular button.
  static void round(
    Canvas canvas,
    Offset center,
    double radius, {
    required JellyColor color,
    bool pressed = false,
    double pulse = 0.0,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    button(
      canvas,
      rect,
      color: color,
      pressed: pressed,
      pulse: pulse,
      borderRadius: radius,
    );
  }

  /// Draws a modal dialog/card panel with rich space-candy styling.
  static void panel(
    Canvas canvas,
    Rect rect, {
    double borderRadius = 24.0,
    Color borderColor = const Color(0xFF6C5CE7),
  }) {
    // Outer Shadow
    final shadowPaint = Paint()
      ..color = const Color(0x88000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(const Offset(0, 6)),
        Radius.circular(borderRadius),
      ),
      shadowPaint,
    );

    // Neon glow behind the frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.inflate(2),
        Radius.circular(borderRadius + 2),
      ),
      Paint()
        ..color = borderColor.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Border Frame Layer (purple -> cyan gradient)
    final borderPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Color.lerp(borderColor, Colors.white, 0.35)!,
          borderColor,
          const Color(0xFF31B8F4),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)),
      borderPaint,
    );

    // Inner Body Panel
    final innerRect = rect.deflate(6.0);
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3A2A8C), Color(0xFF1A1250)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(innerRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, Radius.circular(borderRadius - 4.0)),
      bodyPaint,
    );

    // Inner Top Glossy Gradient Overlay
    final glossRect = Rect.fromLTWH(
      innerRect.left,
      innerRect.top,
      innerRect.width,
      innerRect.height * 0.35,
    );
    final glossPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(glossRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(glossRect, Radius.circular(borderRadius - 6.0)),
      glossPaint,
    );
  }

  /// Draws a cream/beige status pill for hearts/coins counters.
  static void pill(Canvas canvas, Rect rect, {double borderRadius = 18.0}) {
    // Shadow
    final shadowPaint = Paint()
      ..color = const Color(0x44000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(const Offset(0, 2)),
        Radius.circular(borderRadius),
      ),
      shadowPaint,
    );

    // Outer Dark Cream Border
    final borderPaint = Paint()
      ..color = const Color(0xFF2C1E0A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)),
      borderPaint,
    );

    // Creamy Gradient Body
    final innerRect = rect.deflate(2.5);
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFAD1), Color(0xFFFFEAA7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(innerRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, Radius.circular(borderRadius - 2.0)),
      bodyPaint,
    );

    // Top Gloss Accent
    final glossRect = Rect.fromLTWH(
      innerRect.left + 2,
      innerRect.top + 1,
      innerRect.width - 4,
      innerRect.height * 0.45,
    );
    final glossPaint = Paint()..color = const Color(0xAAFFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(glossRect, Radius.circular(borderRadius - 4.0)),
      glossPaint,
    );
  }
}
