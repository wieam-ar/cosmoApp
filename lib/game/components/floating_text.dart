import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Alignment, Curves, LinearGradient;
import 'package:flutter/painting.dart' as painting;

/// Score / combo text: clean deep-violet outline, soft gradient fill, one
/// gentle pop-in. No overshoot past its final size.
class FloatingText extends PositionComponent {
  final String text;
  final ui.Color color;
  final double duration;
  static const double _pad = 8;

  late final painting.TextPainter _stroke;
  late final painting.TextPainter _fill;
  double _age = 0;

  FloatingText({
    required this.text,
    required Vector2 position,
    this.color = const ui.Color(0xFFFFFFFF),
    this.duration = 0.9,
  }) : super(position: position, size: Vector2.zero(), anchor: Anchor.center) {
    const fontSize = 38.0;
    const weight = ui.FontWeight.w800;

    _stroke = painting.TextPainter(
      text: painting.TextSpan(
        text: text,
        style: painting.TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: 0.8,
          foreground: ui.Paint()
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 7
            ..strokeJoin = ui.StrokeJoin.round
            ..color = const ui.Color(0xFF241055),
          shadows: const [
            painting.Shadow(
              color: ui.Color(0x80000000),
              blurRadius: 5,
              offset: ui.Offset(0, 3),
            ),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final w = _stroke.width;
    final h = _stroke.height;
    final top = ui.Color.lerp(color, const ui.Color(0xFFFFFFFF), 0.6)!;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [top, color],
    ).createShader(ui.Rect.fromLTWH(0, 0, w, h));

    _fill = painting.TextPainter(
      text: painting.TextSpan(
        text: text,
        style: painting.TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: 0.8,
          foreground: ui.Paint()..shader = gradient,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    size.setValues(w + _pad * 2, h + _pad * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    // smooth deceleration instead of a hard speed change
    final t = (_age / duration).clamp(0.0, 1.0);
    position.y -= (80 * (1 - t) + 22) * dt;
    if (_age >= duration) removeFromParent();
  }

  @override
  void render(ui.Canvas canvas) {
    final t = (_age / duration).clamp(0.0, 1.0);
    final pop = (t / 0.2).clamp(0.0, 1.0);
    final scale = 0.7 + Curves.easeOutBack.transform(pop) * 0.3;
    final fade = t < 0.6 ? 1.0 : (1 - (t - 0.6) / 0.4).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(scale);
    canvas.translate(-size.x / 2, -size.y / 2);
    canvas.saveLayer(
      ui.Rect.fromLTWH(-20, -20, size.x + 40, size.y + 40),
      ui.Paint()..color = ui.Color.fromRGBO(255, 255, 255, fade),
    );
    _stroke.paint(canvas, const ui.Offset(_pad, _pad));
    _fill.paint(canvas, const ui.Offset(_pad, _pad));
    canvas.restore();
    canvas.restore();
  }
}
