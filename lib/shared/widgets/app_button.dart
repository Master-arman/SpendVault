import 'package:finance_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  danger,
}

/// Standardized modular button component with variants, loading state,
/// icon placement, and built-in haptic feedback.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.isFullWidth = true,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    this.borderRadius = 14.0,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final bool isFullWidth;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide? border;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = AppColors.accentIndigo;
        fg = Colors.white;
        break;
      case AppButtonVariant.secondary:
        bg = isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9);
        fg = theme.colorScheme.onSurface;
        break;
      case AppButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.accentIndigo;
        border = const BorderSide(color: AppColors.accentIndigo, width: 1.2);
        break;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = theme.colorScheme.onSurface;
        break;
      case AppButtonVariant.danger:
        bg = AppColors.expenseRed;
        fg = Colors.white;
        break;
    }

    final buttonChild = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fg,
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ],
    );

    final effectiveOnPressed = (isDisabled || isLoading || onPressed == null)
        ? null
        : () {
            HapticFeedback.lightImpact();
            onPressed!();
          };

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: effectiveOnPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          padding: padding,
          side: border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: buttonChild,
      ),
    );
  }
}
