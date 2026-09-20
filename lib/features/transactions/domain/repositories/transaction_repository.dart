import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';

abstract class TransactionRepository {
  Future<List<TransactionModel>> getTransactions({int limit = 50});
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
}
