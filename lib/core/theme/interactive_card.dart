import 'package:finance_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// A micro-interactive card widget that combines [MouseRegion] and [GestureDetector]
/// to handle smooth hover elevations, border highlights, and tactile spring/press scaling.
class InteractiveCard extends StatefulWidget {
  const InteractiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.gradient,
    this.border,
    this.hoverBorder,
    this.boxShadow,
    this.hoverBoxShadow,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
    this.duration = const Duration(milliseconds: 140),
    this.curve = Curves.easeOutCubic,
    this.enableHover = true,
  });

  /// The child widget placed inside the card.
  final Widget child;

  /// Callback triggered when the card is tapped.
  final VoidCallback? onTap;

  /// Callback triggered when the card is long-pressed.
  final VoidCallback? onLongPress;

  /// Callback triggered when the card is double-tapped.
  final VoidCallback? onDoubleTap;

  /// Internal padding for the card content.
  final EdgeInsetsGeometry? padding;

  /// Outer margin surrounding the card.
  final EdgeInsetsGeometry? margin;

  /// Border radius of the card container.
  final BorderRadius? borderRadius;

  /// Background fill color when no gradient is provided.
  final Color? backgroundColor;

  /// Optional background gradient decoration.
  final Gradient? gradient;

  /// Default border for the card.
  final BoxBorder? border;

  /// Custom border used during hover state.
  final BoxBorder? hoverBorder;

  /// Default shadow for the card.
  final List<BoxShadow>? boxShadow;

  /// Custom shadow used during hover state.
  final List<BoxShadow>? hoverBoxShadow;

  /// Explicit width of the card.
  final double? width;

  /// Explicit height of the card.
  final double? height;

  /// Clip behavior applied to the card container.
  final Clip clipBehavior;

  /// Duration of scale and decoration transitions.
  final Duration duration;

  /// Easing curve of scale and decoration transitions.
  final Curve curve;

  /// Whether hover animations and pointer detection are active.
  final bool enableHover;

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  double get _targetScale {
    if (_isPressed) {
      return 0.98;
    }
    if (_isHovered && widget.enableHover) {
      return 1.015;
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultBg = theme.cardTheme.color ?? (isDark ? AppColors.darkCard : AppColors.lightCard);
    final defaultBorder = theme.colorScheme.outline;

    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final effectiveBackground = widget.backgroundColor ?? defaultBg;

    final effectiveBorder = _isHovered && widget.enableHover
        ? widget.hoverBorder ??
            Border.all(
              color: AppColors.primary.withValues(alpha: 0.5),
              width: 1.0,
            )
        : widget.border ??
            Border.all(
              color: defaultBorder,
              width: 1.0,
            );

    final effectiveShadow = _isHovered && widget.enableHover
        ? widget.hoverBoxShadow ??
            [
              BoxShadow(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
        : widget.boxShadow ??
            (isDark
                ? const <BoxShadow>[]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]);

    return MouseRegion(
      cursor: widget.onTap != null || widget.onLongPress != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: widget.enableHover ? (_) => setState(() => _isHovered = true) : null,
      onExit: widget.enableHover ? (_) => setState(() => _isHovered = false) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onDoubleTap: widget.onDoubleTap,
        child: AnimatedScale(
          scale: _targetScale,
          duration: widget.duration,
          curve: widget.curve,
          child: AnimatedContainer(
            duration: widget.duration,
            curve: widget.curve,
            width: widget.width,
            height: widget.height,
            margin: widget.margin,
            padding: widget.padding,
            clipBehavior: widget.clipBehavior,
            decoration: BoxDecoration(
              color: widget.gradient == null ? effectiveBackground : null,
              gradient: widget.gradient,
              borderRadius: effectiveRadius,
              border: effectiveBorder,
              boxShadow: effectiveShadow,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
