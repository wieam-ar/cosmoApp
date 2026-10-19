import 'dart:math';

import 'package:flutter/material.dart';

import '../core/ui_theme.dart';

class StarRating extends StatefulWidget {
  final int stars; // 0..3
  final bool animated;
  final double size;

  const StarRating({
    super.key,
    required this.stars,
    this.animated = false,
    this.size = 36,
  });

  static Widget staticRating(int stars, {double size = 24}) =>
      StarRating(stars: stars, size: size);

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> with TickerProviderStateMixin {
  late final List<AnimationController> _c = List.generate(
    3,
    (_) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    ),
  );

  @override
  void initState() {
    super.initState();
    _play();
  }

  @override
  void didUpdateWidget(covariant StarRating old) {
    super.didUpdateWidget(old);
    if (old.stars != widget.stars || old.animated != widget.animated) _play();
  }

  void _play() {
    for (var i = 0; i < 3; i++) {
      _c[i].stop();
      if (!widget.animated) {
        _c[i].value = 1;
        continue;
      }
      _c[i].value = 0;
      if (i < widget.stars) {
        Future.delayed(Duration(milliseconds: 280 * i), () {
          if (mounted) _c[i].forward();
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in _c) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final filled = i < widget.stars;
        final s = i == 1 ? widget.size * 1.3 : widget.size;
        return AnimatedBuilder(
          animation: _c[i],
          builder: (_, _) {
            final t = Curves.elasticOut.transform(_c[i].value);
            final scale = widget.animated ? (filled ? t : 1.0) : 1.0;
            return Transform.rotate(
              angle: (i - 1) * 0.12,
              child: Transform.scale(
                scale: scale,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: SizedBox(
                    width: s,
                    height: s,
                    child: CustomPaint(painter: _StarPainter(filled)),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

Path _starPath(Size size, {double inner = 0.5}) {
  final c = size.center(Offset.zero);
  final r = size.width / 2;
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final rad = i.isEven ? r : r * inner;
    final a = -pi / 2 + i * pi / 5;
    final pt = c + Offset(cos(a) * rad, sin(a) * rad);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

class _StarPainter extends CustomPainter {
  final bool filled;
  _StarPainter(this.filled);

  @override
  void paint(Canvas canvas, Size size) {
    final path = _starPath(size * 0.9)
        .shift(Offset(size.width * 0.05, size.height * 0.05));
    final rect = Offset.zero & size;

    if (filled) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Ui.gold.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    // 3D edge
    canvas.drawPath(
      path.shift(const Offset(0, 2.5)),
      Paint()..color = filled ? const Color(0xFFB45F06) : Colors.black38,
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: filled
              ? const [Color(0xFFFFF3A0), Color(0xFFFFC107), Color(0xFFFF9800)]
              : const [Color(0x44FFFFFF), Color(0x22FFFFFF)],
        ).createShader(rect),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round
        ..color = filled ? const Color(0xFF7A3E00) : Colors.white24,
    );
    if (filled) {
      canvas.drawCircle(
        Offset(size.width * 0.38, size.height * 0.34),
        size.width * 0.07,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.filled != filled;
}
