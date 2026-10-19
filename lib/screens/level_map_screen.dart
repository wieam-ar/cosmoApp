import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art/icons_painter.dart';
import '../art/mimo_painter.dart';
import '../art/jelly_painter.dart';
import '../config/levels.dart';
import '../config/planet_config.dart';
import '../core/constants.dart';
import '../core/save_service.dart';
import '../core/theme.dart' hide GlassPanel;
import '../core/transitions.dart';
import '../game/logic/cat_crew.dart';
import '../screens/game_screen.dart';
import '../screens/catalog_screen.dart';
import '../screens/daily_reward_screen.dart';
import '../screens/shop_screen.dart';
import '../screens/spin_screen.dart';
import '../widgets/glass_ui.dart';
import '../widgets/hud_bar.dart';
import '../widgets/jelly_button.dart';
import '../widgets/popup.dart';
import '../widgets/space_background.dart';

const double _levelSpacing = 132;
const int _levelCount = 120;

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _parallaxOffset = ValueNotifier(0);
  final Set<int> _seenLevels = {};
  final _MapPictureCache _pictureCache = _MapPictureCache();
  late final AnimationController _animationController;

  double _contentHeight = 0;
  double _viewportHeight = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animationController.addListener(_onAnimationTick);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _parallaxOffset.dispose();
    _animationController.dispose();
    _pictureCache.dispose();
    super.dispose();
  }

  void _onScroll() {
    _parallaxOffset.value = _scrollController.hasClients
        ? _scrollController.offset * 0.3
        : 0;
    if (mounted) setState(() {});
  }

  void _onAnimationTick() {
    if (mounted) setState(() {});
  }

  void _scrollToCurrent() {
    if (!_scrollController.hasClients || _contentHeight == 0) return;
    final level = SaveService.I.currentLevel.clamp(1, _levelCount);
    final nodeY = _nodeY(level);
    final target = (_contentHeight - nodeY - _viewportHeight / 2).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
    );
  }

  double _nodeY(int level) => _contentHeight - 70 - (level - 1) * _levelSpacing;

  double _nodeX(int level, double width) =>
      width / 2 + sin((level - 1) * 0.72) * width * 0.29;

  Future<void> _openLevel(int level) async {
    final data = getLevel(
      level,
      bubbleSize: SaveService.I.bubbleSize,
      difficultyLevel: SaveService.I.difficultyLevel,
    );
    final selected = <String>{};
    final shouldPlay = await Popup.show<bool>(
      context,
      title: 'LEVEL $level',
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          final powerups = SaveService.I.powerups;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _StarPreview(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _goalIcon(data.goal.type),
                    color: AppColors.accent,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data.bossEncounter == null
                          ? _goalDescription(data.goal)
                          : 'Defeat ${data.bossEncounter!.name}: break each '
                                'shield in order with BURN, STEAM, MUD, then BLOOM.',
                      style: AppTextStyles.body(fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ListenableBuilder(
                listenable: SaveService.I,
                builder: (context, _) {
                  final cat = CatRegistry.getById(SaveService.I.activeCatId);
                  return GlassPanel(
                    radius: 14,
                    tint: cat.element.color,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pets, color: cat.element.color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${cat.name} · ${cat.ability.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.label(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => const CatalogScreen(),
                            ),
                          ),
                          child: Text(
                            'Change',
                            style: AppTextStyles.label(
                              fontSize: 12,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BoosterToggle(
                    name: 'bomb',
                    icon: AppIcon.bomb,
                    count: powerups['bomb'] ?? 0,
                    selected: selected.contains('bomb'),
                    onTap: () => setDialogState(
                      () => _toggleBooster(
                        selected,
                        'bomb',
                        powerups['bomb'] ?? 0,
                      ),
                    ),
                  ),
                  _BoosterToggle(
                    name: 'rainbow',
                    icon: AppIcon.star,
                    count: powerups['rainbow'] ?? 0,
                    selected: selected.contains('rainbow'),
                    onTap: () => setDialogState(
                      () => _toggleBooster(
                        selected,
                        'rainbow',
                        powerups['rainbow'] ?? 0,
                      ),
                    ),
                  ),
                  _BoosterToggle(
                    name: 'rocket',
                    icon: AppIcon.rocket,
                    count: powerups['rocket'] ?? 0,
                    selected: selected.contains('rocket'),
                    onTap: () => setDialogState(
                      () => _toggleBooster(
                        selected,
                        'rocket',
                        powerups['rocket'] ?? 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('CANCEL', style: AppTextStyles.label(fontSize: 14)),
        ),
        JellyButton(
          text: 'PLAY',
          width: 122,
          height: 48,
          fontSize: 18,
          color: JellyColor.green,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );

    if (shouldPlay != true || !mounted) return;
    if (SaveService.I.hearts <= 0 && !await _showOutOfHearts()) return;
    if (!mounted) return;
    if (!SaveService.I.useHeart()) {
      await _showOutOfHearts();
      return;
    }
    await AppNav.go<void>(
      context,
      GameScreen(mode: GameMode.level, level: level),
      style: NavTransition.iris,
    );
  }

  void _toggleBooster(Set<String> selected, String name, int count) {
    if (count <= 0) {
      Toast.show(context, 'No $name boosters available');
      return;
    }
    if (!selected.add(name)) selected.remove(name);
  }

  Future<bool> _showOutOfHearts() async {
    final refilled = await Popup.show<bool>(
      context,
      title: 'OUT OF HEARTS',
      child: Text(
        'Refill your hearts or wait for one to regenerate.',
        textAlign: TextAlign.center,
        style: AppTextStyles.body(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('WAIT', style: AppTextStyles.label(fontSize: 14)),
        ),
        JellyButton(
          text: 'REFILL 100',
          width: 142,
          height: 48,
          fontSize: 15,
          color: JellyColor.green,
          onPressed: () {
            if (!SaveService.I.deductCoins(100)) {
              Toast.show(context, 'Not enough coins');
              return;
            }
            SaveService.I.addHearts(SaveService.kMaxHearts);
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
    return refilled == true;
  }

  void _openShop() {
    AppNav.go<void>(context, const ShopScreen(), style: NavTransition.slide);
  }

  Future<void> _showPlanetBriefing(PlanetDefinition planet) async {
    await Popup.show<void>(
      context,
      title: planet.name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(planet.subtitle, style: AppTextStyles.body(fontSize: 15)),
          const SizedBox(height: 12),
          Text(
            'From level ${planet.mechanicIntroductionLevel}, red embers can '
            'ignite one eligible neighboring bubble after each shot. '
            'At level 60, the spread limit rises to two. The effect is '
            'bounded and never spreads again during that same turn.',
            style: AppTextStyles.body(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            'Complete level ${planet.lastLevel} to earn '
            '${planet.completionRewardCoins} coins.',
            style: AppTextStyles.label(fontSize: 12, color: AppColors.accent),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    _contentHeight = 140 + (_levelCount - 1) * _levelSpacing;
    _viewportHeight = height;

    final offset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    final currentLevel = SaveService.I.currentLevel.clamp(1, _levelCount);
    final unlockedLevel = SaveService.I.unlockedLevel.clamp(1, _levelCount);
    final firstVisible = max(1, ((offset - 220) / _levelSpacing).ceil() + 1);
    final lastVisible = min(
      _levelCount,
      ((height + 230 + offset) / _levelSpacing).floor() + 1,
    );
    final visibleLevels = <Widget>[];
    for (var level = firstVisible; level <= lastVisible; level++) {
      final centerY = height - _contentHeight + _nodeY(level) + offset;
      if (centerY < -150 || centerY > height + 150) continue;
      final stars = SaveService.I.getStarsForLevel(level);
      final state = stars > 0 || level < currentLevel
          ? _LevelNodeState.completed
          : level == currentLevel || level == unlockedLevel
          ? _LevelNodeState.current
          : level <= unlockedLevel
          ? _LevelNodeState.unlocked
          : _LevelNodeState.locked;
      final nodeWidth = level % 10 == 0 ? 104.0 : 78.0;
      final nodeHeight = level % 10 == 0 ? 136.0 : 104.0;
      visibleLevels.add(
        Positioned(
          left: _nodeX(level, width) - nodeWidth / 2,
          top: centerY - nodeHeight + (level % 10 == 0 ? 41 : 31),
          width: nodeWidth,
          height: nodeHeight,
          child: _LevelNode(
            key: ValueKey(level),
            level: level,
            state: state,
            stars: stars,
            boss: level % 10 == 0,
            pulse: _animationController.value,
            animateStars: _seenLevels.add(level),
            onTap: state == _LevelNodeState.locked
                ? () => Toast.show(context, 'Locked')
                : () => _openLevel(level),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SpaceBackground(
        variant: SpaceBgVariant.map,
        showUfos: false,
        showLava: false,
        scrollOffset: _parallaxOffset,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CraterParallaxPainter(_parallaxOffset.value),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomScrollView(
                controller: _scrollController,
                reverse: true,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: CustomPaint(
                      size: Size(width, _contentHeight),
                      painter: _LevelMapPainter(
                        completedThrough: currentLevel - 1,
                        pulse: _animationController.value,
                        cache: _pictureCache,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...visibleLevels,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: HudBar(onAddHearts: _openShop, onAddCoins: _openShop),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 58,
              left: 16,
              right: 16,
              child: _LavaPlanetBanner(
                planet: PlanetRegistry.lava,
                progress: SaveService.I.planetLevelProgress(PlanetId.lava),
                unlocked: SaveService.I.isPlanetUnlocked(PlanetId.lava),
                completed: SaveService.I.isPlanetCompleted(PlanetId.lava),
                pulse: _animationController.value,
                onTap: () => _showPlanetBriefing(PlanetRegistry.lava),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 110,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x000A0826), Color(0x990A0826)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 22,
              child: RoundButton(
                icon: AppIcon.back,
                color: JellyColor.purple,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 22,
              child: RoundButton(
                icon: AppIcon.cart,
                color: JellyColor.orange,
                onPressed: _openShop,
              ),
            ),
            Positioned(
              left: 76,
              right: 76,
              bottom: 22,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RoundButton(
                    icon: AppIcon.gift,
                    color: JellyColor.green,
                    size: 42,
                    pulseRedDot: SaveService.I.dailyClaimable,
                    onPressed: () => AppNav.go<void>(
                      context,
                      const DailyRewardScreen(),
                      style: NavTransition.slide,
                    ),
                  ),
                  RoundButton(
                    icon: AppIcon.replay,
                    color: JellyColor.pink,
                    size: 42,
                    onPressed: () => AppNav.go<void>(
                      context,
                      const SpinScreen(),
                      style: NavTransition.slide,
                    ),
                  ),
                  RoundButton(
                    icon: AppIcon.planet,
                    color: JellyColor.purple,
                    size: 42,
                    onPressed: () => AppNav.go<void>(
                      context,
                      const CatalogScreen(),
                      style: NavTransition.slide,
                    ),
                  ),
                  RoundButton(
                    icon: AppIcon.heart,
                    color: JellyColor.blue,
                    size: 42,
                    onPressed: () => EventPopup.show(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _LevelNodeState { completed, current, unlocked, locked }

class _LevelNode extends StatefulWidget {
  final int level;
  final _LevelNodeState state;
  final int stars;
  final bool boss;
  final double pulse;
  final bool animateStars;
  final VoidCallback onTap;

  const _LevelNode({
    super.key,
    required this.level,
    required this.state,
    required this.stars,
    required this.boss,
    required this.pulse,
    required this.animateStars,
    required this.onTap,
  });

  @override
  State<_LevelNode> createState() => _LevelNodeStatefulState();
}

class _LevelNodeStatefulState extends State<_LevelNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diameter = widget.boss ? 82.0 : 62.0;
    final color = switch (widget.state) {
      _LevelNodeState.completed => const Color(0xFF2AA6EE),
      _LevelNodeState.current => const Color(0xFF2ED58A),
      _LevelNodeState.unlocked => const Color(0xFF7B64E8),
      _LevelNodeState.locked => const Color(0xFF5A6080),
    };
    final ring = diameter + 12 + sin(widget.pulse * 2 * pi) * 3;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (widget.state == _LevelNodeState.locked) {
          _shakeController.forward(from: 0);
        }
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) => Transform.translate(
          offset: Offset(sin(_shakeController.value * pi * 6) * 5, 0),
          child: child,
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            if (widget.boss)
              Positioned(
                top: 0,
                child: CustomPaint(
                  size: const Size(72, 64),
                  painter: _BossBlobPainter(widget.pulse),
                ),
              ),
            if (widget.state == _LevelNodeState.current)
              Positioned(
                top: widget.boss ? 56 : 25,
                child: CustomPaint(
                  size: const Size(38, 38),
                  painter: _MimoIconPainter(widget.pulse),
                ),
              ),
            if (widget.state == _LevelNodeState.completed && widget.stars > 0)
              Positioned(
                top: widget.boss ? 48 : 20,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: widget.animateStars ? 0.15 : 1, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: _GoldStars(count: widget.stars.clamp(1, 3)),
                ),
              ),
            if (widget.state == _LevelNodeState.current)
              Positioned(
                bottom: diameter / 2 + 1 - ring / 2,
                child: Container(
                  width: ring,
                  height: ring,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xAA7CFFCB),
                      width: 2.5,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x557CFFCB), blurRadius: 10),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              child: SizedBox(
                width: diameter,
                height: diameter,
                child: CustomPaint(
                  painter: _NodeBubblePainter(
                    color: color,
                    pulse: widget.pulse,
                  ),
                  child: Center(
                    child: widget.state == _LevelNodeState.locked
                        ? const Icon(
                            Icons.lock_rounded,
                            size: 22,
                            color: Color(0xFFD5D9E2),
                          )
                        : Text(
                            '${widget.level}',
                            style:
                                AppTextStyles.title(
                                  fontSize: widget.boss ? 20 : 18,
                                  color: Colors.white,
                                ).copyWith(
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x99000000),
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldStars extends StatelessWidget {
  final int count;
  const _GoldStars({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Icon(
            Icons.star_rounded,
            size: index == 1 ? 18 : 14,
            color: AppColors.coinGold,
            shadows: const [
              Shadow(
                color: Color(0x99000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LavaPlanetBanner extends StatelessWidget {
  final PlanetDefinition planet;
  final int progress;
  final bool unlocked;
  final bool completed;
  final double pulse;
  final VoidCallback onTap;

  const _LavaPlanetBanner({
    required this.planet,
    required this.progress,
    required this.unlocked,
    required this.completed,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = completed ? Glass.gold : const Color(0xFFFF8248);
    final fraction = progress / planet.levelCount;
    return Semantics(
      button: true,
      label:
          '${planet.name}, $progress of ${planet.levelCount} levels complete',
      child: GestureDetector(
        onTap: unlocked ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          decoration: Glass.surface(
            radius: 20,
            tint: accent,
            glow: 0.08 + pulse * 0.05,
          ),
          foregroundDecoration: Glass.sheen(20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.35, -0.45),
                    colors: [
                      Color(0xFFFFB27A),
                      Color(0xFFE5502A),
                      Color(0xFF7A1D22),
                    ],
                    stops: [0, 0.55, 1],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            planet.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.label(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          completed
                              ? 'Complete'
                              : '$progress/${planet.levelCount}',
                          style: AppTextStyles.label(
                            fontSize: 12,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    GlassProgress(
                      value: fraction.clamp(0.0, 1.0),
                      color: accent,
                      height: 5,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      completed
                          ? 'Planet cleared · ${planet.completionRewardCoins} coins earned'
                          : 'Embers appear at level ${planet.mechanicIntroductionLevel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.info_outline_rounded, color: accent, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}

/// Level node drawn as a small glass bubble, same lighting as the game
/// bubbles: lit from the top-left, thin rim, one specular, soft contact shadow.
class _NodeBubblePainter extends CustomPainter {
  final Color color;
  final double pulse;
  _NodeBubblePainter({required this.color, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * 0.46;
    final c = Offset(size.width / 2, size.height / 2 - 1);
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx, size.height - 1),
        width: r * 1.5,
        height: 6,
      ),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.1,
          colors: [
            Glass.lighten(color, 0.45),
            color,
            Glass.darken(color, 0.35),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );
    // outer edge + inner rim
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Glass.darken(color, 0.5).withValues(alpha: 0.6),
    );
    canvas.drawCircle(
      c,
      r - 1.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.3),
    );
    // bounce light at the bottom
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.78),
      pi * 0.3,
      pi * 0.4,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.16),
    );
    // specular
    canvas.save();
    canvas.translate(c.dx - r * 0.3, c.dy - r * 0.52);
    canvas.rotate(-0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 0.74, height: r * 0.34),
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NodeBubblePainter old) =>
      old.color != color || old.pulse != pulse;
}

class _BossBlobPainter extends CustomPainter {
  final double pulse;
  const _BossBlobPainter(this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final wobble = sin(pulse * 2 * pi) * 2;
    final body = Path()
      ..moveTo(w * 0.12, h * 0.78)
      ..quadraticBezierTo(w * 0.02, h * 0.4, w * 0.3, h * 0.22 + wobble)
      ..quadraticBezierTo(w * 0.5, h * 0.02, w * 0.68, h * 0.22 - wobble)
      ..quadraticBezierTo(w * 1.04, h * 0.35, w * 0.88, h * 0.78)
      ..quadraticBezierTo(w * 0.5, h * 1.05, w * 0.12, h * 0.78)
      ..close();
    final bounds = Offset.zero & size;
    canvas.drawPath(
      body,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.6),
          radius: 1.1,
          colors: [Color(0xFFFFA58E), Color(0xFFE2506F), Color(0xFF8E2250)],
          stops: [0, 0.55, 1],
        ).createShader(bounds),
    );
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.28),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.36, h * 0.27),
        width: w * 0.3,
        height: h * 0.12,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    // eyes with a highlight each
    for (final side in const [-1.0, 1.0]) {
      final e = Offset(w * (0.5 + side * 0.14), h * 0.53);
      canvas.drawCircle(e, 5, Paint()..color = Colors.white);
      canvas.drawCircle(
        e.translate(0, 0.8),
        3,
        Paint()..color = const Color(0xFF27142F),
      );
      canvas.drawCircle(
        e.translate(-1, -0.8),
        1,
        Paint()..color = Colors.white,
      );
    }
    final brow = Paint()
      ..color = const Color(0xFF54203F)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.27, h * 0.41),
      Offset(w * 0.42, h * 0.46),
      brow,
    );
    canvas.drawLine(
      Offset(w * 0.58, h * 0.46),
      Offset(w * 0.73, h * 0.41),
      brow,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w / 2, h * 0.68), width: 12, height: 7),
      pi,
      pi,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BossBlobPainter old) => old.pulse != pulse;
}

class _MimoIconPainter extends CustomPainter {
  final double pulse;
  _MimoIconPainter(this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final hop = sin(pulse * pi * 2).abs() * 5;
    MimoPainter.draw(
      canvas,
      Offset(size.width / 2, size.height / 2 + hop),
      size.width * 0.55,
      state: MimoState.happy,
      t: pulse * 2 * pi,
    );
  }

  @override
  bool shouldRepaint(covariant _MimoIconPainter old) => old.pulse != pulse;
}

/// Two cached pictures: the static starfield + dotted trail, and the part of
/// the trail you have already completed. The old version re-drew every
/// completed dash with a blur filter on each animation frame.
class _MapPictureCache {
  Size? _baseSize;
  ui.Picture? _base;
  Size? _doneSize;
  int _doneThrough = -1;
  ui.Picture? _done;

  ui.Picture base(Size size) {
    if (_base != null && _baseSize == size) return _base!;
    _base?.dispose();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Offset.zero & size);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0x140E0B29),
    );

    final random = Random(84);
    final star = Paint();
    for (var i = 0; i < 200; i++) {
      final point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      canvas.drawCircle(
        point,
        random.nextDouble() * 1.2 + 0.4,
        star
          ..color = Colors.white.withValues(alpha: random.nextDouble() * 0.35),
      );
    }

    final dot = Paint()..color = const Color(0x664793D0);
    for (var level = 1; level < _levelCount; level++) {
      _drawTrail(
        canvas,
        _pointFor(level, size),
        _pointFor(level + 1, size),
        dot,
        spacing: 14,
        radius: 2.2,
      );
    }
    _baseSize = size;
    _base = recorder.endRecording();
    return _base!;
  }

  ui.Picture completed(Size size, int through) {
    if (_done != null && _doneSize == size && _doneThrough == through) {
      return _done!;
    }
    _done?.dispose();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Offset.zero & size);
    final halo = Paint()..color = const Color(0x2231E8F4);
    final dot = Paint()..color = const Color(0xFF7DEBFF);
    for (var level = 1; level <= min(through, _levelCount - 1); level++) {
      final start = _pointFor(level, size);
      final end = _pointFor(level + 1, size);
      _drawTrail(canvas, start, end, halo, spacing: 14, radius: 6);
      _drawTrail(canvas, start, end, dot, spacing: 14, radius: 2.9);
    }
    _doneSize = size;
    _doneThrough = through;
    _done = recorder.endRecording();
    return _done!;
  }

  void dispose() {
    _base?.dispose();
    _done?.dispose();
  }
}

class _CraterParallaxPainter extends CustomPainter {
  final double offset;
  const _CraterParallaxPainter(this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    final centers = [
      Offset(size.width * 0.88, size.height * 0.27 - offset),
      Offset(size.width * 0.13, size.height * 0.72 - offset * 0.72),
    ];
    for (var i = 0; i < centers.length; i++) {
      final center = centers[i];
      final radius = i == 0 ? 84.0 : 66.0;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.4),
            colors: const [
              Color(0x407F5BCB),
              Color(0x227F5BCB),
              Color(0x087F5BCB),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
      for (final crater in [
        Offset(-radius * 0.28, -radius * 0.18),
        Offset(radius * 0.24, radius * 0.2),
      ]) {
        canvas.drawCircle(
          center + crater,
          radius * 0.13,
          Paint()..color = const Color(0x1D08051D),
        );
        canvas.drawCircle(
          center + crater.translate(-2, -2),
          radius * 0.1,
          Paint()..color = const Color(0x147F61C2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CraterParallaxPainter old) =>
      old.offset != offset;
}

class _LevelMapPainter extends CustomPainter {
  final int completedThrough;
  final double pulse;
  final _MapPictureCache cache;

  _LevelMapPainter({
    required this.completedThrough,
    required this.pulse,
    required this.cache,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPicture(cache.base(size));
    if (completedThrough > 0) {
      canvas.drawPicture(cache.completed(size, completedThrough));
    }

    // one small spark travelling toward the next level
    if (completedThrough > 0 && completedThrough < _levelCount) {
      final start = _pointFor(completedThrough, size);
      final end = _pointFor(completedThrough + 1, size);
      final t = (pulse * 1.45) % 1;
      final point = Offset.lerp(start, end, t)!;
      canvas.drawCircle(point, 9, Paint()..color = const Color(0x3331E8F4));
      canvas.drawCircle(point, 3.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _LevelMapPainter old) =>
      old.completedThrough != completedThrough || old.pulse != pulse;
}

Offset _pointFor(int level, Size size) => Offset(
  size.width / 2 + sin((level - 1) * 0.72) * size.width * 0.29,
  size.height - 70 - (level - 1) * _levelSpacing,
);

void _drawTrail(
  Canvas canvas,
  Offset start,
  Offset end,
  Paint paint, {
  required double spacing,
  required double radius,
}) {
  final delta = end - start;
  final length = delta.distance;
  if (length <= 0) return;
  final direction = delta / length;
  // start half a gap in so dots never sit under the level nodes' centers
  for (double d = spacing * 0.5; d < length; d += spacing) {
    canvas.drawCircle(start + direction * d, radius, paint);
  }
}

class _StarPreview extends StatelessWidget {
  const _StarPreview();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      for (var i = 0; i < 3; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Icon(
            Icons.star_rounded,
            color: AppColors.coinGold.withValues(alpha: 0.4),
            size: i == 1 ? 42 : 34,
          ),
        ),
    ],
  );
}

class _BoosterToggle extends StatelessWidget {
  final String name;
  final AppIcon icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _BoosterToggle({
    required this.name,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: count <= 0 ? 0.55 : 1,
    child: SizedBox(
      width: 82,
      child: GlassPanel(
        radius: 16,
        tint: selected ? AppColors.candyGreen : null,
        selected: selected,
        padding: const EdgeInsets.symmetric(vertical: 9),
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CustomPaint(
                painter: _AppIconPainter(icon, AppColors.accent),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${name[0].toUpperCase()}${name.substring(1)}',
              style: AppTextStyles.label(fontSize: 11),
            ),
            Text(
              '×$count',
              style: AppTextStyles.body(fontSize: 12, color: AppColors.accent),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AppIconPainter extends CustomPainter {
  final AppIcon icon;
  final Color color;
  _AppIconPainter(this.icon, this.color);

  @override
  void paint(Canvas canvas, Size size) =>
      IconsPainter.draw(canvas, Offset.zero & size, icon, color: color);

  @override
  bool shouldRepaint(covariant _AppIconPainter old) =>
      old.icon != icon || old.color != color;
}

IconData _goalIcon(GoalType type) => switch (type) {
  GoalType.rescue => Icons.pets_rounded,
  GoalType.clear => Icons.bubble_chart_rounded,
  GoalType.score => Icons.stars_rounded,
  GoalType.timer => Icons.timer_rounded,
  GoalType.boss => Icons.blur_circular_rounded,
};

String _goalDescription(Goal goal) => switch (goal.type) {
  GoalType.rescue => 'Rescue ${goal.target} cats',
  GoalType.clear => 'Clear all bubbles',
  GoalType.score => 'Score ${goal.target} points',
  GoalType.timer => 'Clear the board in ${goal.target} seconds',
  GoalType.boss => 'Defeat the elemental boss',
};
