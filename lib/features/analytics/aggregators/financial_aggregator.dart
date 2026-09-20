class CategoryBreakdown {
  const CategoryBreakdown({
    required this.categoryName,
    required this.totalAmount,
    required this.percentage,
  });

  final String categoryName;
  final double totalAmount;
  final double percentage;
}

/// Aggregation engine for financial analysis, monthly summaries, and category breakdowns.
class FinancialAggregator {
  const FinancialAggregator._();

  /// Calculates total net balance across all accounts.
  static double calculateNetWorth(List<double> accountBalances) {
    return accountBalances.fold(0.0, (double sum, double balance) => sum + balance);
  }

  /// Calculates total income and total expenses from a list of transactions.
  static ({double totalIncome, double totalExpense, double netSavings}) calculateTotals({
    required List<({double amount, bool isIncome})> transactions,
  }) {
    double income = 0;
    double expense = 0;

    for (final ({double amount, bool isIncome}) item in transactions) {
      if (item.isIncome) {
        income += item.amount;
      } else {
        expense += item.amount;
      }
    }

    return (
      totalIncome: income,
      totalExpense: expense,
      netSavings: income - expense,
    );
  }

  /// Generates a breakdown of expenses categorized with percentage distribution.
  static List<CategoryBreakdown> calculateCategoryDistribution(
    Map<String, double> categoryTotals,
  ) {
    final double total = categoryTotals.values.fold(0.0, (double a, double b) => a + b);
    if (total == 0) {
      return [];
    }

    return categoryTotals.entries.map((MapEntry<String, double> entry) {
      return CategoryBreakdown(
        categoryName: entry.key,
        totalAmount: entry.value,
        percentage: (entry.value / total) * 100,
      );
    }).toList()
      ..sort((CategoryBreakdown a, CategoryBreakdown b) => b.totalAmount.compareTo(a.totalAmount));
  }
}
