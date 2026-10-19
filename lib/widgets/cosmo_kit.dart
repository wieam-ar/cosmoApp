import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../art/bubble_painter.dart';
import '../art/icons_painter.dart';
import '../config/bubble_types.dart';
import '../art/jelly_painter.dart';
import '../core/audio_service.dart';
import '../core/constants.dart';
import '../core/haptics.dart';
import '../core/save_service.dart';
import '../core/theme.dart';
import 'jelly_button.dart';

/// Colours sampled from the launcher icon (Mimo in a glass bubble + 4 orbs).
abstract final class Cosmo {
  static const nightDeep = Color(0xFF0B093A);
  static const nightViolet = Color(0xFF421685);
  static const furViolet = Color(0xFFCA84F6);
  static const furLight = Color(0xFFF1DEFA);
  static const blush = Color(0xFFED435E);
  static const sprout = Color(0xFF58AC22);
  static const glassRim = Color(0xFF9ED8FF);
}

/// The four reactions. Tints come from AppColors.candy*, which already follow
/// the logo's orbs, so there is only one palette to maintain.
enum CosmoElement {
  burn(AppColors.candyRed, AppColors.candyRedDark, 'Burn', BubbleType.red),
  steam(AppColors.candyBlue, AppColors.candyBlueDark, 'Steam', BubbleType.blue),
  mud(
    AppColors.candyYellow,
    AppColors.candyYellowDark,
    'Mud',
    BubbleType.yellow,
  ),
  bloom(
    AppColors.candyGreen,
    AppColors.candyGreenDark,
    'Bloom',
    BubbleType.green,
  );

  const CosmoElement(this.light, this.deep, this.label, this.bubble);
  final Color light;
  final Color deep;
  final String label;

  /// The in-game bubble that carries this element's emblem.
  final BubbleType bubble;
}

// ---------------------------------------------------------------------------
// Element orb – just the in-game bubble, so menus and gameplay always match.
// ---------------------------------------------------------------------------

class ElementOrb extends StatelessWidget {
  const ElementOrb({
    super.key,
    required this.element,
    this.size = 64,
    this.glow = 0,
    this.t = 0,
  });

  final CosmoElement element;
  final double size;

  /// 0..1 outer halo.
  final double glow;

  /// Animation clock in seconds (drives flame flicker, leaf sway, ...).
  final double t;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _OrbPainter(element, glow, t)),
  );
}

class _OrbPainter extends CustomPainter {
  const _OrbPainter(this.e, this.glow, this.t);
  final CosmoElement e;
  final double glow;
  final double t;

  @override
  void paint(Canvas canvas, Size size) => BubblePainter.draw(
    canvas,
    size.center(Offset.zero),
    size.shortestSide / 2 - 2,
    e.bubble,
    t: t,
    glow: glow,
  );

  @override
  bool shouldRepaint(covariant _OrbPainter old) =>
      old.e != e || old.glow != glow || old.t != t;
}

// ---------------------------------------------------------------------------
// Glass bubble (the icon's signature container)
// ---------------------------------------------------------------------------

class GlassBubble extends StatelessWidget {
  const GlassBubble({
    super.key,
    required this.size,
    this.child,
    this.tint = Cosmo.glassRim,
  });

  final double size;
  final Widget? child;
  final Color tint;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _GlassBack(tint),
      foregroundPainter: _GlassFront(tint),
      child: child,
    ),
  );
}

class _GlassBack extends CustomPainter {
  const _GlassBack(this.tint);
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(
      c,
      r * 0.97,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.35),
          radius: 1.0,
          colors: [tint.withValues(alpha: 0.08), tint.withValues(alpha: 0.28)],
          stops: const [0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(covariant _GlassBack old) => old.tint != tint;
}

class _GlassFront extends CustomPainter {
  const _GlassFront(this.tint);
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(
      c,
      r * 0.97,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.05
        ..color = tint.withValues(alpha: 0.75),
    );
    canvas.drawCircle(
      c,
      r * 0.93,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.015
        ..color = Colors.white.withValues(alpha: 0.5),
    );
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.055;
    final inner = Rect.fromCircle(center: c, radius: r * 0.84);
    canvas.drawArc(
      inner,
      pi * 1.08,
      pi * 0.3,
      false,
      arc..color = Colors.white.withValues(alpha: 0.8),
    );
    canvas.drawArc(
      inner,
      pi * 0.08,
      pi * 0.16,
      false,
      arc..color = Colors.white.withValues(alpha: 0.4),
    );
    canvas.drawCircle(
      c + Offset(-r * 0.58, -r * 0.32),
      r * 0.035,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _GlassFront old) => old.tint != tint;
}

// ---------------------------------------------------------------------------
// Interaction helpers
// ---------------------------------------------------------------------------

/// Squish-on-press wrapper that also fires haptic + click sound.
class CosmoTap extends StatefulWidget {
  const CosmoTap({super.key, required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<CosmoTap> createState() => _CosmoTapState();
}

class _CosmoTapState extends State<CosmoTap> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => setState(() => _down = true),
    onTapCancel: () => setState(() => _down = false),
    onTapUp: (_) {
      setState(() => _down = false);
      AppHaptics.light();
      Sfx.play(SfxName.click);
      widget.onTap();
    },
    child: AnimatedScale(
      scale: _down ? 0.92 : 1.0,
      duration: const Duration(milliseconds: 90),
      child: widget.child,
    ),
  );
}

/// Rebuilds only [builder] on a timer, so countdowns don't rebuild a screen.
class TickBuilder extends StatefulWidget {
  const TickBuilder({super.key, required this.every, required this.builder});
  final Duration every;
  final WidgetBuilder builder;

  @override
  State<TickBuilder> createState() => _TickBuilderState();
}

class _TickBuilderState extends State<TickBuilder> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.every, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

// ---------------------------------------------------------------------------
// Bottom dock
// ---------------------------------------------------------------------------

class CosmoDockItem {
  const CosmoDockItem({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
    this.materialIcon,
    this.badge = false,
  }) : assert(icon != null || materialIcon != null);

  final String label;
  final Color color;
  final VoidCallback onTap;
  final AppIcon? icon;
  final IconData? materialIcon;
  final bool badge;
}

class CosmoDock extends StatelessWidget {
  const CosmoDock({super.key, required this.items});
  final List<CosmoDockItem> items;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(6, 9, 6, 7),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Cosmo.nightViolet.withValues(alpha: 0.88),
          Cosmo.nightDeep.withValues(alpha: 0.94),
        ],
      ),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Cosmo.furViolet.withValues(alpha: 0.4)),
      boxShadow: const [
        BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 6)),
      ],
    ),
    child: Row(
      children: [for (final i in items) Expanded(child: _DockCell(i))],
    ),
  );
}

class _DockCell extends StatelessWidget {
  const _DockCell(this.item);
  final CosmoDockItem item;

  @override
  Widget build(BuildContext context) => CosmoTap(
    onTap: item.onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(item.color, Colors.white, 0.35)!,
                    item.color,
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.45),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: item.icon != null
                    ? SizedBox(
                        width: 26,
                        height: 26,
                        child: CustomPaint(
                          painter: _DockIconPainter(item.icon!),
                        ),
                      )
                    : Icon(item.materialIcon, size: 24, color: Colors.white),
              ),
            ),
            if (item.badge)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: AppColors.candyRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label(fontSize: 11, color: Colors.white),
        ),
      ],
    ),
  );
}

class _DockIconPainter extends CustomPainter {
  const _DockIconPainter(this.icon);
  final AppIcon icon;

  @override
  void paint(Canvas canvas, Size size) =>
      IconsPainter.draw(canvas, Offset.zero & size, icon, color: Colors.white);

  @override
  bool shouldRepaint(covariant _DockIconPainter old) => old.icon != icon;
}

// ---------------------------------------------------------------------------
// Sub-screen chrome
// ---------------------------------------------------------------------------

class CoinPill extends StatelessWidget {
  const CoinPill({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = ListenableBuilder(
      listenable: SaveService.I,
      builder: (context, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Cosmo.nightDeep.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.coinGold.withValues(alpha: 0.7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
    );
    return onTap == null ? pill : CosmoTap(onTap: onTap!, child: pill);
  }
}

/// Back button + centred title + optional trailing widget.
class CosmoHeader extends StatelessWidget {
  const CosmoHeader({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: RoundButton(
              icon: AppIcon.back,
              color: JellyColor.purple,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Text(
            title,
            style: AppTextStyles.title(fontSize: 24, color: AppColors.accent),
          ),
          if (trailing != null)
            Align(alignment: Alignment.centerRight, child: trailing),
        ],
      ),
    ),
  );
}
