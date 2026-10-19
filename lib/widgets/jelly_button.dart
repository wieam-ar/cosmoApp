import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../art/icons_painter.dart';
import '../core/audio_service.dart';
import '../core/constants.dart';
import '../core/haptics.dart';
import '../core/ui_theme.dart';

class JellyButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final JellyColor color;
  final AppIcon? icon;
  final Widget? customIcon;
  final double width, height, fontSize, phase;
  final bool enabled;
  final String? badgeText;

  const JellyButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = JellyColor.purple,
    this.icon,
    this.customIcon,
    this.width = 200,
    this.height = 58,
    this.fontSize = 22,
    this.phase = 0,
    this.enabled = true,
    this.badgeText,
  });

  @override
  State<JellyButton> createState() => _JellyButtonState();
}

class _JellyButtonState extends State<JellyButton>
    with TickerProviderStateMixin {
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 280),
  );
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );

  Timer? _phaseTimer;
  Offset _tap = Offset.zero;

  bool get _active => widget.enabled && widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    _phaseTimer = Timer(
      Duration(milliseconds: (widget.phase * 1000).round()),
      () {
        if (mounted) _breathe.repeat(reverse: true);
      },
    );
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _breathe.dispose();
    _press.dispose();
    _burst.dispose();
    super.dispose();
  }

  void _down(TapDownDetails d) {
    if (!_active) return;
    _tap = d.localPosition;
    _press.forward();
    _burst.forward(from: 0);
    AppHaptics.light();
    Sfx.play(SfxName.click);
  }

  void _up(TapUpDetails _) {
    if (!_active) return;
    _press.reverse();
    widget.onPressed?.call();
  }

  void _cancel() {
    if (_active) _press.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final r = BorderRadius.circular(widget.height / 2);

    return Opacity(
      opacity: widget.enabled ? 1 : 0.5,
      child: GestureDetector(
        onTapDown: _down,
        onTapUp: _up,
        onTapCancel: _cancel,
        child: AnimatedBuilder(
          animation: Listenable.merge([_breathe, _press, _burst]),
          builder: (_, _) {
            final p = Curves.easeOut.transform(_press.value);
            final scale = (1 - p * 0.06) * (1 + _breathe.value * 0.025);
            final depth = 6 * (1 - p);

            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: widget.width,
                height: widget.height + 6,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 6 - depth,
                      height: widget.height,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: r,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [c.uiTop, c.uiBottom],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.55),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: c.uiEdge,
                              offset: Offset(0, depth),
                            ),
                            BoxShadow(
                              color: c.uiBottom.withValues(alpha: 0.5),
                              blurRadius: 14 + _breathe.value * 6,
                              offset: Offset(0, depth + 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Gloss
                            Positioned(
                              top: 4,
                              left: widget.height * 0.35,
                              right: widget.height * 0.35,
                              height: widget.height * 0.34,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    widget.height,
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.65),
                                      Colors.white.withValues(alpha: 0.05),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.icon != null) ...[
                                  _AppIconWidget(
                                    widget.icon!,
                                    size: widget.fontSize * 1.15,
                                  ),
                                  const SizedBox(width: 8),
                                ] else if (widget.customIcon != null) ...[
                                  widget.customIcon!,
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: OutlinedText(
                                      widget.text,
                                      fontSize: widget.fontSize,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_burst.isAnimating)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _BurstPainter(_tap, _burst.value),
                          ),
                        ),
                      ),
                    if (widget.badgeText?.isNotEmpty ?? false)
                      Positioned(
                        top: -8,
                        right: -6,
                        child: _Badge(widget.badgeText!),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: Ui.red,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
    ),
    child: Text(text, style: Ui.text(12)),
  );
}

/// Radial star-shaped sparkle burst that actually flies outward and fades.
class _BurstPainter extends CustomPainter {
  final Offset origin;
  final double t;
  _BurstPainter(this.origin, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final e = Curves.easeOutCubic.transform(t);
    final paint = Paint()
      ..color = Ui.accent.withValues(alpha: (1 - t).clamp(0, 1));
    for (var i = 0; i < 10; i++) {
      final a = i * 2 * pi / 10 + (i.isEven ? 0.15 : -0.15);
      final d = 14 + e * (i.isEven ? 38 : 26);
      canvas.drawCircle(
        origin + Offset(cos(a) * d, sin(a) * d),
        (1 - t) * (i.isEven ? 3.6 : 2.4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}

class RoundButton extends StatefulWidget {
  final AppIcon icon;
  final VoidCallback? onPressed;
  final JellyColor color;
  final double size;
  final bool pulseRedDot;

  const RoundButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color = JellyColor.purple,
    this.size = 52,
    this.pulseRedDot = false,
  });

  @override
  State<RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<RoundButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 240),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed == null) return;
        _press.forward();
        AppHaptics.light();
        Sfx.play(SfxName.click);
      },
      onTapUp: (_) {
        if (widget.onPressed == null) return;
        _press.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: _press.reverse,
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, _) {
          final p = _press.value;
          final depth = 4 * (1 - p);
          return Transform.scale(
            scale: 1 - p * 0.07,
            child: SizedBox(
              width: widget.size,
              height: widget.size + 4,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 4 - depth,
                    left: 0,
                    width: widget.size,
                    height: widget.size,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.3, -0.5),
                          radius: 1.1,
                          colors: [c.uiTop, c.uiBottom],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(color: c.uiEdge, offset: Offset(0, depth)),
                          BoxShadow(
                            color: c.uiBottom.withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: Offset(0, depth + 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _AppIconWidget(
                          widget.icon,
                          size: widget.size * 0.52,
                        ),
                      ),
                    ),
                  ),
                  if (widget.pulseRedDot)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Ui.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: const [
                            BoxShadow(color: Ui.red, blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// White project icon (AppIcon) drawn with the existing IconsPainter.
class _AppIconWidget extends StatelessWidget {
  final AppIcon icon;
  final double size;
  const _AppIconWidget(this.icon, {required this.size});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _AppIconPainter(icon)),
  );
}

class _AppIconPainter extends CustomPainter {
  final AppIcon icon;
  _AppIconPainter(this.icon);

  @override
  void paint(Canvas canvas, Size size) =>
      IconsPainter.draw(canvas, Offset.zero & size, icon, color: Colors.white);

  @override
  bool shouldRepaint(covariant _AppIconPainter old) => old.icon != icon;
}
