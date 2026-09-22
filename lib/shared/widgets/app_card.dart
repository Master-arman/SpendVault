import 'package:finance_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Standardized modular card component used across the application.
/// Encapsulates responsive background colors, border radius, customizable padding,
/// subtle border strokes, elevation, and tactile InkRipple tap interactions.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.onTap,
    this.elevation = 0,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final double elevation;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveRadius = borderRadius ?? BorderRadius.circular(16);
    final effectiveBg = backgroundColor ??
        (isDark ? AppColors.darkCard : AppColors.lightCard);
    final effectiveBorder = borderColor ??
        (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    final cardShape = RoundedRectangleBorder(
      borderRadius: effectiveRadius,
      side: BorderSide(color: effectiveBorder, width: borderWidth),
    );

    if (onTap != null) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: effectiveRadius,
          boxShadow: elevation > 0
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: elevation * 4,
                    offset: Offset(0, elevation * 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: effectiveBg,
          shape: cardShape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            splashFactory: InkRipple.splashFactory,
            onTap: onTap,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: effectiveRadius,
        border: Border.all(color: effectiveBorder, width: borderWidth),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation * 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
