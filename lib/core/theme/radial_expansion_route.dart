import 'dart:math' as math;
import 'package:finance_app/core/theme/motion_tokens.dart';
import 'package:flutter/material.dart';

/// Custom PageRoute that animates the incoming screen via a radial circular expansion clip.
class RadialExpansionRoute<T> extends PageRouteBuilder<T> {
  RadialExpansionRoute({
    required this.page,
    this.centerAlignment = Alignment.center,
    super.settings,
  }) : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionDuration: MotionTokens.durationSplashTransition,
          reverseTransitionDuration: MotionTokens.durationSplashTransition,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final CurvedAnimation curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: MotionTokens.standardCurve,
              reverseCurve: MotionTokens.standardCurve.flipped,
            );

            return AnimatedBuilder(
              animation: curvedAnimation,
              builder: (BuildContext context, Widget? childWidget) {
                return ClipPath(
                  clipper: RadialClipper(
                    fraction: curvedAnimation.value,
                    alignment: centerAlignment,
                  ),
                  child: childWidget,
                );
              },
              child: child,
            );
          },
        );

  final Widget page;
  final Alignment centerAlignment;
}

/// Custom Clipper that clips child to a circle expanding radially from [alignment].
class RadialClipper extends CustomClipper<Path> {
  const RadialClipper({
    required this.fraction,
    this.alignment = Alignment.center,
  });

  final double fraction;
  final Alignment alignment;

  @override
  Path getClip(Size size) {
    final Path path = Path();
    if (fraction <= 0.0) {
      return path;
    }

    // Convert alignment to coordinate
    final Offset center = Offset(
      (alignment.x + 1) / 2 * size.width,
      (alignment.y + 1) / 2 * size.height,
    );

    // Calculate maximum radius to screen corners
    final double maxDx = math.max(center.dx, size.width - center.dx);
    final double maxDy = math.max(center.dy, size.height - center.dy);
    final double maxRadius = math.sqrt(maxDx * maxDx + maxDy * maxDy);

    final double currentRadius = maxRadius * fraction;

    path.addOval(
      Rect.fromCircle(
        center: center,
        radius: currentRadius,
      ),
    );

    return path;
  }

  @override
  bool shouldReclip(covariant RadialClipper oldClipper) {
    return oldClipper.fraction != fraction || oldClipper.alignment != alignment;
  }
}
