import 'package:finance_app/core/theme/app_theme.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:finance_app/features/transactions/presentation/widgets/transaction_detail_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';

void main() {
  group('Phase 4: Transaction Detail Modal & History Action Tests', () {
    testWidgets('Tapping a transaction tile opens bottom sheet with receipt metrics & actions',
        (WidgetTester tester) async {
      await TransactionRepositoryImpl().addTransaction(
        TransactionModel(
          id: 'txn-salary',
          title: 'Salary Deposit',
          amount: 75000.0,
          flow: TransactionFlow.income,
          category: 'Income',
          date: DateTime.now(),
          accountId: 'acc-1',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const TransactionsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find Salary Deposit tile
      final salaryTile = find.text('Salary Deposit');
      expect(salaryTile, findsOneWidget);

      // Tap on Salary Deposit
      await tester.tap(salaryTile);
      await tester.pumpAndSettle();

      // Verify TransactionDetailModal bottom sheet is opened
      expect(find.byType(TransactionDetailModal), findsOneWidget);
      expect(find.text('Receipt / Ref ID'), findsOneWidget);
      expect(find.text('Account Used'), findsOneWidget);
      expect(find.text('Timestamp'), findsOneWidget);
      expect(find.byKey(const Key('button_edit_transaction')), findsOneWidget);
      expect(find.byKey(const Key('button_delete_transaction')), findsOneWidget);
    });

    testWidgets('TransactionDetailModal displays receipt metadata and handles delete callback',
        (WidgetTester tester) async {
      bool deleted = false;

      final txn = TransactionModel(
        id: 'txn-whole-foods',
        title: 'Whole Foods Market',
        amount: 84.50,
        flow: TransactionFlow.expense,
        category: 'Food & Dining',
        date: DateTime(2026, 9, 21, 14, 30),
        accountId: 'acc-checking',
        accountName: 'Chase Premier Checking',
        merchant: 'Whole Foods Market',
        referenceNumber: 'REC-982341',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  TransactionDetailModal.show(
                    context: context,
                    transaction: txn,
                    onDelete: () {
                      deleted = true;
                    },
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // Open Modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Whole Foods Market'), findsWidgets);
      expect(find.text('Chase Premier Checking'), findsOneWidget);
      expect(find.text('REC-982341'), findsOneWidget);

      // Tap delete button
      await tester.tap(find.byKey(const Key('button_delete_transaction')));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });
  });
}
