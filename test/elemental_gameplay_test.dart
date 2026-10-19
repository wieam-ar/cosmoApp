import 'package:bubble_it/config/bubble_types.dart';
import 'package:bubble_it/config/boss_config.dart';
import 'package:bubble_it/config/planet_config.dart';
import 'package:bubble_it/config/levels.dart';
import 'package:bubble_it/core/constants.dart';
import 'package:bubble_it/core/save_service.dart';
import 'package:bubble_it/game/components/bubble_component.dart';
import 'package:bubble_it/game/grid.dart';
import 'package:bubble_it/game/logic/cat_crew.dart';
import 'package:bubble_it/game/logic/elemental_boss.dart';
import 'package:bubble_it/game/logic/elemental_reaction.dart';
import 'package:bubble_it/game/logic/elemental_codex.dart';
import 'package:bubble_it/game/logic/goals.dart';
import 'package:bubble_it/game/logic/matcher.dart';
import 'package:bubble_it/game/logic/planet_mechanics.dart';
import 'package:bubble_it/game/logic/reaction_chain.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Elemental Reaction Engine Tests', () {
    late BubbleGrid grid;

    setUp(() {
      grid = BubbleGrid(cols: 8, width: 720, top: 150);
      grid.cells.addAll(
        List.generate(4, (_) => List<BubbleComponent?>.filled(grid.cols, null)),
      );
    });

    BubbleComponent addBubble(int row, int col, BubbleType type) {
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

    test('BURN reaction triggers when Fire (Red) matches adjacent to Flora (Green)', () {
      addBubble(1, 1, BubbleType.red);
      addBubble(1, 2, BubbleType.red);
      addBubble(1, 3, BubbleType.red);
      final green1 = addBubble(0, 1, BubbleType.green);
      final green2 = addBubble(0, 2, BubbleType.green);

      final result = BubbleMatcher.resolve(grid, 1, 2);
      expect(result.reactionResult, isNotNull);
      expect(result.reactionResult!.type, ReactionType.burn);
      expect(result.synergy, 'BURN!');
      expect(
        result.reactionResult!.reactionAffected,
        containsAll([green1, green2]),
      );
    });

    test('STEAM reaction triggers when Water (Blue) matches adjacent to Fire (Red)', () {
      addBubble(1, 1, BubbleType.blue);
      addBubble(1, 2, BubbleType.blue);
      addBubble(1, 3, BubbleType.blue);
      final red1 = addBubble(0, 1, BubbleType.red);

      final result = BubbleMatcher.resolve(grid, 1, 2);
      expect(result.reactionResult, isNotNull);
      expect(result.reactionResult!.type, ReactionType.steam);
      expect(result.synergy, 'STEAM!');
      expect(result.reactionResult!.reactionAffected, contains(red1));
    });

    test('MUD reaction triggers when Earth (Yellow) matches adjacent to Water (Blue)', () {
      addBubble(1, 1, BubbleType.yellow);
      addBubble(1, 2, BubbleType.yellow);
      addBubble(1, 3, BubbleType.yellow);
      final blue1 = addBubble(0, 1, BubbleType.blue);

      final result = BubbleMatcher.resolve(grid, 1, 2);
      expect(result.reactionResult, isNotNull);
      expect(result.reactionResult!.type, ReactionType.mud);
      expect(result.synergy, 'MUD!');
      expect(result.reactionResult!.reactionAffected, contains(blue1));
    });

    test('BLOOM reaction triggers when Flora (Green) matches adjacent to Earth (Yellow)', () {
      addBubble(1, 1, BubbleType.green);
      addBubble(1, 2, BubbleType.green);
      addBubble(1, 3, BubbleType.green);
      final yellow1 = addBubble(0, 1, BubbleType.yellow);

      final result = BubbleMatcher.resolve(grid, 1, 2);
      expect(result.reactionResult, isNotNull);
      expect(result.reactionResult!.type, ReactionType.bloom);
      expect(result.synergy, 'BLOOM!');
      expect(result.reactionResult!.reactionAffected, contains(yellow1));
    });

    test('STEAM can clear board locks without an adjacent Fire bubble', () {
      addBubble(1, 1, BubbleType.blue);
      addBubble(1, 2, BubbleType.blue);
      addBubble(1, 3, BubbleType.blue);
      final lock = addBubble(0, 7, BubbleType.locked);

      final result = BubbleMatcher.resolve(grid, 1, 2);

      expect(result.reactionResult?.type, ReactionType.steam);
      expect(result.synergyPopped, contains(lock));
      expect(grid.at(0, 7), isNull);
    });

    test(
      'reaction prerequisites reject invalid matches without mutating grid',
      () {
        final red1 = addBubble(1, 1, BubbleType.red);
        final red2 = addBubble(1, 2, BubbleType.red);
        final green = addBubble(0, 1, BubbleType.green);
        final hitsBefore = green.hits;

        expect(
          ElementalReactionEngine.resolveChain(
            grid: grid,
            matchedGroup: [red1, red2, red1],
            primaryType: BubbleType.red,
          ),
          isEmpty,
        );
        expect(
          ElementalReactionEngine.process(
            grid: grid,
            matchedGroup: [red1, red2, addBubble(1, 3, BubbleType.blue)],
            primaryType: BubbleType.red,
          ),
          isNull,
        );
        expect(
          ElementalReactionEngine.resolveChain(
            grid: grid,
            matchedGroup: [red1, red2],
            primaryType: BubbleType.red,
            powerMultiplier: double.nan,
          ),
          isEmpty,
        );
        expect(grid.at(0, 1), same(green));
        expect(green.hits, hitsBefore);
      },
    );

    test('rainbow bubbles remain valid members of an elemental match', () {
      final reds = [
        addBubble(1, 1, BubbleType.red),
        addBubble(1, 2, BubbleType.rainbow),
        addBubble(1, 3, BubbleType.red),
      ];
      final green = addBubble(0, 1, BubbleType.green);

      final result = ElementalReactionEngine.process(
        grid: grid,
        matchedGroup: reds,
        primaryType: BubbleType.red,
      );

      expect(result?.type, ReactionType.burn);
      expect(result?.reactionAffected, contains(green));
    });

    test('one reaction damages each adjacent stone once', () {
      final reds = [
        addBubble(1, 1, BubbleType.red),
        addBubble(1, 2, BubbleType.red),
        addBubble(1, 3, BubbleType.red),
      ];
      final stone = addBubble(0, 1, BubbleType.stone);

      final result = ElementalReactionEngine.resolveChain(
        grid: grid,
        matchedGroup: reds,
        primaryType: BubbleType.red,
      );

      expect(result.single.damagedStones, [stone]);
      expect(stone.hits, 1);
      expect(grid.at(0, 1), same(stone));
    });

    test('reaction target selection is deterministic and respects caps', () {
      final reds = [
        addBubble(1, 1, BubbleType.red),
        addBubble(1, 2, BubbleType.red),
        addBubble(1, 3, BubbleType.red),
      ];
      final green1 = addBubble(0, 1, BubbleType.green);
      final green2 = addBubble(0, 2, BubbleType.green);
      final green3 = addBubble(0, 3, BubbleType.green);

      final result = ElementalReactionEngine.resolveChain(
        grid: grid,
        matchedGroup: reds,
        primaryType: BubbleType.red,
        maxReactions: 1,
      );

      expect(result, hasLength(1));
      expect(result.single.reactionAffected, [green1, green2]);
      expect(grid.at(0, 3), same(green3));
      expect(grid.at(0, 1), isNull);
      expect(grid.at(0, 2), isNull);
    });

    test(
      'one shot follows only valid elemental reactions and terminates at cap',
      () {
        final reds = [
          addBubble(2, 1, BubbleType.red),
          addBubble(2, 2, BubbleType.red),
          addBubble(2, 3, BubbleType.red),
        ];
        final greens = [
          addBubble(1, 1, BubbleType.green),
          addBubble(1, 2, BubbleType.green),
          addBubble(1, 3, BubbleType.green),
        ];
        final yellows = [
          addBubble(0, 1, BubbleType.yellow),
          addBubble(0, 2, BubbleType.yellow),
          addBubble(0, 3, BubbleType.yellow),
        ];
        final blue = addBubble(1, 0, BubbleType.blue);
        final redBeyondCap = addBubble(0, 0, BubbleType.red);

        final results = ElementalReactionEngine.resolveChain(
          grid: grid,
          matchedGroup: reds,
          primaryType: BubbleType.red,
          powerMultiplier: 1.5,
        );

        expect(results.map((result) => result.type), [
          ReactionType.burn,
          ReactionType.bloom,
          ReactionType.mud,
        ]);
        expect(results.fold(0, (sum, result) => sum + result.bonusScore), 525);
        expect(
          results.expand((result) => result.reactionAffected).toSet().length,
          7,
        );
        expect(grid.at(1, 0), isNull);
        expect(grid.at(0, 0), same(redBeyondCap));
        expect(yellows.every((bubble) => bubble.row == -1), isTrue);
        expect(greens.every((bubble) => bubble.row == -1), isTrue);
        expect(blue.row, -1);
      },
    );
  });

  group('Reaction Chain State Tests', () {
    test('Chain state accumulates combo multipliers and charge', () {
      final state = ReactionChainState();
      expect(state.currentChain, 0);
      expect(state.comboScoreMultiplier, 1.0);

      state.registerReaction(ReactionType.burn);
      expect(state.currentChain, 1);
      expect(state.comboScoreMultiplier, 1.0);

      state.registerReaction(ReactionType.bloom);
      expect(state.currentChain, 2);
      expect(state.comboScoreMultiplier, 2.0);
      expect(state.lastReactionLabel, contains('DOUBLE'));

      final charge = state.calculateCatSkillCharge(
        baseMatchSize: 4,
        hadReaction: true,
      );
      expect(charge, greaterThan(50));
    });

    test('shot chains reject duplicate reaction targets and reset cleanly', () {
      final state = ReactionChainState();
      final bubble = BubbleComponent();

      final first = state.registerReaction(
        ReactionType.burn,
        affected: [bubble],
      );
      expect(first?.scoreMultiplier, 1);
      expect(
        state.registerReaction(ReactionType.bloom, affected: [bubble]),
        isNull,
      );
      expect(state.registerReaction(ReactionType.burn, affected: []), isNull);
      final second = state.registerReaction(
        ReactionType.bloom,
        affected: [BubbleComponent()],
      );
      expect(second?.combinationId, 'chain_burn_bloom');
      expect(second?.scoreMultiplier, 2);
      expect(second?.scaleReactionScore(100), 200);
      expect(state.registerReaction(ReactionType.steam), isNull);
      expect(
        state
            .registerReaction(ReactionType.mud, affected: [BubbleComponent()])
            ?.scoreMultiplier,
        3,
      );
      expect(
        state.registerReaction(
          ReactionType.steam,
          affected: [BubbleComponent()],
        ),
        isNull,
      );

      state.reset();
      expect(state.currentChain, 0);
      expect(state.comboScoreMultiplier, 1);
    });
  });

  group('Elemental Boss Encounter Tests', () {
    test('ordered elemental weaknesses advance one shield per player shot', () {
      final boss = ElementalBossEncounter(kVoidKingEncounter);
      expect(boss.health, 4);
      expect(boss.requiredWeakness, BossWeakness.burn);

      final wrong = boss.registerReaction(ReactionType.steam, 1);
      expect(wrong.outcome, BossReactionOutcome.wrongWeakness);
      expect(boss.health, 4);

      final firstHit = boss.registerReaction(ReactionType.burn, 1);
      expect(firstHit.outcome, BossReactionOutcome.damaged);
      expect(boss.requiredWeakness, BossWeakness.steam);
      expect(
        boss.registerReaction(ReactionType.bloom, 1).outcome,
        BossReactionOutcome.duplicateShot,
      );
      expect(boss.health, 3);

      expect(
        boss.registerReaction(ReactionType.steam, 2).outcome,
        BossReactionOutcome.damaged,
      );
      expect(
        boss.registerReaction(ReactionType.mud, 3).outcome,
        BossReactionOutcome.damaged,
      );
      final finalHit = boss.registerReaction(ReactionType.bloom, 4);
      expect(finalHit.outcome, BossReactionOutcome.defeated);
      expect(boss.health, 0);
      expect(boss.requiredWeakness, isNull);
      expect(
        boss.registerReaction(ReactionType.bloom, 5).outcome,
        BossReactionOutcome.alreadyDefeated,
      );
    });

    test(
      'void pulse telegraphs and hardens one deterministic eligible bubble',
      () {
        final grid = BubbleGrid(cols: 8, width: 720, top: 150)
          ..cells.addAll(
            List.generate(2, (_) => List<BubbleComponent?>.filled(8, null)),
          );
        BubbleComponent add(int row, int col, BubbleType type) {
          final point = grid.cellToXY(row, col);
          final bubble = BubbleComponent(radius: grid.radius)
            ..configure(
              bubbleType: type,
              center: Vector2(point.dx, point.dy),
              bubbleRadius: grid.radius,
              rowIndex: row,
              columnIndex: col,
            );
          grid.insert(row, col, bubble);
          return bubble;
        }

        final first = add(0, 0, BubbleType.red);
        final second = add(0, 1, BubbleType.purple);
        final boss = ElementalBossEncounter(kVoidKingEncounter);

        final warning = boss.resolvePlayerTurn(grid);
        expect(warning.attackTriggered, isFalse);
        expect(warning.turnsUntilAttack, 1);
        expect(boss.telegraph, contains('NEXT SHOT'));

        final attack = boss.resolvePlayerTurn(grid);
        expect(attack.attackTriggered, isTrue);
        expect(attack.hardenedBubble, same(first));
        expect(first.type, BubbleType.stone);
        expect(first.hits, 2);
        expect(second.type, BubbleType.purple);
        expect(attack.turnsUntilAttack, 2);

        boss.registerReaction(ReactionType.burn, 1);
        boss.registerReaction(ReactionType.steam, 2);
        boss.registerReaction(ReactionType.mud, 3);
        boss.registerReaction(ReactionType.bloom, 4);
        expect(boss.resolvePlayerTurn(grid).attackTriggered, isFalse);
        expect(boss.resolvePlayerTurn(grid).attackTriggered, isFalse);
      },
    );

    test(
      'boss goal cannot be won by clearing bubbles and fails at move limit',
      () {
        final goal = GoalProgress(
          mode: GameMode.level,
          goal: const Goal(type: GoalType.boss, target: 4),
          moveLimit: 2,
          targetScore: 1000,
        );
        expect(goal.isWon, isFalse);
        expect(goal.clearedAll(0), isFalse);
        goal.moves = 2;
        expect(goal.isOutOfMoves, isTrue);
        goal.bossDefeated = true;
        expect(goal.isWon, isTrue);
      },
    );

    test(
      'boss victory progress saves once and ignores corrupt legacy values',
      () async {
        SharedPreferences.setMockInitialValues({
          'cosmopop_v1':
              '{"defeatedBosses":["void_king","unknown","void_king"]}',
        });
        await SaveService.I.load();
        expect(SaveService.I.defeatedBosses, {'void_king'});
        expect(SaveService.I.recordBossVictory('unknown'), isFalse);
        expect(SaveService.I.recordBossVictory('void_king'), isFalse);

        SharedPreferences.setMockInitialValues({});
        await SaveService.I.load();
        expect(SaveService.I.recordBossVictory('void_king'), isTrue);
        expect(SaveService.I.recordBossVictory('void_king'), isFalse);
        await SaveService.I.load();
        expect(SaveService.I.isBossDefeated('void_king'), isTrue);
      },
    );
  });

  group('Cat Crew & Progression Tests', () {
    test('Codex progress counts only unique registered discovery IDs', () {
      final progress = ElementalCodexRegistry.progress([
        'reaction_burn',
        'reaction_burn',
        'chain_burn_bloom',
        'unknown',
      ]);

      expect(progress.discovered, 2);
      expect(progress.total, ElementalCodexRegistry.entries.length);
      expect(progress.remaining, progress.total - 2);
      expect(progress.fraction, 2 / progress.total);
      expect(
        ElementalCodexRegistry.entriesFor(CodexCategory.reactions).length,
        4,
      );
      expect(
        ElementalCodexRegistry.entriesFor(CodexCategory.combinations).length,
        6,
      );
    });

    test('CatRegistry contains 24 valid cats with scaling stats', () {
      expect(CatRegistry.all.length, 24);

      final cosmo = CatRegistry.getById(0);
      expect(cosmo.name, 'Cosmo');
      expect(cosmo.element, ElementalType.cosmic);
      expect(cosmo.rarity, CatRarity.legendary);

      expect(cosmo.upgradeCost(1), greaterThan(0));
      expect(cosmo.abilityMultiplier(1), 1.0);
      expect(cosmo.abilityMultiplier(5), greaterThan(1.0));
    });

    test('four elemental starter cats have executable reaction skills', () {
      final starters = CatRegistry.starterIds.map(CatRegistry.getById).toList();
      expect(
        starters.map((cat) => cat.element),
        containsAll([
          ElementalType.fire,
          ElementalType.water,
          ElementalType.earth,
          ElementalType.flora,
        ]),
      );
      expect(
        starters.map((cat) => cat.skillKind),
        containsAll([
          CatSkillKind.burn,
          CatSkillKind.steam,
          CatSkillKind.mud,
          CatSkillKind.bloom,
        ]),
      );
      expect(
        starters.every((cat) => cat.ability.requiredCharge == 100),
        isTrue,
      );
      expect(
        CatRegistry.all.every((cat) => cat.skillDescription.isNotEmpty),
        isTrue,
      );
    });

    test('SaveService handles cat level upgrade and codex claims', () async {
      SharedPreferences.setMockInitialValues({});
      await SaveService.I.load();
      SaveService.I.addCoins(10000);

      final initialLevel = SaveService.I.getCatLevel(0);
      expect(initialLevel, 1);

      expect(SaveService.I.upgradeCat(0, 150), isFalse);
      final balance = SaveService.I.coins;
      final success = SaveService.I.upgradeCat(0, 1200);
      expect(success, isTrue);
      expect(SaveService.I.getCatLevel(0), 2);
      expect(SaveService.I.coins, balance - 1200);

      SaveService.I.discoverReaction('reaction_burn');
      expect(SaveService.I.discoveredReactions, contains('reaction_burn'));

      final coinsBeforeReward = SaveService.I.coins;
      final claimed = SaveService.I.claimCodexReward('reaction_burn');
      expect(claimed, isTrue);
      expect(SaveService.I.claimedCodexRewards, contains('reaction_burn'));
      expect(SaveService.I.coins, coinsBeforeReward + 150);
      expect(SaveService.I.gems, 3);
      expect(SaveService.I.claimCodexReward('reaction_burn'), isFalse);
    });

    test(
      'starter selection and level persist; locked cats cannot be selected',
      () async {
        SharedPreferences.setMockInitialValues({});
        await SaveService.I.load();
        expect(SaveService.I.cats, containsAll(CatRegistry.starterIds));

        SaveService.I.activeCatId = 1;
        expect(SaveService.I.activeCatId, 1);
        SaveService.I.activeCatId = 3;
        expect(SaveService.I.activeCatId, 1);

        expect(SaveService.I.upgradeCat(1, 150), isFalse);
        expect(SaveService.I.coins, 100);
        SaveService.I.addCoins(500);
        expect(SaveService.I.upgradeCat(1, 149), isFalse);
        expect(SaveService.I.getCatLevel(1), 1);
        expect(SaveService.I.upgradeCat(1, 150), isTrue);
        expect(SaveService.I.coins, 450);

        await SaveService.I.load();
        expect(SaveService.I.activeCatId, 1);
        expect(SaveService.I.getCatLevel(1), 2);
        expect(SaveService.I.cats.toSet().length, SaveService.I.cats.length);
      },
    );

    test('rescue rewards never unlock the same unique cat twice', () async {
      SharedPreferences.setMockInitialValues({});
      await SaveService.I.load();
      final newlyUnlocked = SaveService.I.addCats(100);
      expect(newlyUnlocked.toSet().length, newlyUnlocked.length);
      expect(SaveService.I.addCats(100), isEmpty);
    });

    test('older and malformed cat saves normalize to owned starter cats', () async {
      SharedPreferences.setMockInitialValues({
        'cosmopop_v1':
            '{"cats":["bad-id",999,2],"catLevels":{"2":999},"activeCatId":999}',
      });
      await SaveService.I.load();

      expect(SaveService.I.cats, containsAll([0, ...CatRegistry.starterIds]));
      expect(SaveService.I.cats.toSet().length, SaveService.I.cats.length);
      expect(SaveService.I.getCatLevel(2), CatRarity.rare.maxLevel);
      expect(SaveService.I.activeCatId, CatRegistry.starterIds.first);
    });

    test(
      'Codex discoveries migrate aliases and reject unknown entries',
      () async {
        SharedPreferences.setMockInitialValues({
          'cosmopop_v1': '{"discoveredReactions":["burn","double_chain","not-a-reaction"],"claimedCodexRewards":["burn"]}',
        });
        await SaveService.I.load();

        expect(
          SaveService.I.discoveredReactions,
          containsAll(['reaction_burn', 'chain_double']),
        );
        expect(
          SaveService.I.discoveredReactions,
          isNot(contains('not-a-reaction')),
        );
        expect(SaveService.I.claimedCodexRewards, contains('reaction_burn'));
        expect(SaveService.I.discoverReaction('not-a-reaction'), isFalse);
        expect(SaveService.I.discoverReaction('chain_burn_bloom'), isTrue);
        expect(SaveService.I.claimCodexReward('chain_burn_bloom'), isTrue);
        expect(SaveService.I.claimCodexReward('chain_burn_bloom'), isFalse);
      },
    );

    test(
      'Lava spread is bounded, deterministic, and only propagates next turn',
      () {
        final grid = BubbleGrid(cols: 8, width: 720, top: 150)
          ..cells.addAll(
            List.generate(3, (_) => List<BubbleComponent?>.filled(8, null)),
          );

        BubbleComponent add(
          int row,
          int col,
          BubbleType type, {
          bool source = false,
        }) {
          final point = grid.cellToXY(row, col);
          final bubble = BubbleComponent(radius: grid.radius)
            ..configure(
              bubbleType: type,
              center: Vector2(point.dx, point.dy),
              bubbleRadius: grid.radius,
              rowIndex: row,
              columnIndex: col,
              isFireSource: source,
            );
          grid.insert(row, col, bubble);
          return bubble;
        }

        add(1, 1, BubbleType.red, source: true);
        final neighbors = grid.neighbors(1, 1)
          ..sort((a, b) {
            final row = a.row.compareTo(b.row);
            return row != 0 ? row : a.col.compareTo(b.col);
          });
        final targets = [
          for (final cell in neighbors)
            add(cell.row, cell.col, BubbleType.blue),
        ];

        final firstTurn = LavaPlanetMechanics.spreadFire(grid, budget: 1);
        expect(firstTurn.ignited, [targets.first]);
        expect(firstTurn.ignited.single.type, BubbleType.red);
        expect(firstTurn.ignited.single.fireSource, isTrue);
        expect(
          targets.skip(1).every((bubble) => bubble.type == BubbleType.blue),
          isTrue,
        );

        final nextTurn = LavaPlanetMechanics.spreadFire(grid, budget: 1);
        expect(nextTurn.ignited, hasLength(1));
        expect(nextTurn.ignited.single, isNot(firstTurn.ignited.single));
      },
    );

    test(
      'Lava rules start at level 24 and scale their fixed spread budget',
      () {
        expect(getLevel(23).lavaRules.fireSpreadBudgetPerShot, 0);
        expect(getLevel(24).lavaRules.fireSpreadBudgetPerShot, 1);
        expect(getLevel(59).lavaRules.fireSpreadBudgetPerShot, 1);
        expect(getLevel(60).lavaRules.fireSpreadBudgetPerShot, 2);
        expect(getLevel(24).lavaRules.initialFireCell, isNotNull);
        expect(getLevel(24).planet?.id, PlanetId.lava);
      },
    );

    test(
      'Lava planet completion reward persists and is awarded only once',
      () async {
        SharedPreferences.setMockInitialValues({
          'cosmopop_v1': '{"unlockedLevel":120,"coins":75}',
        });
        await SaveService.I.load();
        expect(SaveService.I.isPlanetUnlocked(PlanetId.lava), isTrue);

        final balance = SaveService.I.coins;
        expect(
          SaveService.I.completePlanet(PlanetId.lava, completedLevel: 119),
          isFalse,
        );
        expect(
          SaveService.I.completePlanet(PlanetId.lava, completedLevel: 120),
          isTrue,
        );
        expect(
          SaveService.I.coins,
          balance + PlanetRegistry.lava.completionRewardCoins,
        );
        expect(
          SaveService.I.completePlanet(PlanetId.lava, completedLevel: 120),
          isFalse,
        );

        await SaveService.I.load();
        expect(SaveService.I.isPlanetCompleted(PlanetId.lava), isTrue);
        expect(
          SaveService.I.completePlanet(PlanetId.lava, completedLevel: 120),
          isFalse,
        );
        expect(
          SaveService.I.planetLevelProgress(PlanetId.lava),
          PlanetRegistry.lava.levelCount,
        );
      },
    );

    test(
      'corrupt planet completion data safely migrates as incomplete',
      () async {
        SharedPreferences.setMockInitialValues({
          'cosmopop_v1': '{"unlockedLevel":6,"completedPlanets":"bad"}',
        });
        await SaveService.I.load();
        expect(SaveService.I.completedPlanets, isEmpty);
        expect(SaveService.I.planetLevelProgress(PlanetId.lava), 5);
        expect(
          SaveService.I.completePlanet(PlanetId.lava, completedLevel: 120),
          isFalse,
        );
      },
    );
  });
}
