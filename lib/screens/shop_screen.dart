import 'dart:math';

import 'package:flutter/material.dart';

import '../art/icons_painter.dart';
import '../art/jelly_painter.dart';
import '../art/mimo_painter.dart';
import '../art/space_painter.dart';
import '../core/audio_service.dart';
import '../core/constants.dart';
import '../core/save_service.dart';
import '../core/theme.dart';
import '../game/logic/powerups.dart';
import '../widgets/cosmo_deco.dart';
import '../widgets/jelly_button.dart';
import '../widgets/popup.dart';

class ShopScreen extends StatefulWidget {
  final int initialTab;

  const ShopScreen({super.key, this.initialTab = 0});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

// FIX: TickerProviderStateMixin (2 controllers)
class _ShopScreenState extends State<ShopScreen> with TickerProviderStateMixin {
  late final AnimationController _preview;
  late final AnimationController _coinFly;
  bool _showCoinsFlying = false;

  @override
  void initState() {
    super.initState();
    _preview = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _coinFly = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
  }

  @override
  void dispose() {
    _preview.dispose();
    _coinFly.dispose();
    super.dispose();
  }

  void _flyCoins(int amount) {
    SaveService.I.addCoins(amount);
    Sfx.play(SfxName.coin);
    setState(() => _showCoinsFlying = true);
    _coinFly.forward(from: 0).then((_) {
      if (mounted) setState(() => _showCoinsFlying = false);
    });
  }

  void _buyPowerup(String id) {
    if (!PowerupLogic.purchase(id)) {
      _shakeAndToast('Not enough coins');
      return;
    }
    Sfx.play(SfxName.coin);
    Toast.show(context, '$id added to your inventory');
  }

  void _buySkin(String id, int price) {
    if (!SaveService.I.buySkin(id, price)) {
      _shakeAndToast('Not enough coins');
      return;
    }
    SaveService.I.equipSkin(id);
    Sfx.play(SfxName.coin);
    Toast.show(context, 'Skin unlocked and equipped!');
  }

  void _shakeAndToast(String message) {
    Sfx.play(SfxName.thud);
    Toast.show(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: widget.initialTab.clamp(0, 3),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // FIX: space background (same sky as menu / garden)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _preview,
                builder: (_, _) => CustomPaint(
                  painter: _ShopBgPainter(_preview.value * 8 * pi),
                ),
              ),
            ),
            SafeArea(
              child: ListenableBuilder(
                listenable: SaveService.I,
                builder: (context, _) => Stack(
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 7, 16, 8),
                          child: Row(
                            children: [
                              RoundButton(
                                icon: AppIcon.back,
                                color: JellyColor.purple,
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                              ),
                              const Spacer(),
                              Text(
                                'COSMO SHOP',
                                style: AppTextStyles.title(
                                  fontSize: 25,
                                  color: AppColors.coinGold,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.monetization_on_rounded,
                                color: AppColors.coinGold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${SaveService.I.coins}',
                                style: AppTextStyles.label(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                        const TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.center,
                          labelColor: AppColors.accent,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicatorColor: AppColors.candyGreen,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                          tabs: [
                            Tab(text: 'COINS'),
                            Tab(text: 'POWER-UPS'),
                            Tab(text: 'SKINS'),
                            Tab(text: 'HEARTS'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildCoinsTab(),
                              _buildPowerupsTab(),
                              _buildSkinsTab(),
                              _buildHeartsTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_showCoinsFlying)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _coinFly,
                            builder: (context, _) => Stack(
                              children: List.generate(5, (index) {
                                final startX = 80.0 + index * 32;
                                final startY =
                                    MediaQuery.sizeOf(context).height * 0.65;
                                final t = (_coinFly.value - index * 0.055)
                                    .clamp(0.0, 1.0);
                                return Positioned(
                                  left:
                                      startX +
                                      (MediaQuery.sizeOf(context).width -
                                              120 -
                                              startX) *
                                          t,
                                  top: startY * (1 - t) + 18 * t,
                                  child: Opacity(
                                    opacity: t > 0.88 ? (1 - t) / 0.12 : 1,
                                    child: const Icon(
                                      Icons.monetization_on_rounded,
                                      color: AppColors.coinGold,
                                      size: 25,
                                      shadows: [
                                        Shadow(
                                          color: Colors.orange,
                                          blurRadius: 9,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinsTab() {
    const packs = [(500, 0), (1200, 1), (3000, 2), (8000, 3)];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      children: [
        _demoNotice(),
        for (final pack in packs)
          _ShopCard(
            icon: Icons.monetization_on_rounded,
            iconColor: AppColors.coinGold,
            title: '${pack.$1} COSMO COINS',
            subtitle: 'Demo pack ${pack.$2 + 1} · no real purchase',
            price: 'DEMO',
            onPressed: () => _flyCoins(pack.$1),
          ),
      ],
    );
  }

  Widget _buildPowerupsTab() {
    const items = [
      ('bomb', Icons.circle, 75, 'Explode a cluster of nearby bubbles'),
      (
        'rainbow',
        Icons.public_rounded,
        100,
        'Your next shot matches any color',
      ),
      ('lightning', Icons.bolt_rounded, 125, 'Clear the row you choose'),
      (
        'rocket',
        Icons.rocket_launch_rounded,
        100,
        'Clear a full bubble column',
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      children: [
        for (final item in items)
          _ShopCard(
            icon: item.$2,
            iconColor: AppColors.candyBlueLight,
            title:
                '${item.$1.toUpperCase()}  ·  ${SaveService.I.powerups[item.$1] ?? 0} OWNED',
            subtitle: item.$4,
            price: '${item.$3} COINS',
            onPressed: () => _buyPowerup(item.$1),
          ),
      ],
    );
  }

  Widget _buildSkinsTab() {
    const skins = [
      ('astronaut', 'ASTRONAUT', 'Free', 0, SkinId.defaultMimo),
      ('pirate', 'PIRATE MIMO', 'Space corsair', 250, SkinId.spaceMimo),
      ('wizard', 'WIZARD MIMO', 'Cosmic spellcaster', 400, SkinId.neonMimo),
      ('ninja', 'NINJA MIMO', 'Golden moon ninja', 600, SkinId.goldenMimo),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
      children: [
        AnimatedBuilder(
          animation: _preview,
          builder: (context, _) => Container(
            height: 220,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF5A44C8),
                  Color(0xFF2A1A78),
                  Color(0xFF140C4A),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(color: const Color(0xFFB79BFF), width: 2.5),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Color(0x557CF6FF), blurRadius: 18),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(sin(_preview.value * 2 * pi) * 0.45),
                  child: CustomPaint(
                    size: const Size(165, 180),
                    painter: _SkinPreviewPainter(
                      skin: _skinPainter(SaveService.I.skin),
                      time: _preview.value * 2 * pi,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 17,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateX(-0.15)
                      ..rotateZ(_preview.value * pi * 2),
                    child: Container(
                      width: 150,
                      height: 25,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB7A4FF), Color(0xFF5843B6)],
                        ),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  child: Text(
                    SaveService.I.skin.toUpperCase(),
                    style: AppTextStyles.label(
                      fontSize: 15,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final item in skins)
          _ShopCard(
            icon: Icons.pets_rounded,
            iconColor: AppColors.candyPurpleLight,
            title: item.$2,
            subtitle: item.$3,
            price: SaveService.I.skin == item.$1
                ? 'EQUIPPED'
                : SaveService.I.skins.contains(item.$1)
                ? 'EQUIP'
                : item.$4 == 0
                ? 'FREE'
                : '${item.$4} COINS',
            onPressed: () {
              if (SaveService.I.skins.contains(item.$1)) {
                SaveService.I.equipSkin(item.$1);
              } else {
                _buySkin(item.$1, item.$4);
              }
            },
          ),
      ],
    );
  }

  Widget _buildHeartsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      children: [
        Center(
          child: Column(
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: AppColors.heartRed,
                size: 86,
                shadows: [Shadow(color: Colors.red, blurRadius: 20)],
              ),
              const SizedBox(height: 10),
              Text(
                '${SaveService.I.hearts} / ${SaveService.kMaxHearts} HEARTS',
                style: AppTextStyles.title(fontSize: 23, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ShopCard(
          icon: Icons.favorite_rounded,
          iconColor: AppColors.heartRed,
          title: 'REFILL TO FULL',
          subtitle:
              'Restore all hearts. They also regenerate every 20 minutes.',
          price: '100 COINS',
          onPressed: () {
            if (SaveService.I.hearts >= SaveService.kMaxHearts) {
              Toast.show(context, 'Your hearts are already full');
              return;
            }
            if (!SaveService.I.deductCoins(100)) {
              _shakeAndToast('Not enough coins');
              return;
            }
            SaveService.I.addHearts(SaveService.kMaxHearts);
            Sfx.play(SfxName.coin);
            Toast.show(context, 'Hearts refilled!');
          },
        ),
        Text(
          'Heart regeneration continues while you are away.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _demoNotice() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0x553EDC9A),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.candyGreen),
    ),
    child: Text(
      'DEMO STORE — no real purchase or payment is made.',
      textAlign: TextAlign.center,
      style: AppTextStyles.label(fontSize: 13, color: AppColors.candyGreen),
    ),
  );

  SkinId _skinPainter(String id) => switch (id) {
    'pirate' => SkinId.spaceMimo,
    'wizard' => SkinId.neonMimo,
    'ninja' => SkinId.goldenMimo,
    _ => SkinId.defaultMimo,
  };
}

class _ShopBgPainter extends CustomPainter {
  final double t;
  const _ShopBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    SpacePainter.nebula(canvas, size, t: t);
    SpacePainter.starfield(canvas, size, t: t);
  }

  @override
  bool shouldRepaint(covariant _ShopBgPainter old) => old.t != t;
}

class _ShopCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String price;
  final VoidCallback onPressed;

  const _ShopCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onPressed,
  });

  @override
  State<_ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<_ShopCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, _) => Transform.translate(
        offset: Offset(sin(_shake.value * pi * 6) * 6, 0),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            gradient: kCardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF9B7BFF), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(11),
                  child: Icon(widget.icon, color: widget.iconColor, size: 30),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FIX: no overflow on long text
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label(fontSize: 13),
                      ),
                      Text(
                        widget.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                JellyButton(
                  text: widget.price,
                  width: 112,
                  height: 43,
                  fontSize: 12,
                  color: JellyColor.green,
                  onPressed: widget.onPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkinPreviewPainter extends CustomPainter {
  final SkinId skin;
  final double time;

  const _SkinPreviewPainter({required this.skin, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    MimoPainter.draw(
      canvas,
      // FIX: lowered so hats (wizard/pirate) stay inside the container
      Offset(size.width / 2, size.height * 0.70),
      148,
      state: MimoState.idle,
      skin: skin,
      t: time,
    );
  }

  @override
  bool shouldRepaint(covariant _SkinPreviewPainter oldDelegate) =>
      oldDelegate.skin != skin || oldDelegate.time != time;
}
