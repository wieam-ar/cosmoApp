import 'package:flutter/services.dart';

import 'save_service.dart';

/// Wraps device haptic feedback and respects user vibration settings.
class AppHaptics {
  static void light() {
    if (SaveService.I.vibrateEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  static void medium() {
    if (SaveService.I.vibrateEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  static void heavy() {
    if (SaveService.I.vibrateEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  static void selection() {
    if (SaveService.I.vibrateEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  static void vibrate() {
    if (SaveService.I.vibrateEnabled) {
      HapticFeedback.vibrate();
    }
  }
}
