import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../art/bubble_painter.dart';
import '../../art/icons_painter.dart';
import '../../art/jelly_painter.dart';
import '../../art/mimo_painter.dart';
import '../../art/title3d.dart';
import '../../config/bubble_types.dart';
import '../../config/planet_config.dart';
import '../../core/audio_service.dart';
import '../../core/constants.dart';
import '../../core/save_service.dart';
import '../../core/theme.dart';
import '../../core/transitions.dart';
import '../../screens/game_screen.dart';
import '../../widgets/jelly_button.dart';
import '../../widgets/popup.dart';
import '../cosmo_game.dart';

class ResultOverlay extends StatefulWidget {
  final CosmoGame game;
  final VoidCallback onExit;

  const ResultOverlay({super.key, required this.game, required this.onExit});

  @override
  State<ResultOverlay> createState() => _ResultOverlayState();
}

class _ResultOverlayState extends State<ResultOverlay>
    with TickerProviderStateMixin {
  late final bool _won;
  late final bool _scoreMode;
  late final int _stars;
  late final int _reward;
  late final int _planetReward;
  final List<int> _newCats = [];
  final List<int> _catDisplayIds = [];
  late final AnimationController _panelController;
  late final AnimationController _coinController;
  late final AnimationController _fireworksController;
  late final AnimationController _badgeController;
  late final List<AnimationController> _starControllers;
  int _lastCoinTick = -1;
  int _visibleCats = 0;
  int? _demoCountdown;
  bool _demoRunning = false;

  CosmoGame get game => widget.game;

  @override
  void initState() {
    super.initState();
    _won = game.didWin;
    _scoreMode = game.mode == GameMode.arcade || game.mode == GameMode.classic;
    _stars = game.mode == GameMode.level ? game.earnedStars : 0;
    _reward = _won ? 50 + _stars * 25 + game.goal.rescued * 5 : 0;
    _planetReward = game.planetCompletionRewardEarned
        ? PlanetRegistry.lava.completionRewardCoins
        : 0;

    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fireworksController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _starControllers = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 560),
      ),
    );

    if (_won) {
      _coinController.forward();
      if (game.isNewBest) _badgeController.repeat(reverse: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _settleWinRewards();
        _playWinCelebration();
      });
    } else {
      game.particles.shakeCamera(2.2, duration: 0.28);
    }
  }

  void _settleWinRewards() {
    final catRandom = Random(game.level * 7919 + game.score);
    _newCats.addAll(
      SaveService.I.addCats(game.goal.rescued, random: catRandom),
    );
    if (game.goal.rescued > 0) {
      SaveService.I.addEventProgress(game.goal.rescued);
    }
    if (_reward > 0) SaveService.I.addCoins(_reward);
    _catDisplayIds.addAll(_newCats);
  }

  Future<void> _playWinCelebration() async {
    for (var index = 0; index < _stars; index++) {
      await Future<void>.delayed(const Duration(milliseconds: 260));
      if (!mounted) return;
      _starControllers[index].forward();
      Sfx.play(SfxName.star, pitch: 1 + index * 0.14);
    }
    for (var index = 0; index < _catDisplayIds.length; index++) {
      await Future<void>.delayed(const Duration(milliseconds: 170));
      if (!mounted) return;
      setState(() => _visibleCats = index + 1);
    }
  }

  @override
  void dispose() {
    _panelController.dispose();
    _coinController.dispose();
    _fireworksController.dispose();
    _badgeController.dispose();
    for (final controller in _starControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _retry() async {
    if (!SaveService.I.useHeart()) {
      await _showOutOfHearts();
      return;
    }
    if (mounted) game.restart();
  }

  Future<void> _showOutOfHearts() async {
    final refill = await Popup.show<bool>(
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
    if (refill == true && mounted && SaveService.I.useHeart()) {
      game.restart();
    }
  }

  void _buyContinue() {
    if (!SaveService.I.deductCoins(200)) {
      Toast.show(context, 'Not enough coins');
      return;
    }
    game.continueWithExtraMoves(5);
  }

  Future<void> _watchDemoAd() async {
    if (_demoRunning) return;
    setState(() {
      _demoRunning = true;
      _demoCountdown = 3;
    });
    for (var seconds = 3; seconds > 0; seconds--) {
      if (!mounted) return;
      setState(() => _demoCountdown = seconds);
      Sfx.play(SfxName.tick);
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    game.continueWithExtraMoves(5);
  }

  void _next() {
    if (game.mode == GameMode.level && game.level < 120) {
      AppNav.go<void>(
        context,
        GameScreen(mode: GameMode.level, level: game.level + 1),
        replace: true,
      );
    } else {
      widget.onExit();
    }
  }

  Future<void> _shareResult() async {
    final text = _scoreMode
        ? 'I scored ${game.score} in Cosmo Pop ${game.mode.name}!'
        : 'I completed level ${game.level} in Cosmo Pop with $_stars stars!';
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final title = _won
        ? game.mode == GameMode.level
              ? 'LEVEL ${game.level} COMPLETE!'
              : 'MISSION COMPLETE!'
        : game.lossReason;
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: ColoredBox(
                color: _won ? const Color(0xB80B0927) : const Color(0xCC250816),
              ),
            ),
          ),
          if (_won)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _fireworksController,
                  builder: (context, _) => CustomPaint(
                    painter: _FireworksPainter(_fireworksController.value),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.center,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _panelController,
                  curve: Curves.elasticOut,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.91,
                  ),
                  child: SingleChildScrollView(
                    child: Container(
                      width: min(MediaQuery.sizeOf(context).width - 32, 390),
                      margin: const EdgeInsets.symmetric(vertical: 18),
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _won
                              ? const [Color(0xFF5A44C8), Color(0xFF211862)]
                              : const [Color(0xFF712747), Color(0xFF32183C)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _won
                              ? const Color(0xFFFFD76A)
                              : const Color(0xFFFF6B81),
                          width: 3,
                        ),
                        boxShadow: [
                          const BoxShadow(
                            color: Color(0xB3000000),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                          BoxShadow(
                            color:
                                (_won
                                        ? const Color(0xFFFFD76A)
                                        : const Color(0xFFFF6B81))
                                    .withValues(alpha: 0.35),
                            blurRadius: 34,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomPaint(
                            size: Size(
                              min(MediaQuery.sizeOf(context).width - 80, 340),
                              58,
                            ),
                            painter: _ResultTitlePainter(
                              text: title,
                              won: _won,
                            ),
                          ),
                          const SizedBox(height: 3),
                          SizedBox(
                            height: 104,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (!_won)
                                  const Positioned(
                                    top: 0,
                                    right: 54,
                                    child: Icon(
                                      Icons.cloud_rounded,
                                      size: 38,
                                      color: Color(0xFFCED7E8),
                                    ),
                                  ),
                                if (!_won)
                                  const Positioned(
                                    top: 28,
                                    right: 68,
                                    child: Icon(
                                      Icons.water_drop_rounded,
                                      size: 13,
                                      color: Color(0xFF70A1FF),
                                    ),
                                  ),
                                AnimatedBuilder(
                                  animation: _fireworksController,
                                  builder: (context, _) => CustomPaint(
                                    size: const Size(118, 100),
                                    painter: _MimoResultPainter(
                                      won: _won,
                                      time: _fireworksController.value * 2 * pi,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (game.bossEncounter != null) ...[
                            Text(
                              _won
                                  ? 'VOID KING DEFEATED · '
                                        '${game.bossEncounter!.maxHealth} SHIELDS'
                                  : 'VOID KING · '
                                        '${game.bossEncounter!.stagesCleared}/'
                                        '${game.bossEncounter!.maxHealth} '
                                        'SHIELDS BROKEN',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.label(
                                fontSize: 11,
                                color: _won
                                    ? const Color(0xFFFFE184)
                                    : const Color(0xFFD5BDFF),
                              ),
                            ),
                            const SizedBox(height: 5),
                          ],
                          if (_scoreMode) ...[
                            Text(
                              'SCORE',
                              style: AppTextStyles.label(fontSize: 13),
                            ),
                            Text(
                              '${game.score}',
                              style: AppTextStyles.title(
                                fontSize: 36,
                                color: AppColors.accent,
                              ),
                            ),
                            Text(
                              'BEST SCORE  ${SaveService.I.highscores[game.mode.name] ?? 0}',
                              style: AppTextStyles.label(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (game.isNewBest) _buildNewBestBadge(),
                          ] else if (_won) ...[
                            if (game.mode == GameMode.level) _buildStars(),
                            Text(
                              'SCORE  ${game.score}',
                              style: AppTextStyles.label(
                                fontSize: 17,
                                color: AppColors.accent,
                              ),
                            ),
                            if (game.isNewBest) _buildNewBestBadge(),
                          ] else ...[
                            Text(
                              'SCORE  ${game.score}',
                              style: AppTextStyles.label(
                                fontSize: 18,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                          if (_won) ...[
                            const SizedBox(height: 8),
                            _buildCoinReward(),
                            if (_planetReward > 0) ...[
                              const SizedBox(height: 5),
                              Text(
                                'LAVA PLANET COMPLETE · +$_planetReward COINS',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.label(
                                  fontSize: 11,
                                  color: const Color(0xFFFFAA54),
                                ),
                              ),
                            ],
                            if (game.gardenProgressUpdate?.rewards.isNotEmpty ??
                                false) ...[
                              const SizedBox(height: 6),
                              Text(
                                'GARDEN GIFT · ${game.gardenProgressUpdate!.rewards.join(' · ')}',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.label(
                                  fontSize: 10,
                                  color: const Color(0xFF9CF4C0),
                                ),
                              ),
                            ],
                            if (_catDisplayIds.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'RESCUED KITTENS!',
                                style: AppTextStyles.label(
                                  fontSize: 13,
                                  color: AppColors.candyPurpleLight,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                children: List.generate(
                                  _visibleCats,
                                  (index) => _CatBubble(
                                    key: ValueKey(
                                      '$index-${_catDisplayIds[index]}',
                                    ),
                                    catId: _catDisplayIds[index],
                                    index: index,
                                  ),
                                ),
                              ),
                            ],
                            if (game.goal.rescued > 0 && _catDisplayIds.isEmpty)
                              Text(
                                '${game.goal.rescued} RESCUED · ALL ALREADY IN YOUR CREW',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.label(
                                  fontSize: 10,
                                  color: AppColors.candyGreen,
                                ),
                              ),
                          ],
                          const SizedBox(height: 15),
                          if (_won) _buildWinButtons() else _buildLoseButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 12,
            child: RoundButton(
              icon: AppIcon.home,
              color: JellyColor.blue,
              size: 48,
              onPressed: widget.onExit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStars() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final earned = index < _stars;
          final animation = CurvedAnimation(
            parent: _starControllers[index],
            curve: Curves.elasticOut,
          );
          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final scale = earned ? animation.value : 1.0;
              return Transform.rotate(
                angle: earned
                    ? (1 - animation.value) * (index.isEven ? -0.5 : 0.5)
                    : 0,
                child: Transform.translate(
                  offset: earned
                      ? Offset(
                          (index == 0
                                  ? -72
                                  : index == 2
                                  ? 72
                                  : 0) *
                              (1 - animation.value),
                          20 * (1 - animation.value),
                        )
                      : Offset.zero,
                  child: Transform.scale(
                    scale: scale,
                    child: SizedBox(
                      width: 62,
                      height: 62,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (earned)
                            CustomPaint(
                              size: const Size(62, 62),
                              painter: _StarSparklePainter(animation.value),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            child: Icon(
                              Icons.star_rounded,
                              size: 49,
                              color: earned
                                  ? AppColors.coinGold
                                  : const Color(0xFF737486),
                              shadows: earned
                                  ? const [
                                      Shadow(
                                        color: Colors.orange,
                                        blurRadius: 14,
                                      ),
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : const [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 4,
                                      ),
                                    ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildNewBestBadge() {
    return AnimatedBuilder(
      animation: _badgeController,
      builder: (context, child) => Transform.rotate(
        angle: sin(_badgeController.value * pi * 2) * 0.055,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.candyRed,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Text(
          'NEW BEST!',
          style: AppTextStyles.label(fontSize: 13, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCoinReward() {
    return AnimatedBuilder(
      animation: _coinController,
      builder: (context, _) {
        final amount =
            (_reward * Curves.easeOutCubic.transform(_coinController.value))
                .round();
        final tick = amount ~/ 10;
        if (tick > _lastCoinTick) {
          _lastCoinTick = tick;
          if (tick > 0) Sfx.play(SfxName.tick, pitch: 0.9 + tick % 5 * 0.04);
        }
        return Transform.translate(
          offset: Offset(0, 18 * (1 - _coinController.value)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                color: AppColors.coinGold,
                size: 27,
              ),
              const SizedBox(width: 5),
              Text(
                '+$amount',
                style: AppTextStyles.title(
                  fontSize: 24,
                  color: AppColors.coinGold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWinButtons() {
    return Column(
      children: [
        JellyButton(
          text: game.mode == GameMode.level ? 'NEXT' : 'CONTINUE',
          width: 250,
          color: JellyColor.green,
          onPressed: _next,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            JellyButton(
              text: 'REPLAY',
              width: 142,
              height: 49,
              fontSize: 16,
              color: JellyColor.orange,
              onPressed: game.restart,
            ),
            const SizedBox(width: 10),
            JellyButton(
              text: 'SHARE',
              width: 142,
              height: 49,
              fontSize: 16,
              color: JellyColor.blue,
              onPressed: _shareResult,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoseButtons() {
    return Column(
      children: [
        JellyButton(
          text: '+5 MOVES - 200 COINS',
          width: 270,
          height: 52,
          fontSize: 15,
          color: JellyColor.green,
          onPressed: _buyContinue,
        ),
        const SizedBox(height: 8),
        JellyButton(
          text: _demoCountdown == null
              ? 'WATCH AD (DEMO)'
              : 'DEMO  $_demoCountdown',
          width: 230,
          height: 48,
          fontSize: 15,
          color: JellyColor.blue,
          enabled: !_demoRunning,
          onPressed: _watchDemoAd,
        ),
        const SizedBox(height: 8),
        JellyButton(
          text: 'RETRY - 1 HEART',
          width: 230,
          color: JellyColor.orange,
          onPressed: _retry,
        ),
      ],
    );
  }
}

class _ResultTitlePainter extends CustomPainter {
  final String text;
  final bool won;

  const _ResultTitlePainter({required this.text, required this.won});

  @override
  void paint(Canvas canvas, Size size) {
    Title3D.draw(
      canvas,
      text,
      Offset(size.width / 2, size.height / 2),
      fontSize: text.length > 19
          ? 22
          : text.length > 15
          ? 25
          : 32,
      fillTop: won ? const Color(0xFFFFFFDC) : const Color(0xFFFFA4B3),
      fillBottom: won ? AppColors.coinGold : AppColors.candyRed,
      extrusionColor: won ? const Color(0xFF583C21) : const Color(0xFF43112F),
    );
  }

  @override
  bool shouldRepaint(covariant _ResultTitlePainter oldDelegate) =>
      oldDelegate.text != text || oldDelegate.won != won;
}

class _MimoResultPainter extends CustomPainter {
  final bool won;
  final double time;

  const _MimoResultPainter({required this.won, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    MimoPainter.draw(
      canvas,
      Offset(size.width / 2, size.height / 2 + 7),
      88,
      state: won ? MimoState.cheer : MimoState.sad,
      t: time,
    );
  }

  @override
  bool shouldRepaint(covariant _MimoResultPainter oldDelegate) =>
      oldDelegate.won != won || oldDelegate.time != time;
}

class _StarSparklePainter extends CustomPainter {
  final double progress;

  const _StarSparklePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final phase = progress * 2 * pi;
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: (1 - progress) * 0.9)
      ..blendMode = BlendMode.plus
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    for (var ray = 0; ray < 8; ray++) {
      final angle = ray * pi / 4 + phase;
      final direction = Offset(cos(angle), sin(angle));
      canvas.drawLine(
        center + direction * 23,
        center + direction * (29 + progress * 3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarSparklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CatBubble extends StatelessWidget {
  final int catId;
  final int index;

  const _CatBubble({super.key, required this.catId, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + index * 70),
      curve: Curves.elasticOut,
      builder: (context, scale, _) => Transform.translate(
        offset: Offset(0, sin(scale * pi * 2) * 5),
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(
                0xFF000000 | ((catId * 0x24145B + 0x9B59B6) & 0xFFFFFF),
              ),
              border: Border.all(color: AppColors.accent, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x885F55E8), blurRadius: 8),
              ],
            ),
            child: CustomPaint(painter: _CatBubblePainter(t: index.toDouble())),
          ),
        ),
      ),
    );
  }
}

class _CatBubblePainter extends CustomPainter {
  final double t;
  const _CatBubblePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    BubblePainter.draw(
      canvas,
      Offset(size.width / 2, size.height / 2),
      size.width * 0.43,
      BubbleType.purple,
      t: t,
    );
  }

  @override
  bool shouldRepaint(covariant _CatBubblePainter oldDelegate) =>
      oldDelegate.t != t;
}

class _FireworksPainter extends CustomPainter {
  final double phase;

  const _FireworksPainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Color(0xFFFFD700),
      Color(0xFF31E8F4),
      Color(0xFFFF6B81),
      Color(0xFF7BED9F),
    ];
    final centers = [
      Offset(size.width * 0.18, size.height * 0.22),
      Offset(size.width * 0.82, size.height * 0.29),
      Offset(size.width * 0.24, size.height * 0.68),
      Offset(size.width * 0.79, size.height * 0.72),
    ];
    for (var burstIndex = 0; burstIndex < centers.length; burstIndex++) {
      final localPhase = (phase + burstIndex * 0.23) % 1;
      final radius = 12 + localPhase * 68;
      final alpha = (1 - localPhase) * 0.88;
      final paint = Paint()
        ..color = colors[burstIndex].withValues(alpha: alpha)
        ..blendMode = BlendMode.plus
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (var ray = 0; ray < 12; ray++) {
        final angle = ray * pi / 6;
        final start =
            centers[burstIndex] +
            Offset(cos(angle), sin(angle)) * (radius * 0.42);
        final end =
            centers[burstIndex] + Offset(cos(angle), sin(angle)) * radius;
        canvas.drawLine(start, end, paint);
        canvas.drawCircle(
          end,
          2.4 * alpha + 0.5,
          paint..style = PaintingStyle.fill,
        );
        paint.style = PaintingStyle.stroke;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
