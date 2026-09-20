import 'package:finance_app/core/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SpendingTrendChart extends StatelessWidget {
  const SpendingTrendChart({
    required this.monthlyValues,
    super.key,
  });

  final List<double> monthlyValues;

  @override
  Widget build(BuildContext context) {
    if (monthlyValues.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final List<FlSpot> spots = List.generate(
      monthlyValues.length,
      (int index) => FlSpot(index.toDouble(), monthlyValues[index]),
    );

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStroke),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 500,
            getDrawingHorizontalLine: (double value) {
              return const FlLine(
                color: Color(0x1F24304F),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: 1000,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    '\$${(value / 1000).toStringAsFixed(0)}k',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  const List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];
                  final int idx = value.toInt();
                  if (idx >= 0 && idx < months.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        months[idx],
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
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
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.accentIndigo,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.accentIndigo.withValues(alpha: 0.35),
                    AppColors.accentIndigo.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
