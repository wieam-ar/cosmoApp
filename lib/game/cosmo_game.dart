import 'dart:async' as async;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;

import '../art/space_painter.dart';
import '../config/bubble_types.dart';
import '../config/garden_config.dart';
import '../config/levels.dart';
import '../core/audio_service.dart';
import '../core/constants.dart';
import '../core/save_service.dart';
import 'components/bubble_component.dart';
import 'components/cosmic_boss_component.dart';
import 'components/floating_text.dart';
import 'components/particles.dart';
import 'components/shooter_component.dart';
import 'grid.dart';
import 'logic/cat_crew.dart';
import 'logic/elemental_boss.dart';
import 'logic/elemental_reaction.dart';
import 'logic/goals.dart';
import 'logic/matcher.dart';
import 'logic/powerups.dart';
import 'logic/planet_mechanics.dart';
import 'logic/reaction_chain.dart';
import 'logic/specials.dart';

class CosmoWorld extends World with HasTimeScale {}

class GameHudState {
  final int score;
  final int rescued;
  final int target;
  final int stars;
  final double starProgress;
  final int movesLeft;
  final bool warning;
  final String goalLabel;
  final String activePowerup;
  final bool hintActive;
  final double catAbilityCharge;
  final String companionCatName;
  final String catSkillName;
  final int catSkillCooldown;
  final int catSkillRequiredCharge;
  final bool hasBoss;
  final String bossName;
  final String bossStageTitle;
  final String bossWeakness;
  final String bossTelegraph;
  final int bossHealth;
  final int bossMaxHealth;
  final int bossStage;
  final int bossStageCount;

  const GameHudState({
    required this.score,
    required this.rescued,
    required this.target,
    required this.stars,
    required this.starProgress,
    required this.movesLeft,
    required this.warning,
    required this.goalLabel,
    required this.activePowerup,
    required this.hintActive,
    this.catAbilityCharge = 0.0,
    this.companionCatName = 'Cosmo',
    this.catSkillName = 'SKILL',
    this.catSkillCooldown = 0,
    this.catSkillRequiredCharge = 100,
    this.hasBoss = false,
    this.bossName = '',
    this.bossStageTitle = '',
    this.bossWeakness = '',
    this.bossTelegraph = '',
    this.bossHealth = 0,
    this.bossMaxHealth = 0,
    this.bossStage = 0,
    this.bossStageCount = 0,
  });
}

class CosmoGame extends FlameGame<CosmoWorld> with PanDetector {
  final GameMode mode;
  final int level;
  final CosmoWorld gameWorld;
  final ValueNotifier<GameHudState> hudState = ValueNotifier(
    const GameHudState(
      score: 0,
      rescued: 0,
      target: 1,
      stars: 0,
      starProgress: 0,
      movesLeft: 0,
      warning: false,
      goalLabel: '',
      activePowerup: '',
      hintActive: false,
    ),
  );
  late final BubbleGrid grid;
  late final GoalProgress goal;
  late final Random _random;
  late final ParticleSystem particles;
  late final ShooterComponent shooter;
  late final int colorsCount;
  late final int ceilingDropEvery;
  late final LevelData? levelData;
  late final List<int> _starScores;
  late final ElementalBossEncounter? bossEncounter;
  late final CosmicBossComponent? bossComponent;
  final List<BubbleComponent> _bubblePool = [];
  bool _isAiming = false;
  bool _targetGestureAllowed = false;
  bool _finished = false;
  bool _didWin = false;
  bool _newBest = false;
  String _lossReason = 'OUT OF MOVES!';
  double _deadLineY = 1050;
  bool _warning = false;
  bool _ending = false;
  String? _pendingPowerup;
  ui.Offset _powerupTargetPoint = ui.Offset.zero;
  double _idleTime = 0;
  bool _hintActive = false;
  bool _hintPulseUp = true;
  double _hintPulse = 0;
  final List<BubbleComponent> _hintGroup = [];
  late final CatData companionCat;
  double catAbilityCharge = 0.0;
  int _catSkillCooldown = 0;
  bool _activatingCatSkill = false;
  final ReactionChainState reactionChainState = ReactionChainState();
  bool planetCompletionRewardEarned = false;
  GardenProgressUpdate? gardenProgressUpdate;

  int _shotsSinceDrop = 0;
  int _bossShotId = 0;
  int _runGeneration = 0;
  async.Timer? _winOverlayTimer;
  int _chain = 0;
  double _elapsed = 0;
  double _slowTimeScale = 1;
  DateTime _lastHudUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  factory CosmoGame({required GameMode mode, required int level}) =>
      CosmoGame._(mode, level, CosmoWorld());

  CosmoGame._(this.mode, this.level, this.gameWorld)
    : super(
        world: gameWorld,
        camera: CameraComponent.withFixedResolution(
          width: 720,
          height: 1280,
          world: gameWorld,
        ),
      ) {
    camera.viewfinder.position = Vector2(360, 640);
    levelData = mode == GameMode.level
        ? getLevel(
            level,
            bubbleSize: SaveService.I.bubbleSize,
            difficultyLevel: SaveService.I.difficultyLevel,
          )
        : null;
    final bossDefinition = levelData?.bossEncounter;
    bossEncounter = bossDefinition == null
        ? null
        : ElementalBossEncounter(bossDefinition);
    bossComponent = bossDefinition == null
        ? null
        : CosmicBossComponent(position: Vector2(360, 272));
    _starScores = levelData?.starScores ?? const <int>[3333, 6666, 10000];
    colorsCount = levelData?.colorsCount ?? (mode == GameMode.daily ? 4 : 5);
    ceilingDropEvery = levelData?.ceilingDropEvery ?? 5;
    _random = Random(
      mode == GameMode.daily
          ? _dailySeed()
          : mode == GameMode.level
          ? level * 4423
          : DateTime.now().millisecondsSinceEpoch,
    );
    grid = BubbleGrid(
      cols: gridColsBySize(SaveService.I.bubbleSize),
      width: 720,
      top: bossDefinition == null ? 154 : 330,
    );
    final goalData =
        levelData?.goal ??
        Goal(
          type: mode == GameMode.arcade ? GoalType.score : GoalType.clear,
          target: mode == GameMode.arcade ? 10000 : 1,
        );
    goal = GoalProgress(
      mode: mode,
      goal: goalData,
      moveLimit: levelData?.moves ?? 0,
      targetScore: levelData?.starScores.last ?? 10000,
    );
    goal.setRemainingBubbles(0);
    companionCat = CatRegistry.getById(SaveService.I.activeCatId);
    particles = ParticleSystem(size: Vector2(720, 1280))..priority = 40;
    shooter = ShooterComponent(game: this);
  }

  bool get isFinished => _finished;
  double get deadLineY => _deadLineY;
  int get bubbleCount => grid.activeBubbleCount;
  int get score => goal.score;
  bool get didWin => _didWin;
  bool get isNewBest => _newBest;
  String get lossReason => _lossReason;
  int get earnedStars => goal.score >= _starScores[2]
      ? 3
      : goal.score >= _starScores[1]
      ? 2
      : goal.score >= _starScores[0]
      ? 1
      : 0;
  String? get pendingPowerup => _pendingPowerup;
  bool get hintActive => _hintActive;
  bool get catSkillReady =>
      catAbilityCharge >= companionCat.ability.requiredCharge &&
      _catSkillCooldown == 0 &&
      !_finished;

  bool isPowerupUnlocked(String id) =>
      PowerupLogic.isUnlocked(id, mode: mode, level: level);

  int powerupCount(String id) => PowerupLogic.count(id);

  @override
  Color backgroundColor() => const Color(0xFF0F0C29);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    world.addAll([_GameBackground()..priority = -100, particles, shooter]);
    if (bossComponent != null) world.add(bossComponent!);
    _loadInitialGrid();
    goal.setRemainingBubbles(bubbleCount);
    _publishHud(force: true);
  }

  void _loadInitialGrid() {
    if (mode == GameMode.level) {
      grid.loadPattern(levelData!.pattern, _createGridBubble);
      final seed = levelData!.lavaRules.initialFireCell;
      if (seed != null) {
        grid.at(seed.row, seed.col)?.fireSource = true;
      }
    } else {
      final rows = mode == GameMode.classic
          ? 7
          : mode == GameMode.daily
          ? 6
          : 5;
      final pattern = List.generate(rows, (row) {
        return List<BubbleType?>.generate(grid.cols, (col) {
          if (mode == GameMode.classic &&
              (row == 0 || row == rows - 1) &&
              col % 3 == 0) {
            return null;
          }
          return randomBubbleType();
        });
      });
      grid.loadPattern(pattern, _createGridBubble);
    }
  }

  void _playReactionSound(ReactionType type) {
    final sound = switch (type) {
      ReactionType.burn => SfxName.boom,
      ReactionType.steam => SfxName.whoosh,
      ReactionType.mud => SfxName.thud,
      ReactionType.bloom => SfxName.star,
    };
    Sfx.play(sound, pitch: 0.9 + type.index * 0.08, volume: 0.75);
  }

  int _dailySeed() {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  BubbleType randomBubbleType() {
    if (goal.goal.type == GoalType.rescue &&
        _random.nextInt(colorsCount + 1) == colorsCount) {
      return BubbleType.purple;
    }
    return kNormalBubbleTypes[_random.nextInt(
      colorsCount.clamp(1, kNormalBubbleTypes.length).toInt(),
    )];
  }

  BubbleComponent _createGridBubble(BubbleType type, int row, int col) {
    final point = grid.cellToXY(row, col);
    final bubble = obtainBubble(
      type,
      Vector2(point.dx, point.dy),
      state: BubbleState.idle,
      row: row,
      col: col,
    );
    return bubble;
  }

  BubbleComponent obtainBubble(
    BubbleType type,
    Vector2 center, {
    BubbleState state = BubbleState.idle,
    int row = -1,
    int col = -1,
  }) {
    BubbleComponent? bubble;
    for (final pooled in _bubblePool) {
      if (!pooled.isMounted && pooled.state == BubbleState.inactive) {
        bubble = pooled;
        break;
      }
    }
    bubble ??= BubbleComponent(radius: grid.radius);
    if (!_bubblePool.contains(bubble)) _bubblePool.add(bubble);
    bubble.configure(
      bubbleType: type,
      center: center,
      bubbleRadius: grid.radius,
      bubbleState: state,
      rowIndex: row,
      columnIndex: col,
    );
    if (!bubble.isMounted) world.add(bubble);
    return bubble;
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (_finished) return;
    final point = camera.globalToLocal(info.eventPosition.widget);
    _registerActivity();
    if (_pendingPowerup != null) {
      _targetGestureAllowed = _isPlayablePoint(point.x, point.y);
      if (!_targetGestureAllowed) return;
      _powerupTargetPoint = ui.Offset(point.x, point.y);
      particles.setTarget(point.x, point.y);
      return;
    }
    if (point.y < 145 || point.y > 1110) return;
    if (point.x < 165 && point.y > 990) return;
    _isAiming = true;
    shooter.setAim(ui.Offset(point.x, point.y));
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_finished) return;
    final point = camera.globalToLocal(info.eventPosition.widget);
    if (_pendingPowerup != null && _targetGestureAllowed) {
      _powerupTargetPoint = ui.Offset(point.x, point.y);
      particles.setTarget(point.x, point.y);
      return;
    }
    if (!_isAiming) return;
    shooter.setAim(ui.Offset(point.x, point.y));
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (_pendingPowerup != null) {
      if (_targetGestureAllowed) {
        _applyTargetedPowerup(
          _pendingPowerup!,
          _powerupTargetPoint.dx,
          _powerupTargetPoint.dy,
        );
      }
      _targetGestureAllowed = false;
      return;
    }
    if (!_isAiming) return;
    _isAiming = false;
    shooter.release();
  }

  @override
  void onPanCancel() {
    _isAiming = false;
    _targetGestureAllowed = false;
    if (_pendingPowerup != null) {
      _pendingPowerup = null;
      particles.clearTarget();
      _publishHud(force: true);
    }
  }

  void handleTapAt(ui.Offset widgetPoint) {
    if (_finished) return;
    final point = camera.globalToLocal(Vector2(widgetPoint.dx, widgetPoint.dy));
    _registerActivity();
    if (_pendingPowerup != null) {
      if (!_isPlayablePoint(point.x, point.y)) return;
      _applyTargetedPowerup(_pendingPowerup!, point.x, point.y);
      return;
    }
    if (point.y > 990 && point.y < 1120 && point.x < 180) {
      shooter.swap();
    }
  }

  void shotStarted() {
    _registerActivity();
    _bossShotId++;
    reactionChainState.beginShot();
    if (_catSkillCooldown > 0) _catSkillCooldown--;
    goal.moves++;
    goal.missedShots++;
    _shotsSinceDrop++;
    _warning = _shotsSinceDrop == ceilingDropEvery - 1;
    Sfx.play(SfxName.shoot);
    _publishHud();
  }

  void playBounce() => Sfx.play(SfxName.bounce);

  void missShot(BubbleComponent bubble) {
    bubble.deactivate();
    _chain = 0;
    reactionChainState.reset();
    _resolveBossTurn();
    _finishShot();
    _publishHud();
    _checkLoss();
  }

  void onBubbleLanded(BubbleComponent bubble) {
    final catLevel = SaveService.I.getCatLevel(companionCat.id);
    final powerMultiplier = companionCat.abilityMultiplier(catLevel);
    final resolution = BubbleMatcher.resolve(
      grid,
      bubble.row,
      bubble.col,
      powerMultiplier: powerMultiplier,
    );
    if (resolution.combo == 0) {
      _chain = 0;
      reactionChainState.reset();
      _applyPlanetTurnRules();
      _resolveBossTurn();
      _finishShot();
      _checkLoss();
      _publishHud();
      return;
    }
    _chain++;
    goal.missedShots = 0;

    var reactionBonusScore = 0;
    for (final reaction in resolution.reactionResults) {
      final event = reactionChainState.registerReaction(
        reaction.type,
        affected: [...reaction.reactionAffected, ...reaction.damagedStones],
      );
      if (event == null) continue;
      SaveService.I.discoverReaction(reaction.type.codexId);
      if (event.combinationId != null) {
        SaveService.I.discoverReaction(event.combinationId!);
      }
      if (event.chainCount >= 2) {
        SaveService.I.discoverReaction('chain_double');
      }
      if (event.chainCount >= 3) {
        SaveService.I.discoverReaction('chain_triple');
      }
      reactionBonusScore += event.scaleReactionScore(reaction.bonusScore);
      final effectOrigin = reaction.primaryPopped.isEmpty
          ? bubble.position
          : reaction.primaryPopped.first.position;
      _playReactionAnimation(reaction.type, effectOrigin.x, effectOrigin.y);
      _playReactionSound(reaction.type);
      for (final stone in reaction.damagedStones.take(12)) {
        particles.flash(stone.position.x, stone.position.y);
      }
      if (event.chainCount > 1) {
        world.add(
          FloatingText(
            text: event.label,
            position: Vector2(360, 490 - event.chainCount * 52),
            color: const ui.Color(0xFFFFEAA7),
          ),
        );
        particles.ripple(
          bubble.position.x,
          bubble.position.y,
          companionCat.element.color.toARGB32(),
        );
        Sfx.play(SfxName.combo, pitch: 1 + (event.chainCount - 2) * 0.12);
      }
      _handleBossReaction(reaction.type, effectOrigin);
    }

    // Charge Companion Cat Ability Meter
    final previousCharge = catAbilityCharge;
    final chargeGained = reactionChainState.calculateCatSkillCharge(
      baseMatchSize: resolution.popped.length,
      hadReaction: resolution.reactionResult != null,
    );
    catAbilityCharge = (catAbilityCharge + chargeGained).clamp(
      0.0,
      companionCat.ability.requiredCharge.toDouble(),
    );

    if (previousCharge < companionCat.ability.requiredCharge &&
        catAbilityCharge >= companionCat.ability.requiredCharge) {
      world.add(
        FloatingText(
          text: 'SKILL READY!',
          position: Vector2(360, 420),
          color: companionCat.element.color,
        ),
      );
    }

    final basePoints =
        (resolution.popped.length * 10 + resolution.dropped.length * 20) *
            _chain +
        resolution.synergyPopped.length * 20;
    final points = basePoints + reactionBonusScore;
    goal.score += points;
    goal.rescued += resolution.rescued;

    final stoneBreaks = <BubbleComponent>[];
    for (final stone in resolution.stoneDamage) {
      final special = SpecialBubbleLogic.hit(grid, stone);
      stoneBreaks.addAll(special.removed);
    }
    final affected = _processSpecialEffects([
      ...resolution.popped,
      ...resolution.dropped,
      ...resolution.synergyPopped,
      ...stoneBreaks,
    ]);
    goal.score += affected.length * 20;
    goal.rescued += affected.where((bubble) => bubble.isCat).length;
    _animateResolution(resolution, extraPopped: [...stoneBreaks, ...affected]);
    _applyPlanetTurnRules();
    _resolveBossTurn();

    final bannerLabel = resolution.reactionResults.isEmpty
        ? resolution.synergy
        : reactionChainState.lastReactionLabel;
    if (bannerLabel != null) {
      world.add(
        FloatingText(
          text: bannerLabel,
          position: Vector2(360, 490),
          color: const ui.Color(0xFFFFC857),
        ),
      );
    }
    _finishShot();
    _checkWin();
    _checkLoss();
    _publishHud(force: true);
    reactionChainState.reset();
  }

  void _handleBossReaction(ReactionType type, Vector2 origin) {
    final encounter = bossEncounter;
    if (encounter == null) return;
    final result = encounter.registerReaction(type, _bossShotId);
    if (result.outcome == BossReactionOutcome.wrongWeakness) {
      world.add(
        FloatingText(
          text: 'SHIELD RESISTS · NEED ${result.requiredWeakness!.name}',
          position: origin + Vector2(0, -54),
          color: const ui.Color(0xFFBDAAFF),
        ),
      );
      return;
    }
    if (!result.didDamage) return;

    bossComponent?.syncStage(
      result.currentStage,
      defeated: encounter.isDefeated,
    );
    goal.score += result.outcome == BossReactionOutcome.defeated ? 500 : 250;
    particles.ripple(origin.x, origin.y, 0xFFC6A8FF);
    particles.burst(
      360,
      272,
      result.outcome == BossReactionOutcome.defeated ? 0xFFFFE184 : 0xFFB99AFF,
      count: 12,
    );
    final defeated = result.outcome == BossReactionOutcome.defeated;
    world.add(
      FloatingText(
        text: defeated
            ? 'CORE SHATTERED!'
            : 'VOID KING HIT · ${result.currentStage}/${encounter.maxHealth}',
        position: Vector2(360, 216),
        color: defeated
            ? const ui.Color(0xFFFFE184)
            : const ui.Color(0xFFD7C1FF),
      ),
    );
    Sfx.play(SfxName.boom, pitch: defeated ? 1.15 : 0.8);
    if (defeated) {
      goal.bossDefeated = true;
    }
    _publishHud(force: true);
  }

  void _resolveBossTurn() {
    final result = bossEncounter?.resolvePlayerTurn(grid);
    if (result == null || !result.attackTriggered) {
      if (result != null) _publishHud();
      return;
    }
    final target = result.hardenedBubble;
    if (target != null) {
      particles.flash(target.position.x, target.position.y);
      particles.ripple(target.position.x, target.position.y, 0xFFAA8FE0);
      world.add(
        FloatingText(
          text: 'VOID PULSE · STONE!',
          position: target.position + Vector2(0, -target.radius * 1.6),
          color: const ui.Color(0xFFCBB7FF),
        ),
      );
    } else {
      world.add(
        FloatingText(
          text: 'VOID PULSE FADES',
          position: Vector2(360, 320),
          color: const ui.Color(0xFFCBB7FF),
        ),
      );
    }
    Sfx.play(SfxName.thud, pitch: 0.85);
    _publishHud(force: true);
  }

  void _applyPlanetTurnRules() {
    final budget = levelData?.lavaRules.fireSpreadBudgetPerShot ?? 0;
    if (budget <= 0) return;
    final result = LavaPlanetMechanics.spreadFire(grid, budget: budget);
    if (!result.changed) return;
    for (final bubble in result.ignited) {
      particles.fireSpread(bubble.position.x, bubble.position.y);
    }
    final first = result.ignited.first;
    world.add(
      FloatingText(
        text: 'FIRE SPREAD',
        position: first.position + Vector2(0, -first.radius * 1.8),
        color: const ui.Color(0xFFFFA03A),
      ),
    );
    Sfx.play(SfxName.whoosh, pitch: 0.8, volume: 0.55);
  }

  void _playReactionAnimation(ReactionType type, double x, double y) {
    switch (type) {
      case ReactionType.burn:
        particles.burstBurn(x, y);
        break;
      case ReactionType.steam:
        particles.burstSteam(x, y);
        break;
      case ReactionType.mud:
        particles.burstMud(x, y);
        break;
      case ReactionType.bloom:
        particles.burstBloom(x, y);
        break;
    }
  }

  /// Activates the selected cat's charged skill once a valid reaction target exists.
  bool activateCatSkill() {
    if (!catSkillReady || _activatingCatSkill || _pendingPowerup != null) {
      return false;
    }

    _activatingCatSkill = true;
    try {
      final ability = companionCat.ability;
      final skillKind = companionCat.skillKind;
      if (skillKind == CatSkillKind.wildcard) {
        shooter.makeNextRainbow();
      } else {
        final reactionType = switch (skillKind) {
          CatSkillKind.burn => ReactionType.burn,
          CatSkillKind.steam => ReactionType.steam,
          CatSkillKind.mud => ReactionType.mud,
          CatSkillKind.bloom => ReactionType.bloom,
          CatSkillKind.wildcard => null,
        };
        final reaction = reactionType!;
        final group = _largestSkillMatch(reaction.primaryBubble);
        if (group == null) {
          world.add(
            FloatingText(
              text: 'NEED ${reaction.primaryBubble.name.toUpperCase()} MATCH',
              position: Vector2(360, 420),
              color: companionCat.element.color,
            ),
          );
          return false;
        }
        final result = ElementalReactionEngine.process(
          grid: grid,
          matchedGroup: group,
          primaryType: reaction.primaryBubble,
          powerMultiplier: companionCat.abilityMultiplier(
            SaveService.I.getCatLevel(companionCat.id),
          ),
        );
        if (result == null) {
          world.add(
            FloatingText(
              text: 'NO ${reaction.targetBubble.name.toUpperCase()} NEARBY',
              position: Vector2(360, 420),
              color: companionCat.element.color,
            ),
          );
          return false;
        }

        final extra = _processSpecialEffects(result.reactionAffected);
        final removed = <BubbleComponent>{
          ...result.reactionAffected,
          ...extra,
        }.toList(growable: false);
        goal.score += result.bonusScore + extra.length * 20;
        goal.rescued += removed.where((bubble) => bubble.isCat).length;
        _animateSpecialBubbles(removed);
        SaveService.I.discoverReaction(result.type.codexId);
        _playReactionAnimation(result.type, 360, 430);
        _playReactionSound(result.type);
        for (final stone in result.damagedStones) {
          particles.flash(stone.position.x, stone.position.y);
        }
        world.add(
          FloatingText(
            text: '${ability.name.toUpperCase()}!',
            position: Vector2(360, 420),
            color: companionCat.element.color,
          ),
        );
      }

      catAbilityCharge = 0;
      _catSkillCooldown = ability.cooldownShots;
      _registerActivity();
      _checkWin();
      _checkLoss();
      _publishHud(force: true);
      return true;
    } finally {
      _activatingCatSkill = false;
    }
  }

  List<BubbleComponent>? _largestSkillMatch(BubbleType type) {
    final visited = <BubbleComponent>{};
    List<BubbleComponent>? largest;
    for (var row = 0; row < grid.rowCount; row++) {
      for (var col = 0; col < grid.cols; col++) {
        final start = grid.at(row, col);
        if (start == null || start.type != type || !visited.add(start)) {
          continue;
        }
        final group = <BubbleComponent>[start];
        for (var cursor = 0; cursor < group.length; cursor++) {
          for (final neighbor in grid.neighbors(
            group[cursor].row,
            group[cursor].col,
          )) {
            final bubble = grid.at(neighbor.row, neighbor.col);
            if (bubble != null && bubble.type == type && visited.add(bubble)) {
              group.add(bubble);
            }
          }
        }
        if (group.length >= 3 &&
            (largest == null || group.length > largest.length)) {
          largest = group;
        }
      }
    }
    return largest;
  }

  void _animateResolution(
    MatchResolution resolution, {
    List<BubbleComponent> extraPopped = const [],
  }) {
    final popped = <BubbleComponent>{
      ...resolution.popped,
      ...resolution.synergyPopped,
      ...extraPopped,
    };
    var index = 0;
    for (final bubble in popped) {
      if (index < 24) {
        final color =
            kBubbleStyles[bubble.type]?.midColor.toARGB32() ?? 0xFFFFFFFF;
        particles.burst(bubble.position.x, bubble.position.y, color, count: 8);
        particles.flash(bubble.position.x, bubble.position.y);
      }
      if (bubble.state != BubbleState.falling) {
        bubble.pop(delay: min(index, 24) * 0.015);
      }
      if (index < 16) {
        Sfx.play(SfxName.pop, pitch: 1 + index * 0.05, volume: 0.7);
      }
      index++;
    }
    for (var i = 0; i < resolution.dropped.length; i++) {
      final bubble = resolution.dropped[i];
      if (i < 24) {
        particles.burst(
          bubble.position.x,
          bubble.position.y,
          kBubbleStyles[bubble.type]?.midColor.toARGB32() ?? 0xFFFFFFFF,
          count: 6,
        );
      }
      bubble.fall();
    }
    final count = resolution.combo + extraPopped.length;
    if (count >= 4) {
      final label = count >= 13
          ? 'COSMIC!'
          : count >= 9
          ? 'AMAZING!'
          : count >= 6
          ? 'GREAT!'
          : 'NICE!';
      world.add(
        FloatingText(
          text: label,
          position: Vector2(360, 560),
          color: const ui.Color(0xFFFFEAA7),
        ),
      );
    }
    if (count >= 9) particles.shakeCamera(5 + count * 0.45);
    if (resolution.combo > 0) {
      shooter.celebrate();
    }
  }

  void _finishShot() {
    _warning = false;
    if (_shotsSinceDrop < ceilingDropEvery) return;
    _shotsSinceDrop = 0;
    grid.descendCeiling(
      kNormalBubbleTypes.take(colorsCount).toList(growable: false),
      _random,
      _createGridBubble,
    );
    _checkLoss();
  }

  void onSpecialHit(BubbleComponent bubble) {
    final effect = SpecialBubbleLogic.hit(grid, bubble);
    final affected = _processSpecialEffects(
      effect.removed.where((removed) => !identical(removed, bubble)),
    );
    if (effect.damaged.isNotEmpty) {
      particles.flash(bubble.position.x, bubble.position.y);
    }
    final removed = <BubbleComponent>{...effect.removed, ...affected}.toList();
    if (removed.isNotEmpty) {
      goal.score += removed.length * 20;
      goal.rescued += removed.where((item) => item.isCat).length;
      _animateSpecialBubbles(removed);
      _checkWin();
    }
    _checkLoss();
    _publishHud(force: true);
  }

  bool usePowerup(String id) {
    if (_finished || _pendingPowerup != null || !isPowerupUnlocked(id)) {
      return false;
    }
    final definition = PowerupLogic.definition(id);
    if (definition == null || PowerupLogic.count(id) <= 0) {
      return false;
    }
    _registerActivity();
    if (id == 'rainbow') {
      if (!PowerupLogic.consume(id)) return false;
      shooter.makeNextRainbow();
    } else {
      _pendingPowerup = id;
      particles.setTarget(shooter.launchPoint.x, shooter.launchPoint.y - 150);
    }
    _publishHud(force: true);
    return true;
  }

  void _applyTargetedPowerup(String id, double x, double y) {
    final cell = grid.xyToCell(x, y, allowOccupied: true);
    if (!_isPlayablePoint(x, y) || cell == null || cell.row >= grid.rowCount) {
      _publishHud(force: true);
      return;
    }
    if (!PowerupLogic.consume(id)) {
      _pendingPowerup = null;
      particles.clearTarget();
      _publishHud(force: true);
      return;
    }
    _pendingPowerup = null;
    particles.clearTarget();
    _registerActivity();
    final removed = <BubbleComponent>[];
    switch (PowerupLogic.definition(id)?.kind) {
      case PowerupKind.bomb:
        final explosion = SpecialBubbleLogic.explode(grid, x, y, hexRadius: 2);
        removed.addAll(explosion.removed);
        particles.ripple(x, y, 0xFFFFA502);
        particles.shakeCamera(9, duration: 0.34);
        Sfx.play(SfxName.boom);
        break;
      case PowerupKind.lightning:
        for (var col = 0; col < grid.cols; col++) {
          final bubble = grid.remove(cell.row, col);
          if (bubble != null) removed.add(bubble);
        }
        particles.flash(x, y);
        particles.lightning(x, grid.top, 1120);
        particles.burst(x, y, 0xFFFFFFFF, count: 28);
        particles.shakeCamera(5);
        Sfx.play(SfxName.combo);
        break;
      case PowerupKind.rocket:
        for (var row = 0; row < grid.rowCount; row++) {
          final bubble = grid.remove(row, cell.col);
          if (bubble != null) removed.add(bubble);
        }
        particles.rocketTrail(grid.cellToXY(0, cell.col).dx, y);
        particles.shakeCamera(6);
        Sfx.play(SfxName.whoosh);
        break;
      case PowerupKind.rainbow:
      case null:
        break;
    }
    final affected = _processSpecialEffects(removed);
    final unique = <BubbleComponent>{...removed, ...affected}.toList();
    goal.score += unique.length * 20;
    goal.rescued += unique.where((bubble) => bubble.isCat).length;
    _animateSpecialBubbles(unique);
    if (unique.length >= 8) shooter.cheer();
    _checkWin();
    _checkLoss();
    _publishHud(force: true);
  }

  bool _isPlayablePoint(double x, double y) =>
      x >= 0 && x <= 720 && y >= grid.top && y < deadLineY;

  List<BubbleComponent> _processSpecialEffects(
    Iterable<BubbleComponent> initial,
  ) {
    final effects = <BubbleComponent>[];
    final seen = <BubbleComponent>{};
    final queue = <BubbleComponent>[];
    queue.addAll(initial);
    final initialSet = queue.toSet();
    var index = 0;
    while (true) {
      while (index < queue.length) {
        final bubble = queue[index++];
        if (!seen.add(bubble)) continue;
        if (!initialSet.contains(bubble)) effects.add(bubble);
        if (bubble.type == BubbleType.bomb) {
          final blast = SpecialBubbleLogic.explode(
            grid,
            bubble.position.x,
            bubble.position.y,
            hexRadius: 2,
          );
          particles.ripple(bubble.position.x, bubble.position.y, 0xFFFF8A32);
          particles.shakeCamera(8, duration: 0.32);
          Sfx.play(SfxName.boom);
          queue.addAll(blast.removed);
        } else if (bubble.type == BubbleType.key) {
          queue.addAll(SpecialBubbleLogic.openLocks(grid));
          particles.flash(bubble.position.x, bubble.position.y);
          Sfx.play(SfxName.star);
        }
      }
      final orphans = BubbleMatcher.dropOrphans(grid);
      if (orphans.isEmpty) break;
      for (final orphan in orphans) {
        orphan.fall();
      }
      queue.addAll(orphans);
    }
    return effects;
  }

  void _animateSpecialBubbles(List<BubbleComponent> bubbles) {
    for (var i = 0; i < bubbles.length; i++) {
      final bubble = bubbles[i];
      if (i < 24) {
        particles.burst(
          bubble.position.x,
          bubble.position.y,
          kBubbleStyles[bubble.type]?.midColor.toARGB32() ?? 0xFFFFFFFF,
          count: bubble.type == BubbleType.bomb ? 14 : 7,
        );
      }
      if (bubble.state != BubbleState.falling) {
        bubble.pop(delay: min(i, 24) * 0.015);
      }
      if (i < 16) {
        Sfx.play(SfxName.pop, pitch: 1 + i * 0.04, volume: 0.7);
      }
    }
  }

  void _registerActivity() {
    _idleTime = 0;
    _setHint(false);
  }

  void _setHint(bool enabled, [List<BubbleComponent> group = const []]) {
    if (_hintActive == enabled &&
        _hintGroup.length == group.length &&
        _hintGroup.every(group.contains)) {
      return;
    }
    for (final bubble in _hintGroup) {
      bubble.hintGlow = 0;
    }
    _hintGroup
      ..clear()
      ..addAll(group);
    _hintActive = enabled;
    for (final bubble in _hintGroup) {
      bubble.hintGlow = enabled ? 0.2 : 0;
    }
    _publishHud(force: true);
  }

  void _updateHint(double dt) {
    if (_finished || _pendingPowerup != null || shooter.projectile != null) {
      return;
    }
    _idleTime += dt;
    if (_idleTime < 8) {
      if (_hintActive) _setHint(false);
      return;
    }
    final currentType = shooter.currentBubble?.type;
    if (currentType == null) return;
    final visited = <int>{};
    List<BubbleComponent>? best;
    for (var row = 0; row < grid.rowCount; row++) {
      for (var col = 0; col < grid.cols; col++) {
        final start = grid.at(row, col);
        if (start == null ||
            start.type == BubbleType.rainbow ||
            !(kBubbleStyles[start.type]?.isMatchable ?? false)) {
          continue;
        }
        final key = row * grid.cols + col;
        if (!visited.add(key)) continue;
        final cluster = <BubbleComponent>[];
        final queue = <GridCell>[GridCell(row, col)];
        for (var cursor = 0; cursor < queue.length; cursor++) {
          final cell = queue[cursor];
          final bubble = grid.at(cell.row, cell.col);
          if (bubble == null || bubble.type != start.type) continue;
          cluster.add(bubble);
          for (final neighbor in grid.neighbors(cell.row, cell.col)) {
            final neighborKey = neighbor.row * grid.cols + neighbor.col;
            if (grid.at(neighbor.row, neighbor.col)?.type == start.type &&
                visited.add(neighborKey)) {
              queue.add(neighbor);
            }
          }
        }
        if (cluster.length >= 2 &&
            (start.type == currentType || currentType == BubbleType.rainbow) &&
            (best == null || cluster.length > best.length)) {
          best = cluster;
        }
      }
    }
    if (best != null) {
      _setHint(true, best);
    }
  }

  void _checkWin() {
    if (_finished || mode == GameMode.arcade) return;
    goal.setRemainingBubbles(bubbleCount);
    if (!goal.isWon && !goal.clearedAll(bubbleCount)) return;
    _finished = true;
    _ending = true;
    _didWin = true;
    if (mode == GameMode.level) {
      gardenProgressUpdate = SaveService.I.recordGardenLevelCompletion(
        level,
        rescued: goal.rescued,
      );
      if (bossEncounter?.isDefeated == true) {
        SaveService.I.recordBossVictory(bossEncounter!.definition.id);
      }
      final previousStars = SaveService.I.getStarsForLevel(level);
      _newBest = earnedStars > previousStars;
      _newBest =
          SaveService.I.updateLevelBestScore(level, goal.score) || _newBest;
      SaveService.I.setStarsForLevel(level, max(previousStars, earnedStars));
      final nextLevel = min(120, level + 1);
      SaveService.I.unlockLevel(nextLevel);
      SaveService.I.currentLevel = max(SaveService.I.currentLevel, nextLevel);
      final planet = levelData?.planet;
      if (planet != null &&
          level == planet.lastLevel &&
          SaveService.I.isPlanetUnlocked(planet.id)) {
        planetCompletionRewardEarned = SaveService.I.completePlanet(
          planet.id,
          completedLevel: level,
        );
      }
    } else {
      _newBest = SaveService.I.updateModeHighScore(mode.name, goal.score);
    }
    Sfx.play(SfxName.win);
    _slowTimeScale = gameWorld.timeScale;
    gameWorld.timeScale = 0.3;
    particles.confetti(360, 470);
    final runGeneration = _runGeneration;
    _winOverlayTimer?.cancel();
    _winOverlayTimer = async.Timer(const Duration(seconds: 1), () {
      _winOverlayTimer = null;
      if (!isMounted || runGeneration != _runGeneration || !_didWin) {
        return;
      }
      gameWorld.timeScale = _slowTimeScale;
      _ending = false;
      overlays.add('result');
      pauseEngine();
    });
  }

  void _checkLoss() {
    if (_finished || _ending) return;
    var lowestY = 0.0;
    for (var row = 0; row < grid.rowCount; row++) {
      for (final bubble in grid.cells[row]) {
        if (bubble != null) {
          lowestY = max(lowestY, bubble.position.y + bubble.radius);
        }
      }
    }
    if (lowestY >= deadLineY || goal.isOutOfMoves) {
      _finished = true;
      _didWin = false;
      _lossReason = lowestY >= deadLineY
          ? 'BUBBLES REACHED THE BASE!'
          : 'OUT OF MOVES!';
      if (mode == GameMode.arcade || mode == GameMode.classic) {
        _newBest = SaveService.I.updateModeHighScore(mode.name, goal.score);
      }
      Sfx.play(SfxName.lose);
      _publishHud(force: true);
      overlays.add('result');
      pauseEngine();
    }
  }

  void updateTimer(double dt) {
    _elapsed += dt;
    goal.setRemainingBubbles(bubbleCount);
    if (goal.goal.type == GoalType.timer &&
        _elapsed >= goal.goal.target &&
        !goal.clearedAll(bubbleCount)) {
      _finished = true;
      _didWin = false;
      _lossReason = 'TIME IS UP!';
      Sfx.play(SfxName.lose);
      overlays.add('result');
      pauseEngine();
    }
  }

  void _publishHud({bool force = false}) {
    final now = DateTime.now();
    if (!force && now.difference(_lastHudUpdate).inMilliseconds < 80) return;
    _lastHudUpdate = now;
    final stars = goal.score >= _starScores[2]
        ? 3
        : goal.score >= _starScores[1]
        ? 2
        : goal.score >= _starScores[0]
        ? 1
        : 0;
    final starProgress = stars == 3
        ? 1.0
        : stars == 2
        ? 2 / 3 +
              ((goal.score - _starScores[1]) /
                          max(1, _starScores[2] - _starScores[1]))
                      .clamp(0.0, 1.0) /
                  3
        : stars == 1
        ? 1 / 3 +
              ((goal.score - _starScores[0]) /
                          max(1, _starScores[1] - _starScores[0]))
                      .clamp(0.0, 1.0) /
                  3
        : (goal.score / max(1, _starScores[0])).clamp(0.0, 1.0) / 3;
    hudState.value = GameHudState(
      score: goal.score,
      rescued: goal.rescued,
      target: goal.goal.type == GoalType.rescue
          ? goal.goal.target
          : goal.goal.type == GoalType.score
          ? goal.goal.target
          : 0,
      stars: stars,
      starProgress: starProgress,
      movesLeft: goal.moveLimit > 0
          ? max(0, goal.moveLimit + goal.extraMoves - goal.moves)
          : -1,
      warning: _warning,
      goalLabel: goal.goal.type.name,
      activePowerup: _pendingPowerup ?? '',
      hintActive: _hintActive,
      catAbilityCharge: catAbilityCharge,
      companionCatName: companionCat.name,
      catSkillName: companionCat.ability.name,
      catSkillCooldown: _catSkillCooldown,
      catSkillRequiredCharge: companionCat.ability.requiredCharge,
      hasBoss: bossEncounter != null,
      bossName: bossEncounter?.definition.name ?? '',
      bossStageTitle: bossEncounter?.currentStageTitle ?? '',
      bossWeakness: bossEncounter?.requiredWeakness?.name.toUpperCase() ?? '',
      bossTelegraph: bossEncounter?.telegraph ?? '',
      bossHealth: bossEncounter?.health ?? 0,
      bossMaxHealth: bossEncounter?.maxHealth ?? 0,
      bossStage: bossEncounter?.stagesCleared ?? 0,
      bossStageCount: bossEncounter?.maxHealth ?? 0,
    );
  }

  void openPause() {
    if (_finished || overlays.isActive('pause')) return;
    pauseEngine();
    overlays.add('pause');
  }

  void resumeFromPause() {
    overlays.remove('pause');
    resumeEngine();
  }

  void continueWithExtraMoves(int amount) {
    if (amount <= 0 || !_finished || _didWin) return;
    goal.extraMoves += amount;
    if (_lossReason == 'BUBBLES REACHED THE BASE!') {
      _deadLineY = 1210;
    }
    _finished = false;
    _lossReason = 'OUT OF MOVES!';
    overlays.remove('result');
    resumeEngine();
  }

  void restart() {
    _runGeneration++;
    _winOverlayTimer?.cancel();
    _winOverlayTimer = null;
    overlays.remove('result');
    overlays.remove('pause');
    _finished = false;
    _didWin = false;
    _newBest = false;
    _ending = false;
    _deadLineY = 1050;
    goal.score = 0;
    goal.rescued = 0;
    goal.moves = 0;
    goal.extraMoves = 0;
    goal.missedShots = 0;
    _shotsSinceDrop = 0;
    _elapsed = 0;
    _warning = false;
    _chain = 0;
    _bossShotId = 0;
    bossEncounter?.reset();
    bossComponent?.syncStage(0);
    goal.bossDefeated = false;
    reactionChainState.reset();
    catAbilityCharge = 0;
    _catSkillCooldown = 0;
    _pendingPowerup = null;
    particles.clearTarget();
    _setHint(false);
    gameWorld.timeScale = 1;
    for (final bubble in _bubblePool) {
      bubble.deactivate();
    }
    grid.cells.clear();
    _loadInitialGrid();
    if (shooter.projectile != null) shooter.projectile!.deactivate();
    shooter.projectile = null;
    shooter.currentBubble?.deactivate();
    shooter.currentBubble = null;
    shooter.reload();
    _publishHud(force: true);
    resumeEngine();
  }

  void exitToMap() {
    pauseEngine();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final shake = particles.cameraShakeOffset;
    camera.viewfinder.position.setValues(360 + shake.dx, 640 + shake.dy);
    updateTimer(dt);
    goal.setRemainingBubbles(bubbleCount);
    _checkLoss();
    _updateHint(dt);
    if (_hintActive) {
      _hintPulse += dt * (_hintPulseUp ? 1.8 : -1.8);
      if (_hintPulse >= 1) {
        _hintPulse = 1;
        _hintPulseUp = false;
      } else if (_hintPulse <= 0) {
        _hintPulse = 0;
        _hintPulseUp = true;
      }
      for (final bubble in _hintGroup) {
        bubble.hintGlow = 0.2 + _hintPulse * 0.85;
      }
    }
    if (_warning) {
      _publishHud();
    }
  }

  @override
  void onRemove() {
    _runGeneration++;
    _winOverlayTimer?.cancel();
    _winOverlayTimer = null;
    hudState.dispose();
    super.onRemove();
  }
}

class _GameBackground extends PositionComponent {
  ui.Picture? _picture;

  _GameBackground()
    : super(size: Vector2(720, 1280), priority: -100, anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 720, 1280));
    final rect = const ui.Rect.fromLTWH(0, 0, 720, 1280);
    canvas.drawRect(rect, ui.Paint()..color = const ui.Color(0xFF0F0C29));
    SpacePainter.nebula(canvas, const ui.Size(720, 1280));
    SpacePainter.starfield(canvas, const ui.Size(720, 1280));
    SpacePainter.planet(
      canvas,
      const ui.Offset(96, 330),
      92,
      PlanetKind.purpleMoon,
    );
    SpacePainter.planet(
      canvas,
      const ui.Offset(640, 190),
      44,
      PlanetKind.iceWorld,
    );
    SpacePainter.planet(
      canvas,
      const ui.Offset(655, 985),
      38,
      PlanetKind.gasGiant,
    );
    SpacePainter.lavaSurface(
      canvas,
      const ui.Size(720, 1280),
      heightFactor: 0.11,
    );
    canvas.drawCircle(
      const ui.Offset(360, 1170),
      38,
      ui.Paint()..color = const ui.Color(0x553F203F),
    );
    _picture = recorder.endRecording();
  }

  @override
  void render(ui.Canvas canvas) {
    final picture = _picture;
    if (picture != null) canvas.drawPicture(picture);
  }

  @override
  void onRemove() {
    _picture?.dispose();
    _picture = null;
    super.onRemove();
  }
}
