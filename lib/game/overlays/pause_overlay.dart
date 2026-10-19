import 'dart:ui';

import 'package:flutter/material.dart';

import '../../art/icons_painter.dart';
import '../../art/jelly_painter.dart';
import '../../art/mimo_painter.dart';
import '../../art/title3d.dart';
import '../../core/audio_service.dart';
import '../../core/constants.dart';
import '../../core/save_service.dart';
import '../../core/theme.dart';
import '../../widgets/jelly_button.dart';
import '../cosmo_game.dart';

class PauseOverlay extends StatefulWidget {
  final CosmoGame game;
  final VoidCallback onExit;

  const PauseOverlay({super.key, required this.game, required this.onExit});

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _loop;
  int? _countdown;
  bool _countingDown = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _loop = AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..repeat();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _loop.dispose();
    super.dispose();
  }

  Future<void> _resume() async {
    if (_countingDown) return;
    setState(() {
      _countingDown = true;
      _countdown = 3;
    });
    for (var count = 3; count > 0; count--) {
      if (!mounted) return;
      setState(() => _countdown = count);
      Sfx.play(SfxName.tick, pitch: 1 + (3 - count) * 0.12);
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    widget.game.resumeFromPause();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: ColoredBox(color: const Color(0xB80A0821)),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _entrance,
                curve: Curves.elasticOut,
              ),
              child: Container(
                width: 320,
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF5A44C8),
                      Color(0xFF2A1A78),
                      Color(0xFF1B1058),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFB79BFF), width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Color(0x667CF6FF),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mimo sits on top of the panel and waves
                    SizedBox(
                      height: 0,
                      child: OverflowBox(
                        alignment: Alignment.bottomCenter,
                        minHeight: 0,
                        maxHeight: 118,
                        maxWidth: 160,
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _loop,
                            builder: (context, _) => CustomPaint(
                              size: const Size(160, 118),
                              painter: _MimoPausePainter(_loop.value * 3600),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 60,
                      child: CustomPaint(
                        painter: _PauseRibbonPainter(),
                        child: Center(
                          child: CustomPaint(
                            size: const Size(180, 58),
                            painter: _PauseTitlePainter(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    JellyButton(
                      text: _countingDown ? 'GET READY!' : 'RESUME',
                      width: 238,
                      color: JellyColor.green,
                      enabled: !_countingDown,
                      onPressed: _resume,
                    ),
                    const SizedBox(height: 14),
                    JellyButton(
                      text: 'RESTART',
                      width: 238,
                      color: JellyColor.orange,
                      enabled: !_countingDown,
                      onPressed: widget.game.restart,
                    ),
                    const SizedBox(height: 14),
                    JellyButton(
                      text: 'HOME',
                      width: 238,
                      color: JellyColor.blue,
                      enabled: !_countingDown,
                      onPressed: widget.onExit,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'SOUND',
                          style: AppTextStyles.label(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        RoundButton(
                          icon: SaveService.I.soundEnabled
                              ? AppIcon.sound
                              : AppIcon.mute,
                          color: JellyColor.purple,
                          size: 48,
                          onPressed: () => setState(
                            () => SaveService.I.soundEnabled =
                                !SaveService.I.soundEnabled,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_countdown != null)
            Center(
              child: IgnorePointer(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.elasticOut,
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Text(
                    '$_countdown',
                    key: ValueKey(_countdown),
                    style:
                        AppTextStyles.title(
                          fontSize: 112,
                          color: AppColors.accent,
                        ).copyWith(
                          shadows: const [
                            Shadow(color: Colors.black87, blurRadius: 16),
                            Shadow(color: AppColors.primary, blurRadius: 28),
                          ],
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PauseTitlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Title3D.draw(
      canvas,
      'PAUSED',
      Offset(size.width / 2, size.height / 2),
      fontSize: 34,
      fillTop: const Color(0xFFFFFFD1),
      fillBottom: AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PauseRibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    JellyPainter.button(
      canvas,
      Rect.fromLTWH(size.width * 0.08, 4, size.width * 0.84, size.height - 8),
      color: JellyColor.purple,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MimoPausePainter extends CustomPainter {
  final double t;
  const _MimoPausePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    MimoPainter.draw(
      canvas,
      Offset(size.width / 2, size.height - 42),
      94,
      state: MimoState.wave,
      t: t,
    );
  }

  @override
  bool shouldRepaint(covariant _MimoPausePainter old) => old.t != t;
}
