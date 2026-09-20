import 'package:finance_app/features/analytics/data/models/category_budget.dart';
import 'package:finance_app/features/analytics/presentation/widgets/budget_slider.dart';
import 'package:finance_app/features/categories/data/models/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 16: Category Budget Ledger & Dynamic Sliders Tests', () {
    test('CategoryBudget model holds schema properties and category link', () {
      final category = Category()
        ..name = 'Groceries'
        ..colorHex = 0xFF10B981;

      final budget = CategoryBudget()
        ..monthlyLimit = 15000.0
        ..month = 9
        ..year = 2026;
      budget.category.value = category;

      expect(budget.monthlyLimit, 15000.0);
      expect(budget.month, 9);
      expect(budget.year, 2026);
      expect(budget.category.value?.name, 'Groceries');
    });

    testWidgets('BudgetSlider renders sticky percentage ticks and handles snapping',
        (WidgetTester tester) async {
      double currentBudget = 1000.0;
      const double userIncome = 4000.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return BudgetSlider(
                  budgetAmount: currentBudget,
                  userIncome: userIncome,
                  categoryName: 'Dining Out',
                  onChanged: (newVal) {
                    setState(() {
                      currentBudget = newVal;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify category name and sticky ticks exist
      expect(find.text('Dining Out'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      // Tap on 50% tick (should set budget to 50% of 4000 = 2000.0)
      await tester.tap(find.text('50%'));
      await tester.pumpAndSettle();

      expect(currentBudget, 2000.0);

      // Tap on 75% tick (should set budget to 75% of 4000 = 3000.0)
      await tester.tap(find.text('75%'));
      await tester.pumpAndSettle();

      expect(currentBudget, 3000.0);
    });
  });
}
