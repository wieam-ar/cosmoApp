import 'dart:async';

import 'package:flutter/material.dart';

import '../art/icons_painter.dart';
import '../core/save_service.dart';
import '../core/ui_theme.dart';
import 'jelly_button.dart';

class HudBar extends StatefulWidget {
  final VoidCallback? onAddHearts;
  final VoidCallback? onAddCoins;

  const HudBar({super.key, this.onAddHearts, this.onAddCoins});

  @override
  State<HudBar> createState() => _HudBarState();
}

class _HudBarState extends State<HudBar> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Ticks only when a heart is regenerating.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && SaveService.I.nextHeartIn != Duration.zero) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    if (d == Duration.zero) return 'FULL';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SaveService.I,
      builder: (_, _) {
        final s = SaveService.I;
        final screenWidth = MediaQuery.sizeOf(context).width;
        final horizontalInset = screenWidth < 360 ? 8.0 : 20.0;
        final availableWidth = screenWidth - horizontalInset * 2;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalInset,
              vertical: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Pill(
                  width: (availableWidth * 0.51).clamp(0.0, 150.0).toDouble(),
                  icon: Icons.favorite_rounded,
                  iconColor: Ui.heart,
                  onAdd: widget.onAddHearts,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${s.hearts}', style: Ui.text(17, color: Ui.ink)),
                      Text(
                        _fmt(s.nextHeartIn),
                        style: Ui.text(12, color: const Color(0xFF8E44AD)),
                      ),
                    ],
                  ),
                ),
                _Pill(
                  width: (availableWidth * 0.46).clamp(0.0, 136.0).toDouble(),
                  icon: Icons.monetization_on_rounded,
                  iconColor: Ui.gold,
                  onAdd: widget.onAddCoins,
                  child: TweenAnimationBuilder<int>(
                    tween: IntTween(begin: s.coins, end: s.coins),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) =>
                        Text('$v', style: Ui.text(17, color: Ui.ink)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  final double width;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onAdd;
  final Widget child;

  const _Pill({
    required this.width,
    required this.icon,
    required this.iconColor,
    required this.onAdd,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 34, right: 28),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFFFF), Color(0xFFE6DBFF)],
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0xFF5B3BA8), offset: Offset(0, 3)),
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 8,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: child,
          ),
          Positioned(
            left: -10,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Ui.surface,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
          ),
          Positioned(
            right: -10,
            child: RoundButton(
              icon: AppIcon.plus,
              color: JellyColor.green,
              size: 32,
              onPressed: onAdd,
            ),
          ),
        ],
      ),
    );
  }
}
