import 'package:flutter/material.dart';

import '../art/icons_painter.dart';
import '../core/save_service.dart';
import '../core/ui_theme.dart';
import 'jelly_button.dart';

class Popup {
  Popup._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    List<Widget>? actions,
    Color borderColor = Ui.purpleLight,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'PopupBarrier',
      barrierColor: const Color(0xB3000000),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, _, _) => PopupPanel(
        title: title,
        actions: actions,
        borderColor: borderColor,
        child: child,
      ),
      transitionBuilder: (_, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }
}

class PopupPanel extends StatelessWidget {
  final String? title;
  final Widget child;
  final List<Widget>? actions;
  final Color borderColor;

  const PopupPanel({
    super.key,
    this.title,
    required this.child,
    this.actions,
    this.borderColor = Ui.purpleLight,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 26),
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF3A2579), Ui.surface],
                    ),
                    border: Border.all(color: borderColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: borderColor.withValues(alpha: 0.45),
                        blurRadius: 24,
                      ),
                      const BoxShadow(
                        color: Colors.black54,
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      child,
                      if (actions?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: actions!,
                        ),
                      ],
                    ],
                  ),
                ),
                if (title?.isNotEmpty ?? false)
                  Positioned(
                    top: 0,
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            JellyColor.purple.uiTop,
                            JellyColor.purple.uiBottom,
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: JellyColor.purple.uiEdge,
                            offset: const Offset(0, 5),
                          ),
                          const BoxShadow(
                            color: Colors.black45,
                            blurRadius: 10,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: OutlinedText(
                        title!,
                        fontSize: 21,
                        fill: Ui.accent,
                      ),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: -6,
                  child: RoundButton(
                    icon: AppIcon.close,
                    color: JellyColor.red,
                    size: 38,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EventPopup extends StatelessWidget {
  const EventPopup({super.key});

  static Future<void> show(BuildContext context) => Popup.show<void>(
    context,
    title: 'CAT RESCUE WEEK',
    child: const EventPopup(),
  );

  static const _thresholds = [50, 100, 200, 200];
  static const _rewards = ['100 COINS', '250 COINS', '500 COINS', '25 GEMS'];

  static DateTime _nextMonday(DateTime now) {
    final d = (DateTime.monday - now.weekday + 7) % 7;
    return DateTime(now.year, now.month, now.day + (d == 0 ? 7 : d));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SaveService.I,
      builder: (_, _) {
        final done = SaveService.I.eventProgress.clamp(0, 200);
        final left = _nextMonday(DateTime.now()).difference(DateTime.now());

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rescue kittens this week and collect rewards!',
              textAlign: TextAlign.center,
              style: Ui.text(15, weight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            _ProgressBar(value: done / 200),
            const SizedBox(height: 6),
            Text(
              '$done / 200 rescued  •  ${left.inDays}d ${left.inHours.remainder(24)}h ${left.inMinutes.remainder(60)}m left',
              style: Ui.text(12, color: Ui.accent),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _thresholds.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: _EventTier(
                  milestone: i + 1,
                  threshold: _thresholds[i],
                  reward: _rewards[i],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: LayoutBuilder(
        builder: (_, c) => Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            width: c.maxWidth * value.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFF86EFAC), Ui.green],
              ),
              boxShadow: [
                BoxShadow(
                  color: Ui.green.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventTier extends StatelessWidget {
  final int milestone, threshold;
  final String reward;

  const _EventTier({
    required this.milestone,
    required this.threshold,
    required this.reward,
  });

  @override
  Widget build(BuildContext context) {
    final claimed = SaveService.I.claimedEventTiers.contains(milestone);
    final eligible = SaveService.I.eventProgress >= threshold;
    final gems = milestone == 4;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: eligible && !claimed ? 0.14 : 0.07,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: eligible && !claimed ? Ui.accent : Colors.white12,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            gems ? Icons.diamond_rounded : Icons.card_giftcard_rounded,
            color: gems ? Ui.blueLight : Ui.gold,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('$threshold RESCUES · $reward', style: Ui.text(12)),
          ),
          SizedBox(
            height: 36,
            child: claimed
                ? const Icon(Icons.check_circle_rounded, color: Ui.green)
                : JellyButton(
                    text: 'CLAIM',
                    width: 74,
                    height: 30,
                    fontSize: 12,
                    color: JellyColor.green,
                    enabled: eligible,
                    onPressed: eligible
                        ? () => SaveService.I.claimEventTier(milestone)
                        : null,
                  ),
          ),
        ],
      ),
    );
  }
}

class Toast {
  Toast._();

  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 1800),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        duration: duration,
        onDismiss: entry.remove,
      ),
    );
    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, -1.6),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));

  @override
  void initState() {
    super.initState();
    _c.forward();
    Future.delayed(widget.duration, () async {
      if (!mounted) return;
      await _c.reverse();
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _slide,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3A2579), Ui.surface],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Ui.accent, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(widget.message, style: Ui.text(15)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
