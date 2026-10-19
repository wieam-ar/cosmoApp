enum PlanetId { lava }

class PlanetCell {
  final int row;
  final int col;

  const PlanetCell(this.row, this.col);
}

class LavaPlanetRules {
  final int fireSpreadBudgetPerShot;
  final PlanetCell? initialFireCell;

  const LavaPlanetRules({
    required this.fireSpreadBudgetPerShot,
    this.initialFireCell,
  });

  static const inactive = LavaPlanetRules(fireSpreadBudgetPerShot: 0);
}

class PlanetDefinition {
  final PlanetId id;
  final String name;
  final String subtitle;
  final int firstLevel;
  final int lastLevel;
  final int mechanicIntroductionLevel;
  final int completionRewardCoins;

  const PlanetDefinition({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.firstLevel,
    required this.lastLevel,
    required this.mechanicIntroductionLevel,
    required this.completionRewardCoins,
  });

  int get levelCount => lastLevel - firstLevel + 1;
  bool containsLevel(int level) => level >= firstLevel && level <= lastLevel;
}

class PlanetRegistry {
  static const lava = PlanetDefinition(
    id: PlanetId.lava,
    name: 'LAVA PLANET',
    subtitle: 'A warm-up match can wake the living embers.',
    firstLevel: 1,
    lastLevel: 120,
    mechanicIntroductionLevel: 24,
    completionRewardCoins: 500,
  );

  static const List<PlanetDefinition> worlds = [lava];

  static PlanetDefinition? forLevel(int level) {
    for (final planet in worlds) {
      if (planet.containsLevel(level)) return planet;
    }
    return null;
  }

  static PlanetDefinition? byId(String id) {
    for (final planet in worlds) {
      if (planet.id.name == id) return planet;
    }
    return null;
  }
}
