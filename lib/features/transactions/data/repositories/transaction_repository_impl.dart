import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  static final List<TransactionModel> _transactions = [
    TransactionModel(
      id: 'txn-1',
      title: 'Salary Deposit',
      amount: 75000.00,
      flow: TransactionFlow.income,
      category: 'Income',
      date: DateTime.now().subtract(const Duration(days: 1)),
      accountId: 'acc-1',
      merchant: 'Tech Corp Payroll',
      isAutomated: true,
    ),
    TransactionModel(
      id: 'txn-2',
      title: 'Nature\'s Basket Supermarket',
      amount: 1420.00,
      flow: TransactionFlow.expense,
      category: 'Food & Dining',
      date: DateTime.now().subtract(const Duration(days: 2)),
      accountId: 'acc-2',
      merchant: 'Nature\'s Basket',
      isAutomated: true,
    ),
    TransactionModel(
      id: 'txn-3',
      title: 'Apple Store Online',
      amount: 2499.00,
      flow: TransactionFlow.expense,
      category: 'Shopping',
      date: DateTime.now().subtract(const Duration(days: 3)),
      accountId: 'acc-2',
      merchant: 'Apple Services',
    ),
    TransactionModel(
      id: 'txn-4',
      title: 'Uber Ride',
      amount: 340.00,
      flow: TransactionFlow.expense,
      category: 'Transport',
      date: DateTime.now().subtract(const Duration(days: 4)),
      accountId: 'acc-1',
      merchant: 'Uber India',
      isAutomated: true,
    ),
  ];

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
