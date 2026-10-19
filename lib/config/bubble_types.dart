import 'dart:math';

import 'package:flutter/material.dart';

import '../core/constants.dart';

/// All bubble kinds supported by the game engine.
enum BubbleType {
  red,
  blue,
  green,
  yellow,
  purple,
  bomb,
  rainbow,
  stone,
  locked,
  key,
}

/// Visual and behavioral properties of a bubble type.
class BubbleStyle {
  final Color lightColor;
  final Color midColor;
  final Color darkColor;
  final Color shadowColor;
  final bool isMatchable;
  final bool isSpecial;
  final int requiredHits;

  const BubbleStyle({
    required this.lightColor,
    required this.midColor,
    required this.darkColor,
    required this.shadowColor,
    this.isMatchable = true,
    this.isSpecial = false,
    this.requiredHits = 1,
  });
}

/// Mapping of BubbleType to its corresponding visual style.
final Map<BubbleType, BubbleStyle> kBubbleStyles = {
  BubbleType.red: const BubbleStyle(
    lightColor: AppColors.candyRedLight,
    midColor: AppColors.candyRed,
    darkColor: AppColors.candyRedDark,
    shadowColor: Color(0x66900000),
    isMatchable: true,
    isSpecial: false,
  ),
  BubbleType.blue: const BubbleStyle(
    lightColor: AppColors.candyBlueLight,
    midColor: AppColors.candyBlue,
    darkColor: AppColors.candyBlueDark,
    shadowColor: Color(0x66003090),
    isMatchable: true,
    isSpecial: false,
  ),
  BubbleType.green: const BubbleStyle(
    lightColor: AppColors.candyGreenLight,
    midColor: AppColors.candyGreen,
    darkColor: AppColors.candyGreenDark,
    shadowColor: Color(0x66006020),
    isMatchable: true,
    isSpecial: false,
  ),
  BubbleType.yellow: const BubbleStyle(
    lightColor: AppColors.candyYellowLight,
    midColor: AppColors.candyYellow,
    darkColor: AppColors.candyYellowDark,
    shadowColor: Color(0x66806000),
    isMatchable: true,
    isSpecial: false,
  ),
  BubbleType.purple: const BubbleStyle(
    lightColor: AppColors.candyPurpleLight,
    midColor: AppColors.candyPurple,
    darkColor: AppColors.candyPurpleDark,
    shadowColor: Color(0x66400060),
    isMatchable: true,
    isSpecial: false,
  ),
  BubbleType.bomb: const BubbleStyle(
    lightColor: Color(0xFF636E72),
    midColor: AppColors.bombBlack,
    darkColor: Color(0xFF1E272C),
    shadowColor: Color(0x99000000),
    isMatchable: false,
    isSpecial: true,
  ),
  BubbleType.rainbow: const BubbleStyle(
    lightColor: Color(0xFFFFFFFF),
    midColor: Color(0xFFFF7675),
    darkColor: Color(0xFF74B9FF),
    shadowColor: Color(0x666C5CE7),
    isMatchable: true,
    isSpecial: true,
  ),
  BubbleType.stone: const BubbleStyle(
    lightColor: Color(0xFFB2BEC3),
    midColor: AppColors.stoneGray,
    darkColor: Color(0xFF2D3436),
    shadowColor: Color(0x66000000),
    isMatchable: false,
    isSpecial: true,
    requiredHits: 2,
  ),
  BubbleType.locked: const BubbleStyle(
    lightColor: Color(0xFFE1B12C),
    midColor: Color(0xFFCD6133),
    darkColor: Color(0xFF84817A),
    shadowColor: Color(0x66000000),
    isMatchable: false,
    isSpecial: true,
  ),
  BubbleType.key: const BubbleStyle(
    lightColor: Color(0xFFFFF200),
    midColor: Color(0xFFFFA801),
    darkColor: Color(0xFFFF5252),
    shadowColor: Color(0x66804000),
    isMatchable: true,
    isSpecial: true,
  ),
};

/// Normal colored bubble types used for matching.
const List<BubbleType> kNormalBubbleTypes = [
  BubbleType.red,
  BubbleType.blue,
  BubbleType.green,
  BubbleType.yellow,
  BubbleType.purple,
];

/// Helper to select a random normal bubble based on the available [colorsCount].
BubbleType randomNormalBubble([Random? rng, int colorsCount = 3]) {
  final random = rng ?? Random();
  final maxCount = colorsCount.clamp(1, kNormalBubbleTypes.length);
  final index = random.nextInt(maxCount);
  return kNormalBubbleTypes[index];
}
