import 'package:finance_app/features/accounts/data/models/account.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:isar/isar.dart';

class TransactionService {
  const TransactionService(this.isar);

  final Isar isar;

  /// Executes an atomic transaction mutation, updating account balances and persisting the transaction record.
  Future<void> executeTransaction(Transaction tx) async {
    await isar.writeTxn(() async {
      if (tx.type == TransactionType.expense) {
        final Account src = tx.sourceAccount.value!;
        src.currentBalance -= tx.amount;
        await isar.accounts.put(src);
      } else if (tx.type == TransactionType.income) {
        final Account src = tx.sourceAccount.value!;
        src.currentBalance += tx.amount;
        await isar.accounts.put(src);
      } else if (tx.type == TransactionType.transfer) {
        final Account src = tx.sourceAccount.value!;
        final Account dest = tx.destinationAccount.value!;
        src.currentBalance -= tx.amount;
        dest.currentBalance += tx.amount;
        await isar.accounts.putAll([src, dest]);
      }

      await isar.transactions.put(tx);
      await tx.sourceAccount.save();
      if (tx.destinationAccount.value != null) {
        await tx.destinationAccount.save();
      }
      if (tx.category.value != null) {
        await tx.category.save();
      }
    });
  }

  /// Atomically rolls back balance changes associated with a transaction and deletes the record.
  Future<void> deleteTransaction(Transaction tx) async {
    await isar.writeTxn(() async {
      await tx.sourceAccount.load();
      await tx.destinationAccount.load();

      if (tx.type == TransactionType.expense) {
        final Account? src = tx.sourceAccount.value;
        if (src != null) {
          src.currentBalance += tx.amount;
          await isar.accounts.put(src);
        }
      } else if (tx.type == TransactionType.income) {
        final Account? src = tx.sourceAccount.value;
        if (src != null) {
          src.currentBalance -= tx.amount;
          await isar.accounts.put(src);
        }
      } else if (tx.type == TransactionType.transfer) {
        final Account? src = tx.sourceAccount.value;
        final Account? dest = tx.destinationAccount.value;
        if (src != null && dest != null) {
          src.currentBalance += tx.amount;
          dest.currentBalance -= tx.amount;
          await isar.accounts.putAll([src, dest]);
        }
      }

      await isar.transactions.delete(tx.id);
    });
  }

  /// Atomically rolls back old balance impact and applies new balance impact on an updated transaction.
  Future<void> updateTransaction({
    required Transaction existingTx,
    required double newAmount,
    String? newNote,
    List<String>? newTags,
  }) async {
    await isar.writeTxn(() async {
      await existingTx.sourceAccount.load();
      await existingTx.destinationAccount.load();

      final double diff = newAmount - existingTx.amount;

      if (existingTx.type == TransactionType.expense) {
        final Account? src = existingTx.sourceAccount.value;
        if (src != null) {
          src.currentBalance -= diff;
          await isar.accounts.put(src);
        }
      } else if (existingTx.type == TransactionType.income) {
        final Account? src = existingTx.sourceAccount.value;
        if (src != null) {
          src.currentBalance += diff;
          await isar.accounts.put(src);
        }
      } else if (existingTx.type == TransactionType.transfer) {
        final Account? src = existingTx.sourceAccount.value;
        final Account? dest = existingTx.destinationAccount.value;
        if (src != null && dest != null) {
          src.currentBalance -= diff;
          dest.currentBalance += diff;
          await isar.accounts.putAll([src, dest]);
        }
      }

      existingTx.amount = newAmount;
      if (newNote != null) existingTx.note = newNote;
      if (newTags != null) existingTx.tags = newTags;

      await isar.transactions.put(existingTx);
    });
  }
}
