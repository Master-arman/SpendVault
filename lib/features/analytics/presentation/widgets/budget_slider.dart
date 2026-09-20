import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom budget slider with sticky percentage ticks (25%, 50%, 75%, 100%) of user income.
class BudgetSlider extends StatefulWidget {
  const BudgetSlider({
    super.key,
    required this.budgetAmount,
    required this.userIncome,
    required this.onChanged,
    this.categoryName = 'Category Budget',
    this.categoryColor = AppColors.accentIndigo,
  });

  final double budgetAmount;
  final double userIncome;
  final ValueChanged<double> onChanged;
  final String categoryName;
  final Color categoryColor;

  @override
  State<BudgetSlider> createState() => _BudgetSliderState();
}

class _BudgetSliderState extends State<BudgetSlider> {
  static const List<double> _snapPercentages = [0.25, 0.50, 0.75, 1.00];

  double _snapValue(double rawValue) {
    if (widget.userIncome <= 0) return rawValue;

    for (final double pct in _snapPercentages) {
      final double target = widget.userIncome * pct;
      final double threshold = widget.userIncome * 0.025; // 2.5% snap magnetic window
      if ((rawValue - target).abs() <= threshold) {
        return target;
      }
    }
    return rawValue;
  }

  void _onSliderChanged(double value) {
    final double snapped = _snapValue(value);
    if (snapped != widget.budgetAmount) {
      widget.onChanged(snapped);
    }
  }

  void _snapToPercentage(double percentage) {
    HapticFeedback.selectionClick();
    widget.onChanged(widget.userIncome * percentage);
  }

  @override
  Widget build(BuildContext context) {
    final double maxBudget = widget.userIncome > 0 ? widget.userIncome : 5000.0;
    final double clampedValue = widget.budgetAmount.clamp(0.0, maxBudget);
    final double currentPercentage = maxBudget > 0 ? (clampedValue / maxBudget) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: widget.categoryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.categoryName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.categoryColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '${currentPercentage.toStringAsFixed(0)}% of Income',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.categoryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CurrencyFormatter.format(clampedValue),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Cap: ${CurrencyFormatter.format(maxBudget)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: widget.categoryColor,
              inactiveTrackColor: AppColors.borderStroke,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              overlayColor: widget.categoryColor.withValues(alpha: 0.2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              trackHeight: 6,
            ),
            child: Slider(
              value: clampedValue,
              min: 0.0,
              max: maxBudget,
              onChanged: _onSliderChanged,
            ),
          ),
          const SizedBox(height: 4),
          // Sticky Percentage Ticks (25%, 50%, 75%, 100%)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _snapPercentages.map((double pct) {
              final int pctInt = (pct * 100).toInt();
              final bool isNear = (clampedValue - (maxBudget * pct)).abs() < (maxBudget * 0.03);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _snapToPercentage(pct),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isNear
                        ? widget.categoryColor.withValues(alpha: 0.25)
                        : AppColors.surfaceCardElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isNear
                          ? widget.categoryColor
                          : AppColors.borderStroke,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$pctInt%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isNear ? FontWeight.w700 : FontWeight.w500,
                      color: isNear ? widget.categoryColor : AppColors.textMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
