import 'dart:math';

import 'package:flutter/material.dart';

import '../art/title3d.dart';
import '../core/constants.dart';

/// Animated "COSMO POP / MEOW GALAXY" logo.
///
/// Drawn with [Title3D] (the same painter the splash screen uses), so the
/// menu and the splash can never drift apart, and the whole title is a single
/// CustomPaint instead of ~100 stacked Text widgets rebuilt every frame.
class GameTitle extends StatefulWidget {
  final bool animateIntro;
  final String title;
  final String subtitle;

  const GameTitle({
    super.key,
    this.animateIntro = false,
    this.title = 'COSMO POP',
    this.subtitle = 'MEOW GALAXY',
  });

  @override
  State<GameTitle> createState() => _GameTitleState();
}

class _GameTitleState extends State<GameTitle> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    widget.animateIntro ? _intro.forward() : _intro.value = 1;
  }

  @override
  void dispose() {
    _loop.dispose();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_loop, _intro]),
        builder: (_, _) {
          final p = _loop.value;
          final floatY = sin(p * 2 * pi) * 6;
          final shine = p > 0.75 ? (p - 0.75) / 0.25 : -1.0; // last 25%
          return Transform.translate(
            offset: Offset(0, floatY),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 320,
                height: 104,
                child: CustomPaint(
                  painter: _TitlePainter(
                    title: widget.title,
                    subtitle: widget.subtitle,
                    intro: _intro.value,
                    shine: shine,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TitlePainter extends CustomPainter {
  final String title;
  final String subtitle;
  final double intro; // 0..1
  final double shine; // -1 = off, 0..1 = sweep position

  const _TitlePainter({
    required this.title,
    required this.subtitle,
    required this.intro,
    required this.shine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final anims = <LetterAnim>[
      for (var i = 0; i < title.length; i++)
        () {
          final t = ((intro * 1.6 - i * 0.08) / 0.5).clamp(0.0, 1.0);
          final drop = Curves.bounceOut.transform(t);
          return LetterAnim(
            offsetY: (1 - drop) * -60,
            scale: 0.6 + 0.4 * t,
            opacity: t,
          );
        }(),
    ];

    Title3D.drawLetters(
      canvas,
      title,
      Offset(size.width / 2, 44),
      fontSize: 46,
      anims: anims,
      shine: shine,
      sweep: true,
    );

    final fade = intro.clamp(0.0, 1.0);
    if (fade < 1.0) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Color.fromRGBO(0, 0, 0, fade),
      );
    }
    _outlined(
      canvas,
      Offset(size.width / 2, 92),
      subtitle,
      16,
      AppColors.accent,
    );
    if (fade < 1.0) canvas.restore();
  }

  void _outlined(
    Canvas canvas,
    Offset center,
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
    final offset = center - Offset(face.width / 2, face.height / 2);
    stroke.paint(canvas, offset);
    face.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _TitlePainter old) =>
      old.intro != intro ||
      old.shine != shine ||
      old.title != title ||
      old.subtitle != subtitle;
}
