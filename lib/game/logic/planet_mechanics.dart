import '../../config/bubble_types.dart';
import '../components/bubble_component.dart';
import '../grid.dart';

/// One deterministic generation of fire spread on the hex grid.
class FireSpreadResult {
  final List<BubbleComponent> ignited;

  const FireSpreadResult(this.ignited);

  bool get changed => ignited.isNotEmpty;
}

class LavaPlanetMechanics {
  static const Set<BubbleType> eligibleFireTargets = {
    BubbleType.blue,
    BubbleType.green,
    BubbleType.yellow,
  };

  /// Each source contributes eligible adjacent cells. Candidates resolve by
  /// row/column, and newly ignited bubbles cannot propagate until a later shot.
  static FireSpreadResult spreadFire(BubbleGrid grid, {required int budget}) {
    if (budget <= 0 || grid.rowCount == 0) {
      return const FireSpreadResult([]);
    }

    final sources = <BubbleComponent>[];
    for (var row = 0; row < grid.rowCount; row++) {
      for (var col = 0; col < grid.cols; col++) {
        final bubble = grid.at(row, col);
        if (bubble?.fireSource == true && bubble?.type == BubbleType.red) {
          sources.add(bubble!);
        }
      }
    }

    final candidates = <BubbleComponent>{};
    for (final source in sources) {
      for (final cell in grid.neighbors(source.row, source.col)) {
        final neighbor = grid.at(cell.row, cell.col);
        if (neighbor != null &&
            !neighbor.fireSource &&
            eligibleFireTargets.contains(neighbor.type)) {
          candidates.add(neighbor);
        }
      }
    }

    final ordered = candidates.toList()
      ..sort((a, b) {
        final rowOrder = a.row.compareTo(b.row);
        return rowOrder != 0 ? rowOrder : a.col.compareTo(b.col);
      });
    final ignited = ordered.take(budget).toList(growable: false);
    for (final bubble in ignited) {
      bubble
        ..type = BubbleType.red
        ..hits = 1
        ..fireSource = true;
    }
    return FireSpreadResult(List.unmodifiable(ignited));
  }
}
