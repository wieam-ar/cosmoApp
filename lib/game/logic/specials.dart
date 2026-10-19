import '../../config/bubble_types.dart';
import '../components/bubble_component.dart';
import '../grid.dart';

class SpecialResolution {
  final List<BubbleComponent> removed;
  final List<BubbleComponent> damaged;

  const SpecialResolution({this.removed = const [], this.damaged = const []});

  bool get isEmpty => removed.isEmpty && damaged.isEmpty;
}

class SpecialBubbleLogic {
  static SpecialResolution hit(BubbleGrid grid, BubbleComponent bubble) {
    if (bubble.type == BubbleType.stone) {
      bubble.hits -= 1;
      if (bubble.hits > 0) return SpecialResolution(damaged: [bubble]);
      grid.remove(bubble.row, bubble.col);
      return SpecialResolution(removed: [bubble]);
    }
    if (bubble.type == BubbleType.bomb) {
      return explode(grid, bubble.position.x, bubble.position.y);
    }
    return const SpecialResolution();
  }

  static SpecialResolution damageAdjacentStones(
    BubbleGrid grid,
    Iterable<BubbleComponent> popped,
  ) {
    final damageTargets = <int, BubbleComponent>{};
    for (final bubble in popped) {
      for (final cell in grid.neighbors(bubble.row, bubble.col)) {
        final neighbor = grid.at(cell.row, cell.col);
        if (neighbor?.type == BubbleType.stone) {
          damageTargets[cell.row * grid.cols + cell.col] = neighbor!;
        }
      }
    }
    final removed = <BubbleComponent>[];
    final damaged = <BubbleComponent>[];
    for (final stone in damageTargets.values) {
      final result = hit(grid, stone);
      removed.addAll(result.removed);
      damaged.addAll(result.damaged);
    }
    return SpecialResolution(removed: removed, damaged: damaged);
  }

  static SpecialResolution explode(
    BubbleGrid grid,
    double x,
    double y, {
    int hexRadius = 2,
  }) {
    final center = grid.xyToCell(x, y, allowOccupied: true);
    if (center == null) return const SpecialResolution();
    final removed = <BubbleComponent>[];
    for (var row = 0; row < grid.rowCount; row++) {
      for (var col = 0; col < grid.cols; col++) {
        final bubble = grid.at(row, col);
        if (bubble == null) continue;
        if (_hexDistance(center.row, center.col, row, col) <= hexRadius) {
          grid.remove(row, col);
          removed.add(bubble);
        }
      }
    }
    return SpecialResolution(removed: removed);
  }

  static List<BubbleComponent> openLocks(BubbleGrid grid) {
    final opened = <BubbleComponent>[];
    for (var row = 0; row < grid.rowCount; row++) {
      for (var col = 0; col < grid.cols; col++) {
        final bubble = grid.at(row, col);
        if (bubble?.type != BubbleType.locked) continue;
        grid.remove(row, col);
        opened.add(bubble!);
      }
    }
    return opened;
  }

  static int _hexDistance(int rowA, int colA, int rowB, int colB) {
    final qA = colA - (rowA - (rowA & 1)) ~/ 2;
    final qB = colB - (rowB - (rowB & 1)) ~/ 2;
    final xA = qA;
    final zA = rowA;
    final yA = -xA - zA;
    final xB = qB;
    final zB = rowB;
    final yB = -xB - zB;
    return ((xA - xB).abs() + (yA - yB).abs() + (zA - zB).abs()) ~/ 2;
  }
}
