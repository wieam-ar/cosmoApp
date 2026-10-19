import '../../config/bubble_types.dart';
import '../components/bubble_component.dart';
import '../grid.dart';
import 'cat_crew.dart';

enum ReactionType { burn, steam, mud, bloom }

extension ReactionTypeX on ReactionType {
  String get label => switch (this) {
    ReactionType.burn => 'BURN!',
    ReactionType.steam => 'STEAM!',
    ReactionType.mud => 'MUD!',
    ReactionType.bloom => 'BLOOM!',
  };

  String get description => switch (this) {
    ReactionType.burn =>
      'Fire scorches nearby Flora and damages adjacent stone.',
    ReactionType.steam =>
      'Water clears nearby Fire and opens up to two board locks.',
    ReactionType.mud =>
      'Earth absorbs nearby Water and damages adjacent stone.',
    ReactionType.bloom =>
      'Flora absorbs nearby Earth and damages adjacent stone.',
  };

  ElementalType get primaryElement => switch (this) {
    ReactionType.burn => ElementalType.fire,
    ReactionType.steam => ElementalType.water,
    ReactionType.mud => ElementalType.earth,
    ReactionType.bloom => ElementalType.flora,
  };

  ElementalType get targetElement => switch (this) {
    ReactionType.burn => ElementalType.flora,
    ReactionType.steam => ElementalType.fire,
    ReactionType.mud => ElementalType.water,
    ReactionType.bloom => ElementalType.earth,
  };

  BubbleType get primaryBubble => primaryElement.matchingBubbleType!;
  BubbleType get targetBubble => targetElement.matchingBubbleType!;

  String get codexId => 'reaction_$name';
}

/// Declarative rules keep reaction eligibility and caps visible in one place.
class ReactionRule {
  final ReactionType type;
  final BubbleType primary;
  final BubbleType target;
  final int minimumMatch;
  final int minimumFollowUpSources;
  final int baseTargetLimit;
  final bool opensBoardLocks;
  final bool damagesAdjacentStone;
  final ReactionType? followUp;

  const ReactionRule({
    required this.type,
    required this.primary,
    required this.target,
    this.minimumMatch = 3,
    this.minimumFollowUpSources = 1,
    this.baseTargetLimit = 2,
    this.opensBoardLocks = false,
    this.damagesAdjacentStone = true,
    this.followUp,
  });
}

const Map<ReactionType, ReactionRule> kReactionRules = {
  ReactionType.burn: ReactionRule(
    type: ReactionType.burn,
    primary: BubbleType.red,
    target: BubbleType.green,
    followUp: ReactionType.bloom,
  ),
  ReactionType.steam: ReactionRule(
    type: ReactionType.steam,
    primary: BubbleType.blue,
    target: BubbleType.red,
    opensBoardLocks: true,
    followUp: ReactionType.burn,
  ),
  ReactionType.mud: ReactionRule(
    type: ReactionType.mud,
    primary: BubbleType.yellow,
    target: BubbleType.blue,
    followUp: ReactionType.steam,
  ),
  ReactionType.bloom: ReactionRule(
    type: ReactionType.bloom,
    primary: BubbleType.green,
    target: BubbleType.yellow,
    followUp: ReactionType.mud,
  ),
};

class ElementalReactionResult {
  final ReactionType type;
  final List<BubbleComponent> primaryPopped;
  final List<BubbleComponent> reactionAffected;
  final List<BubbleComponent> damagedStones;
  final int bonusScore;
  final String label;

  const ElementalReactionResult({
    required this.type,
    required this.primaryPopped,
    required this.reactionAffected,
    required this.damagedStones,
    required this.bonusScore,
    required this.label,
  });

  bool get isEmpty => reactionAffected.isEmpty && damagedStones.isEmpty;
  int get totalAffected =>
      primaryPopped.length + reactionAffected.length + damagedStones.length;
}

/// Resolves elemental effects in row/column order; effects are bounded and
/// target bubbles are removed only after the full cascade has been planned.
class ElementalReactionEngine {
  static const int maxChainReactions = 3;

  static ReactionType? detectReaction(BubbleType primaryType) {
    for (final rule in kReactionRules.values) {
      if (rule.primary == primaryType) return rule.type;
    }
    return null;
  }

  static ElementalReactionResult? process({
    required BubbleGrid grid,
    required List<BubbleComponent> matchedGroup,
    required BubbleType primaryType,
    double powerMultiplier = 1.0,
  }) {
    final results = resolveChain(
      grid: grid,
      matchedGroup: matchedGroup,
      primaryType: primaryType,
      powerMultiplier: powerMultiplier,
      maxReactions: 1,
    );
    return results.isEmpty ? null : results.first;
  }

  static List<ElementalReactionResult> resolveChain({
    required BubbleGrid grid,
    required List<BubbleComponent> matchedGroup,
    required BubbleType primaryType,
    double powerMultiplier = 1.0,
    int maxReactions = maxChainReactions,
  }) {
    final firstType = detectReaction(primaryType);
    if (firstType == null ||
        !powerMultiplier.isFinite ||
        powerMultiplier <= 0 ||
        matchedGroup.toSet().length < kReactionRules[firstType]!.minimumMatch ||
        maxReactions <= 0 ||
        maxReactions > maxChainReactions ||
        matchedGroup.any(
          (bubble) =>
              (bubble.type != primaryType &&
                  bubble.type != BubbleType.rainbow) ||
              grid.at(bubble.row, bubble.col) != bubble,
        )) {
      return const [];
    }

    final effectivePower = powerMultiplier.clamp(0.5, 2.0);
    final results = <ElementalReactionResult>[];
    final consumed = <BubbleComponent>{...matchedGroup};
    final pendingRemoval = <BubbleComponent>{};
    final hitStones = <BubbleComponent>{};
    final triggered = <ReactionType>{};
    var sources = List<BubbleComponent>.of(matchedGroup);
    var type = firstType;

    while (results.length < maxReactions && triggered.add(type)) {
      final rule = kReactionRules[type]!;
      final targetCandidates = <BubbleComponent>{};
      final stoneCandidates = <BubbleComponent>{};
      final orderedSources = List<BubbleComponent>.of(sources)
        ..sort(_compareBubbles);

      for (final source in orderedSources) {
        for (final cell in grid.neighbors(source.row, source.col)) {
          final neighbor = grid.at(cell.row, cell.col);
          if (neighbor == null || consumed.contains(neighbor)) continue;
          if (neighbor.type == rule.target) {
            targetCandidates.add(neighbor);
          } else if (rule.damagesAdjacentStone &&
              neighbor.type == BubbleType.stone &&
              !hitStones.contains(neighbor)) {
            stoneCandidates.add(neighbor);
          }
        }
      }

      if (rule.opensBoardLocks) {
        for (var row = 0; row < grid.rowCount; row++) {
          for (var col = 0; col < grid.cols; col++) {
            final bubble = grid.at(row, col);
            if (bubble?.type == BubbleType.locked &&
                !consumed.contains(bubble)) {
              targetCandidates.add(bubble!);
            }
          }
        }
      }

      final targetLimit = (rule.baseTargetLimit * effectivePower).ceil().clamp(
        1,
        6,
      );
      final targets = targetCandidates.toList()..sort(_compareBubbles);
      final affected = targets.take(targetLimit).toList(growable: false);
      final damaged = <BubbleComponent>[];
      final broken = <BubbleComponent>[];
      final stones = stoneCandidates.toList()..sort(_compareBubbles);
      for (final stone in stones) {
        hitStones.add(stone);
        stone.hits -= 1;
        if (stone.hits <= 0) {
          broken.add(stone);
        } else {
          damaged.add(stone);
        }
      }

      if (affected.isEmpty && damaged.isEmpty && broken.isEmpty) break;

      for (final bubble in affected) {
        consumed.add(bubble);
        pendingRemoval.add(bubble);
      }
      for (final stone in broken) {
        consumed.add(stone);
        pendingRemoval.add(stone);
      }

      final allAffected = [...affected, ...broken];
      results.add(
        ElementalReactionResult(
          type: type,
          primaryPopped: List.unmodifiable(orderedSources),
          reactionAffected: List.unmodifiable(allAffected),
          damagedStones: List.unmodifiable(damaged),
          bonusScore: (allAffected.length * 50 * effectivePower).round(),
          label: type.label,
        ),
      );

      final followUp = rule.followUp;
      if (followUp == null ||
          results.length >= maxReactions ||
          triggered.contains(followUp)) {
        break;
      }
      final nextRule = kReactionRules[followUp]!;
      sources = affected
          .where((bubble) => bubble.type == nextRule.primary)
          .toList(growable: false);
      if (sources.length < nextRule.minimumFollowUpSources) break;
      type = followUp;
    }

    for (final bubble in pendingRemoval) {
      grid.remove(bubble.row, bubble.col);
    }
    return List.unmodifiable(results);
  }

  static int _compareBubbles(BubbleComponent a, BubbleComponent b) {
    final rowOrder = a.row.compareTo(b.row);
    return rowOrder != 0 ? rowOrder : a.col.compareTo(b.col);
  }
}
