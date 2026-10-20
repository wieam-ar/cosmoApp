import 'dart:math';

import 'package:flutter/material.dart';

import '../art/icons_painter.dart';
import '../art/jelly_painter.dart';
import '../art/space_painter.dart';
import '../core/audio_service.dart';
import '../core/constants.dart';
import '../core/save_service.dart';
import '../core/theme.dart' hide GlassPanel;
import '../widgets/glass_ui.dart';
import '../widgets/jelly_button.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _background;

  static const _thresholds = [50, 100, 200, 200];
  static const _rewards = ['100 COINS', '250 COINS', '500 COINS', '25 GEMS'];

  @override
  void initState() {
    super.initState();
    _background = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 32),
    )..repeat();
  }

  @override
  void dispose() {
    _background.dispose();
    super.dispose();
  }

  String _timeRemaining() {
    final now = DateTime.now();
    final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
    final nextMonday = DateTime(
      now.year,
      now.month,
      now.day + (daysUntilMonday == 0 ? 7 : daysUntilMonday),
    );
    final remaining = nextMonday.difference(now);
    return '${remaining.inDays}d ${remaining.inHours.remainder(24)}h left';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _background,
              builder: (_, _) => CustomPaint(
                painter: _MissionsBackground(_background.value * 2 * pi),
              ),
            ),
          ),
          SafeArea(
            child: ListenableBuilder(
              listenable: SaveService.I,
              builder: (context, _) {
                final progress = SaveService.I.eventProgress.clamp(0, 200);
                final claimed = SaveService.I.claimedEventTiers;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
                        child: Row(
                          children: [
                            RoundButton(
                              icon: AppIcon.back,
                              color: JellyColor.purple,
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'MISSIONS',
                                style: AppTextStyles.title(
                                  fontSize: 23,
                                  color: AppColors.coinGold,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.monetization_on_rounded,
                              color: AppColors.coinGold,
                              size: 20,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${SaveService.I.coins}',
                              style: AppTextStyles.label(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                      sliver: SliverList.list(
                        children: [
                          _eventPanel(progress),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'WEEKLY REWARDS',
                                  style: AppTextStyles.label(
                                    fontSize: 15,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                              GlassPill(
                                icon: Icons.schedule_rounded,
                                text: _timeRemaining(),
                                color: AppColors.candyBlueLight,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          for (
                            var index = 0;
                            index < _thresholds.length;
                            index++
                          ) ...[
                            _MissionReward(
                              tier: index + 1,
                              threshold: _thresholds[index],
                              reward: _rewards[index],
                              progress: progress,
                              claimed: claimed.contains(index + 1),
                              onClaim: () {
                                final didClaim = SaveService.I.claimEventTier(
                                  index + 1,
                                );
                                if (didClaim) Sfx.play(SfxName.coin);
                              },
                            ),
                            const SizedBox(height: 9),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Rescue kittens in any game mode to earn mission progress.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventPanel(int progress) {
    return GlassPanel(
      radius: 24,
      tint: AppColors.candyPurpleLight,
      glow: 0.16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.candyPurpleLight.withValues(alpha: 0.2),
                  border: Border.all(
                    color: AppColors.candyPurpleLight.withValues(alpha: 0.8),
                  ),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: AppColors.accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAT RESCUE WEEK',
                      style: AppTextStyles.label(
                        fontSize: 15,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Rescue kittens and collect gifts',
                      style: AppTextStyles.body(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KITTENS RESCUED',
                style: AppTextStyles.label(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$progress / 200',
                style: AppTextStyles.label(
                  fontSize: 13,
                  color: AppColors.candyGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GlassProgress(
            value: progress / 200,
            color: AppColors.candyGreen,
            height: 11,
          ),
          const SizedBox(height: 10),
          Text(
            'Every rescued kitten brings you closer to the next reward.',
            style: AppTextStyles.body(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionReward extends StatelessWidget {
  const _MissionReward({
    required this.tier,
    required this.threshold,
    required this.reward,
    required this.progress,
    required this.claimed,
    required this.onClaim,
  });

  final int tier;
  final int threshold;
  final String reward;
  final int progress;
  final bool claimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final unlocked = progress >= threshold;
    final color = tier == 4 ? AppColors.candyBlueLight : AppColors.coinGold;

    return GlassPanel(
      radius: 18,
      tint: color,
      glow: unlocked && !claimed ? 0.13 : 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(
              tier == 4 ? Icons.diamond_rounded : Icons.card_giftcard_rounded,
              color: color,
              size: 23,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$threshold RESCUES',
                  style: AppTextStyles.label(fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  reward,
                  style: AppTextStyles.body(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (claimed)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.candyGreen,
              size: 26,
            )
          else
            JellyButton(
              text: unlocked
                  ? 'CLAIM'
                  : '${progress.clamp(0, threshold)}/$threshold',
              width: unlocked ? 82 : 100,
              height: 38,
              fontSize: 10,
              color: unlocked ? JellyColor.green : JellyColor.purple,
              enabled: unlocked,
              onPressed: unlocked ? onClaim : null,
            ),
        ],
      ),
    );
  }
}

class _MissionsBackground extends CustomPainter {
  const _MissionsBackground(this.time);

  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    SpacePainter.nebula(canvas, size, t: time);
    SpacePainter.starfield(canvas, size, t: time);
  }

  @override
  bool shouldRepaint(covariant _MissionsBackground oldDelegate) =>
      oldDelegate.time != time;
}
