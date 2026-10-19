import 'dart:math';

import 'package:flutter/material.dart';

import '../art/bubble_painter.dart';
import '../art/jelly_painter.dart';
import '../art/mimo_painter.dart';
import '../art/space_painter.dart';
import '../art/title3d.dart';
import '../art/ufo_painter.dart';
import '../config/bubble_types.dart';
import '../core/audio_service.dart';
import '../core/constants.dart';
import '../core/haptics.dart';
import '../core/transitions.dart';

import 'menu_screen.dart';

/// Pre-calculated deterministic physics bubble data.
class _SplashBubble {
  final int id;
  final BubbleType type;
  final double spawnTime; // 1.8..2.9s
  final double spawnXOffset; // offset from UFO beam center
  final double radius;

  // Integrated physics state
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;
  double squashX = 1.0;
  double squashY = 1.0;
  bool landed = false;

  _SplashBubble({
    required this.id,
    required this.type,
    required this.spawnTime,
    required this.spawnXOffset,
    required this.radius,
  });
}

/// Cinematic splash screen featuring deterministic timeline & physics simulation.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _timelineController;
  final List<_SplashBubble> _bubbles = [];

  bool _navigated = false;
  bool _rumblePlayed = false;
  bool _ufoInWhooshPlayed = false;
  bool _ufoOutWhooshPlayed = false;

  @override
  void initState() {
    super.initState();

    // Start ambient background music loop
    Music.start();

    // Pre-generate 25 deterministic bubbles
    _generateDeterministicBubbles();

    // 4.5-second master timeline clock
    _timelineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..addListener(_onTimelineUpdate);

    _timelineController.forward();
  }

  void _generateDeterministicBubbles() {
    final rng = Random(9991);
    final types = [
      BubbleType.red,
      BubbleType.blue,
      BubbleType.green,
      BubbleType.yellow,
      BubbleType.purple,
      BubbleType.purple, // Cat bubble
    ];

    for (int i = 0; i < 25; i++) {
      final spawnTime = 1.8 + (i * 1.1 / 25.0);
      final xOffset = (rng.nextDouble() * 2.0 - 1.0) * 30.0;
      final radius = 18.0 + rng.nextDouble() * 4.0;
      final type = types[i % types.length];

      _bubbles.add(
        _SplashBubble(
          id: i,
          type: type,
          spawnTime: spawnTime,
          spawnXOffset: xOffset,
          radius: radius,
        ),
      );
    }
  }

  void _onTimelineUpdate() {
    final t = _timelineController.value * 4.5;

    // Trigger Timeline Sound Effects
    if (t >= 0.4 && !_rumblePlayed) {
      _rumblePlayed = true;
      Sfx.play(SfxName.thud);
    }
    if (t >= 1.2 && !_ufoInWhooshPlayed) {
      _ufoInWhooshPlayed = true;
      Sfx.play(SfxName.whoosh);
    }
    if (t >= 3.2 && !_ufoOutWhooshPlayed) {
      _ufoOutWhooshPlayed = true;
      Sfx.play(SfxName.whoosh);
      Sfx.play(SfxName.boom);
    }

    // Auto navigate when timeline completes
    if (_timelineController.isCompleted && !_navigated) {
      _navigateToMenu(Offset.zero);
    }
  }

  void _navigateToMenu(Offset origin) {
    if (_navigated) return;
    _navigated = true;

    AppNav.go(
      context,
      const MenuScreen(),
      style: NavTransition.iris,
      origin: origin == Offset.zero ? null : origin,
      replace: true,
    );
  }

  void _handleTap(TapDownDetails details) {
    AppHaptics.light();
    Sfx.play(SfxName.pop);
    _navigateToMenu(details.globalPosition);
  }

  @override
  void dispose() {
    _timelineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceDark,
      body: GestureDetector(
        onTapDown: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _timelineController,
          builder: (context, _) {
            final t = _timelineController.value * 4.5;
            return RepaintBoundary(
              child: CustomPaint(
                painter: _SplashCinematicPainter(t: t, bubbles: _bubbles),
                child: const SizedBox.expand(),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Single CustomPainter executing master timeline rendering & deterministic physics.
class _SplashCinematicPainter extends CustomPainter {
  final double t; // Master timeline seconds (0.0 .. 4.5)
  final List<_SplashBubble> bubbles;

  _SplashCinematicPainter({required this.t, required this.bubbles});

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle Camera Zoom Scale (1.0 -> 1.05) over 4.5s
    final cameraScale = 1.0 + (t / 4.5) * 0.05;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(cameraScale);
    canvas.translate(-size.width / 2, -size.height / 2);

    // 0.0s..0.4s: Fade in Space Background
    final bgAlpha = (t / 0.4).clamp(0.0, 1.0);
    if (bgAlpha < 0.99) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Color.fromRGBO(0, 0, 0, bgAlpha),
      );
    }

    // 1. Starfield Background
    SpacePainter.nebula(canvas, size, t: t);
    SpacePainter.starfield(canvas, size, t: t);
    SpacePainter.planet(
      canvas,
      Offset(size.width * 0.16, size.height * 0.2),
      size.width * 0.13,
      PlanetKind.purpleMoon,
      t: t,
    );
    SpacePainter.shootingStar(canvas, size, t: t);

    // 2. 0.4s..1.8s: Rising Lava Planet Surface
    final riseProgress = (t < 0.4)
        ? 0.0
        : ((t - 0.4) / 1.4).clamp(0.0, 1.0); // easeOutCubic
    final cubicRise = 1.0 - pow(1.0 - riseProgress, 3).toDouble();
    final lavaHeightFactor = 0.24 * cubicRise;

    if (lavaHeightFactor > 0.0) {
      SpacePainter.lavaSurface(
        canvas,
        size,
        t: t,
        heightFactor: lavaHeightFactor,
      );
    }

    // 3. UFO Bezier Movement & Beam
    _drawUfo(canvas, size);

    // 4. Deterministic Physics Simulation & Bubble Pile Rendering
    _stepAndDrawBubbles(canvas, size);

    // 5. 3.2s: Shockwave Ring & Sparkle Burst
    if (t >= 3.2) {
      _drawShockwave(canvas, size);
    }

    // 6. 3.4s: "COSMO POP" Title & Mimo Peeking
    if (t >= 3.4) {
      _drawTitleAndMimo(canvas, size);
    }

    // 7. 4.0s: Loading Progress Bar
    if (t >= 4.0) {
      _drawLoadingBar(canvas, size);
    }

    if (bgAlpha < 0.99) {
      canvas.restore();
    }
    canvas.restore();
  }

  void _drawUfo(Canvas canvas, Size size) {
    Offset ufoPos;
    double beamLength = 0.0;

    if (t < 1.2) {
      // Offscreen
      return;
    } else if (t >= 1.2 && t < 1.8) {
      // Fly in Bezier
      final prog = (t - 1.2) / 0.6;
      final start = Offset(size.width + 80, -60);
      final control = Offset(size.width * 0.8, size.height * 0.1);
      final end = Offset(size.width * 0.5, size.height * 0.22);

      final p0 = Offset.lerp(start, control, prog)!;
      final p1 = Offset.lerp(control, end, prog)!;
      ufoPos = Offset.lerp(p0, p1, prog)!;
      beamLength = prog * 0.85;
    } else if (t >= 1.8 && t < 3.2) {
      // Hovering
      ufoPos = Offset(size.width * 0.5, size.height * 0.22);
      beamLength = 0.85;
    } else {
      // 3.2s+: Fly away
      final prog = ((t - 3.2) / 0.6).clamp(0.0, 1.0);
      final start = Offset(size.width * 0.5, size.height * 0.22);
      final end = Offset(-100, size.height * 0.15);
      ufoPos = Offset.lerp(start, end, prog)!;
      beamLength = (1.0 - prog) * 0.85;
    }

    UfoPainter.draw(canvas, ufoPos, 70.0, t: t, beamLength: beamLength);
  }

  void _stepAndDrawBubbles(Canvas canvas, Size size) {
    if (t < 1.8) return;

    final topY = size.height * (1.0 - 0.24);
    final ufoX = size.width * 0.5;
    final ufoY = size.height * 0.22 + 20;

    // Sub-step deterministic physics integration
    const dt = 1 / 60.0;
    final totalSteps = ((min(t, 4.5) - 1.8) / dt).floor();

    // Reset bubble positions for step-by-step integration
    for (final b in bubbles) {
      b.landed = false;
      b.x = ufoX + b.spawnXOffset;
      b.y = ufoY;
      b.vx = b.spawnXOffset * 0.5;
      b.vy = 120.0;
      b.squashX = 1.0;
      b.squashY = 1.0;
    }

    for (int step = 0; step < totalSteps; step++) {
      final simTime = 1.8 + step * dt;

      for (int i = 0; i < bubbles.length; i++) {
        final b = bubbles[i];
        if (simTime < b.spawnTime) continue;

        // Apply gravity
        b.vy += 550.0 * dt;
        b.x += b.vx * dt;
        b.y += b.vy * dt;

        // Collision with curved terrain
        final relX = (b.x / size.width).clamp(0.0, 1.0);
        final terrainY = topY + sin(relX * pi * 2) * 8.0 + 15.0;

        if (b.y + b.radius >= terrainY) {
          b.y = terrainY - b.radius;
          b.vy = -b.vy * 0.3; // bounce damping
          b.vx *= 0.75; // friction
          b.squashX = 1.2;
          b.squashY = 0.8;
          b.landed = true;

          // Roll toward center crater curve
          b.vx += (size.width * 0.5 - b.x) * 0.5 * dt;
        }

        // Recover squash
        b.squashX += (1.0 - b.squashX) * 8.0 * dt;
        b.squashY += (1.0 - b.squashY) * 8.0 * dt;

        // Circle-circle collisions
        for (int j = i + 1; j < bubbles.length; j++) {
          final b2 = bubbles[j];
          if (simTime < b2.spawnTime) continue;

          final dx = b2.x - b.x;
          final dy = b2.y - b.y;
          final dist = sqrt(dx * dx + dy * dy);
          final minDist = b.radius + b2.radius;

          if (dist < minDist && dist > 0.001) {
            final overlap = (minDist - dist) * 0.5;
            final nx = dx / dist;
            final ny = dy / dist;

            b.x -= nx * overlap;
            b.y -= ny * overlap;
            b2.x += nx * overlap;
            b2.y += ny * overlap;
          }
        }
      }
    }

    // 3.2s Shockwave pulse on pile
    double pulseGlow = 0.0;
    if (t >= 3.2 && t <= 3.6) {
      final pulseT = (t - 3.2) / 0.4;
      pulseGlow = sin(pulseT * pi);
    }

    // Render active bubbles
    for (final b in bubbles) {
      if (t < b.spawnTime) continue;

      // Gentle idle wobble after landing
      final idleWobble = b.landed ? sin(t * 3.0 + b.id) * 0.04 : 0.0;

      BubblePainter.draw(
        canvas,
        Offset(b.x, b.y),
        b.radius,
        b.type,
        t: t,
        squashX: b.squashX + idleWobble,
        squashY: b.squashY - idleWobble,
        glow: pulseGlow,
      );
    }
  }

  void _drawShockwave(Canvas canvas, Size size) {
    final prog = ((t - 3.2) / 0.5).clamp(0.0, 1.0);
    final center = Offset(size.width * 0.5, size.height * 0.76);
    final radius = prog * 180.0;

    final shockPaint = Paint()
      ..color = AppColors.starYellow.withValues(alpha: (1.0 - prog) * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (1.0 - prog) * 6.0;

    canvas.drawCircle(center, radius, shockPaint);
  }

  void _drawTitleAndMimo(Canvas canvas, Size size) {
    final titleProgress = ((t - 3.4) / 0.6).clamp(0.0, 1.0);
    final titleCenter = Offset(size.width * 0.5, size.height * 0.38);

    // Mimo Peeking behind Title
    final mimoPeekY = titleCenter.dy - 35.0 + (1.0 - titleProgress) * 30.0;
    MimoPainter.draw(
      canvas,
      Offset(size.width * 0.5, mimoPeekY),
      65,
      state: MimoState.wave,
      t: t,
    );

    // Letter-by-letter Drop Intro
    const text = "COSMO POP";
    final anims = <LetterAnim>[];

    for (int i = 0; i < text.length; i++) {
      final delay = i * 0.04;
      final letterT = ((titleProgress - delay) / 0.4).clamp(0.0, 1.0);
      final bounce = sin(letterT * pi);

      anims.add(
        LetterAnim(
          offsetY: (1.0 - letterT) * -50.0,
          scale: 0.5 + 0.5 * bounce,
          opacity: letterT,
        ),
      );
    }

    final shine = (t >= 3.8) ? ((t - 3.8) / 0.5).clamp(0.0, 1.0) : -1.0;

    Title3D.drawLetters(
      canvas,
      text,
      titleCenter,
      fontSize: 42,
      anims: anims,
      shine: shine,
      sweep: true,
    );

    // Subtitle "MEOW GALAXY"
    if (t >= 3.7) {
      final subProg = ((t - 3.7) / 0.3).clamp(0.0, 1.0);
      final subScale = 0.5 + 0.5 * sin(subProg * pi / 2);

      canvas.save();
      canvas.translate(titleCenter.dx, titleCenter.dy + 42.0);
      canvas.scale(subScale);

      _drawOutlinedCentered(canvas, 'MEOW GALAXY', 18, AppColors.accent);

      canvas.restore();
    }
  }

  /// Draws outlined text centered on the current origin. (The old call to
  /// `outlinedText` returned a widget and never painted anything.)
  void _drawOutlinedCentered(
    Canvas canvas,
    String text,
    double fontSize,
    Color fill,
  ) {
    TextPainter make(TextStyle style) => TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final stroke = make(
      TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFF2B1160),
      ),
    );
    final face = make(
      TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
        color: fill,
      ),
    );
    final offset = Offset(-face.width / 2, -face.height / 2);
    stroke.paint(canvas, offset);
    face.paint(canvas, offset);
  }

  void _drawLoadingBar(Canvas canvas, Size size) {
    final barProg = ((t - 4.0) / 0.5).clamp(0.0, 1.0);
    final barRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.58),
      width: 200,
      height: 24,
    );

    // Track
    JellyPainter.button(canvas, barRect, color: JellyColor.purple);

    // Fill
    final fillRect = Rect.fromLTWH(
      barRect.left + 2,
      barRect.top + 2,
      (barRect.width - 4) * barProg,
      barRect.height - 4,
    );

    if (fillRect.width > 4) {
      JellyPainter.button(
        canvas,
        fillRect,
        color: JellyColor.green,
        borderRadius: 10,
      );
    }

    // Sparkle at fill tip
    if (barProg > 0.05 && barProg < 0.98) {
      final tipX = fillRect.right;
      final sparkPaint = Paint()..color = AppColors.starYellow;
      canvas.drawCircle(Offset(tipX, barRect.center.dy), 4.0, sparkPaint);
    }

    // Text Label below
    TextPainter(
        text: const TextSpan(
          text: "Preparing galaxy...",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )
      ..layout()
      ..paint(canvas, Offset(size.width * 0.5 - 50, barRect.bottom + 6));
  }

  @override
  bool shouldRepaint(covariant _SplashCinematicPainter old) {
    return old.t != t;
  }
}
