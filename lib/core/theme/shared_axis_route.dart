import 'package:flutter/material.dart';

/// Shared-axis container transform route transition for chart-to-ledger drill-down navigation.
class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  SharedAxisPageRoute({
    required this.page,
    super.settings,
  }) : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final CurvedAnimation curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            // Shared axis transition with scale, fade, and vertical slide
            final Animation<double> scaleAnimation = Tween<double>(
              begin: 0.92,
              end: 1.0,
            ).animate(curvedAnimation);

            final Animation<double> fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curvedAnimation);

            final Animation<Offset> slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(curvedAnimation);

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: child,
                ),
              ),
            );
          },
        );

  final Widget page;
}
