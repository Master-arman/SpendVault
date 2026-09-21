import 'dart:math' as math;
import 'package:finance_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Representation of an individual spotlight tour step.
class FeatureTourStep {
  const FeatureTourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    required this.icon,
    this.padding = const EdgeInsets.all(8.0),
    this.borderRadius = 14.0,
  });

  /// The [GlobalKey] of the widget being highlighted.
  final GlobalKey targetKey;

  /// Header title for the step.
  final String title;

  /// Explanatory guidance text for the user.
  final String description;

  /// Category or action icon.
  final IconData icon;

  /// Extra margin around the target's bounding box.
  final EdgeInsets padding;

  /// Corner radius of the spotlight punch-out.
  final double borderRadius;
}

/// Interactive spotlight discovery overlay that punches a hole through a dark backdrop
/// and displays a contextual Material 3 tooltip pointing directly at the target widget.
class FeatureSpotlightOverlay extends StatefulWidget {
  const FeatureSpotlightOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    this.onSkip,
  });

  final List<FeatureTourStep> steps;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  @override
  State<FeatureSpotlightOverlay> createState() => _FeatureSpotlightOverlayState();
}

class _FeatureSpotlightOverlayState extends State<FeatureSpotlightOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  FeatureTourStep get _currentStep => widget.steps[_currentStepIndex];

  Rect _calculateTargetRect() {
    try {
      final BuildContext? context = _currentStep.targetKey.currentContext;
      if (context == null) {
        final Size screenSize = MediaQuery.of(this.context).size;
        return Rect.fromCenter(
          center: Offset(screenSize.width / 2, screenSize.height / 2),
          width: 100,
          height: 60,
        );
      }

      final RenderObject? renderObject = context.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize || !renderObject.attached) {
        final Size screenSize = MediaQuery.of(this.context).size;
        return Rect.fromCenter(
          center: Offset(screenSize.width / 2, screenSize.height / 2),
          width: 100,
          height: 60,
        );
      }

      final Offset offset = renderObject.localToGlobal(Offset.zero);
      final Size size = renderObject.size;
      final EdgeInsets pad = _currentStep.padding;

      return Rect.fromLTRB(
        offset.dx - pad.left,
        offset.dy - pad.top,
        offset.dx + size.width + pad.right,
        offset.dy + size.height + pad.bottom,
      );
    } catch (_) {
      final Size screenSize = MediaQuery.of(context).size;
      return Rect.fromCenter(
        center: Offset(screenSize.width / 2, screenSize.height / 2),
        width: 100,
        height: 60,
      );
    }
  }

  void _nextStep() {
    if (_currentStepIndex < widget.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    } else {
      widget.onComplete();
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
    }
  }

  void _handleSkip() {
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();

    final Size screenSize = MediaQuery.of(context).size;
    final Rect targetRect = _calculateTargetRect();
    final bool isTargetInTopHalf = targetRect.center.dy < (screenSize.height * 0.55);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Spotlight Punch-out Backdrop with animated pulse
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: screenSize,
                painter: _SpotlightPainter(
                  targetRect: targetRect,
                  borderRadius: _currentStep.borderRadius,
                  pulseScale: _pulseAnimation.value,
                ),
              );
            },
          ),

          // Tap gesture to advance or absorb clicks
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Allow tapping backdrop or target to advance tour
              },
            ),
          ),

          // Floating Feature Callout Card
          Positioned(
            left: 20,
            right: 20,
            top: isTargetInTopHalf ? math.min(targetRect.bottom + 16, screenSize.height - 240) : null,
            bottom: !isTargetInTopHalf ? math.min(screenSize.height - targetRect.top + 16, screenSize.height - 240) : null,
            child: _buildCalloutCard(isTargetInTopHalf),
          ),
        ],
      ),
    );
  }

  Widget _buildCalloutCard(bool pointerPointsUp) {
    final int totalSteps = widget.steps.length;
    final bool isLastStep = _currentStepIndex == totalSteps - 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderStroke, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Step Badge + Skip button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentIndigo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_currentStep.icon, color: AppColors.indigoLight, size: 20),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.darkSlateBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderStroke),
                ),
                child: Text(
                  'Step ${_currentStepIndex + 1} of $totalSteps',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                key: const Key('feature_tour_skip_button'),
                onPressed: _handleSkip,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Skip Tour', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            _currentStep.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            _currentStep.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),

          // Action Navigation Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStepIndex > 0)
                OutlinedButton.icon(
                  key: const Key('feature_tour_back_button'),
                  onPressed: _previousStep,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.borderStroke),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                )
              else
                const SizedBox.shrink(),
              ElevatedButton.icon(
                key: const Key('feature_tour_next_button'),
                onPressed: _nextStep,
                icon: Icon(
                  isLastStep ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  isLastStep ? 'Got it!' : 'Next',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentIndigo,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter that creates the darkened backdrop with a transparent cutout
/// for the target widget and paints a subtle pulsing beacon outline.
class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({
    required this.targetRect,
    required this.borderRadius,
    required this.pulseScale,
  });

  final Rect targetRect;
  final double borderRadius;
  final double pulseScale;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect screenRect = Offset.zero & size;

    // 1. Full Screen Path
    final Path backgroundPath = Path()..addRect(screenRect);

    // 2. Punch-out Hole Path around Target
    final RRect holeRRect = RRect.fromRectAndRadius(
      targetRect,
      Radius.circular(borderRadius),
    );
    final Path holePath = Path()..addRRect(holeRRect);

    // 3. Subtract Hole from Backdrop
    final Path overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );

    final Paint overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.82)
      ..style = PaintingStyle.fill;

    canvas.drawPath(overlayPath, overlayPaint);

    // 4. Draw Animated Pulsing Beacon Ring around Target
    final double centerDx = targetRect.center.dx;
    final double centerDy = targetRect.center.dy;
    final double scaledWidth = targetRect.width * pulseScale;
    final double scaledHeight = targetRect.height * pulseScale;

    final Rect pulsedRect = Rect.fromCenter(
      center: Offset(centerDx, centerDy),
      width: scaledWidth,
      height: scaledHeight,
    );

    final Paint pulseRingPaint = Paint()
      ..color = AppColors.indigoLight.withValues(alpha: 0.6 / pulseScale)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(pulsedRect, Radius.circular(borderRadius * pulseScale)),
      pulseRingPaint,
    );

    // 5. Solid Highlight Border on the exact target
    final Paint targetBorderPaint = Paint()
      ..color = AppColors.accentIndigo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(holeRRect, targetBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.pulseScale != pulseScale;
  }
}
