import '../../config/bubble_types.dart';
import '../components/bubble_component.dart';
import '../grid.dart';
import 'elemental_reaction.dart';

class MatchResolution {
  final List<BubbleComponent> popped;
  final List<BubbleComponent> dropped;
  final List<BubbleComponent> synergyPopped;
  final List<BubbleComponent> stoneDamage;
  final String? synergy;
  final ElementalReactionResult? reactionResult;
  final List<ElementalReactionResult> reactionResults;

  const MatchResolution({
    required this.popped,
    required this.dropped,
    this.synergyPopped = const [],
    this.stoneDamage = const [],
    this.synergy,
    this.reactionResult,
    this.reactionResults = const [],
  });

  int get rescued =>
      _rescueCount(popped) +
      _rescueCount(dropped) +
      _rescueCount(synergyPopped);

  int get combo => popped.length + dropped.length + synergyPopped.length;

  int get bonusScore {
    var score = synergyPopped.length * 20;
    if (reactionResults.isNotEmpty) {
      score += reactionResults.fold(
        0,
        (sum, reaction) => sum + reaction.bonusScore,
      );
    } else if (reactionResult != null) {
      score += reactionResult!.bonusScore;
    }
    return score;
  }
}

class BubbleMatcher {
  static MatchResolution resolve(
    BubbleGrid grid,
    int row,
    int col, {
    double powerMultiplier = 1.0,
  }) {
    final first = grid.at(row, col);
    if (first == null || !(kBubbleStyles[first.type]?.isMatchable ?? false)) {
      return const MatchResolution(popped: [], dropped: []);
    }

    final targetType = first.type == BubbleType.rainbow
        ? _bestNeighborType(grid, row, col)
        : first.type;
    if (targetType == null) {
      return const MatchResolution(popped: [], dropped: []);
    }

    final group = _floodMatchGroup(grid, row, col, targetType);
    if (group.length < 3) {
      return const MatchResolution(popped: [], dropped: []);
    }

    final adjacentStones = <int, BubbleComponent>{};
    for (final bubble in group) {
      for (final cell in grid.neighbors(bubble.row, bubble.col)) {
        final neighbor = grid.at(cell.row, cell.col);
        if (neighbor?.type == BubbleType.stone) {
          adjacentStones[cell.row * grid.cols + cell.col] = neighbor!;
        }
      }
    }

    // Process elemental reaction via ElementalReactionEngine
    final reactionResults = ElementalReactionEngine.resolveChain(
      grid: grid,
      matchedGroup: group,
      primaryType: targetType,
      powerMultiplier: powerMultiplier,
    );

    final synergyGroup = <BubbleComponent>{
      for (final reaction in reactionResults) ...reaction.reactionAffected,
    }.toList(growable: false);
    final reactionStones = <BubbleComponent>{
      for (final reaction in reactionResults) ...reaction.damagedStones,
      for (final reaction in reactionResults)
        ...reaction.reactionAffected.where(
          (bubble) => bubble.type == BubbleType.stone,
        ),
    };
    final damagedStones = <BubbleComponent>{
      ...adjacentStones.values.where(
        (stone) => !reactionStones.contains(stone),
      ),
    }.toList(growable: false);

    for (final bubble in [...group, ...synergyGroup]) {
      grid.remove(bubble.row, bubble.col);
    }

    final dropped = dropOrphans(grid);

    final reactionResult = reactionResults.isEmpty
        ? null
        : reactionResults.first;
    final synergyLabel =
        reactionResult?.label ??
        (synergyGroup.isNotEmpty ? _synergyLabel(targetType) : null);

    return MatchResolution(
      popped: group,
      dropped: dropped,
      synergyPopped: synergyGroup,
      stoneDamage: damagedStones,
      synergy: synergyLabel,
      reactionResult: reactionResult,
      reactionResults: reactionResults,
    );
  }

  static List<BubbleComponent> dropOrphans(BubbleGrid grid) {
    if (grid.rowCount == 0) return const [];
    final connected = <int>{};
    final queue = <GridCell>[];
    for (var column = 0; column < grid.cols; column++) {
      if (grid.at(0, column) != null) {
        queue.add(GridCell(0, column));
        connected.add(column);
      }
    }
    for (var index = 0; index < queue.length; index++) {
      final cell = queue[index];
      for (final next in grid.neighbors(cell.row, cell.col)) {
        final key = next.row * grid.cols + next.col;
        if (grid.at(next.row, next.col) != null && connected.add(key)) {
          queue.add(next);
        }
      }
    }
    final dropped = <BubbleComponent>[];
    for (var row = 0; row < grid.rowCount; row++) {
      for (var col = 0; col < grid.cols; col++) {
        final bubble = grid.at(row, col);
        if (bubble == null || connected.contains(row * grid.cols + col)) {
          continue;
        }
        grid.remove(row, col);
        dropped.add(bubble);
      }
    }
    return dropped;
  }

  static List<BubbleComponent> _floodMatchGroup(
    BubbleGrid grid,
    int row,
    int col,
    BubbleType targetType,
  ) {
    final group = <BubbleComponent>[];
    final visited = <int>{row * grid.cols + col};
    final queue = <GridCell>[GridCell(row, col)];
    for (var index = 0; index < queue.length; index++) {
      final cell = queue[index];
      final bubble = grid.at(cell.row, cell.col);
      if (bubble == null ||
          (bubble.type != targetType && bubble.type != BubbleType.rainbow)) {
        continue;
      }
      group.add(bubble);
      for (final next in grid.neighbors(cell.row, cell.col)) {
        final key = next.row * grid.cols + next.col;
        final nextType = grid.at(next.row, next.col)?.type;
        if (nextType != null &&
            (nextType == targetType || nextType == BubbleType.rainbow) &&
            visited.add(key)) {
          queue.add(next);
        }
      }
    }
    return group;
  }

  static BubbleType? _bestNeighborType(BubbleGrid grid, int row, int col) {
    BubbleType? best;
    var bestSize = 0;
    final tried = <BubbleType>{};
    for (final cell in grid.neighbors(row, col)) {
      final type = grid.at(cell.row, cell.col)?.type;
      if (type == null ||
          !kNormalBubbleTypes.contains(type) ||
          !tried.add(type)) {
        continue;
      }
      final size = _floodMatchGroup(grid, row, col, type).length;
      if (size > bestSize) {
        best = type;
        bestSize = size;
      }
    }
    return best;
  }

  static String _synergyLabel(BubbleType source) => switch (source) {
    BubbleType.red => 'BURN!',
    BubbleType.blue => 'STEAM!',
    BubbleType.yellow => 'MUD!',
    BubbleType.green => 'BLOOM!',
    _ => '',
  };
}

int _rescueCount(List<BubbleComponent> bubbles) {
  var count = 0;
  for (final bubble in bubbles) {
    if (bubble.isCat) count++;
  }
  return count;
}
