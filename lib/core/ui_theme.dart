import 'package:flutter/material.dart';

import '../art/jelly_painter.dart' show JellyColor, kJellyPalettes;
import 'constants.dart';
import 'theme.dart' show AppGradients;

export '../art/jelly_painter.dart' show JellyColor;

/// Widget-side tokens. Every colour that also exists in [AppColors] is an
/// alias of it, so the two files can no longer drift apart.
class Ui {
  Ui._();

  // Space
  static const spaceDark = AppColors.darkBg;
  static const spaceMid = AppColors.spaceBlue;
  static const spaceBlue = Color(0xFF2E1F8A);
  static const surface = AppColors.cardBg;

  // Brand / rewards
  static const accent = AppColors.accent;
  static const gold = AppColors.gold;
  static const heart = AppColors.heartRed;
  static const green = AppColors.candyGreen;
  static const red = AppColors.candyRed;
  static const purpleLight = AppColors.primaryLight;
  static const blueLight = AppColors.candyBlueLight;

  static const ink = Color(0xFF1B0F4D);

  static const LinearGradient screen = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [spaceBlue, spaceMid, spaceDark],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient card = AppGradients.panel;

  static List<BoxShadow> glow(
    Color c, {
    double blur = 22,
    double opacity = 0.5,
  }) => [
    BoxShadow(
      color: c.withValues(alpha: opacity),
      blurRadius: blur,
      spreadRadius: 1,
    ),
  ];

  static TextStyle text(
    double size, {
    Color color = Colors.white,
    FontWeight weight = FontWeight.w800,
    double letterSpacing = 0.5,
  }) => TextStyle(
    fontSize: size,
    color: color,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: 1.1,
  );
}

/// Button colours for JellyButton / RoundButton / Popup.
/// Read from the same palette as JellyPainter (art/jelly_painter.dart), which
/// is tuned to the launcher icon. Change colours there, once.
extension JellyColorX on JellyColor {
  Color get uiTop => kJellyPalettes[this]!.top;
  Color get uiBottom => kJellyPalettes[this]!.bottom;
  Color get uiEdge => kJellyPalettes[this]!.lip;
}

/// Text with a thick rounded outline and soft drop shadow.
class OutlinedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color fill;
  final Color stroke;
  final double strokeWidth;

  const OutlinedText(
    this.text, {
    super.key,
    this.fontSize = 20,
    this.fill = Colors.white,
    this.stroke = Ui.ink,
    this.strokeWidth = 4,
  });

  @override
  Widget build(BuildContext context) {
    final base = Ui.text(fontSize);
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..color = stroke,
            shadows: const [
              Shadow(
                color: Colors.black45,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
        Text(text, style: base.copyWith(color: fill)),
      ],
    );
  }
}
