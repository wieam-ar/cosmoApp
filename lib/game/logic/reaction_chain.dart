import '../components/bubble_component.dart';
import 'elemental_reaction.dart';

class ReactionChainEvent {
  final ReactionType type;
  final int chainCount;
  final double scoreMultiplier;
  final String label;
  final String? combinationId;

  const ReactionChainEvent({
    required this.type,
    required this.chainCount,
    required this.scoreMultiplier,
    required this.label,
    required this.combinationId,
  });

  int scaleReactionScore(int baseScore) =>
      (baseScore * scoreMultiplier).round();
}

/// Tracks one shot's bounded reaction sequence and its unique affected bubbles.
class ReactionChainState {
  static const int maxChainLength = 3;

  int currentChain = 0;
  int totalReactionsTriggered = 0;
  double comboScoreMultiplier = 1.0;
  String? lastReactionLabel;
  ReactionType? _lastType;
  final Set<ReactionType> _seenTypes = {};
  final Set<BubbleComponent> _scoredBubbles = {};

  void beginShot() => reset();

  void reset() {
    currentChain = 0;
    totalReactionsTriggered = 0;
    comboScoreMultiplier = 1.0;
    lastReactionLabel = null;
    _lastType = null;
    _seenTypes.clear();
    _scoredBubbles.clear();
  }

  ReactionChainEvent? registerReaction(
    ReactionType type, {
    Iterable<BubbleComponent> affected = const [],
  }) {
    final uniqueAffected = affected.toSet();
    if (currentChain >= maxChainLength ||
        _seenTypes.contains(type) ||
        uniqueAffected.any(_scoredBubbles.contains)) {
      return null;
    }
    final combinationId = _lastType == null
        ? null
        : _combinationId(_lastType!, type);
    if (currentChain > 0 && combinationId == null) return null;
    _seenTypes.add(type);
    _scoredBubbles.addAll(uniqueAffected);

    currentChain++;
    totalReactionsTriggered++;
    comboScoreMultiplier = calculateMultiplier(currentChain);
    lastReactionLabel = getChainLabel(currentChain, type);
    final event = ReactionChainEvent(
      type: type,
      chainCount: currentChain,
      scoreMultiplier: comboScoreMultiplier,
      label: lastReactionLabel!,
      combinationId: combinationId,
    );
    _lastType = type;
    return event;
  }

  static double calculateMultiplier(int chainCount) {
    if (chainCount <= 1) return 1.0;
    if (chainCount == 2) return 2.0;
    return 3.0;
  }

  static String getChainLabel(int chainCount, ReactionType type) {
    if (chainCount <= 1) return type.label;
    if (chainCount == 2) return 'DOUBLE ${type.label} x2!';
    return 'TRIPLE ${type.label} x3!';
  }

  static String? _combinationId(ReactionType previous, ReactionType next) {
    final valid = switch ((previous, next)) {
      (ReactionType.burn, ReactionType.bloom) ||
      (ReactionType.bloom, ReactionType.mud) ||
      (ReactionType.mud, ReactionType.steam) ||
      (ReactionType.steam, ReactionType.burn) => true,
      _ => false,
    };
    return valid ? 'chain_${previous.name}_${next.name}' : null;
  }

  int calculateCatSkillCharge({
    required int baseMatchSize,
    bool hadReaction = false,
  }) {
    var charge = baseMatchSize * 10;
    if (hadReaction) charge += 25;
    if (currentChain > 1) charge += (currentChain - 1) * 20;
    return charge;
  }
}
