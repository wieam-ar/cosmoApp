import 'dart:math';

import 'package:flutter/material.dart';

import '../art/icons_painter.dart';
import '../art/jelly_painter.dart';
import '../art/space_painter.dart';
import '../core/audio_service.dart';
import '../core/constants.dart';
import '../core/save_service.dart';
import '../core/theme.dart';
import '../widgets/jelly_button.dart';
import '../widgets/popup.dart';

class SpinScreen extends StatefulWidget {
  const SpinScreen({super.key});

  @override
  State<SpinScreen> createState() => _SpinScreenState();
}

// FIX 1: 3 controllers => TickerProviderStateMixin
class _SpinScreenState extends State<SpinScreen> with TickerProviderStateMixin {
  static const _prizes = <_SpinPrize>[
    _SpinPrize('50 COINS', Icons.monetization_on_rounded, Color(0xFFFFC857)),
    _SpinPrize('BOMB', Icons.local_fire_department_rounded, Color(0xFF636E72)),
    _SpinPrize('100 COINS', Icons.monetization_on_rounded, Color(0xFFFFD166)),
    _SpinPrize('ROCKET', Icons.rocket_launch_rounded, Color(0xFF70A1FF)),
    _SpinPrize('200 COINS', Icons.monetization_on_rounded, Color(0xFFFFEAA7)),
    _SpinPrize('RAINBOW', Icons.public_rounded, Color(0xFFFD79A8)),
    _SpinPrize('+1 HEART', Icons.favorite_rounded, Color(0xFFFF4757)),
    _SpinPrize('JACKPOT\n1000', Icons.diamond_rounded, Color(0xFFB48DFF)),
  ];

  late final AnimationController _spinController;
  late final AnimationController _confettiController;
  late final AnimationController _bg;
  late Animation<double> _spinAnimation;
  double _rotation = 0;
  int _previousSegment = -1;
  bool _spinning = false;

  @override
  void initState() {
    super.initState();
    // FIX 2: the controller had no duration => forward() crashed in debug
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    _spinController.addListener(_onSpinTick);
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _bg = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
  }

  @override
  void dispose() {
    _spinController
      ..removeListener(_onSpinTick)
      ..dispose();
    _confettiController.dispose();
    _bg.dispose();
    super.dispose();
  }

  void _onSpinTick() {
    if (!_spinning) return;
    _rotation = _spinAnimation.value;
    final segment = ((_normaliseAngle(-_rotation) / (pi / 4)).floor()) % 8;
    if (segment != _previousSegment) {
      _previousSegment = segment;
      Sfx.play(SfxName.tick, pitch: 0.92 + segment * 0.025);
    }
    setState(() {});
  }

  double _normaliseAngle(double value) =>
      (value % (2 * pi) + 2 * pi) % (2 * pi);

  Future<void> _spin({required bool paid}) async {
    if (_spinning) return;
    if (!SaveService.I.claimSpin(paid: paid)) {
      Toast.show(
        context,
        paid
            ? 'Not enough coins or daily spin limit reached'
            : 'Free spin already used today',
      );
      return;
    }
    final prizeIndex = Random().nextInt(_prizes.length);
    final segmentAngle = 2 * pi / _prizes.length;
    final currentAngle = _normaliseAngle(_rotation);
    final targetMod = _normaliseAngle(-(prizeIndex + 0.5) * segmentAngle);
    final delta = _normaliseAngle(targetMod - currentAngle) + 2 * pi * 6;
    final start = _rotation;
    _spinAnimation = Tween<double>(begin: start, end: start + delta).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOutQuart),
    );
    setState(() {
      _spinning = true;
      _previousSegment = -1;
    });
    await _spinController.forward(from: 0);
    if (!mounted) return;
    _rotation = _spinAnimation.value;
    // FIX 3: setState so the buttons re-enable after the spin
    setState(() => _spinning = false);
    _award(prizeIndex);
    _showPrize(prizeIndex);
  }

  void _award(int index) {
    switch (index) {
      case 0:
        SaveService.I.addCoins(50);
        break;
      case 1:
        SaveService.I.addPowerups('bomb', 1);
        break;
      case 2:
        SaveService.I.addCoins(100);
        break;
      case 3:
        SaveService.I.addPowerups('rocket', 1);
        break;
      case 4:
        SaveService.I.addCoins(200);
        break;
      case 5:
        SaveService.I.addPowerups('rainbow', 1);
        break;
      case 6:
        SaveService.I.addHearts(1);
        break;
      case 7:
        SaveService.I.addCoins(1000);
        break;
    }
  }

  Future<void> _showPrize(int index) async {
    Sfx.play(SfxName.win);
    _confettiController.forward(from: 0);
    await Popup.show<void>(
      context,
      title: 'YOU WON!',
      borderColor: AppColors.coinGold,
      child: SizedBox(
        height: 230,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, _) => CustomPaint(
                    painter: _SpinConfettiPainter(_confettiController.value),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.coinGold,
                  size: 38,
                ),
                const SizedBox(height: 5),
                Icon(
                  _prizes[index].icon,
                  color: _prizes[index].color,
                  size: 54,
                ),
                const SizedBox(height: 4),
                Text(
                  _prizes[index].label.replaceAll('\n', ' '),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title(
                    fontSize: 24,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 12),
                JellyButton(
                  text: 'AWESOME!',
                  width: 170,
                  color: JellyColor.green,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // UI: space background like the menu / garden
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bg,
              builder: (_, _) =>
                  CustomPaint(painter: _SpinBgPainter(_bg.value * 8 * pi)),
            ),
          ),
          SafeArea(
            child: ListenableBuilder(
              listenable: SaveService.I,
              builder: (context, _) {
                final free = SaveService.I.hasFreeSpin;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Row(
                        children: [
                          RoundButton(
                            icon: AppIcon.back,
                            color: JellyColor.purple,
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                          const Spacer(),
                          Text(
                            'LUCKY SPIN',
                            style: AppTextStyles.title(
                              fontSize: 25,
                              color: AppColors.accent,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.monetization_on_rounded,
                            color: AppColors.coinGold,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${SaveService.I.coins}',
                            style: AppTextStyles.label(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      free
                          ? 'YOUR DAILY FREE SPIN IS READY'
                          : 'COME BACK TOMORROW',
                      style: AppTextStyles.label(
                        fontSize: 13,
                        color: free
                            ? AppColors.candyGreen
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = min(
                            constraints.maxWidth - 30,
                            constraints.maxHeight - 45,
                          ).clamp(250.0, 410.0);
                          // FitBox: no overflow on small screens
                          return Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: size + 28,
                                height: size + 40,
                                child: Stack(
                                  alignment: Alignment.topCenter,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 18),
                                      child: AnimatedBuilder(
                                        animation: _spinController,
                                        builder: (context, _) => CustomPaint(
                                          size: Size.square(size),
                                          painter: _WheelPainter(
                                            _rotation,
                                            _prizes,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_down_rounded,
                                      size: 48,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        children: [
                          JellyButton(
                            text: _spinning ? 'SPINNING...' : 'FREE SPIN',
                            width: 240,
                            color: JellyColor.green,
                            enabled: free && !_spinning,
                            onPressed: () => _spin(paid: false),
                          ),
                          const SizedBox(height: 10),
                          JellyButton(
                            text: 'EXTRA SPIN · 150 COINS',
                            width: 240,
                            height: 48,
                            fontSize: 15,
                            color: JellyColor.orange,
                            enabled:
                                !_spinning &&
                                SaveService.I.paidSpinsToday < 5 &&
                                SaveService.I.coins >= 150,
                            onPressed: () => _spin(paid: true),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Up to 5 extra spins per day',
                            style: AppTextStyles.body(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SpinBgPainter extends CustomPainter {
  final double t;
  const _SpinBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    SpacePainter.nebula(canvas, size, t: t);
    SpacePainter.starfield(canvas, size, t: t);
  }

  @override
  bool shouldRepaint(covariant _SpinBgPainter old) => old.t != t;
}

class _SpinPrize {
  final String label;
  final IconData icon;
  final Color color;

  const _SpinPrize(this.label, this.icon, this.color);
}

class _WheelPainter extends CustomPainter {
  final double rotation;
  final List<_SpinPrize> prizes;

  const _WheelPainter(this.rotation, this.prizes);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.47;
    final sweep = 2 * pi / prizes.length;
    const colors = [
      Color(0xFF694BD3),
      Color(0xFF285BAD),
      Color(0xFF7A3BAA),
      Color(0xFF1C77A8),
      Color(0xFF7251C8),
      Color(0xFFB3387F),
      Color(0xFFB53550),
      Color(0xFF4C319F),
    ];
    canvas.drawCircle(
      center,
      radius + 12,
      Paint()
        ..color = const Color(0x667CF6FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      center,
      radius + 9,
      Paint()
        ..shader = const SweepGradient(
          colors: [
            Color(0xFFFFE27A),
            Color(0xFFE59B1A),
            Color(0xFFFFF4B8),
            Color(0xFFE59B1A),
            Color(0xFFFFE27A),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius + 9))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation - pi / 2);
    for (var i = 0; i < prizes.length; i++) {
      final start = i * sweep;
      final sector = Path()
        ..moveTo(0, 0)
        ..arcTo(
          Rect.fromCircle(center: Offset.zero, radius: radius),
          start,
          sweep,
          false,
        )
        ..close();
      canvas.drawPath(
        sector,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Color.lerp(colors[i], Colors.black, 0.3)!,
              colors[i],
              Color.lerp(colors[i], Colors.white, 0.28)!,
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
      );
      canvas.drawPath(
        sector,
        Paint()
          ..color = const Color(0xAAFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // FIX: icon + label are rotated with their sector, so they read
      // correctly when the sector is under the pointer.
      final angle = start + sweep / 2;
      canvas.save();
      canvas.rotate(angle + pi / 2);
      // after this rotation: local -y = outward, +y = toward the center
      final labelCenter = Offset(0, -radius * 0.67);
      final iconCenter = Offset(0, -radius * 0.43);

      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(prizes[i].icon.codePoint),
          style: TextStyle(
            fontFamily: prizes[i].icon.fontFamily,
            package: prizes[i].icon.fontPackage,
            color: prizes[i].color,
            fontSize: radius * 0.17,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      iconPainter.paint(
        canvas,
        iconCenter - Offset(iconPainter.width / 2, iconPainter.height / 2),
      );

      final labelPainter = TextPainter(
        text: TextSpan(
          text: prizes[i].label,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.08,
            fontWeight: FontWeight.w900,
            height: 0.95,
            shadows: const [Shadow(color: Colors.black87, blurRadius: 3)],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: radius * 0.5);
      labelPainter.paint(
        canvas,
        labelCenter - Offset(labelPainter.width / 2, labelPainter.height / 2),
      );
      canvas.restore();
    }

    canvas.drawCircle(
      Offset.zero,
      radius * 0.14,
      Paint()
        ..shader =
            const RadialGradient(
              colors: [Color(0xFFFFF4B8), Color(0xFFE59B1A)],
              center: Alignment(-0.3, -0.4),
            ).createShader(
              Rect.fromCircle(center: Offset.zero, radius: radius * 0.14),
            ),
    );
    canvas.drawCircle(
      Offset.zero,
      radius * 0.14,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.restore();
    for (var i = 0; i < 16; i++) {
      final angle = i * 2 * pi / 16;
      final peg = center + Offset(cos(angle), sin(angle)) * (radius + 8);
      canvas.drawCircle(
        peg,
        5,
        Paint()
          ..color = sin(rotation * 3 + i * 1.3) > 0
              ? Colors.white
              : const Color(0xFFFFE27A),
      );
      canvas.drawCircle(
        peg,
        5,
        Paint()
          ..color = AppColors.coinGold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.prizes != prizes;
}

class _SpinConfettiPainter extends CustomPainter {
  final double progress;
  const _SpinConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1) return;
    final colors = [
      AppColors.coinGold,
      AppColors.candyBlueLight,
      AppColors.candyGreen,
      AppColors.candyPurpleLight,
      AppColors.candyRed,
    ];
    final paint = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 36; i++) {
      final angle = i * pi * 2 / 36;
      final distance = 18 + progress * (70 + (i % 5) * 9);
      final center = Offset(size.width / 2, size.height * 0.4);
      final position = center + Offset(cos(angle), sin(angle)) * distance;
      paint.color = colors[i % colors.length].withValues(
        alpha: (1 - progress) * 0.9,
      );
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(progress * pi * 3 + i);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: 4 + (i % 3).toDouble(),
          height: 8 + (i % 4).toDouble(),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SpinConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
