import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../art/mimo_painter.dart';

class MimoComponent extends PositionComponent {
  static final ui.Paint _shadow = ui.Paint()
    ..color = const ui.Color(0x38000000)
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7);

  MimoState state = MimoState.idle;
  double time = 0;
  double aimAngle = 0;

  MimoComponent({required Vector2 position, double size = 170})
    : super(
        position: position,
        size: Vector2.all(size),
        anchor: Anchor.center,
        priority: 8,
      );

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;
  }

  @override
  void render(ui.Canvas canvas) {
    // slow float; the contact shadow shrinks as Mimo rises
    final lift = (sin(time * 1.8) + 1) * 0.5;
    canvas.drawOval(
      ui.Rect.fromCenter(
        center: ui.Offset(size.x / 2, size.y * 0.93),
        width: size.x * (0.46 - lift * 0.05),
        height: 12,
      ),
      _shadow,
    );
    MimoPainter.draw(
      canvas,
      ui.Offset(size.x / 2, size.y / 2 - lift * 3),
      size.x,
      state: state,
      t: time,
      aimAngle: aimAngle,
    );
  }
}
