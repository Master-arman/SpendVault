import 'package:finance_app/core/theme/shared_axis_route.dart';
import 'package:finance_app/features/analytics/presentation/controllers/timespan_controller.dart';
import 'package:finance_app/features/analytics/presentation/widgets/category_pie_chart.dart';
import 'package:finance_app/features/transactions/presentation/screens/filtered_transactions_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 13: Interactive Donut Pie Chart Tests', () {
    testWidgets('CategoryPieChart renders with centerSpaceRadius 46, sectionsSpace 3, and center visuals',
        (WidgetTester tester) async {
      const categories = [
        CategoryPieItem(id: '1', name: 'Food', amount: 1500.0, color: Colors.orange),
        CategoryPieItem(id: '2', name: 'Transport', amount: 500.0, color: Colors.blue),
      ];

      CategoryPieItem? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryPieChart(
              categories: categories,
              onCategorySelected: (item) => selected = item,
            ),
          ),
        ),
      );

      expect(find.byType(PieChart), findsOneWidget);
      final pieChart = tester.widget<PieChart>(find.byType(PieChart));
      expect(pieChart.data.centerSpaceRadius, 46);
      expect(pieChart.data.sectionsSpace, 3);
      expect(pieChart.data.sections.length, 2);
      expect(pieChart.data.sections.first.radius, 40.0);

      // Verify Center hole AnimatedSwitcher is present
      expect(find.byType(AnimatedSwitcher), findsOneWidget);
      expect(find.text('TOTAL SPEND'), findsOneWidget);
      expect(selected, isNull);
    });
  });

  group('Phase 14: Chart-to-Ledger Drill-Down Routing Tests', () {
    testWidgets('FilteredTransactionsScreen displays scope and handles category filtering',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FilteredTransactionsScreen(
            categoryId: 'cat-food',
            categoryName: 'Food & Dining',
            startDate: DateTime(2026, 9, 1),
            endDate: DateTime(2026, 9, 30),
          ),
        ),
      );

      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.textContaining('Sep 1 - Sep 30'), findsOneWidget);
    });

    test('SharedAxisPageRoute creates page route with custom transitions', () {
      final route = SharedAxisPageRoute<void>(
        page: const Text('Target Page'),
      );
      expect(route.transitionDuration, const Duration(milliseconds: 320));
      expect(route.reverseTransitionDuration, const Duration(milliseconds: 260));
    });
  });

  group('Phase 15: Temporal Scope Aggregators (Weekly, Monthly, Yearly)', () {
    test('Weekly scope correctly resolves Monday 00:00:00 to Sunday 23:59:59', () {
      // Wednesday Sep 16, 2026
      final refDate = DateTime(2026, 9, 16, 14, 30);
      final weeklyRange = TimespanRange.weekly(refDate);

      // Monday was Sep 14
      expect(weeklyRange.start.year, 2026);
      expect(weeklyRange.start.month, 9);
      expect(weeklyRange.start.day, 14);
      expect(weeklyRange.start.hour, 0);
      expect(weeklyRange.start.minute, 0);
      expect(weeklyRange.start.second, 0);

      // Sunday was Sep 20
      expect(weeklyRange.end.year, 2026);
      expect(weeklyRange.end.month, 9);
      expect(weeklyRange.end.day, 20);
      expect(weeklyRange.end.hour, 23);
      expect(weeklyRange.end.minute, 59);
      expect(weeklyRange.end.second, 59);
    });

    test('Monthly scope correctly resolves Day 1 to End-of-Month', () {
      final refDate = DateTime(2026, 2, 10);
      final monthlyRange = TimespanRange.monthly(refDate);

      expect(monthlyRange.start, DateTime(2026, 2, 1, 0, 0, 0, 0));
      expect(monthlyRange.end.year, 2026);
      expect(monthlyRange.end.month, 2);
      expect(monthlyRange.end.day, 28);
      expect(monthlyRange.end.hour, 23);
      expect(monthlyRange.end.minute, 59);
    });

    test('Yearly scope correctly resolves Jan 1 to Dec 31', () {
      final refDate = DateTime(2026, 7, 24);
      final yearlyRange = TimespanRange.yearly(refDate);

      expect(yearlyRange.start, DateTime(2026, 1, 1, 0, 0, 0, 0));
      expect(yearlyRange.end.year, 2026);
      expect(yearlyRange.end.month, 12);
      expect(yearlyRange.end.day, 31);
      expect(yearlyRange.end.hour, 23);
      expect(yearlyRange.end.minute, 59);
    });

    testWidgets('InterpolatedChartContainer renders child with smooth Tween height vector',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InterpolatedChartContainer(
              height: 250,
              child: Text('Chart Content'),
            ),
          ),
        ),
      );

      expect(find.text('Chart Content'), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
