import 'dart:math';

import 'package:flutter/material.dart';

import '../art/icons_painter.dart';
import '../art/jelly_painter.dart';
import '../core/audio_service.dart';
import '../core/constants.dart';
import '../core/save_service.dart';
import '../game/logic/cat_crew.dart';
import '../core/theme.dart' hide GlassPanel;
import '../widgets/glass_ui.dart';
import '../widgets/jelly_button.dart';
import '../widgets/popup.dart';
import '../widgets/space_background.dart';
import 'codex_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  void _showCat(int id, bool owned) {
    final catData = CatRegistry.getById(id);
    final progress = SaveService.I.catProgress(id);
    final catLevel = progress.level;
    final upgradeCost = progress.upgradeCost;
    final isActive = SaveService.I.activeCatId == id;

    Popup.show<void>(
      context,
      title: owned ? catData.name.toUpperCase() : 'MYSTERY KITTEN',
      borderColor: catData.rarity.color,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: AnimatedBuilder(
              animation: _shimmer,
              builder: (context, _) => CustomPaint(
                painter: _KittenPainter(
                  id: id,
                  revealed: owned,
                  time: _shimmer.value,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (owned) ...[
            Text(
              catData.description,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(fontSize: 13),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                GlassPill(
                  text: '${catData.rarity.label} · LV $catLevel',
                  color: catData.rarity.color,
                ),
                GlassPill(
                  text: catData.element.name,
                  color: catData.element.color,
                ),
              ],
            ),
            const SizedBox(height: 10),
            GlassPanel(
              radius: 14,
              padding: const EdgeInsets.all(10),
              tint: catData.element.color,
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Text(
                      catData.ability.name.toUpperCase(),
                      style: AppTextStyles.label(
                        fontSize: 12,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      catData.skillDescription,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              progress.isMaxLevel
                  ? 'MAX LEVEL'
                  : 'LEVEL $catLevel → ${catLevel + 1}  ·  $upgradeCost COINS  ·  ${SaveService.I.coins} AVAILABLE',
              textAlign: TextAlign.center,
              style: AppTextStyles.label(
                fontSize: 11,
                color: progress.isMaxLevel
                    ? AppColors.candyGreen
                    : AppColors.coinGold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!progress.isMaxLevel)
                  JellyButton(
                    text: 'UPGRADE $upgradeCost',
                    width: 130,
                    height: 42,
                    fontSize: 11,
                    color: JellyColor.green,
                    onPressed: () async {
                      final confirmed = await Popup.show<bool>(
                        context,
                        title: 'UPGRADE ${catData.name.toUpperCase()}?',
                        borderColor: catData.rarity.color,
                        child: Text(
                          'Spend $upgradeCost coins to reach level ${catLevel + 1}?\n\nCoins available: ${SaveService.I.coins}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body(fontSize: 14),
                        ),
                        actions: [
                          JellyButton(
                            text: 'CANCEL',
                            width: 105,
                            height: 40,
                            fontSize: 11,
                            color: JellyColor.purple,
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                          JellyButton(
                            text: 'UPGRADE',
                            width: 105,
                            height: 40,
                            fontSize: 11,
                            color: JellyColor.green,
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ],
                      );
                      if (!mounted) return;
                      if (confirmed == true &&
                          SaveService.I.upgradeCat(id, upgradeCost)) {
                        Sfx.play(SfxName.coin);
                        Navigator.of(context).pop();
                        _showCat(id, owned);
                      } else if (confirmed == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Not enough coins for this upgrade'),
                          ),
                        );
                      }
                    },
                  ),
                JellyButton(
                  text: isActive ? 'ACTIVE' : 'SELECT',
                  width: 110,
                  height: 42,
                  fontSize: 11,
                  color: isActive ? JellyColor.purple : JellyColor.orange,
                  onPressed: () {
                    SaveService.I.activeCatId = id;
                    Sfx.play(SfxName.click);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ] else ...[
            GlassPill(
              text: '${catData.element.name} · ${catData.rarity.label}',
              color: catData.rarity.color,
            ),
            const SizedBox(height: 12),
            Text(
              catData.unlockCondition,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Text(
              '${catData.ability.name}: ${catData.skillDescription}',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SpaceBackground(
        showUfos: false,
        showLava: false,
        animated: false,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: SaveService.I,
            builder: (context, _) {
              final owned = SaveService.I.cats.toSet();
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
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
                            'CAT-ALOG',
                            style: AppTextStyles.title(
                              fontSize: 22,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CodexScreen(),
                            ),
                          ),
                          child: Tooltip(
                            message: 'Elemental Codex',
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: Glass.surface(
                                radius: 20,
                                tint: AppColors.coinGold,
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: AppColors.coinGold,
                                size: 21,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GlassPill(
                          text: '${owned.length}/${CatRegistry.all.length}',
                          color: AppColors.candyGreen,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
                    child: Row(
                      children: [
                        for (final milestone in const [5, 10, 20])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: _MilestoneCard(
                                milestone: milestone,
                                unlockedCount: owned.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: owned.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.pets_rounded,
                                  color: AppColors.candyPurpleLight,
                                  size: 52,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Your crew is waiting',
                                  style: AppTextStyles.label(
                                    fontSize: 16,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rescue kittens during levels to meet them.',
                                  style: AppTextStyles.body(fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 2, 14, 20),
                            itemCount: CatRegistry.all.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.84,
                                ),
                            itemBuilder: (context, index) {
                              final isOwned = owned.contains(index);
                              final cat = CatRegistry.getById(index);
                              final rarity = _Rarity(
                                cat.rarity.label,
                                cat.rarity.color,
                                cat.rarity.index,
                              );
                              return _KittenTile(
                                id: index,
                                owned: isOwned,
                                active:
                                    isOwned &&
                                    SaveService.I.activeCatId == index,
                                rarity: rarity,
                                shimmer: _shimmer,
                                onTap: () => _showCat(index, isOwned),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final int milestone;
  final int unlockedCount;

  const _MilestoneCard({required this.milestone, required this.unlockedCount});

  @override
  Widget build(BuildContext context) {
    final claimed = SaveService.I.claimedCatalogMilestones.contains(milestone);
    final available = unlockedCount >= milestone;
    final tint = claimed
        ? AppColors.candyGreen
        : available
        ? AppColors.coinGold
        : null;
    return GlassPanel(
      radius: 16,
      tint: tint,
      padding: const EdgeInsets.fromLTRB(9, 9, 9, 9),
      child: Column(
        children: [
          Text(
            '$milestone cats',
            style: AppTextStyles.label(fontSize: 12, color: Colors.white),
          ),
          const SizedBox(height: 6),
          GlassProgress(
            value: unlockedCount / milestone,
            color: claimed ? AppColors.candyGreen : AppColors.coinGold,
            height: 5,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 28,
            child: claimed
                ? const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.candyGreen,
                      size: 22,
                    ),
                  )
                : available
                ? GlassButton(
                    label: 'CLAIM',
                    color: AppColors.candyGreen,
                    height: 28,
                    fontSize: 11,
                    onPressed: () {
                      if (SaveService.I.claimCatalogMilestone(milestone)) {
                        Sfx.play(SfxName.coin);
                      }
                    },
                  )
                : Center(
                    child: Text(
                      '${min(unlockedCount, milestone)}/$milestone',
                      style: AppTextStyles.label(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _KittenTile extends StatelessWidget {
  final int id;
  final bool owned;
  final bool active;
  final _Rarity rarity;
  final Animation<double> shimmer;
  final VoidCallback onTap;

  const _KittenTile({
    required this.id,
    required this.owned,
    required this.active,
    required this.rarity,
    required this.shimmer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cat = CatRegistry.getById(id);
    return AnimatedBuilder(
      animation: shimmer,
      builder: (context, _) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: Glass.surface(
            radius: 20,
            tint: owned ? rarity.color : null,
            selected: active,
            glow: owned && rarity.rank >= 2
                ? 0.12 + 0.08 * sin(shimmer.value * pi * 2)
                : 0,
          ),
          foregroundDecoration: Glass.sheen(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _KittenPainter(
                    id: id,
                    revealed: owned,
                    time: shimmer.value,
                  ),
                ),
              ),
              Positioned(
                left: 6,
                right: 6,
                bottom: 7,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (owned) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: cat.element.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Flexible(
                      child: Text(
                        owned ? cat.name : '???',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label(
                          fontSize: 11,
                          color: owned ? Colors.white : Colors.white54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (active)
                const Positioned(
                  top: 6,
                  left: 6,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 17,
                    color: AppColors.candyGreen,
                  ),
                ),
              if (owned && rarity.rank == 3)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 15,
                    color: AppColors.coinGold.withValues(
                      alpha: 0.6 + 0.4 * sin(shimmer.value * pi * 2).abs(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rarity {
  final String label;
  final Color color;
  final int rank;

  const _Rarity(this.label, this.color, this.rank);
}

/// Kitten portrait in the style of the logo: a soft glass bubble helmet, lit
/// fur, big glossy eyes with two highlights, tiny nose, blush and whiskers.
class _KittenPainter extends CustomPainter {
  final int id;
  final bool revealed;
  final double time;

  const _KittenPainter({
    required this.id,
    required this.revealed,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cat = CatRegistry.getById(id);
    final center = Offset(size.width / 2, size.height * 0.45);
    final unit = min(size.width, size.height) * 0.27;
    final base = revealed
        ? Color(
            cat.visual?.accent ??
                Color.lerp(cat.element.color, Colors.white, 0.25)!.toARGB32(),
          )
        : const Color(0xFF241F4A);
    final bob = revealed ? sin(time * pi * 2 + id) * unit * 0.03 : 0.0;
    final face = center.translate(0, bob);

    // glass helmet (back layer)
    final helmetR = unit * 1.72;
    final helmet = Rect.fromCircle(center: center, radius: helmetR);
    canvas.drawCircle(
      center,
      helmetR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.45),
          colors: [
            Colors.white.withValues(alpha: 0.13),
            Colors.white.withValues(alpha: 0.02),
          ],
        ).createShader(helmet),
    );

    // ears
    Path ear(double side, double s, double dy) => Path()
      ..moveTo(face.dx + side * unit * 1.05 * s, face.dy - unit * (0.2 - dy))
      ..quadraticBezierTo(
        face.dx + side * unit * 1.12 * s,
        face.dy - unit * (1.02 - dy),
        face.dx + side * unit * 0.72 * s,
        face.dy - unit * (1.12 - dy),
      )
      ..quadraticBezierTo(
        face.dx + side * unit * 0.42 * s,
        face.dy - unit * (1.0 - dy),
        face.dx + side * unit * 0.28 * s,
        face.dy - unit * (0.72 - dy),
      )
      ..close();
    final earFill = Paint()..color = Color.lerp(base, Colors.black, 0.16)!;
    final earInner = Paint()
      ..color = revealed ? const Color(0xB3FF9DB4) : const Color(0x22FFFFFF);
    for (final side in const [-1.0, 1.0]) {
      canvas.drawPath(ear(side, 1, 0), earFill);
      canvas.drawPath(ear(side, 0.62, 0.14), earInner);
    }

    // head with top-left light
    final head = Rect.fromCenter(
      center: face,
      width: unit * 2.2,
      height: unit * 1.85,
    );
    canvas.drawOval(
      head,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.55),
          radius: 1.05,
          colors: [
            Color.lerp(base, Colors.white, 0.28)!,
            base,
            Color.lerp(base, Colors.black, 0.22)!,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(head),
    );

    if (revealed) {
      final markings = Paint()
        ..color = Color.lerp(base, Colors.white, 0.45)!.withValues(alpha: 0.8)
        ..strokeWidth = unit * 0.11
        ..strokeCap = StrokeCap.round;
      switch (cat.visual?.marking ?? id % 4) {
        case 0:
          for (var i = -1; i <= 1; i++) {
            canvas.drawLine(
              face.translate(i * unit * 0.25, -unit * 0.78),
              face.translate(i * unit * 0.18, -unit * 0.42),
              markings,
            );
          }
        case 1:
          canvas.drawOval(
            Rect.fromCenter(
              center: face.translate(0, unit * 0.5),
              width: unit * 0.9,
              height: unit * 0.5,
            ),
            Paint()..color = Colors.white.withValues(alpha: 0.5),
          );
        case 2:
          for (final side in const [-1.0, 1.0]) {
            canvas.drawCircle(
              face.translate(side * unit * 0.62, -unit * 0.22),
              unit * 0.1,
              markings,
            );
          }
        case 3:
          canvas.drawCircle(
            face.translate(0, -unit * 0.4),
            unit * 0.1,
            markings,
          );
      }

      // blush
      for (final side in const [-1.0, 1.0]) {
        canvas.drawCircle(
          face.translate(side * unit * 0.72, unit * 0.36),
          unit * 0.19,
          Paint()
            ..color = const Color(0xFFFF8FB0).withValues(alpha: 0.38)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }

      // whiskers
      final whisker = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round;
      for (final side in const [-1.0, 1.0]) {
        canvas.drawLine(
          face.translate(side * unit * 0.88, unit * 0.34),
          face.translate(side * unit * 1.3, unit * 0.27),
          whisker,
        );
        canvas.drawLine(
          face.translate(side * unit * 0.88, unit * 0.46),
          face.translate(side * unit * 1.3, unit * 0.5),
          whisker,
        );
      }

      // eyes: dark glossy ovals with two highlights
      for (final side in const [-1.0, 1.0]) {
        final e = face.translate(side * unit * 0.44, unit * 0.06);
        final eyeRect = Rect.fromCenter(
          center: e,
          width: unit * 0.42,
          height: unit * 0.54,
        );
        canvas.drawOval(
          eyeRect,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(0, 0.3),
              colors: [Color(0xFF7A4A9A), Color(0xFF241238)],
            ).createShader(eyeRect),
        );
        canvas.drawCircle(
          e.translate(-unit * 0.07, -unit * 0.11),
          unit * 0.075,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          e.translate(unit * 0.07, unit * 0.1),
          unit * 0.036,
          Paint()..color = Colors.white.withValues(alpha: 0.85),
        );
      }

      // nose + mouth
      final nose = Path()
        ..moveTo(face.dx - unit * 0.1, face.dy + unit * 0.4)
        ..quadraticBezierTo(
          face.dx,
          face.dy + unit * 0.34,
          face.dx + unit * 0.1,
          face.dy + unit * 0.4,
        )
        ..quadraticBezierTo(
          face.dx,
          face.dy + unit * 0.54,
          face.dx - unit * 0.1,
          face.dy + unit * 0.4,
        )
        ..close();
      canvas.drawPath(nose, Paint()..color = const Color(0xFFFF7FA3));
      final mouth = Path()
        ..moveTo(face.dx - unit * 0.17, face.dy + unit * 0.56)
        ..quadraticBezierTo(
          face.dx - unit * 0.08,
          face.dy + unit * 0.66,
          face.dx,
          face.dy + unit * 0.54,
        )
        ..quadraticBezierTo(
          face.dx + unit * 0.08,
          face.dy + unit * 0.66,
          face.dx + unit * 0.17,
          face.dy + unit * 0.56,
        );
      canvas.drawPath(
        mouth,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF3A1E52),
      );

      // accessory
      final accessory = Paint()
        ..color = [
          AppColors.candyBlueLight,
          AppColors.candyRed,
          AppColors.coinGold,
          AppColors.candyGreen,
        ][id % 4];
      switch (id % 4) {
        case 0:
          final hat = Path()
            ..moveTo(face.dx - unit * 0.46, face.dy - unit * 0.7)
            ..lineTo(face.dx, face.dy - unit * 1.28)
            ..lineTo(face.dx + unit * 0.46, face.dy - unit * 0.7)
            ..close();
          canvas.drawPath(hat, accessory);
        case 1:
          canvas.drawCircle(
            face.translate(0, -unit * 0.93),
            unit * 0.2,
            accessory,
          );
          canvas.drawCircle(
            face.translate(-unit * 0.05, -unit * 0.98),
            unit * 0.06,
            Paint()..color = Colors.white70,
          );
        case 2:
          canvas.drawOval(
            Rect.fromCenter(
              center: face.translate(0, -unit * 0.8),
              width: unit * 1.1,
              height: unit * 0.2,
            ),
            accessory,
          );
        case 3:
          final bow = Path()
            ..moveTo(face.dx, face.dy - unit * 0.7)
            ..lineTo(face.dx - unit * 0.36, face.dy - unit * 1.0)
            ..lineTo(face.dx - unit * 0.34, face.dy - unit * 0.5)
            ..lineTo(face.dx, face.dy - unit * 0.7)
            ..lineTo(face.dx + unit * 0.36, face.dy - unit * 1.0)
            ..lineTo(face.dx + unit * 0.34, face.dy - unit * 0.5)
            ..close();
          canvas.drawPath(bow, accessory);
      }
    } else {
      final question = TextPainter(
        text: const TextSpan(
          text: '?',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      question.paint(
        canvas,
        Offset(center.dx - question.width / 2, center.dy - question.height / 2),
      );
    }

    // glass helmet (front layer): rim + specular
    canvas.drawCircle(
      center,
      helmetR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: revealed ? 0.3 : 0.14),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: helmetR - 4),
      pi * 1.12,
      pi * 0.3,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: revealed ? 0.5 : 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant _KittenPainter oldDelegate) =>
      oldDelegate.id != id ||
      oldDelegate.revealed != revealed ||
      oldDelegate.time != time;
}
