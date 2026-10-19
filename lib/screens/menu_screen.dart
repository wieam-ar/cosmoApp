import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../art/icons_painter.dart';
import '../art/jelly_painter.dart';
import '../art/mimo_painter.dart';
import '../config/bubble_types.dart';
import '../core/audio_service.dart';
import '../core/constants.dart';
import '../core/haptics.dart';
import '../core/save_service.dart';
import '../core/theme.dart';
import '../core/transitions.dart';
import '../widgets/cosmo_deco.dart';
import '../widgets/cosmo_kit.dart';
import '../widgets/game_title.dart';
import '../widgets/jelly_button.dart';
import '../widgets/popup.dart';
import '../widgets/space_background.dart';

import 'catalog_screen.dart';
import 'codex_screen.dart';
import 'daily_reward_screen.dart';
import 'game_screen.dart';
import 'level_map_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'spin_screen.dart';

const int _kEventGoal = 20;

/// Main menu: level chip + coins on top, title, Mimo with four orbs,
/// a wide PLAY button, the event banner and the bottom dock.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _ambient;
  late final CurvedAnimation _titleIn;
  late final CurvedAnimation _heroIn;
  late final CurvedAnimation _orbsIn;
  late final CurvedAnimation _playIn;
  late final CurvedAnimation _dockIn;

  final GlobalKey _playKey = GlobalKey();
  MimoState _mimo = MimoState.idle;
  Timer? _mimoReset;
  DateTime? _lastBack;

  @override
  void initState() {
    super.initState();
    Music.start();

    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    CurvedAnimation stage(double a, double b, Curve c) => CurvedAnimation(
      parent: _entry,
      curve: Interval(a, b, curve: c),
    );
    _titleIn = stage(0.0, 0.4, Curves.easeOutBack);
    _heroIn = stage(0.1, 0.65, Curves.elasticOut);
    _orbsIn = stage(0.35, 0.8, Curves.easeOutBack);
    _playIn = stage(0.5, 0.9, Curves.easeOutBack);
    _dockIn = stage(0.65, 1.0, Curves.easeOutCubic);
    _entry.forward();
  }

  @override
  void dispose() {
    _mimoReset?.cancel();
    for (final a in [_titleIn, _heroIn, _orbsIn, _playIn, _dockIn]) {
      a.dispose();
    }
    _entry.dispose();
    _ambient.dispose();
    super.dispose();
  }

  // ---- actions -----------------------------------------------------------

  void _reactMimo(MimoState state, {int ms = 900}) {
    setState(() => _mimo = state);
    _mimoReset?.cancel();
    _mimoReset = Timer(Duration(milliseconds: ms), () {
      if (mounted) setState(() => _mimo = MimoState.idle);
    });
  }

  void _go(
    Widget screen, {
    NavTransition style = NavTransition.slide,
    Offset? origin,
  }) {
    AppNav.go(context, screen, style: style, origin: origin);
  }

  Offset? _playOrigin() {
    final box = _playKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  void _play() {
    _reactMimo(MimoState.happy, ms: 1400);
    AppHaptics.medium();
    final origin = _playOrigin();
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _go(const LevelMapScreen(), style: NavTransition.iris, origin: origin);
      }
    });
  }

  void _petMimo() {
    AppHaptics.light();
    Sfx.play(SfxName.pop);
    _reactMimo(MimoState.happy);
  }

  void _onPop(bool didPop, dynamic result) {
    if (didPop) return;
    final now = DateTime.now();
    if (_lastBack == null ||
        now.difference(_lastBack!) > const Duration(seconds: 2)) {
      _lastBack = now;
      Toast.show(context, 'Press back again to exit');
    } else {
      SystemNavigator.pop();
    }
  }

  String _eventCountdown() {
    final now = DateTime.now();
    final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
    final nextMonday = DateTime(
      now.year,
      now.month,
      now.day + (daysUntilMonday == 0 ? 7 : daysUntilMonday),
    );
    final diff = nextMonday.difference(now);
    return '${diff.inDays}d ${diff.inHours.remainder(24)}h left';
  }

  // ---- build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SpaceBackground(
          variant: SpaceBgVariant.menu,
          child: SafeArea(
            child: ListenableBuilder(
              listenable: SaveService.I,
              builder: (context, _) => _content(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    final selected = SaveService.I.selectedSkin;
    final skin = SkinId.values.firstWhere(
      (s) => s.name == selected || s.toString() == selected,
      orElse: () => SkinId.defaultMimo,
    );

    return Column(
      children: [
        _topBar(),
        _rise(_titleIn, const Offset(0, -60), const GameTitle()),
        Expanded(child: _heroWithOrbs(skin)),
        const SizedBox(height: 6),
        _rise(
          _playIn,
          const Offset(0, 40),
          KeyedSubtree(key: _playKey, child: _playButton()),
        ),
        const SizedBox(height: 10),
        _rise(_playIn, const Offset(0, 40), _eventBanner()),
        const SizedBox(height: 10),
        _rise(_dockIn, const Offset(0, 60), _dock()),
      ],
    );
  }

  Widget _rise(Animation<double> a, Offset from, Widget child) =>
      AnimatedBuilder(
        animation: a,
        child: child,
        builder: (_, c) => Opacity(
          opacity: a.value.clamp(0.0, 1.0),
          child: Transform.translate(offset: from * (1 - a.value), child: c),
        ),
      );

  // ---- top bar -----------------------------------------------------------

  Widget _topBar() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
    child: Row(
      children: [
        _levelChip(),
        const Spacer(),
        _resourcePill(),
        const SizedBox(width: 8),
        RoundButton(
          icon: AppIcon.gear,
          color: JellyColor.blue,
          size: 44,
          onPressed: () => _go(const SettingsScreen()),
        ),
      ],
    ),
  );

  Widget _resourcePill() => TickBuilder(
    every: const Duration(minutes: 1),
    builder: (_) => CosmoTap(
      onTap: () => _go(const ShopScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: kCardGradientGlass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_rounded,
              size: 15,
              color: AppColors.heartRed,
            ),
            const SizedBox(width: 3),
            Text(
              '${SaveService.I.hearts}',
              style: AppTextStyles.label(fontSize: 12, color: Colors.white),
            ),
            const SizedBox(width: 7),
            const Icon(
              Icons.monetization_on_rounded,
              size: 15,
              color: AppColors.coinGold,
            ),
            const SizedBox(width: 3),
            Text(
              '${SaveService.I.coins}',
              style: AppTextStyles.label(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _levelChip() => Container(
    padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
    decoration: BoxDecoration(
      gradient: kCardGradientGlass,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white24, width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Cosmo.furViolet.withValues(alpha: 0.5),
            border: Border.all(color: AppColors.accent, width: 2),
          ),
          child: const Icon(Icons.pets_rounded, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lv. ${SaveService.I.unlockedLevel}',
              style: AppTextStyles.label(fontSize: 12, color: Colors.white),
            ),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 64,
                height: 6,
                child: LinearProgressIndicator(
                  value: SaveService.I.totalStarsEarned / (120 * 3),
                  backgroundColor: Colors.black45,
                  valueColor: AlwaysStoppedAnimation(AppColors.candyBlueLight),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  // ---- hero + orbs -------------------------------------------------------

  // Mimo first, orbs painted over his lower edge.
  Widget _heroWithOrbs(SkinId skin) => LayoutBuilder(
    builder: (context, box) {
      const orbRow = 98.0;
      const overlap = 34.0;
      final d = min(
        box.maxWidth * 0.74,
        box.maxHeight - orbRow + overlap,
      ).clamp(100.0, 360.0).toDouble();
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: d,
            child: Center(
              child: _rise(
                _heroIn,
                Offset.zero,
                AnimatedBuilder(
                  animation: _heroIn,
                  builder: (_, child) => Transform.scale(
                    scale: 0.6 + 0.4 * _heroIn.value,
                    child: child,
                  ),
                  child: GestureDetector(
                    onTap: _petMimo,
                    child: AnimatedBuilder(
                      animation: _ambient,
                      builder: (_, _) => Transform.translate(
                        offset: Offset(
                          0,
                          sin(_ambient.value * pi * 4) * d * 0.012,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: d,
                              height: d,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Cosmo.furViolet.withValues(alpha: 0.28),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            SizedBox.square(
                              dimension: d,
                              child: CustomPaint(
                                painter: _MimoHeroPainter(
                                  state: _mimo,
                                  skin: skin,
                                  t: _ambient.value * 10.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 0,
            child: _rise(_orbsIn, const Offset(0, 50), _orbs()),
          ),
        ],
      );
    },
  );

  Widget _orbs() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _orb(
        CosmoElement.burn,
        'Arcade',
        0.0,
        () => _go(const GameScreen(mode: GameMode.arcade)),
      ),
      _orb(
        CosmoElement.mud,
        'Classic',
        0.25,
        () => _go(const GameScreen(mode: GameMode.classic)),
      ),
      _orb(
        CosmoElement.steam,
        'Daily Login',
        0.5,
        () => _go(const DailyRewardScreen()),
        badge: SaveService.I.dailyClaimable,
      ),
      _orb(
        CosmoElement.bloom,
        'Settings',
        0.75,
        () => _go(const SettingsScreen()),
      ),
    ],
  );

  Widget _orb(
    CosmoElement element,
    String label,
    double phase,
    VoidCallback onTap, {
    bool badge = false,
  }) => Expanded(
    child: CosmoTap(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _ambient,
                builder: (_, _) => ElementOrb(
                  element: element,
                  size: 62,
                  glow: (sin((_ambient.value + phase) * pi * 4) + 1) / 2,
                  t: _ambient.value * 10.0,
                ),
              ),
              if (badge)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.candyRed,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Text(
                      '1',
                      style: TextStyle(
                        fontSize: 10,
                        height: 1,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTextStyles.label(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    ),
  );

  // ---- play button -------------------------------------------------------

  Widget _playButton() => CosmoTap(
    onTap: _play,
    child: Container(
      width: 290,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFC23A), Color(0xFFFF8A1F)],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFFFE08A), width: 2.5),
        boxShadow: const [
          BoxShadow(color: Color(0x88FF8A1F), blurRadius: 18),
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.pets_rounded, size: 30, color: Colors.white),
          const Spacer(),
          Text(
            'PLAY',
            style: AppTextStyles.label(
              fontSize: 30,
              color: const Color(0xFF5A2D00),
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 30,
            color: Color(0xFF5A2D00),
          ),
        ],
      ),
    ),
  );

  // ---- event banner ------------------------------------------------------

  Widget _eventBanner() {
    final progress = SaveService.I.eventProgress;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CosmoTap(
        onTap: () => EventPopup.show(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: kCardGradientGlass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CustomPaint(
                  painter: _IconPainter(
                    icon: AppIcon.heart,
                    color: AppColors.candyRed,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cat rescue week',
                          style: AppTextStyles.label(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${progress.clamp(0, _kEventGoal)}/$_kEventGoal',
                          style: AppTextStyles.label(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (progress / _kEventGoal).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.black45,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.candyGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    TickBuilder(
                      every: const Duration(minutes: 1),
                      builder: (_) => Text(
                        _eventCountdown(),
                        style: AppTextStyles.body(
                          fontSize: 10,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const SizedBox(
                width: 28,
                height: 28,
                child: CustomPaint(
                  painter: _IconPainter(
                    icon: AppIcon.gift,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- dock --------------------------------------------------------------

  Widget _dock() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
    child: CosmoDock(
      items: [
        CosmoDockItem(
          label: 'Shop',
          icon: AppIcon.cart,
          color: const Color(0xFFFF9A2E),
          onTap: () => _go(const ShopScreen()),
        ),
        CosmoDockItem(
          label: 'Cats',
          materialIcon: Icons.pets_rounded,
          color: const Color(0xFF9B6BFF),
          onTap: () => _go(const CatalogScreen()),
        ),
        CosmoDockItem(
          label: 'Collection',
          materialIcon: Icons.menu_book_rounded,
          color: const Color(0xFF3FA9F5),
          onTap: () => _go(const CodexScreen()),
        ),
        CosmoDockItem(
          label: 'Skin',
          materialIcon: Icons.checkroom_rounded,
          color: const Color(0xFFFF5FA2),
          onTap: () => _go(const ShopScreen(initialTab: 2)),
        ),
        CosmoDockItem(
          label: 'Lucky Spin',
          materialIcon: Icons.star_rounded,
          color: const Color(0xFF4CC23A),
          onTap: () => _go(const SpinScreen()),
        ),
      ],
    ),
  );
}

class _IconPainter extends CustomPainter {
  const _IconPainter({required this.icon, required this.color});
  final AppIcon icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) =>
      IconsPainter.draw(canvas, Offset.zero & size, icon, color: color);

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _MimoHeroPainter extends CustomPainter {
  const _MimoHeroPainter({
    required this.state,
    required this.skin,
    required this.t,
  });
  final MimoState state;
  final SkinId skin;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Mimo already wears the glass helmet from the logo, so he is the bubble.
    // 0.98 / 0.52 are the two numbers to tweak if he sits too high/low.
    MimoPainter.draw(
      canvas,
      Offset(size.width / 2, size.height * 0.52),
      size.width * 0.98,
      state: state,
      skin: skin,
      t: t,
      heldBubble: BubbleType.purple,
    );
  }

  @override
  bool shouldRepaint(covariant _MimoHeroPainter old) =>
      old.state != state || old.skin != skin || old.t != t;
}
