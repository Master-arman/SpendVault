import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/utils/currency_formatter.dart';
import 'package:flutter/material.dart';

/// Pulsating alert card for budgets nearing or exceeding thresholds.
/// Uses a repeating reversed [AnimationController] and dynamic [BoxShadow] glow.
class BudgetAlertCard extends StatefulWidget {
  const BudgetAlertCard({
    super.key,
    required this.categoryName,
    required this.spentAmount,
    required this.budgetLimit,
    this.onTap,
  });

  final String categoryName;
  final double spentAmount;
  final double budgetLimit;
  final VoidCallback? onTap;

  bool get isOverBudget => spentAmount >= budgetLimit;
  double get percentage => budgetLimit > 0 ? (spentAmount / budgetLimit) * 100 : 0.0;

  @override
  State<BudgetAlertCard> createState() => _BudgetAlertCardState();
}

class _BudgetAlertCardState extends State<BudgetAlertCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _anim = Tween<double>(begin: 0.15, end: 0.55).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isOverBudget || widget.percentage >= 90.0) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BudgetAlertCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOverBudget || widget.percentage >= 90.0) {
      if (!_animationController.isAnimating) {
        _animationController.repeat(reverse: true);
      }
    } else {
      if (_animationController.isAnimating) {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isOver = widget.isOverBudget;
    final Color alertColor = isOver ? AppColors.expenseRed : AppColors.warningAmber;

    return AnimatedBuilder(
      animation: _anim,
      builder: (BuildContext context, Widget? child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: alertColor.withValues(alpha: isOver ? _anim.value + 0.2 : 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: alertColor.withValues(alpha: _anim.value),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onTap,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: alertColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOver ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                      color: alertColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.categoryName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${widget.percentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: alertColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOver
                              ? 'Exceeded budget limit by ${CurrencyFormatter.format(widget.spentAmount - widget.budgetLimit)}'
                              : 'Approaching monthly budget threshold',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOver ? const Color(0xFFFDA4AF) : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
