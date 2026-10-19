import 'package:flutter/material.dart';

enum GardenGrowthStage {
  seed('SEED'),
  sprout('SPROUT'),
  young('YOUNG PLANT'),
  mature('MATURE');

  final String label;
  const GardenGrowthStage(this.label);

  static GardenGrowthStage fromProgress(int progress) =>
      values[progress.clamp(0, values.length - 1)];
}

class GardenSeedDefinition {
  final String id;
  final String name;
  final String description;
  final int price;
  final Color color;

  const GardenSeedDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.color,
  });
}

class GardenDecorationDefinition {
  final String id;
  final String name;
  final String description;
  final int? price;
  final String? rescueMilestone;
  final Color color;

  const GardenDecorationDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.color,
    this.rescueMilestone,
  });
}

class GardenPlant {
  final String seedId;
  final int growth;

  const GardenPlant({required this.seedId, required this.growth});

  GardenGrowthStage get stage => GardenGrowthStage.fromProgress(growth);

  Map<String, Object> toJson() => {'seedId': seedId, 'growth': growth};

  @override
  bool operator ==(Object other) =>
      other is GardenPlant && other.seedId == seedId && other.growth == growth;

  @override
  int get hashCode => Object.hash(seedId, growth);
}

class GardenProgressUpdate {
  final bool wasNewLevel;
  final int completedLevels;
  final int totalRescues;
  final List<String> rewards;

  const GardenProgressUpdate({
    required this.wasNewLevel,
    required this.completedLevels,
    required this.totalRescues,
    this.rewards = const [],
  });
}

class GardenCatalog {
  GardenCatalog._();

  static const int plotCount = 4;
  static const int decorationSlotCount = 3;
  static const int growthWins = 3;
  static const int seedRewardEveryLevels = 3;

  static const List<GardenSeedDefinition> seeds = [
    GardenSeedDefinition(
      id: 'moon_daisy',
      name: 'Moon Daisy',
      description: 'A gentle bloom that follows the moon.',
      price: 60,
      color: Color(0xFFFFE58A),
    ),
    GardenSeedDefinition(
      id: 'comet_rose',
      name: 'Comet Rose',
      description: 'A rosy flower with a comet-bright heart.',
      price: 100,
      color: Color(0xFFFF8FBF),
    ),
    GardenSeedDefinition(
      id: 'nebula_lily',
      name: 'Nebula Lily',
      description: 'Violet petals shimmer with stardust.',
      price: 150,
      color: Color(0xFFC3A0FF),
    ),
  ];

  static const List<GardenDecorationDefinition> decorations = [
    GardenDecorationDefinition(
      id: 'star_lantern',
      name: 'Star Lantern',
      description: 'A little light for every rescued friend.',
      price: 90,
      color: Color(0xFFFFD76A),
    ),
    GardenDecorationDefinition(
      id: 'comet_fountain',
      name: 'Comet Fountain',
      description: 'A tiny fountain of cosmic water.',
      price: 160,
      color: Color(0xFF75DFFF),
    ),
    GardenDecorationDefinition(
      id: 'moon_gate',
      name: 'Moon Gate',
      description: 'A curved doorway into the starlight.',
      price: 240,
      color: Color(0xFFB7A1FF),
    ),
    GardenDecorationDefinition(
      id: 'rescue_lantern',
      name: 'Rescue Lantern',
      description: 'A keepsake earned by rescuing five cats.',
      price: null,
      rescueMilestone: 'rescues_5',
      color: Color(0xFFFFC85A),
    ),
    GardenDecorationDefinition(
      id: 'nebula_arch',
      name: 'Nebula Arch',
      description: 'A garden arch earned by rescuing fifteen cats.',
      price: null,
      rescueMilestone: 'rescues_15',
      color: Color(0xFF9B8BFF),
    ),
  ];

  static GardenSeedDefinition? seed(String? id) {
    for (final item in seeds) {
      if (item.id == id) return item;
    }
    return null;
  }

  static GardenDecorationDefinition? decoration(String? id) {
    for (final item in decorations) {
      if (item.id == id) return item;
    }
    return null;
  }
}
