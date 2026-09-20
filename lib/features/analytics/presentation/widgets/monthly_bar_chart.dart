import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/utils/currency_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Interactive Monthly Bar Chart (1..31 Days) with daily average threshold background rod
/// and 1.05x rod scale expansion on touch.
class MonthlyBarChart extends StatefulWidget {
  const MonthlyBarChart({
    super.key,
    required this.dailyExpenses,
    required this.dailyAverageThreshold,
    this.daysInMonth = 31,
    this.height = 240,
  });

  final Map<int, double> dailyExpenses;
  final double dailyAverageThreshold;
  final int daysInMonth;
  final double height;

  @override
  State<MonthlyBarChart> createState() => _MonthlyBarChartState();
}

class _MonthlyBarChartState extends State<MonthlyBarChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final double maxExpense = widget.dailyExpenses.values.fold(
      0.0,
      (double max, double val) => val > max ? val : max,
    );
    final double maxY = ((maxExpense > widget.dailyAverageThreshold ? maxExpense : widget.dailyAverageThreshold) * 1.25)
        .clamp(100.0, double.infinity);

    return Container(
      height: widget.height,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStroke),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceBetween,
          barTouchData: BarTouchData(
            enabled: true,
            touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
              if (response == null || response.spot == null || !event.isInterestedForInteractions) {
                if (_touchedIndex != null) {
                  setState(() {
                    _touchedIndex = null;
                  });
                }
                return;
              }
              setState(() {
                _touchedIndex = response.spot!.touchedBarGroupIndex;
              });
            },
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceCardElevated,
              tooltipBorder: BorderSide(
                color: AppColors.accentIndigo.withValues(alpha: 0.8),
                width: 1.2,
              ),
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              getTooltipItem: (
                BarChartGroupData group,
                int groupIndex,
                BarChartRodData rod,
                int rodIndex,
              ) {
                final int day = group.x;
                final double amount = rod.toY;
                return BarTooltipItem(
                  'Day $day\n',
                  const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: CurrencyFormatter.format(amount),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? (maxY / 4) : 100,
            getDrawingHorizontalLine: (double value) => const FlLine(
              color: Color(0x1F24304F),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                interval: maxY > 0 ? (maxY / 3) : 100,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value <= 0) return const SizedBox.shrink();
                  return Text(
                    CurrencyFormatter.formatCompact(value),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final int day = value.toInt();
                  if (day == 1 || day == 7 || day == 14 || day == 21 || day == 28 || day == widget.daysInMonth) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        '$day',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(widget.daysInMonth, (int index) {
            final int day = index + 1;
            final double value = widget.dailyExpenses[day] ?? 0.0;
            final bool isTouched = _touchedIndex == index;
            const double baseWidth = 12.0;
            final double rodWidth = isTouched ? (baseWidth * 1.05) : baseWidth;

            return BarChartGroupData(
              x: day,
              barRods: [
                BarChartRodData(
                  toY: value,
                  width: rodWidth,
                  borderRadius: BorderRadius.circular(6),
                  color: isTouched ? AppColors.indigoLight : AppColors.accentIndigo,
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: widget.dailyAverageThreshold,
                    color: const Color(0x2894A3B8), // Grey tone representing daily average threshold
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
