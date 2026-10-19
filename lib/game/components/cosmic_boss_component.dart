import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

/// Procedural Void King portrait; encounter state is owned by game logic.
/// A lit violet sphere with an orbit ring and a small gold crown, so it reads
/// as a real object in the same glass-and-rim-light style as the bubbles.
class CosmicBossComponent extends PositionComponent {
  double _age = 0;
  double _impact = 0;
  int _stage = 0;
  bool _defeated = false;

  CosmicBossComponent({required Vector2 position})
    : super(
        position: position,
        size: Vector2.all(112),
        anchor: Anchor.center,
        priority: 3,
      );

  void syncStage(int stage, {bool defeated = false}) {
    if (stage != _stage || defeated != _defeated) {
      _stage = stage;
      _defeated = defeated;
      _impact = 1;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    _impact = max(0, _impact - dt * 2.8);
  }

  @override
  void render(ui.Canvas canvas) {
    final c = ui.Offset(size.x / 2, size.y / 2 + 6);
    final r = size.x * 0.30 + sin(_age * 2.0) * 1.5 + _impact * 4;
    final accent = _defeated
        ? const ui.Color(0xFFFFE184)
        : switch (_stage % 4) {
            0 => const ui.Color(0xFFFF8B52),
            1 => const ui.Color(0xFF73D9FF),
            2 => const ui.Color(0xFFC49A7A),
            _ => const ui.Color(0xFF9BFFAD),
          };
    final orbit = ui.Rect.fromCenter(
      center: c,
      width: r * 3.0,
      height: r * 0.95,
    );
    final orbitPaint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = ui.StrokeCap.round;

    // soft aura
    canvas.drawCircle(
      c,
      r + 12,
      ui.Paint()
        ..color = accent.withValues(alpha: 0.16 + _impact * 0.2)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 14),
    );

    // orbit ring, back half
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.38);
    canvas.translate(-c.dx, -c.dy);
    canvas.drawArc(
      orbit,
      pi,
      pi,
      false,
      orbitPaint..color = accent.withValues(alpha: 0.32),
    );
    canvas.restore();

    // sphere lit from the top-left
    final light = c.translate(-r * 0.32, -r * 0.38);
    canvas.drawCircle(
      c,
      r,
      ui.Paint()
        ..shader = ui.Gradient.radial(
          light,
          r * 1.7,
          const [
            ui.Color(0xFF9272E6),
            ui.Color(0xFF45307F),
            ui.Color(0xFF130D33),
          ],
          const [0, 0.55, 1],
        ),
    );
    // rim light
    canvas.drawArc(
      ui.Rect.fromCircle(center: c, radius: r - 1),
      pi * 1.02,
      pi * 0.62,
      false,
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = ui.StrokeCap.round
        ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.38),
    );
    // specular
    canvas.drawOval(
      ui.Rect.fromCenter(
        center: c.translate(-r * 0.42, -r * 0.5),
        width: r * 0.5,
        height: r * 0.26,
      ),
      ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.28)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2),
    );

    // face
    canvas.drawOval(
      ui.Rect.fromCenter(
        center: c.translate(0, r * 0.42),
        width: r * 0.78,
        height: r * 0.24,
      ),
      ui.Paint()..color = const ui.Color(0xFF0B081D),
    );
    final eyeAlpha = _defeated ? 0.45 : 1.0;
    for (final side in const [-1.0, 1.0]) {
      final eye = c.translate(side * r * 0.36, -r * 0.04);
      canvas.drawCircle(
        eye,
        6.5,
        ui.Paint()..color = accent.withValues(alpha: 0.22 * eyeAlpha),
      );
      canvas.drawCircle(
        eye,
        3.4,
        ui.Paint()
          ..color = const ui.Color(0xFFFFF2C2).withValues(alpha: eyeAlpha),
      );
    }

    // orbit ring, front half
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.38);
    canvas.translate(-c.dx, -c.dy);
    canvas.drawArc(
      orbit,
      0,
      pi,
      false,
      orbitPaint..color = accent.withValues(alpha: 0.85),
    );
    canvas.restore();

    // small gold crown
    final baseY = c.dy - r * 0.8;
    final w = r * 0.9;
    final crown = ui.Path()
      ..moveTo(c.dx - w / 2, baseY)
      ..lineTo(c.dx - w / 2, baseY - 10)
      ..lineTo(c.dx - w / 4, baseY - 4)
      ..lineTo(c.dx, baseY - 15)
      ..lineTo(c.dx + w / 4, baseY - 4)
      ..lineTo(c.dx + w / 2, baseY - 10)
      ..lineTo(c.dx + w / 2, baseY)
      ..close();
    canvas.drawPath(
      crown,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(c.dx, baseY - 15),
          ui.Offset(c.dx, baseY),
          const [ui.Color(0xFFFFE9A6), ui.Color(0xFFE0A93A)],
        ),
    );
    canvas.drawPath(
      crown,
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeJoin = ui.StrokeJoin.round
        ..color = const ui.Color(0xFF7A5515),
    );
    canvas.drawCircle(
      ui.Offset(c.dx, baseY - 6),
      2,
      ui.Paint()..color = accent,
    );
  }
}
