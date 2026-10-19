import '../../config/levels.dart';
import '../../core/constants.dart';

class GoalProgress {
  final GameMode mode;
  Goal goal;
  final int moveLimit;
  int extraMoves = 0;
  final int targetScore;
  int rescued = 0;
  int score = 0;
  int moves = 0;
  int missedShots = 0;
  bool bossDefeated = false;

  GoalProgress({
    required this.mode,
    required this.goal,
    required this.moveLimit,
    required this.targetScore,
  });

  bool get isWon {
    if (mode == GameMode.arcade) return false;
    return switch (goal.type) {
      GoalType.rescue => rescued >= goal.target,
      GoalType.clear => false,
      GoalType.score => score >= goal.target,
      GoalType.timer => _remainingBubbles == 0,
      GoalType.boss => bossDefeated,
    };
  }

  int _remainingBubbles = 1;

  void setRemainingBubbles(int count) {
    _remainingBubbles = count;
  }

  bool clearedAll(int bubbleCount) =>
      mode == GameMode.classic && bubbleCount == 0 ||
      (goal.type == GoalType.clear || goal.type == GoalType.timer) &&
          bubbleCount == 0;

  bool get timerExpired => goal.type == GoalType.timer && _remainingBubbles > 0;

  bool get isOutOfMoves => moveLimit > 0 && moves >= moveLimit + extraMoves;

  double get starProgress =>
      (score / targetScore.clamp(1, 1 << 30)).clamp(0.0, 1.0);
}
