import 'package:flutter/material.dart';

import '../../config/boss_config.dart';
import '../../widgets/cosmo_kit.dart';
import 'cat_crew.dart';
import 'elemental_reaction.dart';

/// Lives in widgets/ on purpose: the game logic stays free of UI imports,
/// the UI reads the logic enums through these extensions.

extension ReactionTypeCosmo on ReactionType {
  CosmoElement get cosmo => switch (this) {
    ReactionType.burn => CosmoElement.burn,
    ReactionType.steam => CosmoElement.steam,
    ReactionType.mud => CosmoElement.mud,
    ReactionType.bloom => CosmoElement.bloom,
  };
}

extension ElementalTypeCosmo on ElementalType {
  /// Null for electric / cosmic: they have no orb of their own.
  CosmoElement? get cosmo => switch (this) {
    ElementalType.fire => CosmoElement.burn,
    ElementalType.water => CosmoElement.steam,
    ElementalType.earth => CosmoElement.mud,
    ElementalType.flora => CosmoElement.bloom,
    ElementalType.electric || ElementalType.cosmic => null,
  };

  /// Logo-matched colour for the four orb elements, existing colour otherwise.
  Color get logoColor => cosmo?.light ?? color;
}

extension BossWeaknessCosmo on BossWeakness {
  /// Boss weaknesses share names with the four reactions.
  CosmoElement get cosmo => CosmoElement.values.byName(name);
}
