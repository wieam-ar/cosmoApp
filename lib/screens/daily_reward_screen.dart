import 'dart:math';

import 'package:flutter/material.dart';

import '../art/jelly_painter.dart';
import '../core/audio_service.dart';
import '../core/constants.dart';
import '../core/save_service.dart';
import '../core/theme.dart';
import 'game_screen.dart';
import '../widgets/cosmo_kit.dart';
import '../widgets/glass_ui.dart';
import '../widgets/jelly_button.dart';

class DailyRewardScreen extends StatefulWidget {
  const DailyRewardScreen({super.key});

  @override
  State<DailyRewardScreen> createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends State<DailyRewardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _celebrate;
  bool _claimedHere = false;

  @override
  void initState() {
    super.initState();
    _celebrate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
  }

  @override
  void dispose() {
    _celebrate.dispose();
    super.dispose();
  }

  int get _claimDay => SaveService.I.dailyClaimable
      ? SaveService.I.dailyStreak % 7 + 1
      : SaveService.I.dailyStreak.clamp(1, 7);

  void _claim() {
    if (!SaveService.I.claimDailyReward()) return;
    setState(() => _claimedHere = true);
    _celebrate.forward(from: 0);
    Sfx.play(SfxName.win);
  }

  String _rewardLabel(int day) {
    final reward = SaveService.I.dailyReward(day);
    return [
      if (reward.containsKey('coins')) '${reward['coins']} coins',
      if (reward.containsKey('gems')) '${reward['gems']} gems',
      if (reward.containsKey('bomb')) 'Bomb ×${reward['bomb']}',
      if (reward.containsKey('rainbow')) 'Rainbow ×${reward['rainbow']}',
      if (reward.containsKey('rocket')) 'Rocket ×${reward['rocket']}',
    ].join('\n');
  }

  IconData _rewardIcon(int day) {
    final reward = SaveService.I.dailyReward(day);
    if (day == 7) return Icons.card_giftcard_rounded;
    if (reward.containsKey('gems')) return Icons.diamond_rounded;
    if (reward.containsKey('bomb')) return Icons.local_fire_department_rounded;
    if (reward.containsKey('rainbow')) return Icons.public_rounded;
    if (reward.containsKey('rocket')) return Icons.rocket_launch_rounded;
    return Icons.monetization_on_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: SaveService.I,
          builder: (context, _) {
            final claimable = SaveService.I.dailyClaimable && !_claimedHere;
            final today = _claimDay;
            final claimedDay = _claimedHere || !SaveService.I.dailyClaimable
                ? today
                : 0;

            Widget tile(int day) {
              final isToday = day == today && claimable;
              final hasClaimed =
                  day <= claimedDay || (day < today && !claimable);
              return _DayTile(
                day: day,
                reward: _rewardLabel(day),
                icon: _rewardIcon(day),
                today: isToday,
                claimed: hasClaimed,
                pulse: _celebrate,
              );
            }

            return Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _celebrate,
                      builder: (context, _) => CustomPaint(
                        painter: _RewardBurstPainter(_celebrate.value),
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    const CosmoHeader(
                      title: 'Daily treasure',
                      trailing: CoinPill(),
                    ),
                    GlassPill(
                      icon: Icons.local_fire_department_rounded,
                      text: 'Streak: ${SaveService.I.dailyStreak} days',
                      color: AppColors.candyPurpleLight,
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.78,
                            children: [for (var d = 1; d <= 6; d++) tile(d)],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(height: 132, child: tile(7)),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: Column(
                        children: [
                          Text(
                            claimable
                                ? today == 7
                                      ? 'The mega chest is ready'
                                      : 'Your gift for day $today is ready'
                                : 'Come back tomorrow for the next gift',
                            style: AppTextStyles.body(
                              fontSize: 14,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 10),
                          JellyButton(
                            text: claimable ? 'CLAIM DAY $today' : 'CLAIMED',
                            width: 245,
                            color: JellyColor.green,
                            enabled: claimable,
                            onPressed: _claim,
                          ),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const GameScreen(mode: GameMode.daily),
                              ),
                            ),
                            icon: const Icon(Icons.bubble_chart_rounded),
                            label: const Text('PLAY DAILY CHALLENGE'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// One day of the week. Days 1-6 cycle through the four element colours,
/// day 7 is a wide card with a bigger bubble.
class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.reward,
    required this.icon,
    required this.today,
    required this.claimed,
    required this.pulse,
  });

  final int day;
  final String reward;
  final IconData icon;
  final bool today;
  final bool claimed;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final big = day == 7;
    final el = CosmoElement.values[(day - 1) % 4];
    final tint = big ? AppColors.coinGold : el.light;

    final bubble = GlassBubble(
      size: big ? 84 : 52,
      tint: tint,
      child: Center(
        child: Icon(icon, size: big ? 44 : 26, color: Colors.white),
      ),
    );

    final label = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Day 7 · Mega chest',
          style: AppTextStyles.label(
            fontSize: 15,
            color: today ? AppColors.accent : Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          reward,
          style: AppTextStyles.label(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );

    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final scale = today ? 1 + sin(pulse.value * pi * 2) * 0.03 : 1.0;
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: claimed ? 0.6 : 1,
            child: Container(
              decoration: Glass.surface(
                radius: 22,
                tint: today ? AppColors.coinGold : tint,
                selected: today,
                glow: today ? 0.3 : 0,
              ),
              foregroundDecoration: Glass.sheen(22),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: big
                        ? Row(
                            children: [
                              bubble,
                              const SizedBox(width: 16),
                              Expanded(child: label),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                'Day $day',
                                style: AppTextStyles.label(
                                  fontSize: 13,
                                  color: today
                                      ? AppColors.accent
                                      : Colors.white,
                                ),
                              ),
                              bubble,
                              Text(
                                reward,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.label(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                  ),
                  if (claimed)
                    const Positioned(
                      right: 8,
                      top: 8,
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.candyGreen,
                        size: 22,
                      ),
                    ),
                  if (big && today && pulse.value > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _ChestRaysPainter(pulse.value),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChestRaysPainter extends CustomPainter {
  const _ChestRaysPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(52, size.height / 2);
    final paint = Paint()
      ..color = AppColors.coinGold.withValues(alpha: (1 - progress) * 0.7)
      ..blendMode = BlendMode.plus
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 16; i++) {
      final angle = i * pi / 8;
      final dir = Offset(cos(angle), sin(angle));
      canvas.drawLine(
        center + dir * 46,
        center + dir * (60 + progress * 20),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChestRaysPainter old) =>
      old.progress != progress;
}

class _RewardBurstPainter extends CustomPainter {
  const _RewardBurstPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height * 0.46);
    const colors = [
      AppColors.coinGold,
      AppColors.candyBlueLight,
      AppColors.candyPurpleLight,
    ];
    for (var i = 0; i < 36; i++) {
      final angle = i * pi * 2 / 36;
      final dir = Offset(cos(angle), sin(angle));
      paint.color = colors[i % 3].withValues(alpha: (1 - progress) * 0.8);
      canvas.drawLine(
        center + dir * progress * 60,
        center + dir * progress * 160,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RewardBurstPainter old) =>
      old.progress != progress;
}
