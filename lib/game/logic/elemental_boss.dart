import '../../config/boss_config.dart';
import '../../config/bubble_types.dart';
import '../components/bubble_component.dart';
import '../grid.dart';
import 'elemental_reaction.dart';

enum BossReactionOutcome {
  damaged,
  wrongWeakness,
  duplicateShot,
  defeated,
  alreadyDefeated,
}

class BossReactionResult {
  final BossReactionOutcome outcome;
  final int previousStage;
  final int currentStage;
  final BossWeakness? requiredWeakness;

  const BossReactionResult({
    required this.outcome,
    required this.previousStage,
    required this.currentStage,
    required this.requiredWeakness,
  });

  bool get didDamage =>
      outcome == BossReactionOutcome.damaged ||
      outcome == BossReactionOutcome.defeated;
}

class BossTurnResult {
  final BubbleComponent? hardenedBubble;
  final bool attackTriggered;
  final int turnsUntilAttack;

  const BossTurnResult({
    required this.hardenedBubble,
    required this.attackTriggered,
    required this.turnsUntilAttack,
  });
}

/// Deterministic boss state and bounded board attacks, independent of rendering.
class ElementalBossEncounter {
  final BossEncounterDefinition definition;
  int _stage = 0;
  int _turnsUntilAttack;
  int? _lastDamageShot;

  ElementalBossEncounter(this.definition)
    : _turnsUntilAttack = definition.attackEveryTurns {
    if (definition.phases.isEmpty) {
      throw ArgumentError.value(
        definition.phases,
        'phases',
        'Must not be empty.',
      );
    }
    if (definition.attackEveryTurns < 1) {
      throw RangeError.range(
        definition.attackEveryTurns,
        1,
        null,
        'attackEveryTurns',
      );
    }
  }

  int get stage => _stage;
  int get health => definition.health - _stage;
  int get maxHealth => definition.health;
  int get stagesCleared => _stage;
  bool get isDefeated => _stage >= definition.phases.length;
  int get turnsUntilAttack => _turnsUntilAttack;
  BossWeakness? get requiredWeakness =>
      isDefeated ? null : definition.phases[_stage].weakness;
  String get currentStageTitle =>
      isDefeated ? 'CORE EXPOSED' : definition.phases[_stage].title;
  String get telegraph => isDefeated
      ? 'THE VOID KING IS DEFEATED'
      : _turnsUntilAttack == 1
      ? 'VOID PULSE · NEXT SHOT'
      : 'VOID PULSE · $_turnsUntilAttack SHOTS';

  void reset() {
    _stage = 0;
    _turnsUntilAttack = definition.attackEveryTurns;
    _lastDamageShot = null;
  }

  BossReactionResult registerReaction(ReactionType type, int shotId) {
    final previous = _stage;
    if (isDefeated) {
      return _reactionResult(BossReactionOutcome.alreadyDefeated, previous);
    }
    if (_lastDamageShot == shotId) {
      return _reactionResult(BossReactionOutcome.duplicateShot, previous);
    }
    final weakness = switch (type) {
      ReactionType.burn => BossWeakness.burn,
      ReactionType.steam => BossWeakness.steam,
      ReactionType.mud => BossWeakness.mud,
      ReactionType.bloom => BossWeakness.bloom,
    };
    if (weakness != requiredWeakness) {
      return _reactionResult(BossReactionOutcome.wrongWeakness, previous);
    }
    _lastDamageShot = shotId;
    _stage++;
    return _reactionResult(
      isDefeated ? BossReactionOutcome.defeated : BossReactionOutcome.damaged,
      previous,
    );
  }

  BossReactionResult _reactionResult(
    BossReactionOutcome outcome,
    int previousStage,
  ) => BossReactionResult(
    outcome: outcome,
    previousStage: previousStage,
    currentStage: _stage,
    requiredWeakness: requiredWeakness,
  );

  /// Resolves one player turn. It can harden at most one ordinary grid bubble.
  BossTurnResult resolvePlayerTurn(BubbleGrid grid) {
    if (isDefeated) {
      return BossTurnResult(
        hardenedBubble: null,
        attackTriggered: false,
        turnsUntilAttack: _turnsUntilAttack,
      );
    }
    _turnsUntilAttack--;
    if (_turnsUntilAttack > 0) {
      return BossTurnResult(
        hardenedBubble: null,
        attackTriggered: false,
        turnsUntilAttack: _turnsUntilAttack,
      );
    }

    _turnsUntilAttack = definition.attackEveryTurns;
    final candidates = <BubbleComponent>[];
    for (var row = 0; row < grid.rowCount; row++) {
      for (var col = 0; col < grid.cols; col++) {
        final bubble = grid.at(row, col);
        if (bubble != null &&
            !bubble.fireSource &&
            bubble.type != BubbleType.purple &&
            kNormalBubbleTypes.contains(bubble.type)) {
          candidates.add(bubble);
        }
      }
    }
    candidates.sort((a, b) {
      final rowOrder = a.row.compareTo(b.row);
      return rowOrder != 0 ? rowOrder : a.col.compareTo(b.col);
    });
    if (candidates.isEmpty) {
      return BossTurnResult(
        hardenedBubble: null,
        attackTriggered: true,
        turnsUntilAttack: _turnsUntilAttack,
      );
    }

    final target = candidates.first;
    target
      ..type = BubbleType.stone
      ..hits = 2
      ..fireSource = false;
    return BossTurnResult(
      hardenedBubble: target,
      attackTriggered: true,
      turnsUntilAttack: _turnsUntilAttack,
    );
  }
}
