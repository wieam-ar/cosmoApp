import 'dart:math';

import 'package:flutter/material.dart';

import '../art/bubble_painter.dart';
import '../art/icons_painter.dart';
import '../art/jelly_painter.dart';
import '../art/mimo_painter.dart';
import '../art/space_painter.dart';
import '../art/title3d.dart';
import '../art/ufo_painter.dart';
import '../config/bubble_types.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../widgets/glass_ui.dart';

/// Interactive gallery screen displaying every procedural art element in the game.
class ArtGalleryScreen extends StatefulWidget {
  const ArtGalleryScreen({super.key});

  @override
  State<ArtGalleryScreen> createState() => _ArtGalleryScreenState();
}

class _ArtGalleryScreenState extends State<ArtGalleryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _t = 0.0;
  bool _colorblind = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            setState(() {
              _t = _controller.value * 10.0;
            });
          })
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Art gallery', style: AppTextStyles.label()),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: Icon(
              _colorblind ? Icons.color_lens : Icons.color_lens_outlined,
            ),
            onPressed: () {
              setState(() {
                _colorblind = !_colorblind;
              });
            },
            tooltip: 'Toggle Colorblind Mode',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Space Canvas
          Positioned.fill(
            child: CustomPaint(painter: _SpaceGalleryPainter(t: _t)),
          ),

          // Gallery Grid View
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionTitle('Title'),
              _buildTitleCard(),

              _buildSectionTitle('Jelly buttons'),
              _buildJellyCard(),

              _buildSectionTitle('App icons'),
              _buildIconsCard(),

              _buildSectionTitle('Bubbles'),
              _buildBubblesCard(),

              _buildSectionTitle('Mimo'),
              _buildMimoCard(),

              _buildSectionTitle('UFO'),
              _buildUfoCard(),

              const SizedBox(height: 60),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: AppTextStyles.title(fontSize: 18, color: AppColors.accent),
      ),
    );
  }

  Widget _buildTitleCard() {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: Glass.surface(radius: 20),
      foregroundDecoration: Glass.sheen(20),
      child: CustomPaint(painter: _TitleGalleryPainter(t: _t)),
    );
  }

  Widget _buildJellyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Glass.surface(radius: 20),
      foregroundDecoration: Glass.sheen(20),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: JellyColor.values.map((color) {
              return SizedBox(
                width: 130,
                height: 50,
                child: CustomPaint(
                  painter: _JellyButtonPainter(color: color, t: _t),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 120,
                height: 36,
                child: CustomPaint(painter: _PillPainter()),
              ),
              SizedBox(
                width: 50,
                height: 50,
                child: CustomPaint(painter: _RoundJellyPainter(t: _t)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Glass.surface(radius: 20),
      foregroundDecoration: Glass.sheen(20),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: AppIcon.values.map((icon) {
          return Column(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CustomPaint(painter: _IconGalleryPainter(icon: icon)),
              ),
              const SizedBox(height: 4),
              Text(
                icon.name,
                style: AppTextStyles.body(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBubblesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Glass.surface(radius: 20),
      foregroundDecoration: Glass.sheen(20),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: BubbleType.values.map((type) {
          return Column(
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: CustomPaint(
                  painter: _BubbleGalleryPainter(
                    type: type,
                    t: _t,
                    colorblind: _colorblind,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                type.name,
                style: AppTextStyles.body(
                  fontSize: 11,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMimoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Glass.surface(radius: 20),
      foregroundDecoration: Glass.sheen(20),
      child: Column(
        children: [
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: MimoState.values.map((state) {
              return Column(
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CustomPaint(
                      painter: _MimoGalleryPainter(
                        state: state,
                        skin: SkinId.defaultMimo,
                        t: _t,
                      ),
                    ),
                  ),
                  Text(
                    state.name,
                    style: AppTextStyles.body(
                      fontSize: 11,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const Divider(height: 24, color: Colors.white24),
          Text('Skins Catalog', style: AppTextStyles.label(fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: SkinId.values.map((skin) {
              return Column(
                children: [
                  SizedBox(
                    width: 65,
                    height: 65,
                    child: CustomPaint(
                      painter: _MimoGalleryPainter(
                        state: MimoState.idle,
                        skin: skin,
                        t: _t,
                      ),
                    ),
                  ),
                  Text(
                    skin.name,
                    style: AppTextStyles.body(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUfoCard() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: Glass.surface(radius: 20),
      foregroundDecoration: Glass.sheen(20),
      child: CustomPaint(painter: _UfoGalleryPainter(t: _t)),
    );
  }
}

// ============================================================================
// CUSTOM PAINTERS FOR GALLERY CARDS
// ============================================================================

class _SpaceGalleryPainter extends CustomPainter {
  final double t;
  _SpaceGalleryPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    SpacePainter.nebula(canvas, size, t: t);
    SpacePainter.starfield(canvas, size, t: t);
    SpacePainter.planet(
      canvas,
      Offset(size.width * 0.85, 120),
      35,
      PlanetKind.purpleMoon,
      t: t,
    );
    SpacePainter.shootingStar(canvas, size, t: t);
    SpacePainter.lavaSurface(canvas, size, t: t, heightFactor: 0.12);
  }

  @override
  bool shouldRepaint(covariant _SpaceGalleryPainter old) => old.t != t;
}

class _TitleGalleryPainter extends CustomPainter {
  final double t;
  _TitleGalleryPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final shine = (sin(t * 2.0) + 1.0) / 2.0;
    Title3D.draw(
      canvas,
      "COSMO POP",
      Offset(size.width / 2, size.height / 2),
      fontSize: 38,
      shine: shine,
    );
  }

  @override
  bool shouldRepaint(covariant _TitleGalleryPainter old) => old.t != t;
}

class _JellyButtonPainter extends CustomPainter {
  final JellyColor color;
  final double t;
  _JellyButtonPainter({required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = (sin(t * 3.0) + 1.0) / 2.0;
    JellyPainter.button(
      canvas,
      Rect.fromLTWH(0, 0, size.width, size.height),
      color: color,
      pulse: pulse,
    );
  }

  @override
  bool shouldRepaint(covariant _JellyButtonPainter old) => old.t != t;
}

class _PillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    JellyPainter.pill(canvas, Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _RoundJellyPainter extends CustomPainter {
  final double t;
  _RoundJellyPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    JellyPainter.round(
      canvas,
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      color: JellyColor.purple,
      pulse: (sin(t * 4.0) + 1.0) / 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant _RoundJellyPainter old) => old.t != t;
}

class _IconGalleryPainter extends CustomPainter {
  final AppIcon icon;
  _IconGalleryPainter({required this.icon});

  @override
  void paint(Canvas canvas, Size size) {
    IconsPainter.draw(
      canvas,
      Rect.fromLTWH(0, 0, size.width, size.height),
      icon,
      color: AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _BubbleGalleryPainter extends CustomPainter {
  final BubbleType type;
  final double t;
  final bool colorblind;
  _BubbleGalleryPainter({
    required this.type,
    required this.t,
    required this.colorblind,
  });

  @override
  void paint(Canvas canvas, Size size) {
    BubblePainter.draw(
      canvas,
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - 2,
      type,
      t: t,
      glow: (sin(t * 3.0) + 1.0) / 2.0,
      colorblind: colorblind,
    );
  }

  @override
  bool shouldRepaint(covariant _BubbleGalleryPainter old) =>
      old.t != t || old.colorblind != colorblind;
}

class _MimoGalleryPainter extends CustomPainter {
  final MimoState state;
  final SkinId skin;
  final double t;
  _MimoGalleryPainter({
    required this.state,
    required this.skin,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    MimoPainter.draw(
      canvas,
      Offset(size.width / 2, size.height / 2 + 5),
      size.width,
      state: state,
      skin: skin,
      t: t,
      heldBubble: state == MimoState.idle ? BubbleType.red : null,
    );
  }

  @override
  bool shouldRepaint(covariant _MimoGalleryPainter old) => old.t != t;
}

class _UfoGalleryPainter extends CustomPainter {
  final double t;
  _UfoGalleryPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final beamLength = (sin(t * 2.0) + 1.0) / 2.0;
    UfoPainter.draw(
      canvas,
      Offset(size.width / 2, 45),
      80,
      t: t,
      beamLength: beamLength,
    );
  }

  @override
  bool shouldRepaint(covariant _UfoGalleryPainter old) => old.t != t;
}
