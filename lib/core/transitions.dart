import 'dart:math';

import 'package:flutter/material.dart';

/// Transition styles supported by AppNav.
enum NavTransition { iris, slide, fade }

/// Circular iris clipper expanding from origin to full screen.
class IrisClipper extends CustomClipper<Path> {
  final double progress;
  final Offset? origin;

  IrisClipper({required this.progress, this.origin});

  @override
  Path getClip(Size size) {
    final center = origin ?? Offset(size.width / 2, size.height / 2);

    final dx = max(center.dx, size.width - center.dx);
    final dy = max(center.dy, size.height - center.dy);
    final maxRadius = sqrt(dx * dx + dy * dy);

    final currentRadius = maxRadius * progress.clamp(0.0, 1.0);

    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: currentRadius));
  }

  @override
  bool shouldReclip(IrisClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.origin != origin;
  }
}

/// Router and transition manager for Cosmo Pop.
class AppNav {
  /// Navigates to [page] using the chosen transition style.
  static Future<T?> go<T>(
    BuildContext context,
    Widget page, {
    NavTransition style = NavTransition.iris,
    Offset? origin,
    Duration duration = const Duration(milliseconds: 600),
    bool replace = false,
  }) {
    final route = PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final isAnimating =
            animation.status == AnimationStatus.forward ||
            animation.status == AnimationStatus.reverse ||
            secondaryAnimation.status == AnimationStatus.forward ||
            secondaryAnimation.status == AnimationStatus.reverse;

        final interactiveChild = IgnorePointer(
          ignoring: isAnimating,
          child: child,
        );

        switch (style) {
          case NavTransition.iris:
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
              reverseCurve: Curves.easeInOutCubic,
            );
            return AnimatedBuilder(
              animation: curved,
              builder: (context, c) {
                return ClipPath(
                  clipper: IrisClipper(progress: curved.value, origin: origin),
                  child: c,
                );
              },
              child: interactiveChild,
            );

          case NavTransition.slide:
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(curved),
              child: interactiveChild,
            );

          case NavTransition.fade:
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            );
            return FadeTransition(opacity: curved, child: interactiveChild);
        }
      },
    );

    if (replace) {
      return Navigator.of(context).pushReplacement(route);
    } else {
      return Navigator.of(context).push(route);
    }
  }

  /// Pops current route.
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }
}
