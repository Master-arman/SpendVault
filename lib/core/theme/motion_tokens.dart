import 'package:flutter/animation.dart';

/// Centralized motion tokens, animation durations, and easing curves.
class MotionTokens {
  const MotionTokens._();

  // Durations
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 350);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationSplashTransition = Duration(milliseconds: 650);

  // Curves
  static const Curve standardCurve = Curves.easeInOutCubic;
  static const Curve entranceCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
  static const Curve springCurve = Curves.elasticOut;
}
