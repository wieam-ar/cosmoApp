import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants.dart';
import 'haptics.dart';

// ============================================================================
// TYPOGRAPHY  (Lilita One for titles, Baloo 2 for UI) - same API as before
// ============================================================================

class AppTextStyles {
  static TextStyle title({
    double fontSize = 28,
    Color color = Colors.white,
    double letterSpacing = 1.0,
  }) {
    try {
      return GoogleFonts.lilitaOne(
        fontSize: fontSize,
        color: color,
        letterSpacing: letterSpacing,
        height: 1.05,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'sans-serif',
        fontWeight: FontWeight.w900,
        fontSize: fontSize,
        color: color,
        letterSpacing: letterSpacing,
        height: 1.05,
      );
    }
  }

  static TextStyle label({
    double fontSize = 18,
    Color color = Colors.white,
    FontWeight fontWeight = FontWeight.w800,
    double letterSpacing = 0.5,
  }) {
    try {
      return GoogleFonts.baloo2(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: 1.1,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'sans-serif',
        fontWeight: fontWeight,
        fontSize: fontSize,
        color: color,
        letterSpacing: letterSpacing,
        height: 1.1,
      );
    }
  }

  static TextStyle body({
    double fontSize = 14,
    Color color = AppColors.textSecondary,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    try {
      return GoogleFonts.baloo2(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: 1.2,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'sans-serif',
        fontWeight: fontWeight,
        fontSize: fontSize,
        color: color,
        height: 1.2,
      );
    }
  }
}

// ============================================================================
// GRADIENTS, SHADOWS, RADII
// ============================================================================

class AppGradients {
  /// Main screen background (violet nebula fading into deep space).
  static const LinearGradient space = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2E1F8A),
      AppColors.spaceBlue,
      AppColors.background,
      AppColors.darkBg,
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  static const LinearGradient panel = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B2C93), Color(0xFF241A66)],
  );

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFB794F6), AppColors.primary, AppColors.primaryDark],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF0A3), AppColors.gold, AppColors.goldDark],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient green = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.candyGreenLight,
      AppColors.candyGreen,
      AppColors.candyGreenDark,
    ],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient pink = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFB3D6), AppColors.secondary, Color(0xFFD6336C)],
    stops: [0.0, 0.45, 1.0],
  );
}

class AppShadows {
  static List<BoxShadow> glow(
    Color c, {
    double blur = 24,
    double opacity = 0.55,
  }) => [
    BoxShadow(
      color: c.withValues(alpha: opacity),
      blurRadius: blur,
      spreadRadius: 1,
    ),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 6)),
  ];
}

class AppRadius {
  static const double sm = 12;
  static const double md = 20;
  static const double lg = 28;
  static const double pill = 999;
}

// ============================================================================
// MATERIAL THEME  ->  MaterialApp(theme: AppTheme.data)
// ============================================================================

class AppTheme {
  static ThemeData get data {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      splashFactory: NoSplash.splashFactory,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.title(fontSize: 44),
        headlineMedium: AppTextStyles.title(fontSize: 30),
        titleMedium: AppTextStyles.label(fontSize: 18),
        bodyMedium: AppTextStyles.body(),
        labelLarge: AppTextStyles.label(fontSize: 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardBg,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: AppTextStyles.label(fontSize: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

// ============================================================================
// OUTLINED TEXT  (comic stroke + drop shadow) - same API as before
// ============================================================================

Widget outlinedText(
  String text, {
  required double fontSize,
  required Color fill,
  Color stroke = const Color(0xFF1B0F4D),
  double strokeWidth = 4.0,
  List<Shadow>? shadows,
  TextStyle? baseStyle,
  TextAlign textAlign = TextAlign.center,
}) {
  final styleToUse = baseStyle ?? AppTextStyles.title(fontSize: fontSize);

  final strokeStyle = styleToUse.copyWith(
    fontSize: fontSize,
    foreground: Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..color = stroke,
  );

  final fillStyle = styleToUse.copyWith(
    fontSize: fontSize,
    color: fill,
    shadows:
        shadows ??
        const [
          Shadow(
            offset: Offset(0, 3),
            blurRadius: 4.0,
            color: Color(0x88000000),
          ),
        ],
  );

  return Stack(
    alignment: Alignment.center,
    children: [
      Text(text, textAlign: textAlign, style: strokeStyle),
      Text(text, textAlign: textAlign, style: fillStyle),
    ],
  );
}

// ============================================================================
// COSMIC BACKGROUND  - gradient + nebula glows + twinkling stars + planets
// ============================================================================

class CosmicBackground extends StatefulWidget {
  final Widget? child;
  final bool planets;
  final int starCount;

  const CosmicBackground({
    super.key,
    this.child,
    this.planets = true,
    this.starCount = 70,
  });

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _Star {
  final double x, y, r, phase, speed, drift;
  final bool sparkle;
  final Color color;
  _Star(
    this.x,
    this.y,
    this.r,
    this.phase,
    this.speed,
    this.drift,
    this.sparkle,
    this.color,
  );
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 24))
      ..repeat();
    final rnd = Random(7);
    const tints = [
      Colors.white,
      Color(0xFFFFE9A3),
      Color(0xFFBFE9FF),
      Color(0xFFE0BBFF),
    ];
    _stars = List.generate(widget.starCount, (i) {
      final big = rnd.nextDouble() < 0.12;
      return _Star(
        rnd.nextDouble(),
        rnd.nextDouble(),
        big ? 2.2 + rnd.nextDouble() * 1.6 : 0.6 + rnd.nextDouble() * 1.1,
        rnd.nextDouble() * pi * 2,
        1 + rnd.nextInt(4).toDouble(),
        0.01 + rnd.nextDouble() * 0.03,
        big,
        tints[rnd.nextInt(tints.length)],
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.space),
        ),
        // Nebula glows
        const Positioned.fill(child: _NebulaGlows()),
        // Stars
        RepaintBoundary(
          child: CustomPaint(
            painter: _StarsPainter(_stars, _c),
            size: Size.infinite,
          ),
        ),
        if (widget.planets) const Positioned.fill(child: _Planets()),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _NebulaGlows extends StatelessWidget {
  const _NebulaGlows();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) {
          Widget glow(Color col, double size, double opacity) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  col.withValues(alpha: opacity),
                  col.withValues(alpha: 0),
                ],
              ),
            ),
          );
          return Stack(
            children: [
              Positioned(
                left: -c.maxWidth * 0.3,
                top: c.maxHeight * 0.05,
                child: glow(AppColors.nebulaPink, c.maxWidth * 1.1, 0.35),
              ),
              Positioned(
                right: -c.maxWidth * 0.4,
                top: c.maxHeight * 0.38,
                child: glow(AppColors.nebulaCyan, c.maxWidth * 1.0, 0.16),
              ),
              Positioned(
                left: c.maxWidth * 0.1,
                bottom: -c.maxWidth * 0.5,
                child: glow(AppColors.secondary, c.maxWidth * 1.0, 0.18),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  final List<_Star> stars;
  final Animation<double> anim;
  _StarsPainter(this.stars, this.anim) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    final p = Paint();
    for (final s in stars) {
      final tw = 0.5 + 0.5 * sin(t * pi * 2 * s.speed + s.phase);
      final a = (0.3 + 0.7 * tw).clamp(0.0, 1.0);
      final y = ((s.y + t * s.drift * 6) % 1.0) * size.height;
      final x = s.x * size.width;
      p.color = s.color.withValues(alpha: a);
      if (s.sparkle) {
        p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        final r = s.r * (0.8 + 0.5 * tw);
        final path = Path()
          ..moveTo(x, y - r * 2.4)
          ..quadraticBezierTo(x, y, x + r * 2.4, y)
          ..quadraticBezierTo(x, y, x, y + r * 2.4)
          ..quadraticBezierTo(x, y, x - r * 2.4, y)
          ..quadraticBezierTo(x, y, x, y - r * 2.4)
          ..close();
        canvas.drawPath(path, p);
        p.maskFilter = null;
      } else {
        canvas.drawCircle(Offset(x, y), s.r, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter old) => false;
}

class _Planets extends StatelessWidget {
  const _Planets();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          Widget planet(double size, List<Color> cols, {Color? glow}) =>
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.4, -0.5),
                    radius: 1.0,
                    colors: cols,
                  ),
                  boxShadow: glow == null
                      ? null
                      : AppShadows.glow(glow, blur: 36, opacity: 0.45),
                ),
              );
          return Stack(
            children: [
              // Moon (bottom-left)
              Positioned(
                left: -w * 0.18,
                bottom: -w * 0.16,
                child: planet(w * 0.5, const [
                  Color(0xFFB9A4FF),
                  Color(0xFF7A5BE0),
                  Color(0xFF3B2A8C),
                ]),
              ),
              // Lava planet (bottom-right)
              Positioned(
                right: -w * 0.2,
                bottom: -w * 0.2,
                child: planet(w * 0.52, const [
                  Color(0xFFFFB347),
                  Color(0xFFFF5A36),
                  Color(0xFF8E1B0E),
                ], glow: AppColors.candyOrange),
              ),
              // Small ringed planet (top-left)
              Positioned(
                left: w * 0.06,
                top: c.maxHeight * 0.12,
                child: Transform.rotate(
                  angle: -0.35,
                  child: SizedBox(
                    width: w * 0.16,
                    height: w * 0.16,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        planet(w * 0.09, const [
                          Color(0xFFB7A6FF),
                          Color(0xFF5B3FD0),
                        ]),
                        Container(
                          width: w * 0.16,
                          height: w * 0.045,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: AppColors.primaryLight.withValues(
                                alpha: 0.8,
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Tiny teal planet (top-right)
              Positioned(
                right: w * 0.1,
                top: c.maxHeight * 0.2,
                child: planet(w * 0.05, const [
                  Color(0xFF9BE3FF),
                  Color(0xFF2F8FE8),
                  Color(0xFF1B3A8C),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// GLOSSY 3D BUTTON  (candy look, presses down)
// ============================================================================

class GlossyButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Gradient gradient;
  final Color edge;
  final double width;
  final double height;
  final double fontSize;

  const GlossyButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.gradient = AppGradients.green,
    this.edge = AppColors.candyGreenDark,
    this.width = 240,
    this.height = 58,
    this.fontSize = 24,
  });

  /// Gold CTA preset.
  const GlossyButton.gold({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.width = 240,
    this.height = 58,
    this.fontSize = 24,
  }) : gradient = AppGradients.gold,
       edge = AppColors.goldDark;

  /// Violet secondary preset.
  const GlossyButton.violet({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.width = 240,
    this.height = 54,
    this.fontSize = 22,
  }) : gradient = AppGradients.primary,
       edge = AppColors.primaryDark;

  @override
  State<GlossyButton> createState() => _GlossyButtonState();
}

class _GlossyButtonState extends State<GlossyButton> {
  bool _down = false;
  static const double _depth = 6;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final radius = BorderRadius.circular(widget.height / 2.2);
    final edge = enabled ? widget.edge : const Color(0xFF3A3560);
    final offset = _down ? _depth - 2 : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTap: enabled
          ? () {
              AppHaptics.light();
              widget.onTap!();
            }
          : null,
      child: SizedBox(
        width: widget.width,
        height: widget.height + _depth,
        child: Stack(
          children: [
            // 3D base
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: widget.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: edge,
                  borderRadius: radius,
                  boxShadow: enabled
                      ? [
                          BoxShadow(
                            color: widget.edge.withValues(alpha: 0.45),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
            // Face
            AnimatedPositioned(
              duration: const Duration(milliseconds: 70),
              left: 0,
              right: 0,
              top: offset,
              height: widget.height,
              child: Container(
                decoration: BoxDecoration(
                  gradient: enabled
                      ? widget.gradient
                      : const LinearGradient(
                          colors: [Color(0xFF6E6A99), Color(0xFF4A4678)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                  borderRadius: radius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 1.6,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Gloss highlight
                      Positioned(
                        top: 3,
                        left: 12,
                        right: 12,
                        height: widget.height * 0.38,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.55),
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
                            Icon(
                              widget.icon,
                              color: Colors.white,
                              size: widget.fontSize + 2,
                              shadows: const [
                                Shadow(
                                  color: Color(0x88000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                          ],
                          outlinedText(
                            widget.label,
                            fontSize: widget.fontSize,
                            fill: Colors.white,
                            stroke: widget.edge.withValues(alpha: 0.95),
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// GLASS PANEL  (frosted card for dialogs, stats, settings)
// ============================================================================

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? glow;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = AppRadius.lg,
    this.glow,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          ...AppShadows.soft,
          if (glow != null) ...AppShadows.glow(glow!, blur: 30, opacity: 0.35),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4A3AB0).withValues(alpha: 0.72),
                  const Color(0xFF1E1650).withValues(alpha: 0.82),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1.4,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BUBBLE ORB  (glossy bubble like the logo's elemental bubbles)
// ============================================================================

class BubbleOrb extends StatelessWidget {
  final double size;
  final Color light;
  final Color base;
  final Color dark;
  final Widget? child;
  final bool glow;

  const BubbleOrb({
    super.key,
    required this.size,
    required this.light,
    required this.base,
    required this.dark,
    this.child,
    this.glow = true,
  });

  factory BubbleOrb.fire({Key? key, double size = 64, Widget? child}) =>
      BubbleOrb(
        key: key,
        size: size,
        light: AppColors.candyRedLight,
        base: AppColors.candyRed,
        dark: AppColors.candyRedDark,
        child: child,
      );
  factory BubbleOrb.water({Key? key, double size = 64, Widget? child}) =>
      BubbleOrb(
        key: key,
        size: size,
        light: AppColors.candyBlueLight,
        base: AppColors.candyBlue,
        dark: AppColors.candyBlueDark,
        child: child,
      );
  factory BubbleOrb.leaf({Key? key, double size = 64, Widget? child}) =>
      BubbleOrb(
        key: key,
        size: size,
        light: AppColors.candyGreenLight,
        base: AppColors.candyGreen,
        dark: AppColors.candyGreenDark,
        child: child,
      );
  factory BubbleOrb.earth({Key? key, double size = 64, Widget? child}) =>
      BubbleOrb(
        key: key,
        size: size,
        light: AppColors.candyYellowLight,
        base: AppColors.candyYellow,
        dark: AppColors.candyYellowDark,
        child: child,
      );
  factory BubbleOrb.cosmic({Key? key, double size = 64, Widget? child}) =>
      BubbleOrb(
        key: key,
        size: size,
        light: AppColors.candyPurpleLight,
        base: AppColors.candyPurple,
        dark: AppColors.candyPurpleDark,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _OrbPainter(light, base, dark, glow),
        child: Center(child: child),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final Color light, base, dark;
  final bool glow;
  _OrbPainter(this.light, this.base, this.dark, this.glow);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    if (glow) {
      canvas.drawCircle(
        c,
        r * 1.05,
        Paint()
          ..color = base.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.35),
      );
    }

    // Body
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 1.0,
          colors: [light, base, dark],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    // Inner rim light at the bottom (glass feel)
    canvas.drawCircle(
      c,
      r * 0.92,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, light.withValues(alpha: 0.6)],
          stops: const [0.5, 1.0],
        ).createShader(rect),
    );

    // Outer ring
    canvas.drawCircle(
      c,
      r - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.5),
    );

    // Big gloss
    canvas.save();
    canvas.translate(c.dx - r * 0.38, c.dy - r * 0.5);
    canvas.rotate(-0.6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 0.62, height: r * 0.3),
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
    canvas.restore();

    // Small sparkle dot
    canvas.drawCircle(
      c + Offset(r * 0.42, -r * 0.18),
      r * 0.07,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) =>
      old.light != light ||
      old.base != base ||
      old.dark != dark ||
      old.glow != glow;
}

// ============================================================================
// STAT PILL  (coins, lives, stars in the HUD)
// ============================================================================

class StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final VoidCallback? onPlus;

  const StatPill({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 6, right: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3B2C93), Color(0xFF1E1650)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.4,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.2),
              boxShadow: AppShadows.glow(iconColor, blur: 10, opacity: 0.4),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 8),
          Text(value, style: AppTextStyles.label(fontSize: 17)),
          if (onPlus != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                AppHaptics.selection();
                onPlus!();
              },
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.green,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// STAR RATING  (level complete)
// ============================================================================

class StarRating extends StatelessWidget {
  final int stars; // 0..3
  final double size;
  const StarRating({super.key, required this.stars, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final on = i < stars;
        final s = i == 1 ? size * 1.25 : size;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            Icons.star_rounded,
            size: s,
            color: on ? AppColors.gold : AppColors.cardBg,
            shadows: on
                ? [
                    Shadow(
                      color: AppColors.gold.withValues(alpha: 0.8),
                      blurRadius: 18,
                    ),
                  ]
                : const [
                    Shadow(
                      color: Color(0x66000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
        );
      }),
    );
  }
}
