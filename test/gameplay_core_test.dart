import 'package:bubble_it/config/bubble_types.dart';
import 'package:bubble_it/config/levels.dart';
import 'package:bubble_it/game/components/bubble_component.dart';
import 'package:bubble_it/game/grid.dart';
import 'package:bubble_it/game/cosmo_game.dart';
import 'package:bubble_it/game/logic/matcher.dart';
import 'package:bubble_it/game/logic/specials.dart';
import 'package:bubble_it/screens/game_screen.dart';
import 'package:bubble_it/screens/catalog_screen.dart';
import 'package:bubble_it/screens/codex_screen.dart';
import 'package:bubble_it/screens/level_map_screen.dart';
import 'package:bubble_it/core/save_service.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('all procedural levels validate at every supported grid width', () {
    for (final size in ['S', 'M', 'L']) {
      validateLevels(bubbleSize: size);
      for (var n = 1; n <= 120; n++) {
        final data = getLevel(n, bubbleSize: size);
        expect(data.cols, gridColsBySize(size));
        expect(data.pattern, hasLength(data.rows));
        expect(data.boss, n % 10 == 0);
        expect(data.bossEncounter != null, n == 10);
        expect(data.goal.type, n == 10 ? GoalType.boss : isNot(GoalType.boss));
      }
    }
  });

  test('difficulty changes level board variety and pressure without losing a match', () {
    final easy = getLevel(1, difficultyLevel: 1);
    final hard = getLevel(1, difficultyLevel: 4);

    expect(hard.colorsCount, greaterThan(easy.colorsCount));
    expect(hard.moves!, lessThan(easy.moves!));
    expect(hard.ceilingDropEvery, lessThan(easy.ceilingDropEvery));
    expect(easy.pattern.first.take(3).toSet(), hasLength(1));
    expect(hard.pattern.first.take(3).toSet(), hasLength(1));
  });

  test('bubble size options match their actual grid column counts', () {
    expect(gridColsBySize('S'), 10);
    expect(gridColsBySize('M'), 8);
    expect(gridColsBySize('L'), 7);
  });

  test(
    'hex grid reports adjacent cells and drops ceiling orphans after a match',
    () {
      final grid = BubbleGrid(cols: 8, width: 720, top: 150);
      BubbleComponent add(int row, int col, BubbleType type) {
        final point = grid.cellToXY(row, col);
        final bubble = BubbleComponent(radius: grid.radius)
          ..configure(
            bubbleType: type,
            center: Vector2(point.dx, point.dy),
            bubbleRadius: grid.radius,
          );
        grid.insert(row, col, bubble);
        return bubble;
      }

      final ceiling = add(0, 0, BubbleType.red);
      final matched = [
        add(1, 0, BubbleType.blue),
        add(1, 1, BubbleType.blue),
        add(1, 2, BubbleType.blue),
      ];
      final orphan = add(2, 6, BubbleType.purple);
      expect(grid.neighbors(1, 0), contains(const GridCell(0, 0)));

      final result = BubbleMatcher.resolve(grid, 1, 1);
      expect(result.popped, containsAll(matched));
      expect(result.dropped, contains(orphan));
      expect(result.rescued, 1);
      expect(result.synergy, 'STEAM!');
      expect(result.synergyPopped, contains(ceiling));
      expect(grid.at(0, 0), isNull);
    },
  );

  test('fire synergy removes up to two adjacent nature bubbles', () {
    final grid = BubbleGrid(cols: 8, width: 720, top: 150);
    grid.cells.addAll(
      List.generate(2, (_) => List<BubbleComponent?>.filled(grid.cols, null)),
    );
    BubbleComponent add(int row, int col, BubbleType type) {
      final point = grid.cellToXY(row, col);
      final bubble = BubbleComponent(radius: grid.radius)
        ..configure(
          bubbleType: type,
          center: Vector2(point.dx, point.dy),
          bubbleRadius: grid.radius,
        );
      grid.insert(row, col, bubble);
      return bubble;
    }

    add(1, 1, BubbleType.red);
    add(1, 2, BubbleType.red);
    add(1, 3, BubbleType.red);
    final nature = [
      add(0, 1, BubbleType.green),
      add(0, 2, BubbleType.green),
      add(0, 3, BubbleType.green),
    ];

    final result = BubbleMatcher.resolve(grid, 1, 2);
    expect(result.synergy, 'BURN!');
    expect(result.synergyPopped, hasLength(2));
    expect(nature.where((bubble) => bubble.row == -1), hasLength(2));
  });

  test('stone takes two hits and bomb explosion has a two-cell radius', () {
    final grid = BubbleGrid(cols: 8, width: 720, top: 150);
    grid.cells.addAll(
      List.generate(6, (_) => List<BubbleComponent?>.filled(grid.cols, null)),
    );
    BubbleComponent add(int row, int col, BubbleType type) {
      final point = grid.cellToXY(row, col);
      final bubble = BubbleComponent(radius: grid.radius)
        ..configure(
          bubbleType: type,
          center: Vector2(point.dx, point.dy),
          bubbleRadius: grid.radius,
        );
      grid.insert(row, col, bubble);
      return bubble;
    }

    final stone = add(0, 0, BubbleType.stone);
    expect(SpecialBubbleLogic.hit(grid, stone).damaged, contains(stone));
    expect(grid.at(0, 0), same(stone));
    expect(SpecialBubbleLogic.hit(grid, stone).removed, contains(stone));
    expect(grid.at(0, 0), isNull);

    final bomb = add(1, 2, BubbleType.bomb);
    final nearby = add(2, 2, BubbleType.blue);
    final distant = add(5, 7, BubbleType.yellow);
    final blast = SpecialBubbleLogic.hit(grid, bomb);
    expect(blast.removed, containsAll([bomb, nearby]));
    expect(blast.removed, isNot(contains(distant)));
    expect(grid.at(5, 7), same(distant));
  });

  test('a popped key opens locked bubbles', () {
    final grid = BubbleGrid(cols: 8, width: 720, top: 150);
    final point = grid.cellToXY(0, 0);
    final locked = BubbleComponent(radius: grid.radius)
      ..configure(
        bubbleType: BubbleType.locked,
        center: Vector2(point.dx, point.dy),
        bubbleRadius: grid.radius,
      );
    grid.insert(0, 0, locked);
    final opened = SpecialBubbleLogic.openLocks(grid);
    expect(opened, contains(locked));
    expect(grid.at(0, 0), isNull);
  });

  testWidgets('game screen loads Flame scene and HUD', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('BOMB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cat collection renders owned starters and locked companions', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await SaveService.I.load();
    await tester.pumpWidget(const MaterialApp(home: CatalogScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('CAT-ALOG'), findsOneWidget);
    expect(find.text('5/24'), findsOneWidget);
    expect(find.text('Comet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lava Planet map banner fits a compact mobile screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await SaveService.I.load();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LevelMapScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('LAVA PLANET'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'opening Codex does not discover reactions and clues stay partial',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await SaveService.I.load();
      await tester.pumpWidget(const MaterialApp(home: CodexScreen()));
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.text('0/10'), findsOneWidget);
      expect(SaveService.I.discoveredReactions, isEmpty);
      expect(find.text('Unknown reaction'), findsWidgets);
      expect(
        find.text('A warm-colored match can consume nearby leaves.'),
        findsNothing,
      );

      await tester.tap(find.text('Inspect clue').first);
      await tester.pumpAndSettle();
      expect(
        find.text('A warm-colored match can consume nearby leaves.'),
        findsOneWidget,
      );
      expect(SaveService.I.discoveredReactions, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pause overlay renders over the active game', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen()));
    await tester.pump(const Duration(seconds: 1));
    final game = tester
        .widget<GameWidget<CosmoGame>>(find.byType(GameWidget<CosmoGame>))
        .game!;
    game.openPause();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('RESUME'), findsNWidgets(2));
    expect(find.text('RESTART'), findsNWidgets(2));
    expect(find.text('HOME'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'charged Fire Cat skill triggers one controlled BURN and cooldown',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await SaveService.I.load();
      SaveService.I.activeCatId = 2;
      await tester.pumpWidget(const MaterialApp(home: GameScreen()));
      await tester.pump(const Duration(seconds: 1));

      final game = tester
          .widget<GameWidget<CosmoGame>>(find.byType(GameWidget<CosmoGame>))
          .game!;
      game.grid.cells.clear();
      BubbleComponent addBubble(int row, int col, BubbleType type) {
        final point = game.grid.cellToXY(row, col);
        final bubble = game.obtainBubble(type, Vector2(point.dx, point.dy));
        game.grid.insert(row, col, bubble);
        return bubble;
      }

      addBubble(0, 1, BubbleType.red);
      addBubble(0, 2, BubbleType.red);
      addBubble(0, 3, BubbleType.red);
      addBubble(1, 1, BubbleType.green);
      addBubble(1, 2, BubbleType.green);

      game.catAbilityCharge = 100;
      expect(game.activateCatSkill(), isTrue);
      expect(game.grid.at(1, 1), isNull);
      expect(game.grid.at(1, 2), isNull);
      expect(game.catAbilityCharge, 0);
      expect(game.activateCatSkill(), isFalse);

      game.shotStarted();
      game.shotStarted();
      game.shotStarted();
      game.catAbilityCharge = 100;
      expect(game.activateCatSkill(), isFalse);
      expect(game.catAbilityCharge, 100);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'one player shot scores a bounded reaction chain and discoveries',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await SaveService.I.load();
      SaveService.I.activeCatId = 2;
      await tester.pumpWidget(const MaterialApp(home: GameScreen()));
      await tester.pump(const Duration(seconds: 1));

      final game = tester
          .widget<GameWidget<CosmoGame>>(find.byType(GameWidget<CosmoGame>))
          .game!;
      game.grid.cells
        ..clear()
        ..addAll(
          List.generate(
            4,
            (_) => List<BubbleComponent?>.filled(game.grid.cols, null),
          ),
        );
      BubbleComponent addBubble(int row, int col, BubbleType type) {
        final point = game.grid.cellToXY(row, col);
        final bubble = game.obtainBubble(type, Vector2(point.dx, point.dy));
        game.grid.insert(row, col, bubble);
        return bubble;
      }

      final reds = [
        addBubble(2, 1, BubbleType.red),
        addBubble(2, 2, BubbleType.red),
        addBubble(2, 3, BubbleType.red),
      ];
      addBubble(1, 1, BubbleType.green);
      addBubble(1, 2, BubbleType.green);
      addBubble(1, 3, BubbleType.green);
      addBubble(0, 1, BubbleType.yellow);
      addBubble(0, 2, BubbleType.yellow);
      addBubble(0, 3, BubbleType.yellow);
      addBubble(1, 0, BubbleType.blue);
      addBubble(0, 0, BubbleType.red);

      game.onBubbleLanded(reds[1]);

      expect(game.score, 580);
      expect(
        SaveService.I.discoveredReactions,
        containsAll([
          'reaction_burn',
          'chain_burn_bloom',
          'chain_bloom_mud',
          'chain_double',
          'chain_triple',
        ]),
      );
      expect(game.reactionChainState.currentChain, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'level 10 boss takes ordered reactions, saves victory, and restarts cleanly',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await SaveService.I.load();
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: GameScreen(level: 10)));
      await tester.pump(const Duration(seconds: 1));

      final game = tester
          .widget<GameWidget<CosmoGame>>(find.byType(GameWidget<CosmoGame>))
          .game!;
      expect(game.bossEncounter?.health, 4);
      expect(game.goal.goal.type, GoalType.boss);
      expect(find.text('THE VOID KING'), findsOneWidget);
      game.openPause();
      expect(game.bossEncounter?.health, 4);
      game.resumeFromPause();

      const weaknesses = [
        (BubbleType.red, BubbleType.green),
        (BubbleType.blue, BubbleType.red),
        (BubbleType.yellow, BubbleType.blue),
        (BubbleType.green, BubbleType.yellow),
      ];
      for (final (primary, target) in weaknesses) {
        game.grid.cells
          ..clear()
          ..addAll(
            List.generate(
              3,
              (_) => List<BubbleComponent?>.filled(game.grid.cols, null),
            ),
          );

        final matched = <BubbleComponent>[];
        for (var col = 1; col <= 3; col++) {
          final point = game.grid.cellToXY(1, col);
          final bubble = game.obtainBubble(
            primary,
            Vector2(point.dx, point.dy),
          );
          game.grid.insert(1, col, bubble);
          matched.add(bubble);
        }
        final targetPoint = game.grid.cellToXY(0, 1);
        final targetBubble = game.obtainBubble(
          target,
          Vector2(targetPoint.dx, targetPoint.dy),
        );
        game.grid.insert(0, 1, targetBubble);

        game.shotStarted();
        game.onBubbleLanded(matched[1]);
      }

      expect(game.bossEncounter?.health, 0);
      expect(game.goal.bossDefeated, isTrue);
      expect(game.didWin, isTrue);
      expect(SaveService.I.isBossDefeated('void_king'), isTrue);

      game.restart();
      expect(game.bossEncounter?.health, 4);
      expect(game.goal.bossDefeated, isFalse);
      expect(game.isFinished, isFalse);
      expect(SaveService.I.isBossDefeated('void_king'), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed boss attempt does not save a victory', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await SaveService.I.load();
    await tester.pumpWidget(const MaterialApp(home: GameScreen(level: 10)));
    await tester.pump(const Duration(seconds: 1));

    final game = tester
        .widget<GameWidget<CosmoGame>>(find.byType(GameWidget<CosmoGame>))
        .game!;
    game.goal.moves = game.goal.moveLimit;
    await tester.pump(const Duration(milliseconds: 32));

    expect(game.isFinished, isTrue);
    expect(game.didWin, isFalse);
    expect(SaveService.I.isBossDefeated('void_king'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('win result overlay renders and records a completed level', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen(level: 120)));
    await tester.pump(const Duration(seconds: 1));
    final game = tester
        .widget<GameWidget<CosmoGame>>(find.byType(GameWidget<CosmoGame>))
        .game!;
    game.goal.goal = const Goal(type: GoalType.score, target: 1);
    game.grid.cells.clear();
    final group = <BubbleComponent>[];
    for (var col = 0; col < 3; col++) {
      final point = game.grid.cellToXY(0, col);
      final bubble = BubbleComponent(radius: game.grid.radius)
        ..configure(
          bubbleType: BubbleType.red,
          center: Vector2(point.dx, point.dy),
          bubbleRadius: game.grid.radius,
        );
      game.grid.insert(0, col, bubble);
      group.add(bubble);
    }
    game.onBubbleLanded(group[1]);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('NEXT'), findsNWidgets(2));
    expect(find.text('SCORE  30'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
