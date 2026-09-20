import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/utils/currency_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Item representing a category slice in the interactive pie chart.
class CategoryPieItem {
  const CategoryPieItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.color,
  });

  final String id;
  final String name;
  final double amount;
  final Color color;
}

/// Interactive Donut Pie Chart for Category Breakdown.
/// Features:
/// - [centerSpaceRadius: 46] and [sectionsSpace: 3]
/// - Smooth slice expansion from radius 40 to 52 on tap
/// - Center hole with AnimatedSwitcher showing category name and total sum
class CategoryPieChart extends StatefulWidget {
  const CategoryPieChart({
    super.key,
    required this.categories,
    this.onCategorySelected,
    this.height = 280,
  });

  final List<CategoryPieItem> categories;
  final ValueChanged<CategoryPieItem>? onCategorySelected;
  final double height;

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  double get _totalAmount =>
      widget.categories.fold(0.0, (double sum, CategoryPieItem item) => sum + item.amount);

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return Container(
        height: widget.height,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderStroke),
        ),
        child: const Center(
          child: Text(
            'No category breakdown data',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final CategoryPieItem? selectedCategory = (_touchedIndex >= 0 && _touchedIndex < widget.categories.length)
        ? widget.categories[_touchedIndex]
        : null;

    final String centerTitle = selectedCategory?.name ?? 'Total Spend';
    final double centerAmount = selectedCategory?.amount ?? _totalAmount;

    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStroke),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              centerSpaceRadius: 46,
              sectionsSpace: 3,
              pieTouchData: PieTouchData(
                enabled: true,
                touchCallback: (FlTouchEvent event, PieTouchResponse? response) {
                  if (!event.isInterestedForInteractions ||
                      response == null ||
                      response.touchedSection == null) {
                    return;
                  }
                  final int index = response.touchedSection!.touchedSectionIndex;
                  if (index >= 0 && index < widget.categories.length) {
                    if (_touchedIndex != index) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _touchedIndex = index;
                      });
                      widget.onCategorySelected?.call(widget.categories[index]);
                    }
                  }
                },
              ),
              borderData: FlBorderData(show: false),
              sections: List.generate(widget.categories.length, (int index) {
                final CategoryPieItem item = widget.categories[index];
                final bool isTouched = index == _touchedIndex;
                final double radius = isTouched ? 52.0 : 40.0;
                final double percentage = _totalAmount > 0 ? (item.amount / _totalAmount) * 100 : 0.0;

                return PieChartSectionData(
                  color: item.color,
                  value: item.amount,
                  title: isTouched ? '${percentage.toStringAsFixed(0)}%' : '',
                  radius: radius,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  badgeWidget: isTouched
                      ? Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCardElevated,
                            shape: BoxShape.circle,
                            border: Border.all(color: item.color, width: 1.5),
                          ),
                          child: Icon(Icons.touch_app_rounded, size: 10, color: item.color),
                        )
                      : null,
                  badgePositionPercentageOffset: 1.15,
                );
              }),
            ),
          ),
          // Center Hole Display with Animated Text Switcher
          IgnorePointer(
            child: SizedBox(
              width: 84,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  key: ValueKey<String>('$centerTitle-$centerAmount'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      centerTitle.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatCompact(centerAmount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
