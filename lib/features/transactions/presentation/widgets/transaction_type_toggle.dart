import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sliding segmented control for toggling between Expense, Income, and Transfer.
/// Uses a custom horizontal container with [Stack] and [AnimatedAlign] with a sliding pill indicator.
class TransactionTypeToggle extends StatelessWidget {
  const TransactionTypeToggle({
    super.key,
    required this.selectedType,
    required this.onChanged,
    this.height = 46,
  });

  final TransactionType selectedType;
  final ValueChanged<TransactionType> onChanged;
  final double height;

  Alignment _getAlignment(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return Alignment.centerLeft;
      case TransactionType.income:
        return Alignment.center;
      case TransactionType.transfer:
        return Alignment.centerRight;
    }
  }

  Color _getPillColor(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return AppColors.expenseRed.withValues(alpha: 0.2);
      case TransactionType.income:
        return AppColors.successGreen.withValues(alpha: 0.2);
      case TransactionType.transfer:
        return AppColors.accentIndigo.withValues(alpha: 0.25);
    }
  }

  Color _getPillBorderColor(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return AppColors.expenseRed.withValues(alpha: 0.6);
      case TransactionType.income:
        return AppColors.successGreen.withValues(alpha: 0.6);
      case TransactionType.transfer:
        return AppColors.accentIndigo.withValues(alpha: 0.7);
    }
  }

  Color _getActiveTextColor(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return const Color(0xFFFDA4AF);
      case TransactionType.income:
        return const Color(0xFF6EE7B7);
      case TransactionType.transfer:
        return AppColors.indigoLight;
    }
  }

  void _handleTap(TransactionType type) {
    if (type != selectedType) {
      HapticFeedback.selectionClick();
      onChanged(type);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderStroke,
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          // Active sliding pill indicator
          AnimatedAlign(
            alignment: _getAlignment(selectedType),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 1 / 3,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: _getPillColor(selectedType),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getPillBorderColor(selectedType),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getPillColor(selectedType).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Interactive Segment Buttons
          Row(
            children: [
              _buildSegment(
                type: TransactionType.expense,
                label: 'Expense',
                icon: Icons.arrow_upward_rounded,
              ),
              _buildSegment(
                type: TransactionType.income,
                label: 'Income',
                icon: Icons.arrow_downward_rounded,
              ),
              _buildSegment(
                type: TransactionType.transfer,
                label: 'Transfer',
                icon: Icons.swap_horiz_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required TransactionType type,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = selectedType == type;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleTap(type),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? _getActiveTextColor(type)
                    : AppColors.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? _getActiveTextColor(type)
                      : AppColors.textMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
