import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/features/analytics/presentation/widgets/monthly_bar_chart.dart';
import 'package:finance_app/features/analytics/presentation/widgets/spending_trend_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const List<double> monthlyTrend = [1200, 1850, 1400, 2200, 1950, 2400, 2100];
    const Map<int, double> dailyExpenses = {
      1: 150.0,
      3: 840.0,
      5: 320.0,
      8: 1200.0,
      12: 450.0,
      15: 1600.0,
      18: 300.0,
      22: 950.0,
      25: 680.0,
      28: 1400.0,
      30: 520.0,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Spend & Average Threshold',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const MonthlyBarChart(
              dailyExpenses: dailyExpenses,
              dailyAverageThreshold: 620.0,
              daysInMonth: 30,
            ),
            const SizedBox(height: 24),
            const Text(
              'Cashflow Trend',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const SpendingTrendChart(monthlyValues: monthlyTrend),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderStroke),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Inflow', style: TextStyle(color: AppColors.textSecondary)),
                      Text('\$6,850.00', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.successGreen)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Outflow', style: TextStyle(color: AppColors.textSecondary)),
                      Text('\$4,120.00', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.expenseRed)),
                    ],
                  ),
                  Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Net Savings', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      Text('+\$2,730.00', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.indigoLight)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
