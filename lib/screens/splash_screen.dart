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

// Also exports kLogoAsset / kCatAsset (defined in menu_screen.dart).
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

  // Set to true only if the PNG fails to load -> painter draws the old art.
  bool _logoFailed = false;
  bool _catFailed = false;
  bool _precached = false;

  @override
  void initState() {
    super.initState();

    Music.start();
    _generateDeterministicBubbles();

    _timelineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..addListener(_onTimelineUpdate);

    _timelineController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    precacheImage(const AssetImage(kLogoAsset), context).catchError((_) {
      if (mounted) setState(() => _logoFailed = true);
    });
    precacheImage(const AssetImage(kCatAsset), context).catchError((_) {
      if (mounted) setState(() => _catFailed = true);
    });
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

  // ---- logo + cat overlay (images) ---------------------------------------

  Widget _imageOverlay(BuildContext context, double t) {
    if (t < 3.4) return const SizedBox.shrink();

    final p = ((t - 3.4) / 0.6).clamp(0.0, 1.0);
    final ease = Curves.easeOutBack.transform(p);
    final w = MediaQuery.of(context).size.width;
    final logoW = min(w * 0.86, 360.0);
    final catD = min(w * 0.42, 170.0);

    Widget logo = const SizedBox.shrink();
    if (!_logoFailed) {
      logo = Align(
        alignment: const Alignment(0, -0.2),
        child: Opacity(
          opacity: p,
          child: Transform.translate(
            offset: Offset(0, (1.0 - ease) * -40.0),
            child: Transform.scale(
              scale: 0.7 + 0.3 * ease,
              child: SizedBox(
                width: logoW,
                child: Image.asset(
                  kLogoAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget cat = const SizedBox.shrink();
    if (!_catFailed) {
      cat = Align(
        alignment: const Alignment(0, -0.64),
        child: Opacity(
          opacity: p,
          child: Transform.translate(
            offset: Offset(0, (1.0 - ease) * 30.0 + sin(t * 3.0) * 4.0),
            child: Transform.scale(
              scale: 0.6 + 0.4 * ease,
              child: SizedBox.square(
                dimension: catD,
                child: Image.asset(
                  kCatAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Cat first (behind), logo on top.
    return IgnorePointer(child: Stack(children: [cat, logo]));
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
            return Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _SplashCinematicPainter(
                      t: t,
                      bubbles: _bubbles,
                      legacyTitle: _logoFailed,
                      legacyMimo: _catFailed,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                _imageOverlay(context, t),
              ],
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
  final bool legacyTitle; // draw old painted title if logo PNG is missing
  final bool legacyMimo; // draw old painted Mimo if cat PNG is missing

  _SplashCinematicPainter({
    required this.t,
    required this.bubbles,
    this.legacyTitle = false,
    this.legacyMimo = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cameraScale = 1.0 + (t / 4.5) * 0.05;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(cameraScale);
    canvas.translate(-size.width / 2, -size.height / 2);

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
    final riseProgress = (t < 0.4) ? 0.0 : ((t - 0.4) / 1.4).clamp(0.0, 1.0);
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

    // 3. UFO
    _drawUfo(canvas, size);

    // 4. Physics + bubbles
    _stepAndDrawBubbles(canvas, size);

    // 5. Shockwave
    if (t >= 3.2) {
      _drawShockwave(canvas, size);
    }

    // 6. Legacy title / Mimo (only if the PNGs are missing)
    if (t >= 3.4 && (legacyTitle || legacyMimo)) {
      _drawTitleAndMimo(canvas, size);
    }

    // 7. Loading bar
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
      return;
    } else if (t >= 1.2 && t < 1.8) {
      final prog = (t - 1.2) / 0.6;
      final start = Offset(size.width + 80, -60);
      final control = Offset(size.width * 0.8, size.height * 0.1);
      final end = Offset(size.width * 0.5, size.height * 0.22);

      final p0 = Offset.lerp(start, control, prog)!;
      final p1 = Offset.lerp(control, end, prog)!;
      ufoPos = Offset.lerp(p0, p1, prog)!;
      beamLength = prog * 0.85;
    } else if (t >= 1.8 && t < 3.2) {
      ufoPos = Offset(size.width * 0.5, size.height * 0.22);
      beamLength = 0.85;
    } else {
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

    const dt = 1 / 60.0;
    final totalSteps = ((min(t, 4.5) - 1.8) / dt).floor();

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

        b.vy += 550.0 * dt;
        b.x += b.vx * dt;
        b.y += b.vy * dt;

        final relX = (b.x / size.width).clamp(0.0, 1.0);
        final terrainY = topY + sin(relX * pi * 2) * 8.0 + 15.0;

        if (b.y + b.radius >= terrainY) {
          b.y = terrainY - b.radius;
          b.vy = -b.vy * 0.3;
          b.vx *= 0.75;
          b.squashX = 1.2;
          b.squashY = 0.8;
          b.landed = true;

          b.vx += (size.width * 0.5 - b.x) * 0.5 * dt;
        }

        b.squashX += (1.0 - b.squashX) * 8.0 * dt;
        b.squashY += (1.0 - b.squashY) * 8.0 * dt;

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

    double pulseGlow = 0.0;
    if (t >= 3.2 && t <= 3.6) {
      final pulseT = (t - 3.2) / 0.4;
      pulseGlow = sin(pulseT * pi);
    }

    for (final b in bubbles) {
      if (t < b.spawnTime) continue;

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

  /// Fallback art, used only when logo/cat PNGs fail to load.
  void _drawTitleAndMimo(Canvas canvas, Size size) {
    final titleProgress = ((t - 3.4) / 0.6).clamp(0.0, 1.0);
    final titleCenter = Offset(size.width * 0.5, size.height * 0.38);

    if (legacyMimo) {
      final mimoPeekY = titleCenter.dy - 35.0 + (1.0 - titleProgress) * 30.0;
      MimoPainter.draw(
        canvas,
        Offset(size.width * 0.5, mimoPeekY),
        65,
        state: MimoState.wave,
        t: t,
      );
    }

    if (!legacyTitle) return;

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

    JellyPainter.button(canvas, barRect, color: JellyColor.purple);

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

    if (barProg > 0.05 && barProg < 0.98) {
      final tipX = fillRect.right;
      final sparkPaint = Paint()..color = AppColors.starYellow;
      canvas.drawCircle(Offset(tipX, barRect.center.dy), 4.0, sparkPaint);
    }

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
    return old.t != t ||
        old.legacyTitle != legacyTitle ||
        old.legacyMimo != legacyMimo;
  }
}