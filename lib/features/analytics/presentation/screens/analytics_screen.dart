import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/features/analytics/presentation/widgets/spending_trend_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const List<double> monthlyTrend = [1200, 1850, 1400, 2200, 1950, 2400, 2100];

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
