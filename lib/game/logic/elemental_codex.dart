import 'elemental_reaction.dart';

enum CodexCategory { reactions, combinations }

/// Single discoverable entry in the Elemental Codex.
class CodexEntry {
  final String id;
  final String title;
  final String formula;
  final String description;
  final String clue;
  final ReactionType? reactionType;
  final CodexCategory category;
  final int rewardCoins;
  final int rewardGems;

  const CodexEntry({
    required this.id,
    required this.title,
    required this.formula,
    required this.description,
    required this.clue,
    this.reactionType,
    this.category = CodexCategory.reactions,
    this.rewardCoins = 100,
    this.rewardGems = 2,
  });
}

class CodexProgress {
  final int discovered;
  final int total;

  const CodexProgress({required this.discovered, required this.total});

  double get fraction => total == 0 ? 0 : discovered / total;
  int get remaining => total - discovered;
}

/// Registry of discoverable entries in the Elemental Codex.
class ElementalCodexRegistry {
  static const List<CodexEntry> entries = [
    CodexEntry(
      id: 'reaction_burn',
      title: 'BURN Reaction',
      formula: 'Fire (Red) + Flora (Green)',
      description: 'Fire scorches up to two adjacent Flora bubbles and damages neighboring stone.',
      clue: 'A warm-colored match can consume nearby leaves.',
      reactionType: ReactionType.burn,
      rewardCoins: 150,
      rewardGems: 3,
    ),
    CodexEntry(
      id: 'reaction_steam',
      title: 'STEAM Reaction',
      formula: 'Water (Blue) + Fire (Red)',
      description: 'Water clears nearby Fire and up to two locks anywhere on the board; absorbed Fire may seed BURN.',
      clue: 'Look for a cool-colored match near something hot.',
      reactionType: ReactionType.steam,
      rewardCoins: 150,
      rewardGems: 3,
    ),
    CodexEntry(
      id: 'reaction_mud',
      title: 'MUD Reaction',
      formula: 'Earth (Yellow) + Water (Blue)',
      description:
          'Earth absorbs nearby Water and may trigger a STEAM follow-up.',
      clue: 'A grounded match can soak up nearby liquid.',
      reactionType: ReactionType.mud,
      rewardCoins: 150,
      rewardGems: 3,
    ),
    CodexEntry(
      id: 'reaction_bloom',
      title: 'BLOOM Reaction',
      formula: 'Flora (Green) + Earth (Yellow)',
      description:
          'Flora absorbs nearby Earth and may trigger a MUD follow-up.',
      clue: 'A leafy match can draw strength from nearby soil.',
      reactionType: ReactionType.bloom,
      rewardCoins: 150,
      rewardGems: 3,
    ),
    CodexEntry(
      id: 'chain_double',
      title: 'Double Chain Combo',
      formula: 'Trigger 2 Reactions From One Shot',
      description:
          'The second reaction in a same-shot chain earns a x2 reaction bonus.',
      clue: 'One reaction can awaken another during the same shot.',
      category: CodexCategory.combinations,
      rewardCoins: 250,
      rewardGems: 5,
    ),
    CodexEntry(
      id: 'chain_triple',
      title: 'Cosmic Reaction Master',
      formula: 'Trigger 3 Reactions From One Shot',
      description: 'A bounded three-reaction chain awards a x3 reaction bonus multiplier.',
      clue: 'Keep an elemental cascade going to its third reaction.',
      category: CodexCategory.combinations,
      rewardCoins: 500,
      rewardGems: 10,
    ),
    CodexEntry(
      id: 'chain_burn_bloom',
      title: 'Kindling Bloom',
      formula: 'BURN → BLOOM',
      description:
          'A scorched Flora target can seed a neighboring BLOOM reaction.',
      clue:
          'Sometimes the element caught in a reaction becomes the next spark.',
      reactionType: ReactionType.burn,
      category: CodexCategory.combinations,
      rewardCoins: 100,
      rewardGems: 2,
    ),
    CodexEntry(
      id: 'chain_bloom_mud',
      title: 'Rooted Earth',
      formula: 'BLOOM → MUD',
      description:
          'Earth absorbed by BLOOM can seed a neighboring MUD reaction.',
      clue: 'Let the first reaction expose a new elemental neighbor.',
      reactionType: ReactionType.bloom,
      category: CodexCategory.combinations,
      rewardCoins: 100,
      rewardGems: 2,
    ),
    CodexEntry(
      id: 'chain_mud_steam',
      title: 'Rising Vapor',
      formula: 'MUD → STEAM',
      description:
          'Water absorbed by MUD can seed a neighboring STEAM reaction.',
      clue: 'A reaction can pass its energy into a nearby element.',
      reactionType: ReactionType.mud,
      category: CodexCategory.combinations,
      rewardCoins: 100,
      rewardGems: 2,
    ),
    CodexEntry(
      id: 'chain_steam_burn',
      title: 'Flashpoint',
      formula: 'STEAM → BURN',
      description:
          'Fire absorbed by STEAM can seed a neighboring BURN reaction.',
      clue: 'Some cascades circle back to a familiar element.',
      reactionType: ReactionType.steam,
      category: CodexCategory.combinations,
      rewardCoins: 100,
      rewardGems: 2,
    ),
  ];

  static CodexEntry getById(String id) {
    return entries.firstWhere((e) => e.id == id, orElse: () => entries.first);
  }

  static String? getEntryIdForReaction(ReactionType type) => switch (type) {
    ReactionType.burn => 'reaction_burn',
    ReactionType.steam => 'reaction_steam',
    ReactionType.mud => 'reaction_mud',
    ReactionType.bloom => 'reaction_bloom',
  };

  static CodexProgress progress(Iterable<String> discoveredIds) {
    final validIds = entries.map((entry) => entry.id).toSet();
    final discovered = discoveredIds.where(validIds.contains).toSet().length;
    return CodexProgress(discovered: discovered, total: entries.length);
  }

  static List<CodexEntry> entriesFor(CodexCategory category) => entries
      .where((entry) => entry.category == category)
      .toList(growable: false);
}
