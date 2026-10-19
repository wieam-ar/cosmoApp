import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../art/space_painter.dart';
import '../art/ufo_painter.dart';

enum SpaceBgVariant { menu, map, settings, game }

/// Animated cosmic backdrop. All drawing is delegated to [SpacePainter] and
/// [UfoPainter], so the menu, map, splash and garden share one sky.
class SpaceBackground extends StatefulWidget {
  final SpaceBgVariant variant;
  final bool showUfos;
  final bool showLava;
  final ValueListenable<double>? scrollOffset;
  final Widget? child;

  const SpaceBackground({
    super.key,
    this.variant = SpaceBgVariant.menu,
    this.showUfos = true,
    this.showLava = true,
    this.scrollOffset,
    this.child,
  });

  @override
  State<SpaceBackground> createState() => _SpaceBackgroundState();
}

class _SpaceBackgroundState extends State<SpaceBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _anim,
                if (widget.scrollOffset != null) widget.scrollOffset!,
              ]),
              builder: (_, _) => CustomPaint(
                painter: _BackgroundPainter(
                  variant: widget.variant,
                  showUfos: widget.showUfos,
                  showLava: widget.showLava,
                  t: _anim.value * 60,
                  scrollY: widget.scrollOffset?.value ?? 0,
                ),
              ),
            ),
          ),
        ),
        if (widget.child != null) Positioned.fill(child: widget.child!),
      ],
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final SpaceBgVariant variant;
  final bool showUfos, showLava;
  final double t, scrollY;

  const _BackgroundPainter({
    required this.variant,
    required this.showUfos,
    required this.showLava,
    required this.t,
    required this.scrollY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    SpacePainter.nebula(canvas, size, t: t);
    SpacePainter.starfield(canvas, size, t: t, parallaxY: -scrollY * 0.001);

    SpacePainter.planet(
      canvas,
      Offset(size.width * 0.85 + sin(t * 0.2) * 8, 120 - scrollY * 0.15),
      38,
      PlanetKind.gasGiant,
      t: t,
    );
    SpacePainter.planet(
      canvas,
      Offset(
        size.width * 0.16 + cos(t * 0.15) * 10,
        size.height * 0.45 - scrollY * 0.25,
      ),
      26,
      PlanetKind.purpleMoon,
      t: t,
    );

    SpacePainter.shootingStar(canvas, size, t: t);

    if (showUfos && variant != SpaceBgVariant.settings) {
      UfoPainter.draw(
        canvas,
        Offset(
          size.width * 0.3 + sin(t * 0.8) * size.width * 0.22,
          170 + cos(t * 0.6) * 14 - scrollY * 0.1,
        ),
        64,
        t: t,
        beamLength: (sin(t * 2) + 1) / 2 * 0.6,
        beamColor: const Color(0x6684FFD0),
      );
      if (variant == SpaceBgVariant.menu) {
        UfoPainter.draw(
          canvas,
          Offset(
            size.width * 0.72 + cos(t * 0.7) * size.width * 0.18,
            size.height * 0.58 + sin(t * 0.5) * 18,
          ),
          52,
          t: t + 2,
          beamLength: (cos(t * 1.8) + 1) / 2 * 0.5,
          beamColor: const Color(0x66FD79A8),
        );
      }
    }

    if (showLava && variant != SpaceBgVariant.map) {
      SpacePainter.lavaSurface(
        canvas,
        size,
        t: t,
        heightFactor: switch (variant) {
          SpaceBgVariant.menu => 0.22,
          SpaceBgVariant.settings => 0.12,
          _ => 0.10,
        },
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) =>
      old.t != t ||
      old.scrollY != scrollY ||
      old.variant != variant ||
      old.showUfos != showUfos ||
      old.showLava != showLava;
}
