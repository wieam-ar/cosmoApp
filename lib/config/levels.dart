import 'dart:math';

import 'bubble_types.dart';
import '../core/constants.dart';
import 'boss_config.dart';
import 'planet_config.dart';

enum GoalType { rescue, clear, score, timer, boss }

class Goal {
  final GoalType type;
  final int target;

  const Goal({required this.type, required this.target});
}

class LevelData {
  final int n;
  final int rows;
  final int cols;
  final List<List<BubbleType?>> pattern;
  final int colorsCount;
  final Goal goal;
  final int? moves;
  final int ceilingDropEvery;
  final List<int> starScores;
  final bool boss;
  final BossEncounterDefinition? bossEncounter;
  final PlanetDefinition? planet;
  final LavaPlanetRules lavaRules;

  const LevelData({
    required this.n,
    required this.rows,
    required this.cols,
    required this.pattern,
    required this.colorsCount,
    required this.goal,
    required this.moves,
    required this.ceilingDropEvery,
    required this.starScores,
    required this.boss,
    this.bossEncounter,
    this.planet,
    this.lavaRules = LavaPlanetRules.inactive,
  });
}

/// Returns the grid width for the selected bubble size.
int gridColsBySize(String bubbleSize) {
  switch (bubbleSize.toUpperCase()) {
    case 'S':
      return 10;
    case 'L':
      return 7;
    case 'M':
    default:
      return kGridCols;
  }
}

LevelData getLevel(int n, {String bubbleSize = 'M', int difficultyLevel = 1}) {
  if (n < 1 || n > 120) {
    throw RangeError.range(n, 1, 120, 'n');
  }
  if (difficultyLevel < 1 || difficultyLevel > 4) {
    throw RangeError.range(difficultyLevel, 1, 4, 'difficultyLevel');
  }
  assert(() {
    final sizeKey = bubbleSize.toUpperCase();
    if (!_validatedBubbleSizes.contains(sizeKey)) {
      validateLevels(bubbleSize: bubbleSize);
      _validatedBubbleSizes.add(sizeKey);
    }
    return true;
  }());
  return _buildLevel(n, bubbleSize, difficultyLevel: difficultyLevel);
}

final Set<String> _validatedBubbleSizes = {};

LevelData _buildLevel(int n, String bubbleSize, {int difficultyLevel = 1}) {
  final rng = Random(n * 7919);
  final cols = gridColsBySize(bubbleSize);
  final boss = n % 10 == 0;
  final rows = n <= 3
      ? 3 + n
      : boss
      ? 8
      : 4 + min(5, n ~/ 16).toInt();
  final baseColorsCount = n <= 2
      ? 3
      : n < 18
      ? 3 + ((n - 3) ~/ 6)
      : 5;
  final colorsCount = min(
    kNormalBubbleTypes.length,
    baseColorsCount + difficultyLevel - 1,
  );
  final ceilingDropEvery = max(3, 9 - n ~/ 18 - difficultyLevel + 1);
  final maskKind = (n - 1) % 7;
  final pattern = <List<BubbleType?>>[];

  for (var row = 0; row < rows; row++) {
    final cells = <BubbleType?>[];
    for (var col = 0; col < cols; col++) {
      final x = (col - (cols - 1) / 2).abs() / (cols / 2);
      final y = row / max(1, rows - 1);
      final included = switch (maskKind) {
        0 => x < 0.88 && (y < 0.45 || x > 0.30),
        1 => x < 0.95 - y * 0.55,
        2 => y < 0.28 || x > 0.2 + y * 0.7,
        3 => x < 0.95 - (y - 0.5).abs() * 1.5,
        4 => row % 2 == 0 || x < 0.72,
        5 => x < 0.84 && (row < 2 || row > rows - 3 || x > 0.45),
        _ => x < 0.78 || row == 0 || row == rows - 1,
      };
      if (!included) {
        cells.add(null);
        continue;
      }
      final color = kNormalBubbleTypes[rng.nextInt(colorsCount)];
      cells.add(color);
    }
    pattern.add(cells);
  }

  // Keep a deterministic matchable cluster in every generated board.
  final clusterColor = kNormalBubbleTypes[(n - 1) % colorsCount];
  for (var col = 0; col < min(3, cols); col++) {
    pattern[0][col] = clusterColor;
  }

  if (n >= 6) {
    final stoneCount = boss ? max(10, cols + 4) : max(1, n ~/ 12);
    _replaceCells(
      pattern,
      stoneCount,
      BubbleType.stone,
      rng,
      protectFirstRow: true,
    );
  }
  if (n >= 12) {
    _replaceCells(
      pattern,
      max(1, n ~/ 18),
      BubbleType.bomb,
      rng,
      protectFirstRow: true,
    );
  }
  if (n >= 15) {
    _replaceCells(
      pattern,
      max(1, n ~/ 30),
      BubbleType.rainbow,
      rng,
      protectFirstRow: true,
    );
  }
  if (n >= 20) {
    _replaceCells(pattern, 1, BubbleType.locked, rng, protectFirstRow: true);
    _replaceCells(pattern, 1, BubbleType.key, rng, protectFirstRow: true);
  }
  if (n >= 4 && n % 3 == 1) {
    final catTarget = min(3 + n ~/ 15, rows * cols);
    for (var col = 0; col < min(3, cols); col++) {
      pattern[0][col] = BubbleType.purple;
    }
    var catCount = pattern
        .expand((row) => row)
        .where((type) => type == BubbleType.purple)
        .length;
    for (var row = 1; row < rows && catCount < catTarget; row++) {
      for (var col = 0; col < cols && catCount < catTarget; col++) {
        if (kNormalBubbleTypes.contains(pattern[row][col]) &&
            pattern[row][col] != BubbleType.purple) {
          pattern[row][col] = BubbleType.purple;
          catCount++;
        }
      }
    }
  }

  final planet = PlanetRegistry.forLevel(n);
  var lavaRules = LavaPlanetRules.inactive;
  if (planet?.id == PlanetId.lava && n >= planet!.mechanicIntroductionLevel) {
    final seed = _selectLavaSeed(pattern, cols);
    if (seed != null) {
      pattern[seed.row][seed.col] = BubbleType.red;
      lavaRules = LavaPlanetRules(
        fireSpreadBudgetPerShot: n < 60 ? 1 : 2,
        initialFireCell: seed,
      );
    }
  }

  final available = pattern.expand((row) => row).whereType<BubbleType>().length;
  final goal = switch (n) {
    >= 4 when n % 3 == 1 => Goal(
      type: GoalType.rescue,
      target: min(
        3 + n ~/ 15,
        pattern
            .expand((row) => row)
            .where((type) => type == BubbleType.purple)
            .length,
      ),
    ),
    _ when n % 4 == 0 => Goal(type: GoalType.score, target: 1200 + n * 180),
    _ when n % 4 == 2 => Goal(
      type: GoalType.timer,
      target: max(45, 100 - n ~/ 2).toInt(),
    ),
    _ when n % 4 == 3 => Goal(type: GoalType.clear, target: available),
    _ => Goal(type: GoalType.clear, target: available),
  };

  final baseScore = 1000 + n * 240;
  final bossEncounter = n == 10 ? kVoidKingEncounter : null;
  return LevelData(
    n: n,
    rows: rows,
    cols: cols,
    pattern: pattern,
    colorsCount: colorsCount,
    goal: bossEncounter == null
        ? goal
        : Goal(type: GoalType.boss, target: bossEncounter.health),
    moves: max(
      8,
      (n <= 3 ? 30 - n * 3 : max(16, 34 - n ~/ 5).toInt()) +
          (1 - difficultyLevel) * 2,
    ),
    ceilingDropEvery: ceilingDropEvery,
    starScores: [
      baseScore,
      baseScore + 700 + n * 30,
      baseScore + 1500 + n * 50,
    ],
    boss: boss,
    bossEncounter: bossEncounter,
    planet: planet,
    lavaRules: lavaRules,
  );
}

PlanetCell? _selectLavaSeed(List<List<BubbleType?>> pattern, int cols) {
  final candidates = <PlanetCell>[];
  for (var row = 1; row < pattern.length; row++) {
    for (var col = 0; col < cols; col++) {
      final type = pattern[row][col];
      if (type != null &&
          type != BubbleType.purple &&
          kNormalBubbleTypes.contains(type)) {
        candidates.add(PlanetCell(row, col));
      }
    }
  }
  if (candidates.isEmpty) {
    for (var col = 3; col < cols; col++) {
      if (kNormalBubbleTypes.contains(pattern[0][col])) {
        candidates.add(PlanetCell(0, col));
      }
    }
  }
  if (candidates.isEmpty) {
    for (var row = 1; row < pattern.length; row++) {
      for (var col = 0; col < cols; col++) {
        if (pattern[row][col] == null) candidates.add(PlanetCell(row, col));
      }
    }
  }
  candidates.sort((a, b) {
    final center = cols / 2;
    final centerOrder = (a.col - center).abs().compareTo(
      (b.col - center).abs(),
    );
    if (centerOrder != 0) return centerOrder;
    final rowOrder = a.row.compareTo(b.row);
    return rowOrder != 0 ? rowOrder : a.col.compareTo(b.col);
  });
  return candidates.firstOrNull;
}

void _replaceCells(
  List<List<BubbleType?>> pattern,
  int count,
  BubbleType type,
  Random rng, {
  bool protectFirstRow = false,
}) {
  final candidates = <Point<int>>[];
  for (var row = protectFirstRow ? 1 : 0; row < pattern.length; row++) {
    for (var col = 0; col < pattern[row].length; col++) {
      if (kNormalBubbleTypes.contains(pattern[row][col])) {
        candidates.add(Point(row, col));
      }
    }
  }
  candidates.shuffle(rng);
  for (final point in candidates.take(count)) {
    pattern[point.x][point.y] = type;
  }
}

/// Checks generated levels across all supported grid widths.
void validateLevels({String bubbleSize = 'M'}) {
  final expectedCols = gridColsBySize(bubbleSize);
  for (var n = 1; n <= 120; n++) {
    final level = _buildLevel(n, bubbleSize);
    if (level.cols != expectedCols ||
        level.pattern.length != level.rows ||
        level.pattern.any((row) => row.length != expectedCols)) {
      throw StateError('Level $n has an invalid grid size for $bubbleSize.');
    }

    final available = level.pattern
        .expand((row) => row)
        .whereType<BubbleType>();
    final bubbles = available.toList();
    final matchable = <BubbleType, int>{};
    for (final bubble in available) {
      if (kBubbleStyles[bubble]?.isMatchable ?? false) {
        matchable.update(bubble, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    if (!matchable.values.any((count) => count >= 3)) {
      throw StateError('Level $n has no matchable group.');
    }
    if ((level.goal.type == GoalType.rescue ||
            level.goal.type == GoalType.clear) &&
        level.goal.target > available.length) {
      throw StateError('Level $n has an unreachable goal target.');
    }
    if (level.goal.type == GoalType.rescue &&
        bubbles.where((bubble) => bubble == BubbleType.purple).length <
            level.goal.target) {
      throw StateError('Level $n does not contain enough rescue cats.');
    }
    if (level.boss != (n % 10 == 0)) {
      throw StateError('Level $n has an invalid boss flag.');
    }
    if ((n >= 6) != bubbles.contains(BubbleType.stone) ||
        (n >= 12) != bubbles.contains(BubbleType.bomb) ||
        (n >= 15) != bubbles.contains(BubbleType.rainbow) ||
        (n >= 20) !=
            (bubbles.contains(BubbleType.locked) &&
                bubbles.contains(BubbleType.key))) {
      throw StateError(
        'Level $n has incorrect special-bubble unlocks: '
        'stone=${bubbles.contains(BubbleType.stone)}, '
        'bomb=${bubbles.contains(BubbleType.bomb)}, '
        'rainbow=${bubbles.contains(BubbleType.rainbow)}, '
        'locked=${bubbles.contains(BubbleType.locked)}, '
        'key=${bubbles.contains(BubbleType.key)}.',
      );
    }
    if (level.boss &&
        bubbles.where((bubble) => bubble == BubbleType.stone).length < 10) {
      throw StateError('Boss level $n needs a larger stone formation.');
    }
    if (n < PlanetRegistry.lava.mechanicIntroductionLevel &&
        level.lavaRules.fireSpreadBudgetPerShot != 0) {
      throw StateError(
        'Level $n introduces Lava Planet fire spread too early.',
      );
    }
    if (n >= PlanetRegistry.lava.mechanicIntroductionLevel &&
        (level.lavaRules.fireSpreadBudgetPerShot == 0 ||
            level.lavaRules.initialFireCell == null ||
            level.pattern[level.lavaRules.initialFireCell!.row][level
                    .lavaRules
                    .initialFireCell!
                    .col] !=
                BubbleType.red)) {
      throw StateError('Level $n is missing its deterministic Lava fire seed.');
    }
  }
}
