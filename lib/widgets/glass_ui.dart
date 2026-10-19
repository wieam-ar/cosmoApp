import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';

/// Shared "glass bubble" look taken from the Cosmo Pop logo:
/// deep indigo surfaces, a thin rim light, a soft top sheen and one calm
/// colored tint per element. Use these instead of ad-hoc Containers so every
/// screen reads as one family.
abstract final class Glass {
  static const Color ink = Color(0xFF0A0826);
  static const Color deep = Color(0xFF17124F);
  static const Color violet = Color(0xFF9B7BFF);
  static const Color gold = Color(0xFFFFD36B);
  static const Color mint = Color(0xFF63E6B4);
  static const Color cyan = Color(0xFF5CE1FF);

  static Color darken(Color c, double amount) =>
      Color.lerp(c, Colors.black, amount)!;
  static Color lighten(Color c, double amount) =>
      Color.lerp(c, Colors.white, amount)!;

  static BoxDecoration surface({
    double radius = 20,
    Color? tint,
    double glow = 0,
    bool selected = false,
  }) {
    final base = tint ?? violet;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(
            deep,
            base,
            selected ? 0.30 : 0.16,
          )!.withValues(alpha: 0.94),
          Color.lerp(
            ink,
            base,
            selected ? 0.12 : 0.05,
          )!.withValues(alpha: 0.94),
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: tint == null
            ? Colors.white.withValues(alpha: 0.16)
            : tint.withValues(alpha: selected ? 0.85 : 0.5),
        width: selected ? 1.6 : 1.1,
      ),
      boxShadow: [
        const BoxShadow(
          color: Color(0x66000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
        if (glow > 0)
          BoxShadow(color: base.withValues(alpha: glow), blurRadius: 22),
      ],
    );
  }

  static BoxDecoration sheen(double radius) => BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0, 0.45],
      colors: [
        Colors.white.withValues(alpha: 0.07),
        Colors.white.withValues(alpha: 0),
      ],
    ),
  );
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 20,
    this.tint,
    this.glow = 0,
    this.selected = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  final double glow;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: padding,
      decoration: Glass.surface(
        radius: radius,
        tint: tint,
        glow: glow,
        selected: selected,
      ),
      foregroundDecoration: Glass.sheen(radius),
      child: child,
    );
    if (onTap == null) return panel;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: panel,
    );
  }
}

class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.text,
    this.icon,
    this.color = Glass.mint,
  });

  final String text;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
        ],
        Text(text, style: AppTextStyles.label(fontSize: 12, color: color)),
      ],
    ),
  );
}

class GlassProgress extends StatelessWidget {
  const GlassProgress({
    super.key,
    required this.value,
    this.color = Glass.mint,
    this.height = 8,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value.clamp(0.0, 1.0)),
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeOutCubic,
    builder: (context, v, child) => Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(height),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: v,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Glass.lighten(color, 0.35), color],
              ),
              borderRadius: BorderRadius.circular(height),
            ),
          ),
        ),
      ),
    ),
  );
}

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = Glass.violet,
    this.icon,
    this.height = 38,
    this.fontSize = 12,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final double height;
  final double fontSize;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = enabled ? Colors.white : Colors.white.withValues(alpha: 0.4);
    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Glass.lighten(color, 0.2),
                    Glass.darken(color, 0.28),
                  ],
                )
              : null,
          color: enabled ? null : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(
            color: Colors.white.withValues(alpha: enabled ? 0.38 : 0.12),
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        foregroundDecoration: enabled ? Glass.sheen(height / 2) : null,
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: fontSize + 4, color: fg),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label(fontSize: fontSize, color: fg),
              ),
            ),
          ],
        ),
      ),
    );
    return button;
  }
}

class GlassSectionTitle extends StatelessWidget {
  const GlassSectionTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: AppTextStyles.title(fontSize: 18, color: AppColors.accent),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 2),
        Text(
          subtitle!,
          style: AppTextStyles.body(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ],
  );
}
