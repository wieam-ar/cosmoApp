import 'package:flutter/material.dart';

/// Design canvas size for responsive scaling.
const Size kDesignSize = Size(412, 915);

/// Number of hex grid columns.
const int kGridCols = 8;

/// Sound effect identifiers across the game.
enum SfxName {
  pop,
  shoot,
  bounce,
  click,
  star,
  win,
  lose,
  whoosh,
  coin,
  boom,
  combo,
  thud,
  tick,
}

/// Skins available for Mimo.
enum SkinId { defaultMimo, spaceMimo, neonMimo, goldenMimo }

/// Game modes available in Cosmo Pop.
enum GameMode { level, arcade, classic, daily }

/// Difficulty parameters per level.
class DifficultyConfig {
  final int colorsCount;
  final int ceilingDropEvery;
  final double specialsChance;

  const DifficultyConfig({
    required this.colorsCount,
    required this.ceilingDropEvery,
    required this.specialsChance,
  });
}

/// Returns difficulty settings for a given 1-based level.
DifficultyConfig getDifficulty(int level) {
  if (level <= 1) {
    return const DifficultyConfig(
      colorsCount: 3,
      ceilingDropEvery: 8,
      specialsChance: 0.05,
    );
  } else if (level == 2) {
    return const DifficultyConfig(
      colorsCount: 3,
      ceilingDropEvery: 7,
      specialsChance: 0.08,
    );
  } else if (level == 3) {
    return const DifficultyConfig(
      colorsCount: 4,
      ceilingDropEvery: 6,
      specialsChance: 0.10,
    );
  } else {
    // Level 4 and above
    return const DifficultyConfig(
      colorsCount: 4,
      ceilingDropEvery: 5,
      specialsChance: 0.12,
    );
  }
}

/// Complete color palette for Cosmo Pop.
/// Inspired by the logo: deep violet space, a purple cat, and the four
/// elemental bubbles (fire, water, leaf, earth).
class AppColors {
  // Brand
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color primaryLight = Color(0xFFC4B5FD);
  static const Color secondary = Color(0xFFFF7AB6);
  static const Color accent = Color(0xFFFFE066);

  // Space
  static const Color background = Color(0xFF0E0A2E);
  static const Color surface = Color(0xFF1E1650);
  static const Color cardBg = Color(0xFF2B1F6E);
  static const Color darkBg = Color(0xFF080620);
  static const Color spaceBlue = Color(0xFF1A1450);
  static const Color spaceDark = Color(0xFF0A0722);
  static const Color nebulaPink = Color(0xFF7C3AED);
  static const Color nebulaCyan = Color(0xFF22D3EE);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC9C3F0);
  static const Color textMuted = Color(0xFF8A82C4);

  // Elemental bubbles (match the logo)
  static const Color candyRed = Color(0xFFFF4B3E); // fire
  static const Color candyRedDark = Color(0xFFB91C1C);
  static const Color candyRedLight = Color(0xFFFF9A8B);

  static const Color candyBlue = Color(0xFF29B6F6); // water
  static const Color candyBlueDark = Color(0xFF0369A1);
  static const Color candyBlueLight = Color(0xFF9BE3FF);

  static const Color candyGreen = Color(0xFF3DDC6B); // leaf
  static const Color candyGreenDark = Color(0xFF15803D);
  static const Color candyGreenLight = Color(0xFFA7F3C0);

  static const Color candyYellow = Color(0xFFFFB82E); // earth
  static const Color candyYellowDark = Color(0xFFB45309);
  static const Color candyYellowLight = Color(0xFFFFE9A3);

  static const Color candyPurple = Color(0xFFA855F7); // cosmic
  static const Color candyPurpleDark = Color(0xFF6B21A8);
  static const Color candyPurpleLight = Color(0xFFE0BBFF);

  static const Color candyOrange = Color(0xFFFF8A3D); // lava
  static const Color candyOrangeDark = Color(0xFFC2410C);
  static const Color candyOrangeLight = Color(0xFFFFC999);

  static const Color bombBlack = Color(0xFF2D2A4A);
  static const Color stoneGray = Color(0xFF7A74A8);

  // Rewards
  static const Color gold = Color(0xFFFFD43B);
  static const Color goldDark = Color(0xFFD97706);
  static const Color coinGold = Color(0xFFFFC21A);
  static const Color heartRed = Color(0xFFFF4D6D);
  static const Color starYellow = Color(0xFFFFF176);
}
