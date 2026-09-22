import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  static final List<TransactionModel> _transactions = [];

  @override
  Future<List<TransactionModel>> getTransactions({int limit = 50}) async {
    return _transactions.take(limit).toList();
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    _transactions.insert(0, transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((TransactionModel t) => t.id == id);
  }
}
