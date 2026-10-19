import 'package:flutter/material.dart';

/// Shared "cosmic glass" look used by cards, tiles and panels so every
/// screen matches the logo (purple glass, neon cyan glow).
const LinearGradient kCardGradient = LinearGradient(
  colors: [Color(0xFF4A37AE), Color(0xFF25196E)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

/// Slightly translucent variant for cards that sit on top of artwork.
const LinearGradient kCardGradientGlass = LinearGradient(
  colors: [Color(0xDD4A37AE), Color(0xDD1E1458)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

/// Full card decoration with neon rim and soft glow.
BoxDecoration cosmoCard({
  double radius = 20,
  Color border = const Color(0xFF9B7BFF),
  double borderWidth = 2,
  Color? glow,
}) => BoxDecoration(
  gradient: kCardGradient,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: border, width: borderWidth),
  boxShadow: [
    const BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
    BoxShadow(
      color: (glow ?? const Color(0xFF7CF6FF)).withValues(alpha: 0.18),
      blurRadius: 14,
    ),
  ],
);
