import 'package:finance_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Standardized modular Empty State widget with illustration icon,
/// strict typography hierarchy, and optional CTA button.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.inbox_outlined,
    this.iconColor,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
  });

  /// Factory preset for empty transactions list.
  factory EmptyStateView.transactions({
    VoidCallback? onAddTransaction,
    String? customMessage,
  }) {
    return EmptyStateView(
      title: 'No Transactions Yet',
      description: customMessage ??
          'Start logging your expenses, transfers, or incoming income to track your net worth in real time.',
      icon: Icons.receipt_long_outlined,
      iconColor: AppColors.primary,
      actionLabel: onAddTransaction != null ? 'Add First Expense' : null,
      onAction: onAddTransaction,
    );
  }

  /// Factory preset for empty search results.
  factory EmptyStateView.search({
    String? query,
    VoidCallback? onClear,
  }) {
    return EmptyStateView(
      title: 'No Results Found',
      description: query != null && query.isNotEmpty
          ? 'No transactions or records matched "$query". Try searching for a different keyword or category.'
          : 'Type in a merchant name, category, or note to search across your financial history.',
      icon: Icons.search_off_rounded,
      iconColor: AppColors.accentViolet,
      actionLabel: onClear != null ? 'Clear Search' : null,
      onAction: onClear,
    );
  }

  /// Factory preset for filtered lists.
  factory EmptyStateView.filtered({
    VoidCallback? onResetFilter,
  }) {
    return EmptyStateView(
      title: 'No Matching Transactions',
      description:
          'No activity matches your active filter criteria. Try adjusting date ranges, categories, or account selections.',
      icon: Icons.filter_alt_off_rounded,
      iconColor: AppColors.warningAmber,
      actionLabel: onResetFilter != null ? 'Reset Filters' : null,
      onAction: onResetFilter,
    );
  }

  final String title;
  final String description;
  final IconData icon;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveColor = iconColor ?? theme.colorScheme.primary;

    return Center(
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating glowing badge
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: effectiveColor.withValues(alpha: isDark ? 0.12 : 0.08),
                border: Border.all(
                  color: effectiveColor.withValues(alpha: isDark ? 0.25 : 0.18),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: effectiveColor.withValues(alpha: isDark ? 0.15 : 0.06),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 32,
                color: effectiveColor,
              ),
            ),
            const SizedBox(height: 20),

            // Section Title: 16sp / 18sp Semi-Bold
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),

            // Body: 14sp Regular Muted
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13.5,
                  height: 1.45,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),

            // Optional CTA Action
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  splashFactory: InkRipple.splashFactory,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
