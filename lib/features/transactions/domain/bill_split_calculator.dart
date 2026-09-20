/// Result of bill split calculations for user share and group debt.
class BillSplitResult {
  const BillSplitResult({
    required this.totalBill,
    required this.participantsCount,
    required this.userShare,
    required this.lentAmount,
    required this.perPersonShare,
    required this.tags,
  });

  final double totalBill;
  final int participantsCount;
  final double userShare;
  final double lentAmount;
  final double perPersonShare;
  final List<String> tags;
}

/// Participant entry in a group bill split.
class SplitParticipant {
  SplitParticipant({
    required this.name,
    required this.shareAmount,
    this.isSettled = false,
  });

  final String name;
  final double shareAmount;
  bool isSettled;
}

/// Domain calculator for bill splitting and reimbursement expense bucket adjustments.
class BillSplitCalculator {
  const BillSplitCalculator._();

  /// Default tags applied to group split transactions.
  static const List<String> splitTags = ['#split', '#reimbursable'];

  /// Calculates user share and total lent amount based on:
  /// User Share = B / N
  /// Lent Amount = B - (B / N)
  static BillSplitResult calculate({
    required double totalBill,
    required int participantsCount,
  }) {
    if (participantsCount <= 1 || totalBill <= 0) {
      return BillSplitResult(
        totalBill: totalBill,
        participantsCount: 1,
        userShare: totalBill,
        lentAmount: 0.0,
        perPersonShare: totalBill,
        tags: splitTags,
      );
    }

    final double perPerson = totalBill / participantsCount;
    final double userShare = perPerson;
    final double lentAmount = totalBill - userShare;

    return BillSplitResult(
      totalBill: totalBill,
      participantsCount: participantsCount,
      userShare: userShare,
      lentAmount: lentAmount,
      perPersonShare: perPerson,
      tags: splitTags,
    );
  }

  /// Offsets payback directly from the original expense bucket instead of logging as taxable income.
  static double applyReimbursementToExpenseBucket({
    required double currentExpenseTotal,
    required double reimbursementAmount,
  }) {
    final double remainingExpense = currentExpenseTotal - reimbursementAmount;
    return remainingExpense > 0 ? remainingExpense : 0.0;
  }
}
