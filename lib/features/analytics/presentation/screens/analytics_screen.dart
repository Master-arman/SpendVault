import 'package:finance_app/core/constants/app_constants.dart';
import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/theme/theme_toggle_button.dart';
import 'package:finance_app/features/analytics/presentation/controllers/timespan_controller.dart';
import 'package:finance_app/features/analytics/presentation/widgets/category_pie_chart.dart';
import 'package:finance_app/features/analytics/presentation/widgets/monthly_bar_chart.dart';
import 'package:finance_app/features/analytics/presentation/widgets/spending_trend_chart.dart';
import 'package:flutter/material.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  TimespanScope _scope = TimespanScope.monthly;

  static const List<CategoryPieItem> _categoryBreakdown = [
    CategoryPieItem(id: 'cat-food', name: 'Food & Dining', amount: 1850.0, color: Color(0xFFF59E0B)),
    CategoryPieItem(id: 'cat-shopping', name: 'Shopping', amount: 1240.0, color: Color(0xFF6366F1)),
    CategoryPieItem(id: 'cat-bills', name: 'Bills & Utilities', amount: 980.0, color: Color(0xFFEF4444)),
    CategoryPieItem(id: 'cat-transport', name: 'Transport', amount: 620.0, color: Color(0xFF10B981)),
    CategoryPieItem(id: 'cat-entertainment', name: 'Entertainment', amount: 430.0, color: Color(0xFFEC4899)),
  ];

  static const List<double> _monthlyTrend = [1200, 1850, 1400, 2200, 1950, 2400, 2100];
  static const Map<int, double> _dailyExpenses = {
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

  void _onDrillDownToLedger(CategoryPieItem category) {
    final range = TimespanRange.fromScope(_scope);
    Navigator.of(context).pushNamed(
      AppConstants.filteredTransactionsRoute,
      arguments: {
        'categoryId': category.id,
        'categoryName': category.name,
        'startDate': range.start,
        'endDate': range.end,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Spending Analytics',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TimespanScopeSelector(
              selectedScope: _scope,
              onScopeChanged: (newScope) {
                setState(() {
                  _scope = newScope;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Category Breakdown (Donut Engine)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            InterpolatedChartContainer(
              height: 280,
              child: CategoryPieChart(
                categories: _categoryBreakdown,
                onCategorySelected: _onDrillDownToLedger,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Daily Spend & Average Threshold',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const InterpolatedChartContainer(
              height: 240,
              child: MonthlyBarChart(
                dailyExpenses: _dailyExpenses,
                dailyAverageThreshold: 620.0,
                daysInMonth: 30,
              ),
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
            const InterpolatedChartContainer(
              height: 220,
              child: SpendingTrendChart(monthlyValues: _monthlyTrend),
            ),
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
                    'Summary Metrics',
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
                      Text('₹6,850.00', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.successGreen)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Outflow', style: TextStyle(color: AppColors.textSecondary)),
                      Text('₹5,120.00', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.expenseRed)),
                    ],
                  ),
                  Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Net Savings', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      Text('+₹1,730.00', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.indigoLight)),
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

