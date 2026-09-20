import 'package:flutter/foundation.dart';

/// Data transfer model for transaction items processed in the background isolate.
class TransactionData {
  const TransactionData({
    required this.amount,
    required this.isExpense,
    required this.timestamp,
    this.category = 'Uncategorized',
  });

  final double amount;
  final bool isExpense;
  final DateTime timestamp;
  final String category;
}

/// Result of monthly analytics aggregation.
class MonthlyAggregationResult {
  const MonthlyAggregationResult({
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.dailyExpenses,
    required this.dailyIncomes,
    required this.dailyAverageExpense,
    required this.categoryDistribution,
    required this.year,
    required this.month,
  });

  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final Map<int, double> dailyExpenses; // Day 1..31 -> amount
  final Map<int, double> dailyIncomes; // Day 1..31 -> amount
  final double dailyAverageExpense;
  final Map<String, double> categoryDistribution;
  final int year;
  final int month;
}

/// Background aggregation worker input params.
class _AggregationParams {
  const _AggregationParams({
    required this.transactions,
    required this.year,
    required this.month,
    required this.daysInMonth,
  });

  final List<TransactionData> transactions;
  final int year;
  final int month;
  final int daysInMonth;
}

/// Top-level aggregation routine executed in a worker isolate via [compute].
MonthlyAggregationResult _runAggregation(_AggregationParams params) {
  double totalIncome = 0.0;
  double totalExpense = 0.0;

  final Map<int, double> dailyExpenses = {
    for (int i = 1; i <= params.daysInMonth; i++) i: 0.0,
  };
  final Map<int, double> dailyIncomes = {
    for (int i = 1; i <= params.daysInMonth; i++) i: 0.0,
  };
  final Map<String, double> categoryTotals = {};

  for (final TransactionData tx in params.transactions) {
    if (tx.timestamp.year == params.year && tx.timestamp.month == params.month) {
      final int day = tx.timestamp.day;

      if (tx.isExpense) {
        totalExpense += tx.amount;
        dailyExpenses[day] = (dailyExpenses[day] ?? 0.0) + tx.amount;
        categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0.0) + tx.amount;
      } else {
        totalIncome += tx.amount;
        dailyIncomes[day] = (dailyIncomes[day] ?? 0.0) + tx.amount;
      }
    }
  }

  final double dailyAvg = params.daysInMonth > 0 ? (totalExpense / params.daysInMonth) : 0.0;

  return MonthlyAggregationResult(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    netSavings: totalIncome - totalExpense,
    dailyExpenses: dailyExpenses,
    dailyIncomes: dailyIncomes,
    dailyAverageExpense: dailyAvg,
    categoryDistribution: categoryTotals,
    year: params.year,
    month: params.month,
  );
}

/// Pipeline service that offloads heavy monthly summation loops to a background worker isolate.
class AnalyticsAggregator {
  const AnalyticsAggregator();

  /// Calculates monthly financial metrics in a background isolate via [compute].
  Future<MonthlyAggregationResult> aggregateMonthly({
    required List<TransactionData> transactions,
    required int year,
    required int month,
  }) async {
    // Determine days in month (handling leap years)
    final int daysInMonth = DateTime(year, month + 1, 0).day;

    final _AggregationParams params = _AggregationParams(
      transactions: transactions,
      year: year,
      month: month,
      daysInMonth: daysInMonth,
    );

    return compute(_runAggregation, params);
  }

  /// Synchronous computation useful for immediate in-process evaluations and testing.
  MonthlyAggregationResult aggregateMonthlySync({
    required List<TransactionData> transactions,
    required int year,
    required int month,
  }) {
    final int daysInMonth = DateTime(year, month + 1, 0).day;
    final _AggregationParams params = _AggregationParams(
      transactions: transactions,
      year: year,
      month: month,
      daysInMonth: daysInMonth,
    );
    return _runAggregation(params);
  }
}
