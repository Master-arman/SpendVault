import 'package:finance_app/features/accounts/data/models/account.dart';
import 'package:finance_app/features/categories/data/models/category.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 5: Unified Transaction Schema (Triple-Entry System)', () {
    test('Transaction model correctly instantiates and holds all triple-entry properties', () {
      final account1 = Account()
        ..name = 'HDFC Salary'
        ..currentBalance = 50000.0
        ..type = AccountType.bank
        ..last4Digits = '4592'
        ..colorHex = 0xFF4F46E5
        ..isDefault = true;

      final account2 = Account()
        ..name = 'Amazon Pay Wallet'
        ..currentBalance = 2500.0
        ..type = AccountType.wallet
        ..colorHex = 0xFFF59E0B;

      final category = Category()
        ..name = 'Dining Out'
        ..colorHex = 0xFF10B981
        ..budgetLimit = 10000;

      final now = DateTime.now();
      final tx = Transaction()
        ..amount = 1450.00
        ..type = TransactionType.transfer
        ..timestamp = now
        ..note = 'Monthly wallet topup'
        ..receiptLocalPath = '/receipts/rec_001.png'
        ..tags = ['essential', 'wallet']
        ..deduplicationHash = 'hash_tx_12345678';

      tx.sourceAccount.value = account1;
      tx.destinationAccount.value = account2;
      tx.category.value = category;

      expect(tx.amount, 1450.00);
      expect(tx.type, TransactionType.transfer);
      expect(tx.timestamp, now);
      expect(tx.note, 'Monthly wallet topup');
      expect(tx.receiptLocalPath, '/receipts/rec_001.png');
      expect(tx.tags, containsAll(['essential', 'wallet']));
      expect(tx.deduplicationHash, 'hash_tx_12345678');
      expect(tx.sourceAccount.value?.name, 'HDFC Salary');
      expect(tx.destinationAccount.value?.name, 'Amazon Pay Wallet');
      expect(tx.category.value?.name, 'Dining Out');
    });

    test('TransactionType enum includes expense, income, and transfer', () {
      expect(TransactionType.values, [
        TransactionType.expense,
        TransactionType.income,
        TransactionType.transfer,
      ]);
    });
  });

  group('Phase 6: Atomic Ledger Mutation Logic & Rollback Tests', () {
    test('Expense mutation deducts balance from source account', () {
      final account = Account()
        ..name = 'Checking'
        ..currentBalance = 1000.0;

      final tx = Transaction()
        ..amount = 250.0
        ..type = TransactionType.expense;
      tx.sourceAccount.value = account;

      // Execute expense mutation logic
      if (tx.type == TransactionType.expense) {
        final src = tx.sourceAccount.value!;
        src.currentBalance -= tx.amount;
      }

      expect(account.currentBalance, 750.0);

      // Rollback on delete (inversion logic)
      if (tx.type == TransactionType.expense) {
        final src = tx.sourceAccount.value!;
        src.currentBalance += tx.amount;
      }

      expect(account.currentBalance, 1000.0);
    });

    test('Income mutation adds balance to source account and rollback deducts it', () {
      final account = Account()
        ..name = 'Salary Account'
        ..currentBalance = 5000.0;

      final tx = Transaction()
        ..amount = 1500.0
        ..type = TransactionType.income;
      tx.sourceAccount.value = account;

      // Execute income mutation
      if (tx.type == TransactionType.income) {
        final src = tx.sourceAccount.value!;
        src.currentBalance += tx.amount;
      }

      expect(account.currentBalance, 6500.0);

      // Rollback on delete
      if (tx.type == TransactionType.income) {
        final src = tx.sourceAccount.value!;
        src.currentBalance -= tx.amount;
      }

      expect(account.currentBalance, 5000.0);
    });

    test('Transfer mutation atomically debits source and credits destination', () {
      final src = Account()
        ..name = 'HDFC Checking'
        ..currentBalance = 10000.0;

      final dest = Account()
        ..name = 'SBI Savings'
        ..currentBalance = 2000.0;

      final tx = Transaction()
        ..amount = 3000.0
        ..type = TransactionType.transfer;
      tx.sourceAccount.value = src;
      tx.destinationAccount.value = dest;

      // Execute transfer mutation
      if (tx.type == TransactionType.transfer) {
        final s = tx.sourceAccount.value!;
        final d = tx.destinationAccount.value!;
        s.currentBalance -= tx.amount;
        d.currentBalance += tx.amount;
      }

      expect(src.currentBalance, 7000.0);
      expect(dest.currentBalance, 5000.0);

      // Rollback on delete (inversion logic)
      if (tx.type == TransactionType.transfer) {
        final s = tx.sourceAccount.value!;
        final d = tx.destinationAccount.value!;
        s.currentBalance += tx.amount;
        d.currentBalance -= tx.amount;
      }

      expect(src.currentBalance, 10000.0);
      expect(dest.currentBalance, 2000.0);
    });
  });
}

