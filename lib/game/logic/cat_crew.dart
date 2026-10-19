import 'package:flutter/material.dart';

import '../../config/bubble_types.dart';
import '../../core/constants.dart';

/// The elemental affinities assigned to cats and bubbles.
enum ElementalType { fire, water, earth, flora, electric, cosmic }

extension ElementalTypeX on ElementalType {
  String get name => switch (this) {
    ElementalType.fire => 'FIRE',
    ElementalType.water => 'WATER',
    ElementalType.earth => 'EARTH',
    ElementalType.flora => 'FLORA',
    ElementalType.electric => 'ELECTRIC',
    ElementalType.cosmic => 'COSMIC',
  };

  Color get color => switch (this) {
    ElementalType.fire => AppColors.candyRed,
    ElementalType.water => AppColors.candyBlue,
    ElementalType.earth => AppColors.candyYellow,
    ElementalType.flora => AppColors.candyGreen,
    ElementalType.electric => AppColors.coinGold,
    ElementalType.cosmic => AppColors.candyPurpleLight,
  };

  BubbleType? get matchingBubbleType => switch (this) {
    ElementalType.fire => BubbleType.red,
    ElementalType.water => BubbleType.blue,
    ElementalType.earth => BubbleType.yellow,
    ElementalType.flora => BubbleType.green,
    ElementalType.electric => BubbleType.rainbow,
    ElementalType.cosmic => BubbleType.purple,
  };
}

/// Rarity tier for cats.
enum CatRarity { common, rare, epic, legendary }

enum CatSkillKind { burn, steam, mud, bloom, wildcard }

extension CatRarityX on CatRarity {
  String get label => switch (this) {
    CatRarity.common => 'COMMON',
    CatRarity.rare => 'RARE',
    CatRarity.epic => 'EPIC',
    CatRarity.legendary => 'LEGENDARY',
  };

  Color get color => switch (this) {
    CatRarity.common => AppColors.textSecondary,
    CatRarity.rare => AppColors.candyBlueLight,
    CatRarity.epic => AppColors.candyPurpleLight,
    CatRarity.legendary => AppColors.coinGold,
  };

  int get maxLevel => 5;
}

/// Representation of a Cat companion ability.
class CatAbility {
  final String name;
  final String description;
  final int requiredCharge;
  final int cooldownShots;
  final CatSkillKind? kind;

  const CatAbility({
    required this.name,
    required this.description,
    this.requiredCharge = 100,
    this.cooldownShots = 3,
    this.kind,
  });
}

/// Optional parameters for the procedural kitten illustration.
class CatVisualConfig {
  final int accent;
  final int marking;

  const CatVisualConfig({required this.accent, this.marking = 0});
}

/// Static definition and data container for a Cat character.
class CatData {
  final int id;
  final String name;
  final ElementalType element;
  final CatRarity rarity;
  final String description;
  final String unlockCondition;
  final CatAbility ability;
  final CatVisualConfig? visual;

  CatSkillKind get skillKind =>
      ability.kind ??
      switch (element) {
        ElementalType.fire => CatSkillKind.burn,
        ElementalType.water => CatSkillKind.steam,
        ElementalType.earth => CatSkillKind.mud,
        ElementalType.flora => CatSkillKind.bloom,
        ElementalType.electric || ElementalType.cosmic => CatSkillKind.wildcard,
      };

  String get skillDescription {
    if (ability.kind != null) return ability.description;
    return switch (skillKind) {
      CatSkillKind.burn =>
        'Charge fully, then trigger BURN on an eligible Fire match.',
      CatSkillKind.steam =>
        'Charge fully, then trigger STEAM on an eligible Water match.',
      CatSkillKind.mud =>
        'Charge fully, then trigger MUD on an eligible Earth match.',
      CatSkillKind.bloom =>
        'Charge fully, then trigger BLOOM on an eligible Flora match.',
      CatSkillKind.wildcard =>
        'Charge fully, then prepare your next shot as a Rainbow wildcard.',
    };
  }

  const CatData({
    required this.id,
    required this.name,
    required this.element,
    required this.rarity,
    this.description = 'A curious companion from the Cosmo Pop galaxy.',
    this.unlockCondition = 'Rescue cats during levels.',
    required this.ability,
    this.visual,
  });

  /// Calculates upgrade cost in coins for the target level (2..5).
  int upgradeCost(int currentLevel) {
    if (currentLevel >= rarity.maxLevel) return 0;
    final baseCost = switch (rarity) {
      CatRarity.common => 150,
      CatRarity.rare => 300,
      CatRarity.epic => 600,
      CatRarity.legendary => 1200,
    };
    return baseCost * currentLevel;
  }

  /// Calculates passive score bonus percentage based on level.
  double scoreBonusPercent(int level) {
    final base = switch (rarity) {
      CatRarity.common => 0.03,
      CatRarity.rare => 0.05,
      CatRarity.epic => 0.08,
      CatRarity.legendary => 0.12,
    };
    return base * level.clamp(1, 5);
  }

  /// Ability effectiveness multiplier at given level.
  double abilityMultiplier(int level) {
    return 1.0 + (level - 1) * 0.25;
  }
}

/// Immutable view of a cat's persisted collection and upgrade state.
class CatProgress {
  final CatData cat;
  final int level;
  final bool isOwned;

  const CatProgress({
    required this.cat,
    required this.level,
    required this.isOwned,
  });

  int get upgradeCost => cat.upgradeCost(level);
  bool get isMaxLevel => level >= cat.rarity.maxLevel;
}

/// Registry containing definitions for all 24 collectible cats.
class CatRegistry {
  static const List<int> starterIds = [1, 2, 4, 6];

  static const List<CatData> all = [
    CatData(
      id: 0,
      name: 'Cosmo',
      element: ElementalType.cosmic,
      rarity: CatRarity.legendary,
      ability: CatAbility(
        name: 'Cosmic Nova',
        description: 'Transforms surrounding bubbles into Rainbow wildcards.',
        requiredCharge: 80,
      ),
    ),
    CatData(
      id: 1,
      name: 'Mochi',
      element: ElementalType.water,
      rarity: CatRarity.common,
      description:
          'A cool-headed kitten whose mist softens the hottest boards.',
      unlockCondition: 'Starter cat',
      visual: CatVisualConfig(accent: 0xFF70A1FF, marking: 1),
      ability: CatAbility(
        name: 'Steam Burst',
        description: 'Charge fully, then clear nearby Fire and eligible locks with STEAM.',
        requiredCharge: 100,
        kind: CatSkillKind.steam,
      ),
    ),
    CatData(
      id: 2,
      name: 'Comet',
      element: ElementalType.fire,
      rarity: CatRarity.rare,
      description:
          'A bright spark that turns careful matches into a controlled flare.',
      unlockCondition: 'Starter cat',
      visual: CatVisualConfig(accent: 0xFFFF6B81, marking: 0),
      ability: CatAbility(
        name: 'Controlled Burn',
        description:
            'Charge fully, then trigger BURN against nearby Flora and stone.',
        requiredCharge: 100,
        kind: CatSkillKind.burn,
      ),
    ),
    CatData(
      id: 3,
      name: 'Luna',
      element: ElementalType.water,
      rarity: CatRarity.common,
      ability: CatAbility(
        name: 'Moon Mist',
        description: 'Clears fog and locked bubbles on match.',
        requiredCharge: 100,
      ),
    ),
    CatData(
      id: 4,
      name: 'Pickles',
      element: ElementalType.flora,
      rarity: CatRarity.common,
      description: 'A lively garden guardian who encourages nearby Earth bubbles to bloom.',
      unlockCondition: 'Starter cat',
      visual: CatVisualConfig(accent: 0xFF2ED573, marking: 3),
      ability: CatAbility(
        name: 'Bloom Chain',
        description:
            'Charge fully, then trigger BLOOM on a Flora match beside Earth.',
        requiredCharge: 100,
        kind: CatSkillKind.bloom,
      ),
    ),
    CatData(
      id: 5,
      name: 'Nova',
      element: ElementalType.electric,
      rarity: CatRarity.epic,
      ability: CatAbility(
        name: 'Thunder Arc',
        description: 'Erase an entire row of bubbles with lightning.',
        requiredCharge: 85,
      ),
    ),
    CatData(
      id: 6,
      name: 'Mittens',
      element: ElementalType.earth,
      rarity: CatRarity.common,
      description:
          'A steady little digger who turns a good Earth match into MUD.',
      unlockCondition: 'Starter cat',
      visual: CatVisualConfig(accent: 0xFFECCC68, marking: 2),
      ability: CatAbility(
        name: 'Mud Wave',
        description:
            'Charge fully, then trigger MUD on an Earth match beside Water.',
        requiredCharge: 100,
        kind: CatSkillKind.mud,
      ),
    ),
    CatData(
      id: 7,
      name: 'Orbit',
      element: ElementalType.fire,
      rarity: CatRarity.common,
      ability: CatAbility(
        name: 'Inferno Burst',
        description: 'Boosts reaction score and scorches neighboring bubbles.',
        requiredCharge: 90,
      ),
    ),
    CatData(
      id: 8,
      name: 'Pudding',
      element: ElementalType.earth,
      rarity: CatRarity.rare,
      ability: CatAbility(
        name: 'Quake Wave',
        description: 'Shakes the board and breaks stone shields.',
        requiredCharge: 100,
      ),
    ),
    CatData(
      id: 9,
      name: 'Pixel',
      element: ElementalType.electric,
      rarity: CatRarity.common,
      ability: CatAbility(
        name: 'Spark Surge',
        description: 'Fills skill meter faster on electric matches.',
        requiredCharge: 85,
      ),
    ),
    CatData(
      id: 10,
      name: 'Marbles',
      element: ElementalType.flora,
      rarity: CatRarity.common,
      ability: CatAbility(
        name: 'Leaf Sprout',
        description: 'Converts nearby target bubbles into Flora bubbles.',
        requiredCharge: 95,
      ),
    ),
    CatData(
      id: 11,
      name: 'Starry',
      element: ElementalType.cosmic,
      rarity: CatRarity.epic,
      ability: CatAbility(
        name: 'Starlight Blessing',
        description: 'Grants +2 bonus moves when charge is full.',
        requiredCharge: 110,
      ),
    ),
    CatData(
      id: 12,
      name: 'Noodle',
      element: ElementalType.fire,
      rarity: CatRarity.common,
      ability: CatAbility(
        name: 'Fire Dash',
        description: 'Creates a line of fire popping matchable bubbles.',
        requiredCharge: 95,
      ),
    ),
    CatData(
      id: 13,
      name: 'Biscuit',
      element: ElementalType.earth,
      rarity: CatRarity.common,
      ability: CatAbility(
        name: 'Clay Armor',
        description: 'Neutralizes penalty drops on missed shots.',
        requiredCharge: 100,
      ),
    ),
    CatData(
      id: 14,
      name: 'Ziggy',
      element: ElementalType.electric,
      rarity: CatRarity.rare,
      ability: CatAbility(
        name: 'Volt Chain',
        description: 'Increases reaction chain score multiplier.',
        requiredCharge: 85,
      ),
    ),
    CatData(
      id: 15,
      name: 'Pebble',
      element: ElementalType.earth,
      rarity: CatRarity.common,
      ability: CatAbility(
        name: 'Boulder Crush',
        description: 'Crushes adjacent stone obstacles instantly.',
        requiredCharge: 100,
      ),
    ),
    CatData(
      id: 16,
      name: 'Miso',
      element: ElementalType.water,
      rarity: CatRarity.common,
      ability: CatAbility(
        name: 'Aqua Stream',
        description: 'Creates MUD or STEAM reactions on water matches.',
        requiredCharge: 90,
      ),
    ),
    CatData(
      id: 17,
      name: 'Sprout',
      element: ElementalType.flora,
      rarity: CatRarity.epic,
      ability: CatAbility(
        name: 'Floral Bloom',
        description: 'Triggers BLOOM reaction creating score flowers.',
        requiredCharge: 90,
      ),
    ),
    CatData(
      id: 18,
      name: 'Astro',
      element: ElementalType.cosmic,
      rarity: CatRarity.common,
      ability: CatAbility(
        name: 'Graviton Pull',
        description: 'Pulls orphaned bubbles into floating bonus drops.',
        requiredCharge: 100,
      ),
    ),
    CatData(
      id: 19,
      name: 'Clover',
      element: ElementalType.flora,
      rarity: CatRarity.common,
      ability: CatAbility(
        name: 'Lucky Charm',
        description: 'Increases coin rewards by 20% on completion.',
        requiredCharge: 100,
      ),
    ),
    CatData(
      id: 20,
      name: 'Waffles',
      element: ElementalType.fire,
      rarity: CatRarity.rare,
      ability: CatAbility(
        name: 'Sizzle Pop',
        description: 'Extra explosions during BURN reactions.',
        requiredCharge: 90,
      ),
    ),
    CatData(
      id: 21,
      name: 'Doodle',
      element: ElementalType.water,
      rarity: CatRarity.common,
      ability: CatAbility(
        name: 'Bubble Shield',
        description: 'Protects against row drops for 3 turns.',
        requiredCharge: 100,
      ),
    ),
    CatData(
      id: 22,
      name: 'Twinkle',
      element: ElementalType.cosmic,
      rarity: CatRarity.common,
      ability: CatAbility(
        name: 'Prismatic Beam',
        description: 'Converts shooter bubble into a Rainbow wildcard.',
        requiredCharge: 90,
      ),
    ),
    CatData(
      id: 23,
      name: 'Socks',
      element: ElementalType.earth,
      rarity: CatRarity.common,
      ability: CatAbility(
        name: 'Ground Stomp',
        description: 'Causes adjacent bubbles to drop instantly.',
        requiredCharge: 100,
      ),
    ),
  ];

  static CatData getById(int id) {
    return all.firstWhere((cat) => cat.id == id, orElse: () => all.first);
  }
}
