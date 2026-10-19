import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

enum _Kind { dot, ring, star, ribbon }

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  double duration;
  double radius;
  int color;
  double rotation;
  double spin;
  final _Kind kind;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.duration,
    required this.radius,
    required this.color,
    this.rotation = 0,
    this.spin = 0,
    this.kind = _Kind.dot,
  }) : life = 0;
}

/// Pop effects. Kept deliberately light: small round droplets, thin rings and
/// four-point glints (like the sparkles in the logo). Blur is only used for
/// glints, so a big chain reaction stays smooth.
class ParticleSystem extends PositionComponent {
  static const int _maxParticles = 650;

  final List<_Particle> _particles = [];
  final Random _random = Random(382);
  final ui.Paint _paint = ui.Paint();
  final ui.Paint _glowPaint = ui.Paint()
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);
  double _shakeTime = 0;
  double _shakeDuration = 0;
  double _shakeStrength = 0;
  double _shakeElapsed = 0;
  double? _targetX;
  double? _targetY;
  double _targetTime = 0;

  ui.Offset get cameraShakeOffset {
    if (_shakeTime <= 0 || _shakeDuration <= 0) return ui.Offset.zero;
    final progress = _shakeElapsed / _shakeDuration;
    final amplitude = _shakeTime / _shakeDuration * _shakeStrength;
    return ui.Offset(
      sin(progress * 85) * amplitude,
      sin(progress * 59) * amplitude * 0.45,
    );
  }

  ParticleSystem({required super.size});

  void _add(_Particle p) {
    if (_particles.length >= _maxParticles) {
      _particles.removeRange(0, _particles.length - _maxParticles + 1);
    }
    _particles.add(p);
  }

  void setTarget(double x, double y) {
    _targetX = x;
    _targetY = y;
  }

  void clearTarget() {
    _targetX = null;
    _targetY = null;
  }

  void burst(double x, double y, int color, {int count = 10}) {
    for (var i = 0; i < count; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = 70 + _random.nextDouble() * 240;
      _add(
        _Particle(
          x: x,
          y: y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          duration: 0.35 + _random.nextDouble() * 0.35,
          radius: 2 + _random.nextDouble() * 4,
          color: color,
        ),
      );
    }
    // two glints in the middle of every pop
    for (var i = 0; i < 2; i++) {
      _add(
        _Particle(
          x: x + (_random.nextDouble() - 0.5) * 20,
          y: y + (_random.nextDouble() - 0.5) * 20,
          vx: 0,
          vy: 0,
          duration: 0.26 + _random.nextDouble() * 0.1,
          radius: 8 + _random.nextDouble() * 6,
          color: 0xFFFFFFFF,
          kind: _Kind.star,
        ),
      );
    }
  }

  void ripple(double x, double y, int color) {
    _add(
      _Particle(
        x: x,
        y: y,
        vx: 0,
        vy: 0,
        duration: 0.5,
        radius: 10,
        color: color,
        kind: _Kind.ring,
      ),
    );
  }

  void sparkle(double x, double y, int color) {
    _add(
      _Particle(
        x: x,
        y: y,
        vx: (_random.nextDouble() - 0.5) * 30,
        vy: (_random.nextDouble() - 0.5) * 30,
        duration: 0.18 + _random.nextDouble() * 0.12,
        radius: 3.5 + _random.nextDouble() * 3,
        color: color,
        kind: _Kind.star,
      ),
    );
  }

  void flash(double x, double y) {
    _add(
      _Particle(
        x: x,
        y: y,
        vx: 0,
        vy: 0,
        duration: 0.26,
        radius: 24,
        color: 0xFFFFFFFF,
        kind: _Kind.star,
      ),
    );
  }

  void lightning(double x, double top, double bottom) {
    var boltX = x;
    final segmentHeight = (bottom - top) / 12;
    for (var i = 0; i <= 12; i++) {
      final y = top + segmentHeight * i;
      boltX += (_random.nextDouble() - 0.5) * 36;
      sparkle(boltX, y, 0xFFFFFFFF);
      sparkle(boltX + 3, y, 0xFFBDFBFF);
    }
  }

  void rocketTrail(double x, double targetY) {
    for (var i = 0; i < 16; i++) {
      final progress = i / 15;
      final y = 1170 - (1170 - targetY) * progress;
      final spread = (_random.nextDouble() - 0.5) * (10 + progress * 18);
      _add(
        _Particle(
          x: x + spread,
          y: y + 30,
          vx: spread * 0.4,
          vy: 35 + _random.nextDouble() * 35,
          duration: 0.38 + _random.nextDouble() * 0.25,
          radius: 3 + _random.nextDouble() * 4,
          color: 0xFFC9D4E4,
        ),
      );
    }
    burst(x, targetY, 0xFFBDFBFF, count: 10);
  }

  void confetti(double x, double y) {
    const colors = [0xFFFFD36B, 0xFF5CE1FF, 0xFFFF7B93, 0xFF7BED9F, 0xFFB79BFF];
    for (var i = 0; i < 70; i++) {
      final angle = -pi * 0.95 + _random.nextDouble() * pi * 0.9;
      final speed = 100 + _random.nextDouble() * 450;
      _add(
        _Particle(
          x: x,
          y: y,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          duration: 1.4 + _random.nextDouble() * 0.8,
          radius: 4 + _random.nextDouble() * 4,
          color: colors[i % colors.length],
          rotation: _random.nextDouble() * pi,
          spin: (_random.nextDouble() - 0.5) * 14,
          kind: _Kind.ribbon,
        ),
      );
    }
  }

  void burstBurn(double x, double y) {
    burst(x, y, 0xFFFF5A4F, count: 16);
    burst(x, y, 0xFFFFA64D, count: 10);
    ripple(x, y, 0xFFFF8A7A);
    shakeCamera(5.0, duration: 0.24);
  }

  void burstSteam(double x, double y) {
    burst(x, y, 0xFF6FB4FF, count: 14);
    burst(x, y, 0xFFE9D79A, count: 8);
    ripple(x, y, 0xFFBDFBFF);
    shakeCamera(3.5, duration: 0.2);
  }

  void burstMud(double x, double y) {
    burst(x, y, 0xFFE2B95A, count: 16);
    burst(x, y, 0xFFA4B0BE, count: 8);
    ripple(x, y, 0xFFE2B95A);
    shakeCamera(4.5, duration: 0.22);
  }

  void burstBloom(double x, double y) {
    burst(x, y, 0xFF3FD97F, count: 18);
    burst(x, y, 0xFFFF8FA3, count: 10);
    ripple(x, y, 0xFF8CF0AE);
    shakeCamera(4.0, duration: 0.2);
  }

  void fireSpread(double x, double y) {
    burst(x, y, 0xFFFF8A24, count: 6);
    sparkle(x, y, 0xFFFFE5A3);
  }

  void shakeCamera(double strength, {double duration = 0.22}) {
    if (strength > _shakeStrength || _shakeTime <= 0) {
      _shakeStrength = strength;
      _shakeDuration = duration;
      _shakeTime = duration;
      _shakeElapsed = 0;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _targetTime += dt;
    for (var i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.life += dt;
      if (p.life >= p.duration) {
        _particles.removeAt(i);
        continue;
      }
      if (p.kind == _Kind.ring) continue;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 240 * dt;
      p.vx *= 0.992;
      p.rotation += p.spin * dt;
    }
    if (_shakeTime > 0) {
      _shakeTime = max(0, _shakeTime - dt);
      _shakeElapsed += dt;
    } else {
      _shakeStrength = 0;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    _renderTarget(canvas);
    for (final p in _particles) {
      final progress = (p.life / p.duration).clamp(0.0, 1.0);
      final alpha = (1 - progress).clamp(0.0, 1.0);
      final base = ui.Color(p.color);
      final center = ui.Offset(p.x, p.y);

      switch (p.kind) {
        case _Kind.ring:
          final r = p.radius + progress * 46;
          canvas.drawCircle(
            center,
            r,
            _paint
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 6 * alpha + 0.5
              ..color = base.withValues(alpha: alpha * 0.22),
          );
          canvas.drawCircle(
            center,
            r,
            _paint
              ..strokeWidth = 2 * alpha + 0.4
              ..color = const ui.Color(0xFFFFFFFF)
                  .withValues(alpha: alpha * 0.85),
          );
        case _Kind.star:
          final e = p.radius * (1 - progress * 0.5) * (0.6 + alpha * 0.4);
          canvas.drawCircle(
            center,
            e * 0.8,
            _glowPaint
              ..style = ui.PaintingStyle.fill
              ..color = base.withValues(alpha: alpha * 0.4),
          );
          final path = ui.Path()
            ..moveTo(center.dx, center.dy - e)
            ..quadraticBezierTo(center.dx, center.dy, center.dx + e, center.dy)
            ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + e)
            ..quadraticBezierTo(center.dx, center.dy, center.dx - e, center.dy)
            ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - e)
            ..close();
          canvas.drawPath(
            path,
            _paint
              ..style = ui.PaintingStyle.fill
              ..color = base.withValues(alpha: alpha),
          );
        case _Kind.ribbon:
          final flip = cos(p.life * 9 + p.rotation).abs();
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(p.rotation);
          canvas.drawRRect(
            ui.RRect.fromRectAndRadius(
              ui.Rect.fromCenter(
                center: ui.Offset.zero,
                width: p.radius * 2.2,
                height: max(1.2, p.radius * 1.1 * flip),
              ),
              const ui.Radius.circular(2),
            ),
            _paint
              ..style = ui.PaintingStyle.fill
              ..color = base.withValues(alpha: alpha),
          );
          canvas.restore();
        case _Kind.dot:
          final r = p.radius * (1 - progress * 0.35);
          canvas.drawCircle(
            center,
            r * 1.7,
            _paint
              ..style = ui.PaintingStyle.fill
              ..color = base.withValues(alpha: alpha * 0.22),
          );
          canvas.drawCircle(
            center,
            r,
            _paint..color = base.withValues(alpha: alpha),
          );
          canvas.drawCircle(
            center.translate(-r * 0.3, -r * 0.3),
            r * 0.28,
            _paint
              ..color = const ui.Color(0xFFFFFFFF)
                  .withValues(alpha: alpha * 0.8),
          );
      }
    }
  }

  void _renderTarget(ui.Canvas canvas) {
    if (_targetX == null || _targetY == null) return;
    final pulse = (sin(_targetTime * 4.5) + 1) * 0.5;
    final c = ui.Offset(_targetX!, _targetY!);
    canvas.drawCircle(
      c,
      27 + pulse * 5,
      _paint
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = const ui.Color(0xFFFFE9A6).withValues(alpha: 0.22),
    );
    canvas.drawCircle(
      c,
      24 + pulse * 4,
      _paint
        ..strokeWidth = 2.5
        ..color = const ui.Color(0xFFFFE9A6)
            .withValues(alpha: 0.75 + pulse * 0.25),
    );
    canvas.drawCircle(
      c,
      5,
      _paint
        ..style = ui.PaintingStyle.fill
        ..color = const ui.Color(0xFFFFFFFF),
    );
  }
}
