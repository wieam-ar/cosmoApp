import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../game/cosmo_game.dart';
import '../game/overlays/game_hud.dart';
import '../game/overlays/pause_overlay.dart';
import '../game/overlays/result_overlay.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final int level;

  const GameScreen({super.key, this.mode = GameMode.level, this.level = 1});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final CosmoGame _game;
  bool _allowPop = false;
  Offset? _pointerDown;
  bool _pointerDownTargetingPowerup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = CosmoGame(mode: widget.mode, level: widget.level);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _game.openPause();
  }

  void _onBack(bool didPop, Object? result) {
    if (didPop || _allowPop) return;
    _game.openPause();
  }

  void _exitScreen() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: _onBack,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Listener(
          onPointerDown: (event) {
            _pointerDown = event.localPosition;
            _pointerDownTargetingPowerup = _game.pendingPowerup != null;
          },
          onPointerCancel: (_) {
            _pointerDown = null;
            _pointerDownTargetingPowerup = false;
          },
          onPointerUp: (event) {
            final start = _pointerDown;
            final wasTargeting = _pointerDownTargetingPowerup;
            _pointerDown = null;
            _pointerDownTargetingPowerup = false;
            if (start != null &&
                (event.localPosition - start).distance < 18 &&
                (wasTargeting || _game.pendingPowerup != null)) {
              _game.handleTapAt(event.localPosition);
            }
          },
          child: GameWidget<CosmoGame>(
            game: _game,
            initialActiveOverlays: const ['hud'],
            overlayBuilderMap: {
              'hud': (context, game) => GameHud(game: game),
              'pause': (context, game) =>
                  PauseOverlay(game: game, onExit: _exitScreen),
              'result': (context, game) =>
                  ResultOverlay(game: game, onExit: _exitScreen),
            },
            loadingBuilder: (context) => Center(
              child: outlinedText(
                'LOADING...',
                fontSize: 24,
                fill: AppColors.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
