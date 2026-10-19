import 'dart:math';

import 'package:flutter/material.dart';

import '../art/garden_painter.dart';
import '../art/icons_painter.dart';
import '../art/jelly_painter.dart';
import '../config/garden_config.dart';
import '../core/constants.dart';
import '../core/save_service.dart';
import '../core/theme.dart' hide GlassPanel;
import '../core/ui_theme.dart';
import '../widgets/glass_ui.dart';
import '../widgets/jelly_button.dart';
import '../widgets/popup.dart';
import '../widgets/space_background.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen>
    with SingleTickerProviderStateMixin {
  static const double _hPad = 16;
  static const double _gap = 10;
  static const Color _seedBase = Color(0xFF4B4580);

  late final AnimationController _gardenAnimation;
  String? _selectedSeed;

  @override
  void initState() {
    super.initState();
    _gardenAnimation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _gardenAnimation.dispose();
    super.dispose();
  }

  void _buySeed(GardenSeedDefinition seed) {
    final bought = SaveService.I.buyGardenSeed(seed.id);
    if (!bought) {
      Toast.show(
        context,
        SaveService.I.coins < seed.price
            ? 'Not enough coins for ${seed.name}.'
            : 'That seed is unavailable.',
      );
      return;
    }
    setState(() => _selectedSeed = seed.id);
    Toast.show(context, '${seed.name} seed added to your bag!');
  }

  void _plantSeed(int slot) {
    final selected = _selectedSeed;
    if (selected == null) {
      Toast.show(context, 'Choose a seed before planting.');
      return;
    }
    if (!SaveService.I.plantGardenSeed(selected, slot)) {
      Toast.show(context, 'Choose an empty plot with a seed in your bag.');
      return;
    }
    Toast.show(context, 'Seed planted! Clear levels to help it grow.');
  }

  void _buyDecoration(GardenDecorationDefinition decoration) {
    if (!SaveService.I.buyGardenDecoration(decoration.id)) {
      Toast.show(
        context,
        decoration.price != null && SaveService.I.coins < decoration.price!
            ? 'Not enough coins for ${decoration.name}.'
            : 'Earn this keepsake by rescuing more cats.',
      );
      return;
    }
    Toast.show(context, '${decoration.name} unlocked!');
  }

  void _toggleDecoration(GardenDecorationDefinition decoration, int slot) {
    final placed = SaveService.I.placedGardenDecorations[slot];
    if (placed == decoration.id) {
      SaveService.I.removeGardenDecoration(slot);
      Toast.show(context, '${decoration.name} tucked away.');
    } else if (SaveService.I.placeGardenDecoration(decoration.id, slot)) {
      Toast.show(context, '${decoration.name} placed in plot ${slot + 1}.');
    } else {
      Toast.show(context, 'Unlock this decoration before placing it.');
    }
  }

  SkinId _selectedSkin() {
    final stored = SaveService.I.selectedSkin;
    return SkinId.values.firstWhere(
      (skin) => skin.name == stored || skin.toString() == stored,
      orElse: () => SkinId.defaultMimo,
    );
  }

  /// Width of one of the two columns. The old code ignored the horizontal
  /// padding, so the second card often wrapped onto its own line.
  double _cardWidth(double available) {
    final content = min(available - _hPad * 2, 620.0);
    return (content - _gap) / 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SpaceBackground(
        variant: SpaceBgVariant.menu,
        showUfos: false,
        showLava: false,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: SaveService.I,
            builder: (context, _) {
              final seeds = SaveService.I.gardenSeeds;
              final plants = SaveService.I.gardenPlants;
              final decorations = SaveService.I.gardenDecorations;
              final placements = SaveService.I.placedGardenDecorations;
              return Column(
                children: [
                  _header(context),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 28),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _summaryCard(),
                                const SizedBox(height: 12),
                                _gardenScene(plants, placements),
                                const SizedBox(height: 24),
                                const GlassSectionTitle(
                                  'Garden plots',
                                  subtitle: 'Each first-time level clear advances your plants.',
                                ),
                                const SizedBox(height: 12),
                                _plotGrid(constraints.maxWidth, plants, seeds),
                                const SizedBox(height: 24),
                                const GlassSectionTitle(
                                  'Seed pouch',
                                  subtitle: 'Choose a seed to plant, or grow your collection.',
                                ),
                                const SizedBox(height: 12),
                                _seedShop(constraints.maxWidth, seeds),
                                const SizedBox(height: 24),
                                const GlassSectionTitle(
                                  'Cosmic decor',
                                  subtitle: 'Place keepsakes in one of your three garden spots.',
                                ),
                                const SizedBox(height: 12),
                                _decorationShop(
                                  constraints.maxWidth,
                                  decorations,
                                  placements,
                                ),
                                const SizedBox(height: 20),
                                _milestoneNote(),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 4, 16, 8),
    child: Row(
      children: [
        RoundButton(
          icon: AppIcon.back,
          color: JellyColor.purple,
          size: 42,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "MIMO'S GARDEN",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.title(fontSize: 21),
              ),
              Text(
                'A little place to grow between adventures',
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
        GlassPill(
          icon: Icons.monetization_on_rounded,
          text: '${SaveService.I.coins}',
          color: AppColors.coinGold,
        ),
      ],
    ),
  );

  Widget _summaryCard() {
    final levelCount = SaveService.I.gardenCompletedLevelCount;
    final rescues = SaveService.I.gardenTotalRescues;
    final nextRescue = rescues < 5
        ? 5
        : rescues < 15
        ? 15
        : null;
    return GlassPanel(
      radius: 18,
      tint: const Color(0xFF72DDC4),
      glow: 0.08,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Glass.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$levelCount levels tended  ·  $rescues friends rescued',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label(fontSize: 12),
            ),
          ),
          if (nextRescue != null)
            Text(
              '${nextRescue - rescues} to keepsake',
              style: AppTextStyles.label(fontSize: 11, color: Glass.gold),
            )
          else
            const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFFF9DBD),
              size: 18,
            ),
        ],
      ),
    );
  }

  Widget _gardenScene(
    Map<int, GardenPlant> plants,
    Map<int, String> placements,
  ) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: Container(
      height: 270,
      decoration: Glass.surface(radius: 24, tint: Glass.violet, glow: 0.12),
      child: AnimatedBuilder(
        animation: _gardenAnimation,
        builder: (context, _) => CustomPaint(
          painter: GardenPainter(
            plants: plants,
            decorations: placements,
            time: _gardenAnimation.value * 2 * pi,
            mimoSkin: _selectedSkin(),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );

  Widget _plotGrid(
    double availableWidth,
    Map<int, GardenPlant> plants,
    Map<String, int> seeds,
  ) {
    final width = _cardWidth(availableWidth);
    return Wrap(
      spacing: _gap,
      runSpacing: _gap,
      children: List.generate(
        GardenCatalog.plotCount,
        (slot) =>
            SizedBox(width: width, child: _plotCard(slot, plants[slot], seeds)),
      ),
    );
  }

  Widget _plotCard(int slot, GardenPlant? plant, Map<String, int> seeds) {
    final seed = plant == null ? null : GardenCatalog.seed(plant.seedId);
    final stage = plant?.stage;
    final selectedCount = _selectedSeed == null ? 0 : seeds[_selectedSeed] ?? 0;
    final canPlant =
        plant == null && _selectedSeed != null && selectedCount > 0;
    return GlassPanel(
      radius: 18,
      tint: seed?.color,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                plant == null
                    ? Icons.circle_outlined
                    : Icons.local_florist_rounded,
                size: 20,
                color: seed?.color ?? Colors.white54,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Plot ${slot + 1}',
                  style: AppTextStyles.label(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            seed?.name ?? 'An open little patch',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body(fontSize: 12, color: Colors.white),
          ),
          const SizedBox(height: 6),
          if (plant != null) ...[
            Text(
              stage!.label,
              style: AppTextStyles.label(fontSize: 11, color: seed!.color),
            ),
            const SizedBox(height: 6),
            GlassProgress(
              value: plant.growth / GardenCatalog.growthWins,
              color: seed.color,
              height: 6,
            ),
          ] else
            Text(
              _selectedSeed == null
                  ? 'Select a seed to plant here'
                  : selectedCount > 0
                  ? 'Ready for your ${GardenCatalog.seed(_selectedSeed)!.name}'
                  : 'Buy this seed to plant it',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(height: 10),
          GlassButton(
            label: plant == null ? 'Plant here' : 'Growing',
            color: AppColors.candyGreen,
            height: 34,
            onPressed: plant == null && canPlant
                ? () => _plantSeed(slot)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _seedShop(double availableWidth, Map<String, int> counts) {
    final width = _cardWidth(availableWidth);
    return Wrap(
      spacing: _gap,
      runSpacing: _gap,
      children: GardenCatalog.seeds
          .map((seed) {
            final count = counts[seed.id] ?? 0;
            final isSelected = _selectedSeed == seed.id;
            return SizedBox(
              width: width,
              child: GlassPanel(
                radius: 18,
                tint: seed.color,
                selected: isSelected,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_florist_rounded,
                          size: 20,
                          color: seed.color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            seed.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.label(fontSize: 13),
                          ),
                        ),
                        Text(
                          '×$count',
                          style: AppTextStyles.label(
                            fontSize: 12,
                            color: seed.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      seed.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GlassButton(
                            label: isSelected ? 'Selected' : 'Select',
                            color: seed.color,
                            height: 34,
                            fontSize: 11,
                            onPressed: count > 0
                                ? () => setState(() => _selectedSeed = seed.id)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: GlassButton(
                            label: '${seed.price}',
                            icon: Icons.monetization_on_rounded,
                            color: const Color(0xFFD9A33A),
                            height: 34,
                            fontSize: 11,
                            onPressed: SaveService.I.coins >= seed.price
                                ? () => _buySeed(seed)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _decorationShop(
    double availableWidth,
    Set<String> owned,
    Map<int, String> placements,
  ) {
    final width = _cardWidth(availableWidth);
    return Wrap(
      spacing: _gap,
      runSpacing: _gap,
      children: GardenCatalog.decorations
          .map((decoration) {
            final isOwned = owned.contains(decoration.id);
            final rescueMilestone = decoration.rescueMilestone;
            final rescueRequirement = rescueMilestone == 'rescues_5' ? 5 : 15;
            final rescueProgress = SaveService.I.gardenTotalRescues;
            return SizedBox(
              width: width,
              child: GlassPanel(
                radius: 18,
                tint: decoration.color,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _decorationIcon(decoration.id),
                          size: 20,
                          color: decoration.color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            decoration.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.label(fontSize: 12),
                          ),
                        ),
                        if (isOwned)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.candyGreen,
                            size: 17,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      decoration.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isOwned)
                      Row(
                        children: List.generate(
                          GardenCatalog.decorationSlotCount,
                          (slot) {
                            final placed = placements[slot] == decoration.id;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right:
                                      slot ==
                                          GardenCatalog.decorationSlotCount - 1
                                      ? 0
                                      : 6,
                                ),
                                child: GlassButton(
                                  label: placed
                                      ? 'On ${slot + 1}'
                                      : '${slot + 1}',
                                  color: placed ? decoration.color : _seedBase,
                                  height: 34,
                                  fontSize: 11,
                                  onPressed: () =>
                                      _toggleDecoration(decoration, slot),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else if (decoration.price != null)
                      GlassButton(
                        label: 'Unlock · ${decoration.price}',
                        icon: Icons.monetization_on_rounded,
                        color: const Color(0xFFD9A33A),
                        height: 34,
                        fontSize: 11,
                        onPressed: SaveService.I.coins >= decoration.price!
                            ? () => _buyDecoration(decoration)
                            : null,
                      )
                    else ...[
                      GlassProgress(
                        value: rescueProgress / rescueRequirement,
                        color: Glass.gold,
                        height: 6,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$rescueProgress/$rescueRequirement rescues',
                        style: AppTextStyles.label(
                          fontSize: 11,
                          color: Glass.gold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _milestoneNote() => GlassPanel(
    radius: 16,
    padding: const EdgeInsets.all(14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.card_giftcard_rounded, color: Glass.gold, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Every 3 first-time level clears bring a Moon Daisy seed. '
            'Rescue 5 friends for a Rescue Lantern and 15 for a Nebula Arch. '
            'Your plants grow with your level adventures.',
            style: AppTextStyles.body(fontSize: 12),
          ),
        ),
      ],
    ),
  );

  IconData _decorationIcon(String id) => switch (id) {
    'star_lantern' || 'rescue_lantern' => Icons.lightbulb_rounded,
    'comet_fountain' => Icons.water_rounded,
    _ => Icons.architecture_rounded,
  };
}
