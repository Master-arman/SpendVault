import 'package:finance_app/core/widgets/rolling_counter.dart';
import 'package:finance_app/features/transactions/presentation/screens/dashboard_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 19: Executive Balance Dashboard Tests', () {
    testWidgets('DashboardScreen renders sticky glassmorphic Net Worth bar, mini-sparkline, and fast actions',
        (WidgetTester tester) async {
      const double initialNetWorth = 51830.35;
      const List<double> sevenDays = [45.0, 120.0, 85.0, 240.0, 110.0, 310.0, 195.0];

      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(
            initialNetWorth: initialNetWorth,
            sevenDaysSpend: sevenDays,
          ),
        ),
      );

      // Verify Slivers & Glassmorphic App Bar Net Worth
      expect(find.byType(SliverAppBar), findsOneWidget);
      expect(find.text('AGGREGATED NET WORTH'), findsOneWidget);
      expect(find.byType(RollingCounter), findsOneWidget);

      // Verify 7-Day Mini-Sparkline
      expect(find.text('7-Day Outflow Sparkline'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);

      // Verify Fast Action Carousel Items
      expect(find.text('Fast Actions'), findsOneWidget);
      expect(find.text('Add Expense'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('Split Bill'), findsOneWidget);
      expect(find.text('Scan SMS'), findsOneWidget);
      expect(find.text('Export Report'), findsOneWidget);

      // Tap on Fast Action "Add Expense"
      await tester.tap(find.text('Add Expense'));
      await tester.pumpAndSettle();

      expect(find.text('Quick Add Expense Triggered'), findsOneWidget);
    });
  });
}
