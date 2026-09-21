import 'package:finance_app/core/constants/app_constants.dart';
import 'package:finance_app/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:finance_app/features/accounts/domain/models/account_model.dart';
import 'package:finance_app/features/accounts/presentation/screens/transfer_screen.dart';
import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 6: Transfer Action Flow & Double-Entry Ledger Tests', () {
    test('AccountRepositoryImpl.transferFunds executes atomic double-entry balance mutation', () async {
      final repository = AccountRepositoryImpl();
      final txnRepo = TransactionRepositoryImpl();

      final accountsBefore = await repository.getAccounts();
      final fromAccBefore = accountsBefore.firstWhere((a) => a.id == 'acc-1');
      final toAccBefore = accountsBefore.firstWhere((a) => a.id == 'acc-3');

      final double initialFromBalance = fromAccBefore.balance;
      final double initialToBalance = toAccBefore.balance;
      const double transferAmount = 1000.0;

      await repository.transferFunds(
        fromAccountId: 'acc-1',
        toAccountId: 'acc-3',
        amount: transferAmount,
        note: 'Monthly Savings Allocation',
      );

      final accountsAfter = await repository.getAccounts();
      final fromAccAfter = accountsAfter.firstWhere((a) => a.id == 'acc-1');
      final toAccAfter = accountsAfter.firstWhere((a) => a.id == 'acc-3');

      // Verify double-entry balance impact
      expect(fromAccAfter.balance, equals(initialFromBalance - transferAmount));
      expect(toAccAfter.balance, equals(initialToBalance + transferAmount));

      // Verify net worth conservation (sum of both balances remains constant)
      expect(
        fromAccAfter.balance + toAccAfter.balance,
        equals(initialFromBalance + initialToBalance),
      );

      // Verify transaction ledger log was recorded
      final transactions = await txnRepo.getTransactions();
      final loggedTransfer = transactions.firstWhere(
        (t) => t.flow == TransactionFlow.transfer && t.amount == transferAmount,
      );
      expect(loggedTransfer, isNotNull);
      expect(loggedTransfer.category, equals('Transfer'));
      expect(loggedTransfer.accountId, equals('acc-1'));
    });

    testWidgets('TransferScreen renders all input controls and swap button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransferScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('transfer_screen')), findsOneWidget);
      expect(find.byKey(const Key('transfer_from_account_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('transfer_to_account_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('transfer_swap_accounts_button')), findsOneWidget);
      expect(find.byKey(const Key('transfer_amount_field')), findsOneWidget);
      expect(find.byKey(const Key('transfer_date_picker')), findsOneWidget);
      expect(find.byKey(const Key('transfer_notes_field')), findsOneWidget);
      expect(find.byKey(const Key('transfer_submit_button')), findsOneWidget);
    });

    testWidgets('Submitting transfer form updates balances and closes screen',
        (WidgetTester tester) async {
      final repository = AccountRepositoryImpl();
      final accountsBefore = await repository.getAccounts();
      final fromBefore = accountsBefore.firstWhere((a) => a.id == 'acc-1').balance;
      final toBefore = accountsBefore.firstWhere((a) => a.id == 'acc-2').balance;

      await tester.pumpWidget(
        const MaterialApp(
          home: TransferScreen(
            initialFromAccountId: 'acc-1',
            initialToAccountId: 'acc-2',
            initialAmount: 500.0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to and tap Complete Transfer
      await tester.ensureVisible(find.byKey(const Key('transfer_submit_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('transfer_submit_button')));
      await tester.pumpAndSettle();

      // Verify double-entry balances updated
      final accountsAfter = await repository.getAccounts();
      final fromAfter = accountsAfter.firstWhere((a) => a.id == 'acc-1').balance;
      final toAfter = accountsAfter.firstWhere((a) => a.id == 'acc-2').balance;

      expect(fromAfter, equals(fromBefore - 500.0));
      expect(toAfter, equals(toBefore + 500.0));
    });

    testWidgets('DashboardScreen Fast Action "Transfer" triggers navigation to TransferScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppConstants.transferRoute: (_) => const TransferScreen(),
          },
          home: const DashboardScreen(disableTour: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Transfer'), findsOneWidget);
      await tester.tap(find.text('Transfer'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('transfer_screen')), findsOneWidget);
      expect(find.text('Transfer Funds'), findsOneWidget);
    });
  });
}
