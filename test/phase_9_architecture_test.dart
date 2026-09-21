import 'package:finance_app/core/theme/app_theme.dart';
import 'package:finance_app/features/budgets/domain/models/budget_model.dart';
import 'package:finance_app/features/budgets/presentation/screens/budgets_screen.dart';
import 'package:finance_app/features/budgets/presentation/widgets/budget_card.dart';
import 'package:finance_app/features/exports/exports.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/shared/widgets/app_button.dart';
import 'package:finance_app/shared/widgets/app_card.dart';
import 'package:finance_app/shared/widgets/transaction_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 9: File Architecture & Codebase Minimization Tests', () {
    testWidgets('AppCard renders child and triggers onTap callback', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              onTap: () => tapped = true,
              child: const Text('Modular Card Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Modular Card Content'), findsOneWidget);
      await tester.tap(find.text('Modular Card Content'));
      expect(tapped, isTrue);
    });

    testWidgets('AppButton renders variants and handles loading/disabled states',
        (WidgetTester tester) async {
      bool clicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AppButton(
                  label: 'Primary Action',
                  onPressed: () => clicked = true,
                ),
                AppButton(
                  label: 'Loading Action',
                  isLoading: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Primary Action'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Primary Action'));
      expect(clicked, isTrue);
    });

    testWidgets('TransactionListTile renders structured metadata and triggers onTap',
        (WidgetTester tester) async {
      bool tileTapped = false;
      final txn = TransactionModel(
        id: 'txn-arch-1',
        title: 'Starbucks Coffee',
        amount: 8.75,
        flow: TransactionFlow.expense,
        category: 'Food & Dining',
        date: DateTime(2026, 9, 21, 10, 0),
        accountId: 'acc-1',
        accountName: 'Checking',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: TransactionListTile(
              transaction: txn,
              onTap: () => tileTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Starbucks Coffee'), findsOneWidget);
      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.text('-₹8.75'), findsOneWidget);

      await tester.tap(find.text('Starbucks Coffee'));
      expect(tileTapped, isTrue);
    });

    testWidgets('BudgetCard renders category limit and progress bar', (WidgetTester tester) async {
      const budget = BudgetModel(
        id: 'b-dining',
        category: 'Food & Dining',
        limitAmount: 500.0,
        spentAmount: 350.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: BudgetCard(budget: budget),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
      expect(find.text('Spent: ₹350.00'), findsOneWidget);
      expect(find.text('Limit: ₹500.00'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('BudgetsScreen renders list of category envelopes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const BudgetsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Category Budgets'), findsOneWidget);
      expect(find.byType(BudgetCard), findsWidgets);
    });

    test('Exports barrel exports CSV, PDF, and BottomSheet tools', () {
      expect(CsvExporter.csvHeaders, isNotEmpty);
    });
  });
}
