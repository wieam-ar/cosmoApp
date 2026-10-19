import 'dart:math';

import 'package:flutter/material.dart';

import '../../art/icons_painter.dart';
import '../../art/jelly_painter.dart';
import '../../core/audio_service.dart';
import '../../core/constants.dart';
import '../../core/save_service.dart';
import '../../core/theme.dart';
import '../../widgets/jelly_button.dart';
import '../../widgets/popup.dart';
import '../cosmo_game.dart';
import '../logic/powerups.dart';

/// Shared neon-glass look for every HUD panel.
BoxDecoration _hudDecoration({
  double radius = 18,
  Color border = const Color(0xFF9B7BFF),
}) => BoxDecoration(
  gradient: const LinearGradient(
    colors: [Color(0xEE4A33A8), Color(0xEE231760)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: border, width: 2),
  boxShadow: const [
    BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 3)),
    BoxShadow(color: Color(0x447CF6FF), blurRadius: 10),
  ],
);

class GameHud extends StatefulWidget {
  final CosmoGame game;
  const GameHud({super.key, required this.game});

  @override
  State<GameHud> createState() => _GameHudState();
}

class _GameHudState extends State<GameHud> {
  int _lastStars = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.game.hudState, SaveService.I]),
      builder: (context, _) {
        final state = widget.game.hudState.value;
        final compact = MediaQuery.sizeOf(context).width < 360;
        if (state.stars > _lastStars) {
          for (var i = _lastStars; i < state.stars; i++) {
            Sfx.play(SfxName.star);
          }
        }
        _lastStars = state.stars;
        return Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Transform.translate(
                  offset: state.warning
                      ? Offset(
                          sin(DateTime.now().millisecondsSinceEpoch / 20) * 3,
                          0,
                        )
                      : Offset.zero,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RescuePill(
                              rescued: state.rescued,
                              target: state.target,
                              label: state.goalLabel,
                            ),
                            const Spacer(),
                            _ScorePanel(
                              score: state.score,
                              movesLeft: state.movesLeft,
                              stars: state.stars,
                              starProgress: state.starProgress,
                            ),
                            const Spacer(),
                            RoundButton(
                              icon: AppIcon.pause,
                              color: JellyColor.purple,
                              size: 48,
                              onPressed: widget.game.openPause,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _CatAbilityMeter(
                          catName: state.companionCatName,
                          skillName: state.catSkillName,
                          chargeProgress:
                              state.catAbilityCharge /
                              state.catSkillRequiredCharge,
                          cooldownShots: state.catSkillCooldown,
                          onTap: widget.game.activateCatSkill,
                        ),
                        if (state.hasBoss) ...[
                          const SizedBox(height: 7),
                          _BossEncounterPanel(state: state),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: compact ? 18 : 26,
              right: compact ? 18 : 26,
              bottom: 18,
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BoosterSlot(
                      icon: AppIcon.bomb,
                      label: 'BOMB',
                      locked: !widget.game.isPowerupUnlocked('bomb'),
                      count: widget.game.powerupCount('bomb'),
                      onTap: () => _onPowerupTap(context, 'bomb'),
                    ),
                    _BoosterSlot(
                      icon: AppIcon.planet,
                      label: 'RAINBOW',
                      locked: !widget.game.isPowerupUnlocked('rainbow'),
                      count: widget.game.powerupCount('rainbow'),
                      onTap: () => _onPowerupTap(context, 'rainbow'),
                    ),
                    _BoosterSlot(
                      icon: AppIcon.lightning,
                      label: 'LIGHTNING',
                      count: widget.game.powerupCount('lightning'),
                      locked: !widget.game.isPowerupUnlocked('lightning'),
                      onTap: () => _onPowerupTap(context, 'lightning'),
                    ),
                    _BoosterSlot(
                      icon: AppIcon.rocket,
                      label: 'ROCKET',
                      locked: !widget.game.isPowerupUnlocked('rocket'),
                      count: widget.game.powerupCount('rocket'),
                      onTap: () => _onPowerupTap(context, 'rocket'),
                    ),
                  ],
                ),
              ),
            ),
            if (state.activePowerup.isNotEmpty || state.hintActive)
              Positioned(
                top: 118,
                left: 20,
                right: 20,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: _hudDecoration(border: AppColors.accent),
                      child: Text(
                        state.activePowerup.isNotEmpty
                            ? 'TAP A TARGET'
                            : 'TRY THIS MATCH',
                        style: AppTextStyles.label(
                          fontSize: 13,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _onPowerupTap(BuildContext context, String id) {
    if (!widget.game.isPowerupUnlocked(id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${id[0].toUpperCase()}${id.substring(1)} is still locked. Keep playing to unlock it!',
          ),
          duration: const Duration(milliseconds: 900),
        ),
      );
      return;
    }
    final count = widget.game.powerupCount(id);
    if (count == 0) {
      final definition = PowerupLogic.definition(id)!;
      Popup.show<void>(
        context,
        title: 'GET ${id.toUpperCase()}',
        child: Text(
          'Buy 1 $id power-up for ${definition.price} coins?\nCoins: ${SaveService.I.coins}',
          textAlign: TextAlign.center,
          style: AppTextStyles.body(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('CANCEL', style: AppTextStyles.label(fontSize: 13)),
          ),
          JellyButton(
            text: 'BUY ${definition.price}',
            width: 140,
            height: 48,
            fontSize: 15,
            color: JellyColor.green,
            onPressed: () {
              if (!PowerupLogic.purchase(id)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Not enough coins')),
                );
                return;
              }
              Sfx.play(SfxName.coin);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
      return;
    }
    if (!widget.game.usePowerup(id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot use $id right now'),
          duration: const Duration(milliseconds: 900),
        ),
      );
    }
  }
}

class _BossEncounterPanel extends StatelessWidget {
  final GameHudState state;

  const _BossEncounterPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final health = state.bossHealth / max(1, state.bossMaxHealth);
    return Container(
      width: min(MediaQuery.sizeOf(context).width - 42, 300),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: _hudDecoration(radius: 14, border: const Color(0xFFC5A5FF)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.blur_circular_rounded,
                color: Color(0xFFD5BDFF),
                size: 19,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  state.bossName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label(fontSize: 10),
                ),
              ),
              Text(
                '${state.bossHealth}/${state.bossMaxHealth}',
                style: AppTextStyles.label(
                  fontSize: 11,
                  color: const Color(0xFFFFE184),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'STAGE ${min(state.bossStage + 1, state.bossStageCount)}/${state.bossStageCount}',
                style: AppTextStyles.label(fontSize: 8),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: health,
              minHeight: 5,
              backgroundColor: Colors.black38,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFC5A5FF),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  state.bossHealth == 0
                      ? 'CORE EXPOSED'
                      : '${state.bossStageTitle} · WEAK TO ${state.bossWeakness}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label(
                    fontSize: 8,
                    color: const Color(0xFFE4D7FF),
                  ),
                ),
              ),
              Text(
                state.bossTelegraph,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label(
                  fontSize: 7,
                  color: const Color(0xFFFFB48F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RescuePill extends StatelessWidget {
  final int rescued;
  final int target;
  final String label;

  const _RescuePill({
    required this.rescued,
    required this.target,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final hasRescueGoal = label == 'rescue';
    return Container(
      constraints: const BoxConstraints(minWidth: 92, minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: _hudDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasRescueGoal ? Icons.pets_rounded : Icons.bubble_chart_rounded,
            color: AppColors.accent,
            size: 24,
          ),
          const SizedBox(width: 5),
          Text(
            hasRescueGoal ? '$rescued/$target' : label.toUpperCase(),
            style: AppTextStyles.label(fontSize: hasRescueGoal ? 15 : 12),
          ),
        ],
      ),
    );
  }
}

class _ScorePanel extends StatefulWidget {
  final int score;
  final int movesLeft;
  final int stars;
  final double starProgress;

  const _ScorePanel({
    required this.score,
    required this.movesLeft,
    required this.stars,
    required this.starProgress,
  });

  @override
  State<_ScorePanel> createState() => _ScorePanelState();
}

class _ScorePanelState extends State<_ScorePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _countController;
  late Animation<int> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _scoreAnimation = IntTween(begin: widget.score, end: widget.score).animate(
      CurvedAnimation(parent: _countController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant _ScorePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _scoreAnimation =
          IntTween(begin: _scoreAnimation.value, end: widget.score).animate(
            CurvedAnimation(
              parent: _countController,
              curve: Curves.easeOutCubic,
            ),
          );
      _countController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
          decoration: _hudDecoration(),
          child: AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, _) => Text(
              '${_scoreAnimation.value}',
              style: AppTextStyles.title(fontSize: 22, color: AppColors.accent),
            ),
          ),
        ),
        if (widget.movesLeft >= 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${widget.movesLeft} MOVES',
              style: AppTextStyles.label(fontSize: 11),
            ),
          ),
        const SizedBox(height: 4),
        SizedBox(
          width: 124,
          height: 15,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF231B53),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white70, width: 1),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: widget.starProgress,
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC6FF9A), Color(0xFF2ED573)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  3,
                  (index) => Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: index < widget.stars
                        ? AppColors.coinGold
                        : Colors.white70,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BoosterSlot extends StatelessWidget {
  final AppIcon icon;
  final String label;
  final int count;
  final bool locked;
  final VoidCallback onTap;

  const _BoosterSlot({
    required this.icon,
    required this.label,
    required this.count,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: locked ? 0.65 : 1,
        child: TweenAnimationBuilder<double>(
          key: ValueKey('$count-$locked'),
          tween: Tween(begin: 0.92, end: 1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: SizedBox(
            width: 68,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: locked
                              ? const [Color(0xFF5A5478), Color(0xFF2A2644)]
                              : const [Color(0xFF8A63F0), Color(0xFF2B1670)],
                          center: const Alignment(-0.3, -0.4),
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: locked
                              ? Colors.white38
                              : const Color(0xFFBDFBFF),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                          if (!locked && count > 0)
                            BoxShadow(
                              color: Color(0xFF7CF6FF).withValues(alpha: 0.5),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: CustomPaint(
                        painter: _HudIconPainter(icon: icon, locked: locked),
                      ),
                    ),
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.candyRed,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Text(
                          locked
                              ? 'LOCK'
                              : count == 0
                              ? '+'
                              : '$count',
                          style: AppTextStyles.label(fontSize: 9),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(label, style: AppTextStyles.label(fontSize: 8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HudIconPainter extends CustomPainter {
  final AppIcon icon;
  final bool locked;

  const _HudIconPainter({required this.icon, required this.locked});

  @override
  void paint(Canvas canvas, Size size) {
    IconsPainter.draw(
      canvas,
      Offset.zero & size,
      locked ? AppIcon.padlock : icon,
      color: locked ? Colors.white54 : AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(covariant _HudIconPainter old) =>
      old.icon != icon || old.locked != locked;
}

class _CatAbilityMeter extends StatelessWidget {
  final String catName;
  final String skillName;
  final double chargeProgress;
  final int cooldownShots;
  final VoidCallback onTap;

  const _CatAbilityMeter({
    required this.catName,
    required this.skillName,
    required this.chargeProgress,
    required this.cooldownShots,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (chargeProgress * 100).clamp(0, 100).toInt();
    final isFull = chargeProgress >= 1.0;
    final canActivate = isFull && cooldownShots == 0;

    return InkWell(
      onTap: canActivate ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xDD1B1238),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canActivate ? AppColors.coinGold : AppColors.primary,
            width: canActivate ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (canActivate)
              BoxShadow(
                color: AppColors.coinGold.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pets,
              size: 14,
              color: canActivate
                  ? AppColors.coinGold
                  : AppColors.candyPurpleLight,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isFull
                            ? skillName.toUpperCase()
                            : catName.toUpperCase(),
                        style: AppTextStyles.label(
                          fontSize: 9,
                          color: canActivate
                              ? AppColors.coinGold
                              : AppColors.accent,
                        ),
                      ),
                      Text(
                        cooldownShots > 0
                            ? '$cooldownShots SHOTS'
                            : canActivate
                            ? 'TAP!'
                            : isFull
                            ? 'WAIT'
                            : '$percent%',
                        style: AppTextStyles.label(
                          fontSize: 8,
                          color: canActivate
                              ? AppColors.candyGreen
                              : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: chargeProgress,
                      minHeight: 5,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        canActivate
                            ? AppColors.coinGold
                            : AppColors.candyPurpleLight,
                      ),
                    ),
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
