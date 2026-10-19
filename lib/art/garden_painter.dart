import 'dart:math';

import 'package:flutter/material.dart';

import '../config/garden_config.dart';
import '../core/constants.dart';
import 'mimo_painter.dart';
import 'space_painter.dart';

class GardenPainter extends CustomPainter {
  final Map<int, GardenPlant> plants;
  final Map<int, String> decorations;
  final double time;
  final SkinId mimoSkin;

  const GardenPainter({
    required this.plants,
    required this.decorations,
    required this.time,
    required this.mimoSkin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final groundY = size.height * 0.76;

    // Same sky as the menu and splash, so the garden feels like the same galaxy.
    SpacePainter.nebula(canvas, size, t: time);
    SpacePainter.starfield(canvas, size, t: time);
    SpacePainter.planet(
      canvas,
      Offset(size.width * 0.8, size.height * 0.26),
      size.height * 0.11,
      PlanetKind.gasGiant,
      t: time,
    );

    final hill = Path()
      ..moveTo(0, groundY + size.height * 0.03)
      ..quadraticBezierTo(
        size.width * 0.48,
        groundY - size.height * 0.16,
        size.width,
        groundY + size.height * 0.01,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      hill,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF408B80), Color(0xFF15525F), Color(0xFF15284D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds),
    );

    for (var slot = 0; slot < GardenCatalog.plotCount; slot++) {
      final col = slot % 2;
      final row = slot ~/ 2;
      final center = Offset(
        size.width * (col == 0 ? 0.39 : 0.68),
        groundY + size.height * (row == 0 ? 0.045 : 0.13),
      );
      _drawPlot(canvas, center, size.width * 0.095);
      final plant = plants[slot];
      if (plant == null) {
        _drawSeedMound(canvas, center, size.width * 0.095);
      } else {
        final seed = GardenCatalog.seed(plant.seedId);
        if (seed != null) {
          _drawPlant(
            canvas,
            center.translate(0, -size.height * 0.025),
            size.width * 0.12,
            plant.stage,
            seed.color,
            time,
          );
        }
      }
    }

    for (final entry in decorations.entries) {
      final x = switch (entry.key) {
        0 => size.width * 0.13,
        1 => size.width * 0.52,
        _ => size.width * 0.91,
      };
      _drawDecoration(
        canvas,
        entry.value,
        Offset(x, groundY + size.height * 0.005),
        size.width * 0.075,
        time,
      );
    }

    MimoPainter.draw(
      canvas,
      Offset(size.width * 0.14, size.height * 0.57),
      min(size.width * 0.25, size.height * 0.42),
      state: MimoState.happy,
      skin: mimoSkin,
      t: time,
    );
  }

  void _drawPlot(Canvas canvas, Offset center, double width) {
    final rect = Rect.fromCenter(
      center: center,
      width: width * 2,
      height: width * 0.54,
    );
    canvas.drawOval(rect, Paint()..color = const Color(0xFF51366B));
    canvas.drawOval(
      rect.deflate(width * 0.1),
      Paint()..color = const Color(0xFF241A43),
    );
    canvas.drawArc(
      rect.deflate(width * 0.08),
      pi,
      pi,
      false,
      Paint()
        ..color = const Color(0xFFB693E5).withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  void _drawSeedMound(Canvas canvas, Offset center, double width) {
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, -width * 0.13),
        width: width * 0.18,
        height: width * 0.12,
      ),
      Paint()..color = const Color(0xFFFFD76A),
    );
  }

  void _drawPlant(
    Canvas canvas,
    Offset ground,
    double maxHeight,
    GardenGrowthStage stage,
    Color color,
    double time,
  ) {
    final growth = stage.index / GardenCatalog.growthWins;
    final height = maxHeight * (0.22 + growth * 0.78);
    final sway = sin(time * 1.5 + ground.dx * 0.05) * maxHeight * 0.035;
    final top = ground.translate(sway, -height);
    final stemPaint = Paint()
      ..color = const Color(0xFF8CE29A)
      ..strokeWidth = max(1.5, maxHeight * 0.065)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(ground, top, stemPaint);

    if (stage.index >= GardenGrowthStage.young.index) {
      for (final direction in [-1, 1]) {
        final leaf = Path()
          ..moveTo(ground.dx + sway * 0.6, ground.dy - height * 0.45)
          ..quadraticBezierTo(
            ground.dx + direction * maxHeight * 0.48,
            ground.dy - height * 0.62,
            ground.dx + direction * maxHeight * 0.46,
            ground.dy - height * 0.33,
          )
          ..quadraticBezierTo(
            ground.dx + direction * maxHeight * 0.19,
            ground.dy - height * 0.28,
            ground.dx + sway * 0.6,
            ground.dy - height * 0.45,
          );
        canvas.drawPath(leaf, Paint()..color = const Color(0xFF61C985));
      }
    }

    if (stage.index == GardenGrowthStage.seed.index) {
      canvas.drawCircle(
        ground.translate(0, -height),
        maxHeight * 0.11,
        Paint()..color = color,
      );
    } else if (stage.index == GardenGrowthStage.sprout.index) {
      canvas.drawOval(
        Rect.fromCenter(
          center: top,
          width: maxHeight * 0.32,
          height: maxHeight * 0.19,
        ),
        Paint()..color = color,
      );
    } else {
      final petals = stage == GardenGrowthStage.mature ? 8 : 6;
      final petalRadius =
          maxHeight * (stage == GardenGrowthStage.mature ? 0.13 : 0.105);
      for (var petal = 0; petal < petals; petal++) {
        final angle = petal * 2 * pi / petals;
        final point = top.translate(
          cos(angle) * petalRadius * 0.9,
          sin(angle) * petalRadius * 0.9,
        );
        canvas.drawCircle(point, petalRadius, Paint()..color = color);
      }
      canvas.drawCircle(
        top,
        petalRadius * 0.56,
        Paint()..color = const Color(0xFFFFE58A),
      );
      if (stage == GardenGrowthStage.mature) {
        canvas.drawCircle(
          top.translate(0, -petalRadius * 2),
          2,
          Paint()
            ..color = Colors.white.withValues(
              alpha: 0.65 + (sin(time * 3 + ground.dx) + 1) * 0.15,
            ),
        );
      }
    }
  }

  void _drawDecoration(
    Canvas canvas,
    String id,
    Offset base,
    double size,
    double time,
  ) {
    final definition = GardenCatalog.decoration(id);
    if (definition == null) return;
    if (id.contains('lantern')) {
      canvas.drawLine(
        base,
        base.translate(0, -size * 1.1),
        Paint()
          ..color = const Color(0xFFDCBF94)
          ..strokeWidth = 2,
      );
      final light = base.translate(0, -size * 1.25);
      canvas.drawCircle(
        light,
        size * 0.42 + sin(time * 2) * size * 0.04,
        Paint()
          ..color = definition.color.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(light, size * 0.24, Paint()..color = definition.color);
    } else if (id == 'comet_fountain') {
      canvas.drawArc(
        Rect.fromCenter(
          center: base.translate(0, -size * 0.12),
          width: size * 1.35,
          height: size * 0.62,
        ),
        pi,
        pi,
        false,
        Paint()
          ..color = definition.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      canvas.drawCircle(
        base.translate(0, -size * (0.55 + sin(time * 2) * 0.05)),
        size * 0.08,
        Paint()..color = Colors.white,
      );
    } else {
      final arch = Path()
        ..moveTo(base.dx - size * 0.45, base.dy)
        ..lineTo(base.dx - size * 0.45, base.dy - size * 0.65)
        ..quadraticBezierTo(
          base.dx,
          base.dy - size * 1.5,
          base.dx + size * 0.45,
          base.dy - size * 0.65,
        )
        ..lineTo(base.dx + size * 0.45, base.dy);
      canvas.drawPath(
        arch,
        Paint()
          ..color = definition.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(2, size * 0.1)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GardenPainter oldDelegate) =>
      oldDelegate.plants != plants ||
      oldDelegate.decorations != decorations ||
      oldDelegate.time != time ||
      oldDelegate.mimoSkin != mimoSkin;
}
