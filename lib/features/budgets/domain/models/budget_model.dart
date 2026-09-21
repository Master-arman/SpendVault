/// Domain model representing an envelope category budget limit and tracking progress.
class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.category,
    required this.limitAmount,
    required this.spentAmount,
    this.period = 'Monthly',
    this.alertThresholdPercent = 80.0,
  });

  final String id;
  final String category;
  final double limitAmount;
  final double spentAmount;
  final String period;
  final double alertThresholdPercent;

  double get remainingAmount => (limitAmount - spentAmount).clamp(0.0, double.infinity);
  double get progressRatio => limitAmount > 0 ? (spentAmount / limitAmount).clamp(0.0, 1.0) : 0.0;
  bool get isExceeded => spentAmount > limitAmount;
  bool get isNearLimit => (progressRatio * 100) >= alertThresholdPercent;
}
