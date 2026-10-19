import 'package:flutter/material.dart';

import '../art/icons_painter.dart';
import '../art/jelly_painter.dart';
import '../config/levels.dart';
import '../core/audio_service.dart';
import '../core/constants.dart';
import '../core/haptics.dart';
import '../core/save_service.dart';
import '../widgets/cosmo_deco.dart';
import '../core/theme.dart';
import '../core/transitions.dart';
import 'art_gallery_screen.dart';
import 'garden_screen.dart';
import '../widgets/jelly_button.dart';
import '../widgets/space_background.dart';

import 'level_map_screen.dart';

/// Reusable OptionSquare widget for single-choice settings selectors.
class OptionSquare extends StatefulWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final double size;

  const OptionSquare({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.size = 54.0,
  });

  @override
  State<OptionSquare> createState() => _OptionSquareState();
}

class _OptionSquareState extends State<OptionSquare>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void didUpdateWidget(covariant OptionSquare oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? JellyColor.pink : JellyColor.orange;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () {
          AppHaptics.light();
          Sfx.play(SfxName.click);
          widget.onTap();
        },
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _OptionSquareCustomPainter(
              color: color,
              selected: widget.selected,
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

class _OptionSquareCustomPainter extends CustomPainter {
  final JellyColor color;
  final bool selected;

  _OptionSquareCustomPainter({required this.color, required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (selected) {
      final glowPaint = Paint()
        ..color = AppColors.secondary.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(3.0), const Radius.circular(16)),
        glowPaint,
      );
    }

    JellyPainter.button(canvas, rect, color: color, borderRadius: 14);
  }

  @override
  bool shouldRepaint(covariant _OptionSquareCustomPainter old) {
    return old.color != color || old.selected != selected;
  }
}

// ============================================================================
// REUSABLE JELLY SLIDER
// ============================================================================

/// Custom candy volume slider with glossy track, fill & tick audio feedback.
class JellySlider extends StatefulWidget {
  final double value; // 0.0..1.0
  final ValueChanged<double> onChanged;

  const JellySlider({super.key, required this.value, required this.onChanged});

  @override
  State<JellySlider> createState() => _JellySliderState();
}

class _JellySliderState extends State<JellySlider> {
  int _lastTickStep = -1;

  void _updateValue(double localX, double width) {
    final val = (localX / width).clamp(0.0, 1.0);
    final step = (val * 10).floor();
    if (step != _lastTickStep) {
      _lastTickStep = step;
      Sfx.play(SfxName.tick);
    }
    widget.onChanged(val);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return GestureDetector(
            onPanStart: (d) => _updateValue(d.localPosition.dx, width),
            onPanUpdate: (d) => _updateValue(d.localPosition.dx, width),
            onTapDown: (d) => _updateValue(d.localPosition.dx, width),
            child: CustomPaint(
              painter: _JellySliderPainter(value: widget.value),
              child: const SizedBox.expand(),
            ),
          );
        },
      ),
    );
  }
}

class _JellySliderPainter extends CustomPainter {
  final double value;
  _JellySliderPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final trackRect = Rect.fromLTWH(
      0,
      size.height * 0.25,
      size.width,
      size.height * 0.5,
    );

    // Track Background
    JellyPainter.button(
      canvas,
      trackRect,
      color: JellyColor.purple,
      borderRadius: 10,
    );

    // Filled Track
    final fillWidth = trackRect.width * value;
    if (fillWidth > 6) {
      final fillRect = Rect.fromLTWH(
        trackRect.left,
        trackRect.top,
        fillWidth,
        trackRect.height,
      );
      JellyPainter.button(
        canvas,
        fillRect,
        color: JellyColor.green,
        borderRadius: 10,
      );
    }

    // Draggable Knob
    final knobX = trackRect.left + fillWidth;
    JellyPainter.round(
      canvas,
      Offset(knobX, size.height / 2),
      14,
      color: JellyColor.orange,
    );
  }

  @override
  bool shouldRepaint(covariant _JellySliderPainter old) => old.value != value;
}

// ============================================================================
// REUSABLE JELLY SWITCH
// ============================================================================

/// Glossy toggle switch for vibration and colorblind settings.
class JellySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const JellySwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppHaptics.light();
        Sfx.play(SfxName.click);
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 32,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: value
                ? const [Color(0xFF9DFF9A), Color(0xFF1FBF68)]
                : const [Color(0xFF3A3470), Color(0xFF1E1A45)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? AppColors.accent : Colors.white30,
            width: 2,
          ),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
        ),
        child: Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFD9E4FF)],
              center: Alignment(-0.3, -0.4),
            ),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SETTINGS SCREEN MAIN WIDGET
// ============================================================================

/// Complete Settings Screen featuring space background, UFO, alien head difficulty icons,
/// audio sliders, vibration/colorblind switches, and instant persistence.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: SaveService.I,
        builder: (context, _) {
          final bubbleSize = SaveService.I.bubbleSize;
          final difficulty = SaveService.I.difficultyLevel;
          final aimingMode = SaveService.I.aimingMode;
          final sfxVol = SaveService.I.sfxVolume;
          final musicVol = SaveService.I.musicVolume;
          final vibrate = SaveService.I.vibrateEnabled;
          final colorblind = SaveService.I.colorblindEnabled;

          return SpaceBackground(
            variant: SpaceBgVariant.settings,
            child: SafeArea(
              child: AnimatedBuilder(
                animation: _entryController,
                builder: (context, child) {
                  return Column(
                    children: [
                      const SizedBox(height: 12),

                      // 3D Blue Title "SETTINGS"
                      _buildAnimatedHeader(),

                      const SizedBox(height: 12),

                      // Scrollable Settings Content
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          children: [
                            // 1. Bubble Size (S/M/L)
                            _buildSectionRow(
                              title: "BUBBLE SIZE",
                              subtitle: "Grid columns: S(10), M(8), L(7)",
                              index: 0,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: ["S", "M", "L"].map((sz) {
                                  return OptionSquare(
                                    selected: bubbleSize == sz,
                                    onTap: () => SaveService.I.bubbleSize = sz,
                                    child: outlinedText(
                                      sz,
                                      fontSize: 22,
                                      fill: Colors.white,
                                      stroke: Colors.black,
                                      strokeWidth: 4,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 2. Difficulty Level (1 to 4 Alien Heads)
                            _buildSectionRow(
                              title: "DIFFICULTY LEVEL",
                              subtitle: _getDifficultyDescription(difficulty),
                              index: 1,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [1, 2, 3, 4].map((lvl) {
                                  return OptionSquare(
                                    selected: difficulty == lvl,
                                    onTap: () =>
                                        SaveService.I.difficultyLevel = lvl,
                                    child: CustomPaint(
                                      size: const Size(36, 36),
                                      painter: _AlienHeadsPainter(count: lvl),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 3. Aiming Mode (Dotted vs Laser)
                            _buildSectionRow(
                              title: "AIMING MODE",
                              subtitle: aimingMode == 'dotted'
                                  ? "Dotted Trajectory Line"
                                  : "Laser Crosshair",
                              index: 2,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  OptionSquare(
                                    selected: aimingMode == 'dotted',
                                    onTap: () =>
                                        SaveService.I.aimingMode = 'dotted',
                                    child: const SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CustomPaint(
                                        painter: _IconCustomPainter(
                                          icon: AppIcon.swap,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  OptionSquare(
                                    selected: aimingMode == 'laser',
                                    onTap: () =>
                                        SaveService.I.aimingMode = 'laser',
                                    child: const SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CustomPaint(
                                        painter: _IconCustomPainter(
                                          icon: AppIcon.rocket,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 4. Volume Sliders
                            _buildSectionRow(
                              title: "AUDIO VOLUMES",
                              subtitle: "Music & SFX playback levels",
                              index: 3,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Music",
                                        style: AppTextStyles.label(
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: JellySlider(
                                          value: musicVol,
                                          onChanged: (v) {
                                            SaveService.I.musicVolume = v;
                                            Music.applySavedVolume();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text(
                                        "SFX    ",
                                        style: AppTextStyles.label(
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: JellySlider(
                                          value: sfxVol,
                                          onChanged: (v) {
                                            SaveService.I.sfxVolume = v;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 5. Switches (Vibration & Colorblind)
                            _buildSectionRow(
                              title: "ACCESSIBILITY & FEEDBACK",
                              subtitle: "Haptics & high contrast patterns",
                              index: 4,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        "Vibration",
                                        style: AppTextStyles.label(
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      JellySwitch(
                                        value: vibrate,
                                        onChanged: (v) =>
                                            SaveService.I.vibrateEnabled = v,
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        "Colorblind",
                                        style: AppTextStyles.label(
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      JellySwitch(
                                        value: colorblind,
                                        onChanged: (v) =>
                                            SaveService.I.colorblindEnabled = v,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),
                            _buildSectionRow(
                              title: "MIMO'S GARDEN",
                              subtitle: "Grow plants and place keepsakes.",
                              index: 5,
                              child: JellyButton(
                                text: "OPEN GARDEN",
                                color: JellyColor.green,
                                width: 190,
                                height: 46,
                                fontSize: 16,
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const GardenScreen(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSectionRow(
                              title: "ART GALLERY",
                              subtitle:
                                  "Browse the game's illustrated artwork.",
                              index: 6,
                              child: JellyButton(
                                text: "OPEN GALLERY",
                                color: JellyColor.purple,
                                width: 190,
                                height: 46,
                                fontSize: 16,
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const ArtGalleryScreen(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      // Bottom Action Buttons (PLAY & BACK)
                      _buildBottomActionButtons(),

                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOutBack),
    );

    return Transform.scale(
      scale: anim.value,
      child: outlinedText(
        "SETTINGS",
        fontSize: 36,
        fill: AppColors.candyBlueLight,
        stroke: Colors.black,
        strokeWidth: 5,
      ),
    );
  }

  Widget _buildSectionRow({
    required String title,
    required String subtitle,
    required int index,
    required Widget child,
  }) {
    final start = 0.2 + index * 0.1;
    final end = (start + 0.3).clamp(0.0, 1.0);

    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );

    return Transform.translate(
      offset: Offset((1.0 - anim.value) * 120.0, 0),
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          gradient: kCardGradientGlass,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF7C62E0), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x337CF6FF), blurRadius: 12),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.label(fontSize: 16, color: AppColors.accent),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.body(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  String _getDifficultyDescription(int level) {
    final data = getLevel(
      SaveService.I.currentLevel.clamp(1, 120),
      bubbleSize: SaveService.I.bubbleSize,
      difficultyLevel: level,
    );
    return "Affects gameplay: ${data.colorsCount} colors, ${data.moves} moves, ceiling drops every ${data.ceilingDropEvery} shots.";
  }

  Widget _buildBottomActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Red BACK Pill
          JellyButton(
            text: "BACK",
            color: JellyColor.red,
            width: 120,
            height: 52,
            fontSize: 20,
            onPressed: () {
              AppHaptics.light();
              Sfx.play(SfxName.pop);
              AppNav.pop(context);
            },
          ),

          // Big Orange PLAY Pill
          GestureDetector(
            onTapDown: (details) {
              AppHaptics.medium();
              Sfx.play(SfxName.click);
              AppNav.go(
                context,
                const LevelMapScreen(),
                style: NavTransition.iris,
                origin: details.globalPosition,
              );
            },
            child: const JellyButton(
              text: "PLAY",
              color: JellyColor.orange,
              width: 150,
              height: 54,
              fontSize: 22,
              onPressed: null,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ALIEN HEADS PAINTER FOR DIFFICULTY
// ============================================================================

class _AlienHeadsPainter extends CustomPainter {
  final int count; // 1..4
  _AlienHeadsPainter({required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;

    final eyePaint = Paint()..color = Colors.black;

    final spacing = count > 1 ? (w - 18) / (count - 1) : 0.0;

    for (int i = 0; i < count; i++) {
      final cx = count == 1 ? w / 2 : 9.0 + i * spacing;
      final cy = h / 2;

      // Alien Head Oval
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: 16, height: 22),
        paint,
      );

      // Slanted Eyes
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx - 3.5, cy - 2),
          width: 3.5,
          height: 6,
        ),
        eyePaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + 3.5, cy - 2),
          width: 3.5,
          height: 6,
        ),
        eyePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AlienHeadsPainter old) => old.count != count;
}

class _IconCustomPainter extends CustomPainter {
  final AppIcon icon;
  final Color color;

  const _IconCustomPainter({required this.icon, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    IconsPainter.draw(
      canvas,
      Rect.fromLTWH(0, 0, size.width, size.height),
      icon,
      color: color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
