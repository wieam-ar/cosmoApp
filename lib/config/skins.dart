import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Rarity tier for Mimo cosmetics.
enum SkinRarity { common, rare, epic, legendary }

/// Metadata for a Mimo skin cosmetic.
class SkinData {
  final SkinId id;
  final String name;
  final int price;
  final SkinRarity rarity;
  final String description;
  final Color primaryColor;

  const SkinData({
    required this.id,
    required this.name,
    required this.price,
    required this.rarity,
    required this.description,
    required this.primaryColor,
  });
}

/// Catalog of all available Mimo skins in the game shop.
final List<SkinData> kSkinsCatalog = [
  const SkinData(
    id: SkinId.defaultMimo,
    name: 'Astronaut Mimo',
    price: 0,
    rarity: SkinRarity.common,
    description: 'Classic space outfit for the galaxy cadet.',
    primaryColor: Color(0xFF9B59B6),
  ),
  const SkinData(
    id: SkinId.spaceMimo,
    name: 'Cosmo Pirate',
    price: 250,
    rarity: SkinRarity.rare,
    description: 'Sails across star systems in search of cosmic treasures.',
    primaryColor: Color(0xFFE74C3C),
  ),
  const SkinData(
    id: SkinId.neonMimo,
    name: 'Star Wizard',
    price: 500,
    rarity: SkinRarity.epic,
    description: 'Master of celestial magic and starry incantations.',
    primaryColor: Color(0xFF3498DB),
  ),
  const SkinData(
    id: SkinId.goldenMimo,
    name: 'Golden Ninja',
    price: 1000,
    rarity: SkinRarity.legendary,
    description: 'Pure 24k gold astronaut suit infused with starlight.',
    primaryColor: Color(0xFFF1C40F),
  ),
];

/// Helper to get skin data by ID.
SkinData getSkinData(SkinId id) {
  return kSkinsCatalog.firstWhere(
    (s) => s.id == id,
    orElse: () => kSkinsCatalog.first,
  );
}
