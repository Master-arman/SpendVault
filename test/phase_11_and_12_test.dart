import 'package:finance_app/features/analytics/domain/analytics_aggregator.dart';
import 'package:finance_app/features/analytics/presentation/widgets/monthly_bar_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 11: Background Aggregation Pipeline Tests', () {
    test('AnalyticsAggregator correctly aggregates monthly transactions and daily totals', () async {
      const aggregator = AnalyticsAggregator();
      final transactions = [
        TransactionData(
          amount: 500.0,
          isExpense: true,
          timestamp: DateTime(2026, 9, 2),
          category: 'Groceries',
        ),
        TransactionData(
          amount: 1500.0,
          isExpense: true,
          timestamp: DateTime(2026, 9, 2),
          category: 'Dining',
        ),
        TransactionData(
          amount: 80000.0,
          isExpense: false,
          timestamp: DateTime(2026, 9, 1),
          category: 'Salary',
        ),
        TransactionData(
          amount: 3000.0,
          isExpense: true,
          timestamp: DateTime(2026, 9, 15),
          category: 'Shopping',
        ),
      ];

      final result = aggregator.aggregateMonthlySync(
        transactions: transactions,
        year: 2026,
        month: 9,
      );

      expect(result.totalExpense, 5000.0);
      expect(result.totalIncome, 80000.0);
      expect(result.netSavings, 75000.0);
      expect(result.dailyExpenses[2], 2000.0);
      expect(result.dailyExpenses[15], 3000.0);
      expect(result.dailyIncomes[1], 80000.0);
      expect(result.dailyAverageExpense, closeTo(5000.0 / 30, 0.01));
      expect(result.categoryDistribution['Groceries'], 500.0);
      expect(result.categoryDistribution['Dining'], 1500.0);
    });
  });

  group('Phase 12: Monthly Multi-Rod Bar Chart Tests', () {
    testWidgets('MonthlyBarChart renders BarChart with 31 days and threshold background rod',
        (WidgetTester tester) async {
      final dailyExpenses = <int, double>{
        1: 200.0,
        2: 1500.0,
        5: 450.0,
        15: 3200.0,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthlyBarChart(
              dailyExpenses: dailyExpenses,
              dailyAverageThreshold: 650.0,
              daysInMonth: 31,
            ),
          ),
        ),
      );

      expect(find.byType(BarChart), findsOneWidget);

      final barChartWidget = tester.widget<BarChart>(find.byType(BarChart));
      expect(barChartWidget.data.barGroups.length, 31);

      // Verify rod radius and background threshold rod
      final firstGroup = barChartWidget.data.barGroups.first;
      expect(firstGroup.x, 1);
      expect(firstGroup.barRods.first.borderRadius, BorderRadius.circular(6));
      expect(firstGroup.barRods.first.backDrawRodData.show, isTrue);
      expect(firstGroup.barRods.first.backDrawRodData.toY, 650.0);

      // Verify touch data
      expect(barChartWidget.data.barTouchData.enabled, isTrue);
    });
  });
}
