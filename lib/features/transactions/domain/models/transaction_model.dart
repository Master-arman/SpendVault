enum TransactionFlow {
  income,
  expense,
  transfer,
}

/// Domain entity representing a transaction record.
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.flow,
    required this.category,
    required this.date,
    required this.accountId,
    this.accountName = 'Primary Account',
    this.merchant,
    this.note,
    this.referenceNumber,
    this.isAutomated = false,
  });

  final String id;
  final String title;
  final double amount;
  final TransactionFlow flow;
  final String category;
  final DateTime date;
  final String accountId;
  final String accountName;
  final String? merchant;
  final String? note;
  final String? referenceNumber;
  final bool isAutomated;

  bool get isIncome => flow == TransactionFlow.income;
  bool get isExpense => flow == TransactionFlow.expense;
}
