import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../art/bubble_painter.dart';
import '../../config/bubble_types.dart';
import '../../core/save_service.dart';

enum BubbleState { idle, flying, popping, falling, held, inactive }

class BubbleComponent extends PositionComponent {
  static const double _popDuration = 0.2;
  static final ui.Paint _ringPaint = ui.Paint()
    ..style = ui.PaintingStyle.stroke;
  static final ui.Paint _flashPaint = ui.Paint()
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7);

  BubbleType type = BubbleType.red;
  BubbleState state = BubbleState.inactive;
  Vector2 velocity = Vector2.zero();
  double squash = 0;
  double wobble = 0;
  double hits = 1;
  double age = 0;
  double alpha = 1;
  double hintGlow = 0;
  double _animationTime = 0;
  double _lifetime = 0;
  int row = -1;
  int col = -1;
  bool fireSource = false;
  bool get isCat => type == BubbleType.purple;

  BubbleComponent({double radius = 32}) : super(size: Vector2.all(radius * 2));

  double get radius => size.x / 2;

  void configure({
    required BubbleType bubbleType,
    required Vector2 center,
    double bubbleRadius = 32,
    BubbleState bubbleState = BubbleState.idle,
    int rowIndex = -1,
    int columnIndex = -1,
    bool isFireSource = false,
  }) {
    type = bubbleType;
    size.setValues(bubbleRadius * 2, bubbleRadius * 2);
    scale.setValues(1, 1);
    position.setFrom(center);
    state = bubbleState;
    velocity.setZero();
    squash = 0;
    wobble = 0;
    hits = bubbleType == BubbleType.stone ? 2 : 1;
    age = 0;
    alpha = 1;
    hintGlow = 0;
    _animationTime = 0;
    _lifetime = 0;
    row = rowIndex;
    col = columnIndex;
    fireSource = isFireSource;
    anchor = Anchor.center;
    priority = 2;
  }

  void setCell(int rowIndex, int columnIndex, ui.Offset point) {
    row = rowIndex;
    col = columnIndex;
    position.setValues(point.dx, point.dy);
    state = BubbleState.idle;
  }

  void pop({double delay = 0}) {
    state = BubbleState.popping;
    _lifetime = -delay;
    age = 0;
  }

  void fall() {
    state = BubbleState.falling;
    velocity.setValues(0, 150 + radius * 2);
    age = 0;
  }

  void deactivate() {
    state = BubbleState.inactive;
    row = -1;
    col = -1;
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (state == BubbleState.inactive || state == BubbleState.held) return;
    _animationTime += dt;
    if (state == BubbleState.popping) {
      if (_lifetime < 0) {
        _lifetime += dt;
        return;
      }
      _lifetime += dt;
      final p = (_lifetime / _popDuration).clamp(0.0, 1.0);
      final eased = 1 - pow(1 - p, 3).toDouble();
      final s = 1 + eased * 0.12;
      scale.setValues(s, s);
      alpha = 1 - p;
      if (p >= 1) deactivate();
    } else if (state == BubbleState.falling) {
      age += dt;
      velocity.y += 460 * dt;
      position += velocity * dt;
      alpha = (1 - age / 1.1).clamp(0.0, 1.0);
      final s = 1 - (age / 1.1).clamp(0.0, 1.0) * 0.15;
      scale.setValues(s, s);
      if (age >= 1.1 || position.y > 1380) deactivate();
    } else {
      squash = max(0, squash - dt * 3.5);
      // calm idle breathing, a touch smaller than before
      wobble = sin(_animationTime * 4 + row * 0.4) * 0.018;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    if (state == BubbleState.inactive) return;

    // clean pop: one soft tinted flash + one thin shock ring
    if (state == BubbleState.popping && _lifetime >= 0) {
      final p = (_lifetime / _popDuration).clamp(0.0, 1.0);
      final eased = 1 - pow(1 - p, 3).toDouble();
      final tint =
          kBubbleStyles[type]?.lightColor ?? const ui.Color(0xFFFFFFFF);
      final c = ui.Offset(radius, radius);
      canvas.drawCircle(
        c,
        radius * (0.7 + eased * 0.5),
        _flashPaint..color = tint.withValues(alpha: (1 - p) * 0.35),
      );
      canvas.drawCircle(
        c,
        radius * (1 + eased * 0.65),
        _ringPaint
          ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: (1 - p) * 0.75)
          ..strokeWidth = 3 * (1 - p) + 0.6,
      );
    }

    canvas.save();
    canvas.translate(radius, radius);
    if (state == BubbleState.flying) {
      canvas.rotate(wobble);
      final stretch = 1 + min(velocity.length / 12000, 0.16);
      canvas.scale(1 / stretch, stretch as double?);
    } else if (state == BubbleState.falling) {
      canvas.rotate(age * 1.8 * (row.isEven ? 1 : -1));
    } else {
      canvas.rotate(wobble);
    }
    BubblePainter.draw(
      canvas,
      ui.Offset.zero,
      radius,
      type,
      t: _animationTime,
      colorblind: SaveService.I.colorblindEnabled,
      squashX: 1 - squash * 0.18,
      squashY: 1 + squash * 0.2,
      alpha: alpha,
      glow: state == BubbleState.held
          ? 0.3 + sin(_animationTime * 3.2) * 0.08
          : 0,
      hits: hits,
      hintGlow: hintGlow,
      fireSource: fireSource,
    );
    canvas.restore();
  }
}
