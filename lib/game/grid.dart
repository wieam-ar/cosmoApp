import 'dart:math';
import 'dart:ui';

import 'components/bubble_component.dart';
import '../config/bubble_types.dart';

class GridCell {
  final int row;
  final int col;

  const GridCell(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is GridCell && row == other.row && col == other.col;

  @override
  int get hashCode => Object.hash(row, col);
}

class BubbleGrid {
  final int cols;
  final double radius;
  final double top;
  final double width;
  final List<List<BubbleComponent?>> cells = [];

  BubbleGrid({required this.cols, required this.width, required this.top})
    : radius = width / (cols * 2 + 1);

  double get rowSpacing => radius * sqrt(3);
  int get rowCount => cells.length;
  int get lowestRow {
    for (var r = cells.length - 1; r >= 0; r--) {
      if (cells[r].any((bubble) => bubble != null)) return r;
    }
    return -1;
  }

  Offset cellToXY(int row, int col) {
    final firstCenter = (width - (cols * 2 - 1) * radius) / 2;
    return Offset(
      firstCenter + col * radius * 2 + (row.isOdd ? radius : 0),
      top + radius + row * rowSpacing,
    );
  }

  GridCell? xyToCell(double x, double y, {bool allowOccupied = false}) {
    if (cells.isEmpty) return const GridCell(0, 0);
    final approximateRow = ((y - top - radius) / rowSpacing).round();
    final minRow = max(0, approximateRow - 2);
    final maxRow = min(cells.length + 1, approximateRow + 2);
    var nearestDistance = double.infinity;
    GridCell? nearest;
    for (var row = minRow; row <= maxRow; row++) {
      for (var col = 0; col < cols; col++) {
        if (!allowOccupied && row < cells.length && cells[row][col] != null) {
          continue;
        }
        final point = cellToXY(row, col);
        final dx = x - point.dx;
        final dy = y - point.dy;
        final distance = dx * dx + dy * dy;
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearest = GridCell(row, col);
        }
      }
    }
    return nearest;
  }

  List<GridCell> neighbors(int row, int col) {
    final offset = row.isOdd ? 0 : -1;
    final candidates = <GridCell>[
      GridCell(row, col - 1),
      GridCell(row, col + 1),
      GridCell(row - 1, col + offset),
      GridCell(row - 1, col + offset + 1),
      GridCell(row + 1, col + offset),
      GridCell(row + 1, col + offset + 1),
    ];
    return candidates
        .where(
          (cell) =>
              cell.row >= 0 &&
              cell.row < cells.length &&
              cell.col >= 0 &&
              cell.col < cols,
        )
        .toList(growable: false);
  }

  void insert(int row, int col, BubbleComponent bubble) {
    if (row < 0 || row > cells.length || col < 0 || col >= cols) {
      throw RangeError('Invalid bubble cell ($row, $col).');
    }
    if (row == cells.length) {
      cells.add(List<BubbleComponent?>.filled(cols, null));
    }
    if (cells[row][col] != null) {
      throw StateError('Grid cell ($row, $col) is already occupied.');
    }
    cells[row][col] = bubble;
    bubble.setCell(row, col, cellToXY(row, col));
  }

  BubbleComponent? remove(int row, int col) {
    if (row < 0 || row >= cells.length || col < 0 || col >= cols) return null;
    final bubble = cells[row][col];
    cells[row][col] = null;
    if (bubble != null) {
      bubble.row = -1;
      bubble.col = -1;
    }
    return bubble;
  }

  void loadPattern(
    List<List<BubbleType?>> pattern,
    BubbleComponent Function(BubbleType type, int row, int col) createBubble,
  ) {
    cells
      ..clear()
      ..addAll(
        List.generate(
          pattern.length,
          (_) => List<BubbleComponent?>.filled(cols, null),
        ),
      );
    for (var row = 0; row < pattern.length; row++) {
      for (var col = 0; col < min(cols, pattern[row].length); col++) {
        final type = pattern[row][col];
        if (type == null) continue;
        cells[row][col] = createBubble(type, row, col);
      }
    }
  }

  void descendCeiling(
    List<BubbleType> types,
    Random random,
    BubbleComponent Function(BubbleType type, int row, int col) createBubble,
  ) {
    cells.insert(0, List<BubbleComponent?>.filled(cols, null));
    for (var col = 0; col < cols; col++) {
      final type = types[random.nextInt(types.length)];
      cells[0][col] = createBubble(type, 0, col);
    }
    for (var row = 1; row < cells.length; row++) {
      for (var col = 0; col < cols; col++) {
        cells[row][col]?.setCell(row, col, cellToXY(row, col));
      }
    }
  }

  int get activeBubbleCount => cells.fold(
    0,
    (sum, row) => sum + row.where((bubble) => bubble != null).length,
  );

  BubbleComponent? at(int row, int col) {
    if (row < 0 || row >= cells.length || col < 0 || col >= cols) return null;
    return cells[row][col];
  }
}
