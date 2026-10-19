import 'dart:math';

import 'package:flutter/material.dart';

import 'constants.dart';

/// Linear interpolation between [a] and [b] by factor [t].
double lerp(double a, double b, double t) {
  return a + (b - a) * t;
}

/// Clamps [val] between [min] and [max].
double clampDoubleValue(double val, double minVal, double maxVal) {
  if (val < minVal) return minVal;
  if (val > maxVal) return maxVal;
  return val;
}

/// Helper for seedable or global random calculations.
class AppRand {
  static Random _rng = Random();

  /// Set seed for reproducible random operations.
  static void setSeed(int seed) {
    _rng = Random(seed);
  }

  /// Returns random double in range [min, max).
  static double doubleRange(double min, double max, [Random? customRng]) {
    final r = customRng ?? _rng;
    return min + r.nextDouble() * (max - min);
  }

  /// Returns random integer in range [min, max] inclusive.
  static int intRange(int min, int max, [Random? customRng]) {
    final r = customRng ?? _rng;
    return min + r.nextInt(max - min + 1);
  }

  /// Chooses a random element from a list.
  static T choice<T>(List<T> list, [Random? customRng]) {
    final r = customRng ?? _rng;
    return list[r.nextInt(list.length)];
  }
}

// ============================================================================
// EASING FUNCTIONS
// ============================================================================

double easeOutBack(double t) {
  const c1 = 1.70158;
  const c3 = c1 + 1.0;
  final tm1 = t - 1.0;
  return 1.0 + c3 * tm1 * tm1 * tm1 + c1 * tm1 * tm1;
}

double easeOutElastic(double t) {
  if (t <= 0) return 0.0;
  if (t >= 1) return 1.0;
  return pow(2, -10 * t) * sin((t * 10 - 0.75) * (2 * pi / 3)) + 1.0;
}

double easeOutBounce(double t) {
  if (t < 1 / 2.75) {
    return 7.5625 * t * t;
  } else if (t < 2 / 2.75) {
    final t1 = t - (1.5 / 2.75);
    return 7.5625 * t1 * t1 + 0.75;
  } else if (t < 2.5 / 2.75) {
    final t2 = t - (2.25 / 2.75);
    return 7.5625 * t2 * t2 + 0.9375;
  } else {
    final t3 = t - (2.625 / 2.75);
    return 7.5625 * t3 * t3 + 0.984375;
  }
}

double easeInOutQuad(double t) {
  return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2;
}

double spring(double t) {
  if (t <= 0) return 0.0;
  if (t >= 1) return 1.0;
  return pow(2, -10 * t) * sin((t - 0.075) * (2 * pi / 0.3)) + 1.0;
}

// ============================================================================
// CURVE SUBCLASSES
// ============================================================================

class EaseOutBackCurve extends Curve {
  const EaseOutBackCurve();
  @override
  double transformInternal(double t) => easeOutBack(t);
}

class EaseOutElasticCurve extends Curve {
  const EaseOutElasticCurve();
  @override
  double transformInternal(double t) => easeOutElastic(t);
}

class EaseOutBounceCurve extends Curve {
  const EaseOutBounceCurve();
  @override
  double transformInternal(double t) => easeOutBounce(t);
}

class EaseInOutQuadCurve extends Curve {
  const EaseInOutQuadCurve();
  @override
  double transformInternal(double t) => easeInOutQuad(t);
}

class SpringCurve extends Curve {
  const SpringCurve();
  @override
  double transformInternal(double t) => spring(t);
}

class AppCurves {
  static const Curve easeOutBack = EaseOutBackCurve();
  static const Curve easeOutElastic = EaseOutElasticCurve();
  static const Curve easeOutBounce = EaseOutBounceCurve();
  static const Curve easeInOutQuad = EaseInOutQuadCurve();
  static const Curve spring = SpringCurve();
}

/// Calculates scale factor relative to standard design resolution.
double balanceOf(BuildContext context) {
  final size = MediaQuery.of(context).size;
  final scaleX = size.width / kDesignSize.width;
  final scaleY = size.height / kDesignSize.height;
  return scaleX < scaleY ? scaleX : scaleY;
}

/// Convenience alias for balanceOf.
double scaleOf(BuildContext context) => balanceOf(context);
