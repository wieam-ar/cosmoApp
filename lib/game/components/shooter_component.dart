import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart'
    show Alignment, LinearGradient, RadialGradient;
import 'package:flutter/painting.dart' as painting;

import '../../art/bubble_painter.dart';
import '../../art/icons_painter.dart';
import '../../art/mimo_painter.dart';
import '../../config/bubble_types.dart';
import '../../core/save_service.dart';
import '../cosmo_game.dart';
import 'bubble_component.dart';
import 'mimo_component.dart';

class ShooterComponent extends PositionComponent {
  final CosmoGame game;
  final Vector2 launchPoint = Vector2(360, 985);
  final Vector2 mimoPoint = Vector2(360, 1114);
  final MimoComponent mimo;
  BubbleComponent? currentBubble;
  BubbleComponent? projectile;
  BubbleType nextType = BubbleType.blue;
  double aimAngle = 0;
  bool aiming = false;
  double _time = 0;
  double _happyTime = 0;
  double _trailTime = 0;
  final List<ui.Offset> _trajectory = [];
  bool _rainbowNext = false;
  late final painting.TextPainter _nextLabel = painting.TextPainter(
    text: const painting.TextSpan(
      text: 'NEXT',
      style: painting.TextStyle(
        color: ui.Color(0xCCDCCBFF),
        fontSize: 12,
        fontWeight: ui.FontWeight.w800,
        letterSpacing: 2.2,
      ),
    ),
    textDirection: ui.TextDirection.ltr,
  )..layout();

  ShooterComponent({required this.game})
    : mimo = MimoComponent(position: Vector2(360, 1115)),
      super(size: Vector2(720, 1280), priority: 5) {
    anchor = Anchor.topLeft;
  }

  void makeNextRainbow() {
    if (currentBubble != null) {
      currentBubble!.type = BubbleType.rainbow;
      _rainbowNext = false;
    } else {
      _rainbowNext = true;
    }
  }

  void cheer() {
    _happyTime = 1.2;
    mimo.state = MimoState.cheer;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    game.world.add(mimo);
    game.world.add(_SwapTapArea(shooter: this));
    _newBubble();
  }

  void _newBubble() {
    final type = _rainbowNext ? BubbleType.rainbow : game.randomBubbleType();
    _rainbowNext = false;
    currentBubble = game.obtainBubble(
      type,
      launchPoint,
      state: BubbleState.held,
    );
    nextType = game.randomBubbleType();
  }

  void swap() {
    if (projectile != null || currentBubble == null) return;
    final held = currentBubble!.type;
    currentBubble!.type = nextType;
    nextType = held;
  }

  void reload() {
    if (projectile != null || currentBubble != null) return;
    _newBubble();
  }

  void setAim(ui.Offset target) {
    if (projectile != null || game.isFinished) return;
    final dx = target.dx - launchPoint.x;
    final dy = launchPoint.y - target.dy;
    // 0 = straight up, negative = left, positive = right (max ~80° each side)
    const maxAim = pi / 2 - pi / 18;
    aimAngle = atan2(dx, dy).clamp(-maxAim, maxAim);
    aiming = true;
    mimo.state = MimoState.aim;
    mimo.aimAngle = aimAngle;
    _buildTrajectory();
  }

  void celebrate() {
    _happyTime = 0.8;
    mimo.state = MimoState.happy;
  }

  void release() {
    if (!aiming ||
        currentBubble == null ||
        projectile != null ||
        game.isFinished) {
      aiming = false;
      return;
    }
    aiming = false;
    projectile = currentBubble;
    currentBubble = null;
    projectile!.state = BubbleState.flying;
    projectile!.position.setFrom(launchPoint);
    projectile!.velocity.setValues(sin(aimAngle) * 1800, -cos(aimAngle) * 1800);
    projectile!.wobble = 0;
    _trailTime = 0;
    game.shotStarted();
    mimo.state = MimoState.idle;
  }

  void fire() {
    if (currentBubble == null || projectile != null || game.isFinished) return;
    aiming = true;
    release();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _happyTime = max(0, _happyTime - dt);
    if (projectile != null) _advanceProjectile(dt);
    if (!aiming && projectile == null) _refreshMimoState();
  }

  void _advanceProjectile(double dt) {
    final bubble = projectile!;
    final distance = 1800 * dt;
    final steps = max(1, (distance / (game.grid.radius * 0.25)).ceil());
    final stepDt = dt / steps;
    for (var step = 0; step < steps && projectile != null; step++) {
      bubble.position += bubble.velocity * stepDt;
      bubble.wobble = atan2(bubble.velocity.y, bubble.velocity.x) + pi / 2;
      _trailTime += stepDt;
      if (_trailTime >= 0.035) {
        _trailTime = 0;
        game.particles.sparkle(
          bubble.position.x,
          bubble.position.y,
          kBubbleStyles[bubble.type]?.lightColor.toARGB32() ?? 0xFFFFFFFF,
        );
      }
      if (bubble.position.x <= game.grid.radius) {
        bubble.position.x = game.grid.radius;
        bubble.velocity.x = bubble.velocity.x.abs();
        bubble.squash = 0.9;
        _bounce();
      } else if (bubble.position.x >= 720 - game.grid.radius) {
        bubble.position.x = 720 - game.grid.radius;
        bubble.velocity.x = -bubble.velocity.x.abs();
        bubble.squash = 0.9;
        _bounce();
      }

      if (bubble.position.y <= game.grid.top + game.grid.radius) {
        _snapProjectile(bubble.position.x, bubble.position.y);
        break;
      }
      final collisionDistance = game.grid.radius * 1.8;
      final collisionDistanceSquared = collisionDistance * collisionDistance;
      for (var row = 0; row < game.grid.rowCount; row++) {
        for (var col = 0; col < game.grid.cols; col++) {
          final other = game.grid.at(row, col);
          if (other == null) continue;
          final dx = bubble.position.x - other.position.x;
          final dy = bubble.position.y - other.position.y;
          if (dx * dx + dy * dy < collisionDistanceSquared) {
            game.onSpecialHit(other);
            _snapProjectile(bubble.position.x, bubble.position.y);
            return;
          }
        }
      }
    }
  }

  void _bounce() {
    game.playBounce();
  }

  void _snapProjectile(double x, double y) {
    final bubble = projectile;
    if (bubble == null) return;
    final cell = game.grid.xyToCell(x, y);
    if (cell == null) {
      game.missShot(bubble);
      projectile = null;
      _newBubble();
      return;
    }
    if (cell.row >= game.grid.rowCount + 1) {
      game.missShot(bubble);
      projectile = null;
      _newBubble();
      return;
    }
    bubble.state = BubbleState.idle;
    bubble.velocity.setZero();
    bubble.squash = 1;
    game.grid.insert(cell.row, cell.col, bubble);
    game.particles.ripple(bubble.position.x, bubble.position.y, 0xFF7FEAFF);
    game.onBubbleLanded(bubble);
    projectile = null;
    _newBubble();
  }

  void _refreshMimoState() {
    if (_happyTime > 0 || aiming) return;
    final bottomLine = game.deadLineY;
    final nervous = game.grid.cells.asMap().entries.any((entry) {
      final row = entry.key;
      if (row < game.grid.rowCount - 3) return false;
      return entry.value.any((bubble) => bubble != null);
    });
    mimo.state = game.goal.missedShots >= 3
        ? MimoState.sad
        : nervous && bottomLine > 0
        ? MimoState.nervous
        : MimoState.idle;
  }

  void _buildTrajectory() {
    _trajectory.clear();
    var point = ui.Offset(launchPoint.x, launchPoint.y);
    var dx = sin(aimAngle);
    var dy = -cos(aimAngle);
    var hasBounced = false;
    for (var i = 0; i < 90; i++) {
      var step = 20.0;
      final wallX = dx > 0
          ? (720 - game.grid.radius - point.dx) / dx
          : (game.grid.radius - point.dx) / dx;
      if (wallX > 0 && wallX < step) step = wallX;
      final ceilingY = (game.grid.top + game.grid.radius - point.dy) / dy;
      if (ceilingY > 0 && ceilingY < step) step = ceilingY;
      final hitWall = wallX > 0 && wallX <= step;
      final candidate = ui.Offset(point.dx + dx * step, point.dy + dy * step);
      _trajectory.add(candidate);
      point = candidate;
      var hitBubble = false;
      for (var row = 0; row < game.grid.rowCount && !hitBubble; row++) {
        for (var col = 0; col < game.grid.cols; col++) {
          final other = game.grid.at(row, col);
          if (other == null) continue;
          final bx = point.dx - other.position.x;
          final by = point.dy - other.position.y;
          final collisionRadius = game.grid.radius * 1.8;
          if (bx * bx + by * by < collisionRadius * collisionRadius) {
            hitBubble = true;
            break;
          }
        }
      }
      if (hitBubble || point.dy <= game.grid.top + game.grid.radius + 1) break;
      if (hitWall) {
        if (hasBounced) break;
        hasBounced = true;
        dx = -dx;
      }
    }
  }

  @override
  void render(ui.Canvas canvas) {
    _drawLaunchRing(canvas);
    _drawAim(canvas);
    _drawNextPod(canvas);
  }

  ui.Color get _tint =>
      (currentBubble == null ? null : kBubbleStyles[currentBubble!.type])
          ?.lightColor ??
      const ui.Color(0xFFBDFBFF);

  /// Thin rim-light ring around the loaded bubble (ring only, so the bubble
  /// underneath stays fully visible).
  void _drawLaunchRing(ui.Canvas canvas) {
    if (currentBubble == null) return;
    final pulse = (sin(_time * 3.0) + 1) * 0.5;
    final r = game.grid.radius;
    final c = ui.Offset(launchPoint.x, launchPoint.y);
    canvas.drawCircle(
      c,
      r + 11 + pulse * 2,
      ui.Paint()
        ..color = _tint.withValues(alpha: 0.16 + pulse * 0.1)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 7
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      c,
      r + 9,
      ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.4)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  void _drawAim(ui.Canvas canvas) {
    if (!aiming || _trajectory.isEmpty) return;
    final laser = SaveService.I.aimingMode == 'laser';
    final tint = _tint;
    final reticleRadius = game.grid.radius * 0.6;
    if (laser) {
      final path = ui.Path()..moveTo(launchPoint.x, launchPoint.y);
      for (final point in _trajectory) {
        path.lineTo(point.dx, point.dy);
      }
      // soft colored body + thin white core, no heavy bloom
      canvas.drawPath(
        path,
        ui.Paint()
          ..color = tint.withValues(alpha: 0.28)
          ..strokeWidth = 9
          ..strokeCap = ui.StrokeCap.round
          ..strokeJoin = ui.StrokeJoin.round
          ..style = ui.PaintingStyle.stroke
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
      );
      canvas.drawPath(
        path,
        ui.Paint()
          ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.92)
          ..strokeWidth = 2
          ..strokeCap = ui.StrokeCap.round
          ..strokeJoin = ui.StrokeJoin.round
          ..style = ui.PaintingStyle.stroke,
      );
    } else {
      // evenly spaced round dots, shrinking and fading toward the target,
      // with a quiet wave travelling along them
      final dot = ui.Paint();
      for (var i = 1; i < _trajectory.length; i += 2) {
        final point = _trajectory[i];
        final progress = i / _trajectory.length;
        final wave = 0.85 + 0.15 * sin(_time * 8 - i * 0.5);
        final radius = max(2.0, 4.6 - progress * 2.4) * wave;
        final alpha = (1 - progress * 0.65).clamp(0.25, 1.0);
        canvas.drawCircle(
          point,
          radius * 1.9,
          dot..color = tint.withValues(alpha: alpha * 0.18),
        );
        canvas.drawCircle(
          point,
          radius,
          dot..color = const ui.Color(0xFFFFFFFF).withValues(alpha: alpha),
        );
      }
    }
    // landing reticle: soft ghost bubble + thin ring + center dot
    final end = _trajectory.last;
    canvas.drawCircle(
      end,
      reticleRadius,
      ui.Paint()..color = tint.withValues(alpha: 0.14),
    );
    canvas.drawCircle(
      end,
      reticleRadius,
      ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.85)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(end, 2.2, ui.Paint()..color = const ui.Color(0xFFFFFFFF));
  }

  /// "NEXT" capsule: a glass pod with a top sheen, a floating preview bubble
  /// and a round glass swap button. Hit area (see _SwapTapArea) is unchanged.
  void _drawNextPod(ui.Canvas canvas) {
    final rect = ui.Rect.fromCenter(
      center: const ui.Offset(92, 1060),
      width: 104,
      height: 80,
    );
    final body = ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(28));
    final pulse = (sin(_time * 2.2) + 1) * 0.5;

    // contact shadow
    canvas.drawRRect(
      body.shift(const ui.Offset(0, 6)),
      ui.Paint()
        ..color = const ui.Color(0x66000000)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10),
    );
    // glass body
    canvas.drawRRect(
      body,
      ui.Paint()
        ..shader = const LinearGradient(
          colors: [ui.Color(0xEE3A2A8C), ui.Color(0xEE150E48)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
    );
    // top sheen
    final sheen = ui.RRect.fromRectAndCorners(
      ui.Rect.fromLTWH(
        rect.left + 5,
        rect.top + 4,
        rect.width - 10,
        rect.height * 0.4,
      ),
      topLeft: const ui.Radius.circular(23),
      topRight: const ui.Radius.circular(23),
      bottomLeft: const ui.Radius.circular(12),
      bottomRight: const ui.Radius.circular(12),
    );
    canvas.drawRRect(
      sheen,
      ui.Paint()
        ..shader = LinearGradient(
          colors: [
            const ui.Color(0xFFFFFFFF).withValues(alpha: 0.22),
            const ui.Color(0xFFFFFFFF).withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(sheen.outerRect),
    );
    // rim light
    canvas.drawRRect(
      body,
      ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.32)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // label
    _nextLabel.paint(
      canvas,
      ui.Offset(rect.center.dx - _nextLabel.width / 2, rect.bottom - 23),
    );

    // preview bubble on a soft halo
    const bubbleCenter = ui.Offset(92, 1030);
    final haloRadius = game.grid.radius * 1.1;
    canvas.drawCircle(
      bubbleCenter,
      haloRadius,
      ui.Paint()
        ..shader =
            RadialGradient(
              colors: [
                const ui.Color(0xFFFFFFFF).withValues(alpha: 0.26),
                const ui.Color(0xFFFFFFFF).withValues(alpha: 0),
              ],
            ).createShader(
              ui.Rect.fromCircle(center: bubbleCenter, radius: haloRadius),
            ),
    );
    BubblePainter.draw(
      canvas,
      bubbleCenter,
      game.grid.radius * 0.6,
      nextType,
      t: _time,
    );

    // swap button: round glass, cyan
    const swapCenter = ui.Offset(161, 1048);
    canvas.drawCircle(
      swapCenter.translate(0, 3),
      21,
      ui.Paint()
        ..color = const ui.Color(0x55000000)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      swapCenter,
      24,
      ui.Paint()
        ..color = const ui.Color(0xFF5CE1FF)
            .withValues(alpha: 0.14 + pulse * 0.1)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7),
    );
    canvas.drawCircle(
      swapCenter,
      21,
      ui.Paint()
        ..shader = const LinearGradient(
          colors: [ui.Color(0xFF6FE8FF), ui.Color(0xFF2B73F0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(ui.Rect.fromCircle(center: swapCenter, radius: 21)),
    );
    canvas.drawOval(
      ui.Rect.fromCenter(
        center: swapCenter.translate(-2, -11),
        width: 24,
        height: 10,
      ),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      swapCenter,
      21,
      ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.9)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    IconsPainter.draw(
      canvas,
      ui.Rect.fromCenter(center: swapCenter, width: 24, height: 24),
      AppIcon.swap,
      color: const ui.Color(0xFFFFFFFF),
      strokeWidth: 3.2,
    );
  }
}

class _SwapTapArea extends PositionComponent with TapCallbacks {
  final ShooterComponent shooter;

  _SwapTapArea({required this.shooter})
    : super(position: Vector2(30, 987), size: Vector2(175, 98), priority: 20);

  @override
  void onTapUp(TapUpEvent event) {
    if (shooter.game.pendingPowerup == null) shooter.swap();
    super.onTapUp(event);
  }
}
