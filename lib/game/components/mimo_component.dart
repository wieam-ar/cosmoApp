import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import '../../art/mimo_painter.dart';
import '../../core/constants.dart';
import '../../core/save_service.dart';

class MimoComponent extends PositionComponent {
  static const String _assetPath = 'assets/images/menu/mimo_saucer.png';
  static final ui.Paint _shadow = ui.Paint()
    ..color = const ui.Color(0x38000000)
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7);
  static final ui.Paint _imagePaint = ui.Paint()
    ..filterQuality = ui.FilterQuality.medium;

  MimoState state = MimoState.idle;
  double time = 0;
  double aimAngle = 0;
  ui.Image? _mimoImage;

  MimoComponent({required Vector2 position, double size = 170})
    : super(
        position: position,
        size: Vector2.all(size),
        anchor: Anchor.center,
        priority: 8,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final data = await rootBundle.load(_assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    try {
      _mimoImage = (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  @override
  void onRemove() {
    _mimoImage?.dispose();
    _mimoImage = null;
    super.onRemove();
  }

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

    final skin = switch (SaveService.I.selectedSkin) {
      'spaceMimo' => SkinId.spaceMimo,
      'neonMimo' => SkinId.neonMimo,
      'goldenMimo' => SkinId.goldenMimo,
      _ => SkinId.defaultMimo,
    };
    final image = _mimoImage;
    if (image != null && skin == SkinId.defaultMimo) {
      final isHappy = state == MimoState.happy || state == MimoState.cheer;
      final jump = isHappy ? -sin(time * 8).abs() * 5 : 0.0;
      final shakeX = state == MimoState.nervous ? sin(time * 30) * 1.5 : 0.0;
      final tilt = state == MimoState.aim ? sin(aimAngle) * 0.04 : 0.0;
      final scale = 1 + sin(time * 3) * 0.012;

      canvas.save();
      canvas.translate(size.x / 2 + shakeX, size.y / 2 - lift * 3 + jump);
      canvas.rotate(tilt);
      canvas.scale(scale);
      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        ui.Rect.fromCenter(
          center: ui.Offset.zero,
          width: size.x,
          height: size.y,
        ),
        _imagePaint,
      );
      canvas.restore();
    } else {
      MimoPainter.draw(
        canvas,
        ui.Offset(size.x / 2, size.y / 2 - lift * 3),
        size.x,
        state: state,
        skin: skin,
        t: time,
        aimAngle: aimAngle,
      );
    }
  }
}
