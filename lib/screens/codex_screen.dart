import 'package:flutter/material.dart';

import '../art/bubble_painter.dart';
import '../art/icons_painter.dart';
import '../art/jelly_painter.dart';
import '../config/bubble_types.dart';
import '../core/audio_service.dart';
import '../core/constants.dart';
import '../core/save_service.dart';
import '../core/theme.dart' hide GlassPanel;
import '../game/logic/cat_crew.dart';
import '../game/logic/elemental_codex.dart';
import '../game/logic/elemental_reaction.dart';
import '../widgets/glass_ui.dart';
import '../widgets/jelly_button.dart';
import '../widgets/space_background.dart';

enum _CodexFilter { all, reactions, combinations }

class CodexScreen extends StatefulWidget {
  const CodexScreen({super.key});

  @override
  State<CodexScreen> createState() => _CodexScreenState();
}

class _CodexScreenState extends State<CodexScreen> {
  _CodexFilter _filter = _CodexFilter.all;

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
              final discovered = SaveService.I.discoveredReactions;
              final claimed = SaveService.I.claimedCodexRewards;
              final progress = ElementalCodexRegistry.progress(discovered);
              final pendingRewards = discovered.difference(claimed).length;
              final entries = ElementalCodexRegistry.entries
                  .where((entry) {
                    return switch (_filter) {
                      _CodexFilter.all => true,
                      _CodexFilter.reactions =>
                        entry.category == CodexCategory.reactions,
                      _CodexFilter.combinations =>
                        entry.category == CodexCategory.combinations,
                    };
                  })
                  .toList(growable: false);

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
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
                              'ELEMENTAL CODEX',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.title(
                                fontSize: 21,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GlassPill(
                            text: '${progress.discovered}/${progress.total}',
                            color: AppColors.candyGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
                      child: _ProgressPanel(
                        progress: progress,
                        pendingRewards: pendingRewards,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 38,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        scrollDirection: Axis.horizontal,
                        children: const [
                          _ElementBadge(type: ElementalType.fire),
                          _ElementBadge(type: ElementalType.water),
                          _ElementBadge(type: ElementalType.earth),
                          _ElementBadge(type: ElementalType.flora),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                      child: _Segmented(
                        labels: const ['All', 'Reactions', 'Combinations'],
                        index: _filter.index,
                        onChanged: (i) =>
                            setState(() => _filter = _CodexFilter.values[i]),
                      ),
                    ),
                  ),
                  if (entries.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No records in this chapter yet.',
                          style: AppTextStyles.body(),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                      sliver: SliverList.separated(
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return _CodexCard(
                            key: ValueKey(entry.id),
                            entry: entry,
                            discovered: discovered.contains(entry.id),
                            claimed: claimed.contains(entry.id),
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
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

class _ProgressPanel extends StatelessWidget {
  final CodexProgress progress;
  final int pendingRewards;

  const _ProgressPanel({required this.progress, required this.pendingRewards});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 20,
      tint: AppColors.candyGreen,
      glow: 0.10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppColors.coinGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Field notes',
                  style: AppTextStyles.label(
                    fontSize: 15,
                    color: AppColors.accent,
                  ),
                ),
              ),
              Text(
                '${(progress.fraction * 100).round()}%',
                style: AppTextStyles.label(
                  fontSize: 15,
                  color: AppColors.candyGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GlassProgress(value: progress.fraction, color: AppColors.candyGreen),
          const SizedBox(height: 9),
          Text(
            '${progress.discovered} discovered · ${progress.remaining} still mysterious',
            style: AppTextStyles.body(fontSize: 12),
          ),
          if (pendingRewards > 0) ...[
            const SizedBox(height: 8),
            GlassPill(
              icon: Icons.redeem_rounded,
              text:
                  '$pendingRewards reward${pendingRewards == 1 ? '' : 's'} ready',
              color: AppColors.coinGold,
            ),
          ],
        ],
      ),
    );
  }
}

class _ElementBadge extends StatelessWidget {
  final ElementalType type;

  const _ElementBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (type) {
      ElementalType.fire => (Icons.local_fire_department, 'Fire · Red'),
      ElementalType.water => (Icons.water_drop, 'Water · Blue'),
      ElementalType.earth => (Icons.landscape, 'Earth · Yellow'),
      ElementalType.flora => (Icons.eco, 'Flora · Green'),
      ElementalType.electric => (Icons.bolt, 'Electric'),
      ElementalType.cosmic => (Icons.auto_awesome, 'Cosmic'),
    };
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GlassPill(text: label, icon: icon, color: type.color),
    );
  }
}

/// Three-way segmented control that replaces the old chips.
class _Segmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  const _Segmented({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  decoration: i == index
                      ? BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Glass.lighten(Glass.violet, 0.08),
                              Glass.darken(Glass.violet, 0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        )
                      : null,
                  child: Text(
                    labels[i],
                    style: AppTextStyles.label(
                      fontSize: 12,
                      color: i == index ? Colors.white : Colors.white60,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CodexCard extends StatefulWidget {
  final CodexEntry entry;
  final bool discovered;
  final bool claimed;

  const _CodexCard({
    super.key,
    required this.entry,
    required this.discovered,
    required this.claimed,
  });

  @override
  State<_CodexCard> createState() => _CodexCardState();
}

class _CodexCardState extends State<_CodexCard> {
  bool _showClue = false;

  Future<void> _claimReward() async {
    final entry = widget.entry;
    if (!SaveService.I.claimCodexReward(entry.id)) return;
    Sfx.play(SfxName.coin);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'RESEARCH REWARD · +${entry.rewardCoins} COINS · +${entry.rewardGems} GEMS',
            style: AppTextStyles.label(fontSize: 12, color: Colors.white),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final accent =
        entry.reactionType?.primaryElement.color ?? AppColors.candyPurpleLight;
    final title = widget.discovered
        ? entry.title
        : entry.category == CodexCategory.combinations
        ? 'Unknown combination'
        : 'Unknown reaction';

    return GlassPanel(
      radius: 20,
      tint: widget.discovered ? accent : null,
      glow: widget.discovered ? 0.08 : 0,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Container(
                  key: ValueKey(widget.discovered),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.4),
                      colors: widget.discovered
                          ? [
                              accent.withValues(alpha: 0.38),
                              accent.withValues(alpha: 0.10),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.08),
                              Colors.white.withValues(alpha: 0.02),
                            ],
                    ),
                    border: Border.all(
                      color: widget.discovered
                          ? accent.withValues(alpha: 0.8)
                          : Colors.white24,
                    ),
                  ),
                  child: widget.discovered && entry.reactionType != null
                      ? _ElementBubbleGlyph(
                          type: entry.reactionType!.primaryBubble,
                        )
                      : Icon(
                          widget.discovered
                              ? _entryIcon(entry)
                              : Icons.lock_outline_rounded,
                          color: widget.discovered ? accent : Colors.white54,
                          size: 24,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label(
                        fontSize: 15,
                        color: widget.discovered
                            ? AppColors.accent
                            : Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.discovered
                          ? entry.formula
                          : 'A field note is waiting to be uncovered',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label(
                        fontSize: 11,
                        color: widget.discovered
                            ? AppColors.candyYellow
                            : Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.discovered && widget.claimed)
                const Tooltip(
                  message: 'Discovery reward claimed',
                  child: Icon(
                    Icons.verified_rounded,
                    color: AppColors.candyGreen,
                    size: 22,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.discovered ? entry.description : 'Undiscovered research stays partly hidden until you trigger it in a level.',
            style: AppTextStyles.body(fontSize: 13),
          ),
          if (!widget.discovered) ...[
            const SizedBox(height: 6),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _showClue = !_showClue),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showClue
                          ? Icons.visibility_off_rounded
                          : Icons.lightbulb_outline_rounded,
                      size: 17,
                      color: AppColors.coinGold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _showClue ? 'Hide clue' : 'Inspect clue',
                      style: AppTextStyles.label(
                        fontSize: 12,
                        color: AppColors.coinGold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: _showClue
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.coinGold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.coinGold.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        entry.clue,
                        style: AppTextStyles.body(
                          fontSize: 12,
                          color: AppColors.candyYellow,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
          if (widget.discovered) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: widget.claimed
                      ? Text(
                          'Research reward collected',
                          style: AppTextStyles.label(
                            fontSize: 12,
                            color: AppColors.candyGreen,
                          ),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            GlassPill(
                              text: '+${entry.rewardCoins}',
                              icon: Icons.monetization_on_rounded,
                              color: AppColors.coinGold,
                            ),
                            GlassPill(
                              text: '+${entry.rewardGems}',
                              icon: Icons.diamond_rounded,
                              color: AppColors.candyBlueLight,
                            ),
                          ],
                        ),
                ),
                if (!widget.claimed)
                  JellyButton(
                    text: 'CLAIM',
                    width: 92,
                    height: 40,
                    fontSize: 12,
                    color: JellyColor.green,
                    onPressed: _claimReward,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ElementBubbleGlyph extends StatelessWidget {
  final BubbleType type;

  const _ElementBubbleGlyph({required this.type});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ElementBubblePainter(type),
      child: const SizedBox.expand(),
    );
  }
}

class _ElementBubblePainter extends CustomPainter {
  final BubbleType type;

  const _ElementBubblePainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    BubblePainter.draw(
      canvas,
      Offset(size.width / 2, size.height / 2),
      size.shortestSide * 0.36,
      type,
      t: 0.35,
      glow: 0.12,
    );
  }

  @override
  bool shouldRepaint(covariant _ElementBubblePainter oldDelegate) =>
      oldDelegate.type != type;
}

IconData _entryIcon(CodexEntry entry) {
  if (entry.id == 'chain_double' || entry.id == 'chain_triple') {
    return Icons.bolt_rounded;
  }
  if (entry.category == CodexCategory.combinations) {
    return Icons.hub_rounded;
  }
  return switch (entry.reactionType) {
    ReactionType.burn => Icons.local_fire_department,
    ReactionType.steam => Icons.cloud,
    ReactionType.mud => Icons.water_drop,
    ReactionType.bloom => Icons.local_florist,
    null => Icons.auto_awesome,
  };
}
